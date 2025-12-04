extends WorldGenBase

@onready var main_viewport: Viewport = get_viewport()

@onready var occlusion_viewport: SubViewport = $OcclusionViewport
@onready var silhouette_sprite: Sprite2D = $Player/Sprite2D/SilhouetteSprite

var loaded_chunks: Dictionary = {} # Vector2i -> bool
@export var load_radius_chunks: int = 2   # how many chunks around the player to keep generated
var current_center_chunk: Vector2i = Vector2i.ZERO

var generated_chunks: Dictionary = {} #Vector2i -> bool


func _ready():
	super()
	
	
		# --- Silhouette / occlusion setup ---
	# Share the same 2D world so the occlusion viewport sees the same nodes.
	occlusion_viewport.world_2d = get_viewport().world_2d
	# Optional: this is usually default for a visible SubViewport, but harmless to keep.
	occlusion_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Pass the occlusion texture into the silhouette shader.
	var occ_tex: Texture2D = occlusion_viewport.get_texture()
	if occ_tex and silhouette_sprite.material is ShaderMaterial:
		var mat := silhouette_sprite.material as ShaderMaterial
		mat.set_shader_parameter("occlusion_tex", occ_tex)
	# --- end silhouette / occlusion setup ---
	
	
	
	if world_config == null:
		print("WorldGenConfig is not assigned on this node!")
		return
	if player:
		var tile_pos: Vector2i = world_to_tile(player.global_position)
		current_center_chunk = tile_to_chunk(tile_pos)
	else:
		current_center_chunk = Vector2i.ZERO

	_update_chunks_around_player()

func _process(_delta: float) -> void:
	# Critical bit: make occlusion viewport use the same 2D camera transform
	occlusion_viewport.canvas_transform = main_viewport.canvas_transform
	if player == null:
		return

	var tile_pos: Vector2i = world_to_tile(player.global_position)
	var player_chunk: Vector2i = tile_to_chunk(tile_pos)

	if player_chunk != current_center_chunk:
		current_center_chunk = player_chunk
		_update_chunks_around_player()

func generate_chunk(chunk_coord: Vector2i) -> void:
	if generated_chunks.has(chunk_coord):
		return

	generated_chunks[chunk_coord] = true

	var start_x: int = chunk_coord.x * chunk_size
	var start_y: int = chunk_coord.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			_generate_tile_at(Vector2i(x, y))

func _update_chunks_around_player() -> void:
	var desired: Array[Vector2i] = []
	for cx in range(current_center_chunk.x - load_radius_chunks, current_center_chunk.x + load_radius_chunks + 1):
		for cy in range(current_center_chunk.y - load_radius_chunks, current_center_chunk.y + load_radius_chunks + 1):
			desired.append(Vector2i(cx, cy))

	var desired_set: Dictionary = {}
	for c in desired:
		desired_set[c] = true

	# LOAD: any chunk within distance
	for chunk_coord in desired:
		if not loaded_chunks.has(chunk_coord):
			generate_chunk(chunk_coord)
			loaded_chunks[chunk_coord] = true

	# UNLOAD: any loaded chunk not within distance
	var to_unload: Array[Vector2i] = []
	for chunk_coord in loaded_chunks.keys():
		if not desired_set.has(chunk_coord):
			to_unload.append(chunk_coord)

	for chunk_coord in to_unload:
		_unload_chunk(chunk_coord)
		loaded_chunks.erase(chunk_coord)
		
func _unload_chunk(chunk_coord: Vector2i) -> void:
	var start_x: int = chunk_coord.x * chunk_size
	var start_y: int = chunk_coord.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var pos := Vector2i(x, y)
			WaterLayer.erase_cell(pos)
			GroundLayer.erase_cell(pos)
			CliffLayer.erase_cell(pos)
			EnvLayer.erase_cell(pos)
			if biome_map.has(pos):
				biome_map.erase(pos)



	# Remove environment objects from this chunk
	for child in EnvRoot.get_children():
		if child.has_meta("chunk_coord") and child.get_meta("chunk_coord") == chunk_coord:
			child.queue_free()

	# Remove NPCs from this chunk
	for npc in NpcRoot.get_children():
		if npc.has_meta("chunk_coord") and npc.get_meta("chunk_coord") == chunk_coord:
			npc.queue_free()


	if generated_chunks.has(chunk_coord):
		generated_chunks.erase(chunk_coord)
