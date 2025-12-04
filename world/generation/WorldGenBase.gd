extends Node2D
class_name WorldGenBase

var biome_counts: Dictionary = {}

@export var npc_spawn_data: Array[NpcSpawnData] = []
@onready var NpcRoot: Node2D = $NpcRoot

var npc_counts_by_chunk: Dictionary = {}



@export var world_config: WorldGenConfig

@export var player_path: NodePath
var player: Node2D

@export var chunk_size: int = 64 # tiles per side

@export var height_noise_texture: NoiseTexture2D
@export var temperature_noise_texture: NoiseTexture2D
@export var moisture_noise_texture: NoiseTexture2D
@export var tree_noise_texture: NoiseTexture2D

@export var use_fixed_seed := false
@export var fixed_seed:= 123
var world_seed: int

var height_noise : Noise
var temperature_noise : Noise
var moisture_noise : Noise
var tree_noise : Noise

@export var source_id : int = 2

@onready var WaterLayer: TileMapLayer = $WaterLayer
@onready var GroundLayer: TileMapLayer = $GroundLayer
@onready var CliffLayer: TileMapLayer = $CliffLayer
@onready var EnvLayer: TileMapLayer = $EnvLayer
@onready var TestLayer: TileMapLayer = $Test

@onready var EnvRoot: Node2D = $EnvRoot

var tile_layers := {}
var biome_map = {}

var h_min := INF
var h_max := -INF
var t_min := INF
var t_max := -INF
var m_min := INF
var m_max := -INF
var tree_min := INF
var tree_max := -INF

@export var height_scale: float = 0.3
@export var temp_scale: float = 0.3
@export var moist_scale: float = 0.3
@export var tree_scale: float = 0.3

var decorator: WorldDecoration

func _ready():
	if use_fixed_seed:
		world_seed = fixed_seed
		seed(fixed_seed)
	else:
		randomize()
		world_seed = randi()  # seed for the world

	_init_noise()

	tile_layers = {
		"EnvLayer": EnvLayer,
		"GroundLayer": GroundLayer,
		"WaterLayer": WaterLayer,
		"CliffLayer": CliffLayer,
	}

	if player_path != NodePath():
		player = get_node(player_path) as Node2D

	decorator = WorldDecoration.new(self)

func _init_noise():
	height_noise = height_noise_texture.noise
	temperature_noise = temperature_noise_texture.noise
	moisture_noise = moisture_noise_texture.noise
	tree_noise = tree_noise_texture.noise

	if use_fixed_seed:
		height_noise.seed = fixed_seed
		temperature_noise.seed = fixed_seed + 1
		moisture_noise.seed = fixed_seed + 2
		tree_noise.seed = fixed_seed + 3

func sample_noise(pos: Vector2i) -> Dictionary:
	var xf: float = float(pos.x)
	var yf: float = float(pos.y)

	return {
		"h": height_noise.get_noise_2d(xf * height_scale, yf * height_scale),
		"t": temperature_noise.get_noise_2d(xf * temp_scale, yf * temp_scale),
		"m": moisture_noise.get_noise_2d(xf * moist_scale, yf * moist_scale),
		"tree": tree_noise.get_noise_2d(xf * tree_scale, yf * tree_scale),
	}

func normalise_noise(v: float) -> float:
	#map from -1,1 to 0,1
	return (v + 1.0) * 0.5

