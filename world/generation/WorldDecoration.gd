extends RefCounted
class_name WorldDecoration

var world: WorldGenBase

func _init(p_world: WorldGenBase) -> void:
	world = p_world

func _decoration_conditions_met(cond: Dictionary, h: float, t: float, m: float, tree: float) -> bool:
	if cond.has("h_min") and h < cond["h_min"]:
		return false
	if cond.has("h_max") and h > cond["h_max"]:
		return false
	if cond.has("t_min") and t < cond["t_min"]:
		return false
	if cond.has("t_max") and t > cond["t_max"]:
		return false
	if cond.has("m_min") and m < cond["m_min"]:
		return false
	if cond.has("m_max") and m > cond["m_max"]:
		return false
	if cond.has("tree_min") and tree < cond["tree_min"]:
		return false
	if cond.has("tree_max") and tree > cond["tree_max"]:
		return false
	return true

func decorate_tile(
	biome: String,
	pos: Vector2i,
	h: float,
	t: float,
	m: float,
	tree: float
) -> void:
	var rules: Array = world.world_config.decoration_rules.get(biome, [])
	if rules.is_empty():
		return

	# RNG for tile
	var rng := world._get_rng_for_tile(pos, biome)

	for rule in rules:
		var cond: Dictionary = rule.get("conditions", {})
		if not _decoration_conditions_met(cond, h, t, m, tree):
			continue

		# use the tile RNG instead of global randf()
		if rng.randf() > rule["prob"]:
			continue

		match rule["type"]:
			"scene":
				var scene: PackedScene = world.world_config.object_tiles[rule["name"]]
				world.place(scene, pos)
			"tile":
				var tile_names: Array = rule["tiles"]
				var layer_name: String = rule["layer"]
				var layer := world.tile_layers.get(layer_name, null) as TileMapLayer

				if layer and not tile_names.is_empty():
					var idx := rng.randi_range(0, tile_names.size() - 1)
					var tile_name: String = tile_names[idx]
					var info := TileLibrary.get_tile(tile_name)

					if info:
						var atlas := info.get_random_variant()
						layer.set_cell(pos, world.source_id, atlas)