func world_to_tile(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = GroundLayer.to_local(world_pos)
	return GroundLayer.local_to_map(local)

func tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(
		floor(float(tile.x) / chunk_size),
		floor(float(tile.y) / chunk_size)
	)

func get_biome(h: float, t: float, m: float) -> String:
	for biome in world_config.biomes:
		var hmin: float = biome["h_min"]
		var hmax: float = biome["h_max"]

		if h < hmin or h >= hmax:
			continue
		if biome.has("t_min") and t < biome["t_min"]:
			continue
		if biome.has("t_max") and t > biome["t_max"]:
			continue
		if biome.has("m_min") and m < biome["m_min"]:
			continue
		if biome.has("m_max") and m > biome["m_max"]:
			continue
		return biome["name"]
	return "plains"

func pick_weighted_tile(biome_name: String) -> Vector2i:
	var data: Dictionary = world_config.biome_tiles.get(biome_name)
	if data == null:
		push_warning("No biome_tiles entry for biome '%s', falling back to grass" % biome_name)
		var fallback := TileLibrary.get_tile("grass")
		return fallback.get_random_variant()

	var tile_names: Array = data["tiles"]
	var weights: Array = data["weights"]

	if tile_names.is_empty():
		var fallback := TileLibrary.get_tile("grass")
		return fallback.get_random_variant()

	var roll := randf()
	var accum := 0.0
	var chosen_name: String = tile_names.back()

	for i in tile_names.size():
		accum += float(weights[i])
		if roll <= accum:
			chosen_name = tile_names[i]
			break

	var info := TileLibrary.get_tile(chosen_name)
	if info == null:
		push_warning("Tile '%s' not found in TileLibrary, using grass" % chosen_name)
		info = TileLibrary.get_tile("grass")

	return info.get_random_variant()


func place(scene: PackedScene, cell: Vector2i) -> void:
	var inst := scene.instantiate()
	inst.position = GroundLayer.map_to_local(cell)
	# Store which chunk object belongs to
	inst.set_meta("chunk_coord", tile_to_chunk(cell))
	EnvRoot.add_child(inst)

func _generate_tile_at(pos: Vector2i) -> void:
	var raw := sample_noise(pos)

	var h := normalise_noise(raw["h"])
	var t := normalise_noise(raw["t"])
	var m := normalise_noise(raw["m"])
	var tree := normalise_noise(raw["tree"])
	
	# track min/max (debug) in normal space
	h_min = min(h_min, h)
	h_max = max(h_max, h)
	t_min = min(t_min, t)
	t_max = max(t_max, t)
	m_min = min(m_min, m)
	m_max = max(m_max, m)
	tree_min = min(tree_min, tree)
	tree_max = max(tree_max, tree)

	var biome := get_biome(h, t, m)

	# count biomes
	if not biome_counts.has(biome):
		biome_counts[biome] = 0
	biome_counts[biome] += 1

	match biome:
		"ocean", "lake":
			var water_info := TileLibrary.get_tile("water")
			if water_info != null:
				WaterLayer.set_cell(pos, source_id, water_info.get_random_variant())
			else:
				push_warning("TileLibrary: 'water' tile not found, skipping water tile at %s" % [pos])
		"beach", "dirt", "plains", "jungle", "desert", "mountain", "snow":
			var tile := pick_weighted_tile(biome)
			GroundLayer.set_cell(pos, source_id, tile)
		_:
			# Fallback: treat unknown biomes like plains
			var tile := pick_weighted_tile("plains")
			GroundLayer.set_cell(pos, source_id, tile)

	decorator.decorate_tile(biome, pos, h, t, m, tree)
	biome_map[pos] = biome
	
	# NEW: config-driven NPC spawning
	_spawn_npcs_for_tile(pos, biome, h, t, m)

func _get_rng_for_tile(pos: Vector2i, biome: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	# Combine world_seed, tile position and biome into a single seed.
	var combined_hash := hash(Vector3i(pos.x, pos.y, biome.hash()))
	var combined_seed: int = world_seed ^ int(combined_hash)
	rng.seed = combined_seed
	return rng
	
	
func _spawn_npcs_for_tile(tile_pos: Vector2i, biome: String, h: float, t: float, m: float) -> void:
	# Using typed NpcSpawnData resources instead of dictionary config
	if npc_spawn_data.is_empty():
		return

	var chunk_coord := tile_to_chunk(tile_pos)
	var rng := _get_rng_for_tile(tile_pos, biome)

	for def in npc_spawn_data:
		if def == null:
			continue

		# Biome filter
		if not def.allowed_biomes.is_empty():
			# allowed_biomes is Array[StringName], biome is String
			var biome_name: StringName = StringName(biome)
			if not def.allowed_biomes.has(biome_name):
				continue

		# Height / temp / moisture filters
		if h < def.min_height or h > def.max_height:
			continue
		if t < def.min_temp or t > def.max_temp:
			continue
		if m < def.min_moisture or m > def.max_moisture:
			continue

		# Per-chunk cap
		var id_str: String = String(def.id)
		if id_str != "" and def.max_per_chunk < 999:
			if _count_npcs_of_type_in_chunk(id_str, chunk_coord) >= def.max_per_chunk:
				continue

		# Spawn roll
		if rng.randf() <= def.base_spawn_chance:
			_spawn_npc_group_from_data(def, tile_pos, chunk_coord, rng)


func _spawn_npc_group_from_data(def: NpcSpawnData, center_tile_pos: Vector2i, center_chunk: Vector2i, rng: RandomNumberGenerator) -> void:
	var group_min: int = int(max(def.group_min, 1))
	var group_max: int = int(max(def.group_max, group_min))
	var group_radius: int = int(max(def.group_radius, 0))

	var group_size: int = group_min
	if group_max > group_min:
		group_size = rng.randi_range(group_min, group_max)

	var npc_id: String = String(def.id)
	var max_per_chunk: int = def.max_per_chunk

	for i in range(group_size):
		# Respect max_per_chunk per chunk
		if npc_id != "" and max_per_chunk < 999:
			if _count_npcs_of_type_in_chunk(npc_id, center_chunk) >= max_per_chunk:
				break

		var spawn_tile: Vector2i = center_tile_pos

		# Offset around the center tile to form a loose flock
		if group_radius > 0:
			var offset: Vector2i = Vector2i(
				rng.randi_range(-group_radius, group_radius),
				rng.randi_range(-group_radius, group_radius)
			)
			spawn_tile += offset

		var spawn_chunk: Vector2i = tile_to_chunk(spawn_tile)
		_spawn_single_npc_from_data(def, spawn_tile, spawn_chunk)


func _spawn_single_npc_from_data(def: NpcSpawnData, tile_pos: Vector2i, chunk_coord: Vector2i) -> void:
	if def.npc_scene == null:
		return

	var npc := def.npc_scene.instantiate()

	var local_pos := GroundLayer.map_to_local(tile_pos)
	var world_pos := GroundLayer.to_global(local_pos)
	npc.global_position = world_pos

	var npc_id := String(def.id)

	npc.set_meta("chunk_coord", chunk_coord)
	npc.set_meta("npc_id", npc_id)

	NpcRoot.add_child(npc)

	if not npc_counts_by_chunk.has(chunk_coord):
		npc_counts_by_chunk[chunk_coord] = {}

	if not npc_counts_by_chunk[chunk_coord].has(npc_id):
		npc_counts_by_chunk[chunk_coord][npc_id] = 0

	npc_counts_by_chunk[chunk_coord][npc_id] += 1



func _count_npcs_of_type_in_chunk(npc_id: String, chunk_coord: Vector2i) -> int:
	var count := 0
	for npc in NpcRoot.get_children():
		if not npc.has_meta("chunk_coord"):
			continue
		if npc.get_meta("chunk_coord") != chunk_coord:
			continue
		if npc.has_meta("npc_id") and npc.get_meta("npc_id") == npc_id:
			count += 1
	return count
