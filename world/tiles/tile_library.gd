# TileLibrary.gd
extends Node

var _tiles: Dictionary = {}         # tile_name → TileInfo
var _coords_lookup: Dictionary = {} # atlas_coords → TileInfo

func _ready():
	randomize()
	_register_default_tiles()

func register_tile(info: TileInfo):
	_tiles[info.tile_name] = info
	_coords_lookup[info.atlas_coords] = info

	for v in info.variants:
		_coords_lookup[v] = info

func get_tile(name: String) -> TileInfo:
	return _tiles.get(name)

func get_tile_from_coords(coords: Vector2i) -> TileInfo:
	return _coords_lookup.get(coords)

func get_all_tiles() -> Dictionary:
	return _tiles


# ------------------------------------------------------------------------------
# DEFAULT TILE DEFINITIONS
# You can move these into .tres files later, but for now this is perfect.
# ------------------------------------------------------------------------------

func _register_default_tiles():
	# Water
	var water := TileInfo.new()
	water.tile_name = "water"
	water.atlas_coords = Vector2i(0, 0)
	water.variants = [
		Vector2i(0, 0)
	]
	water.walkable = false
	water.is_water = true
	water.terrain_type = "water"
	water.tile_color_debug = Color(0.2, 0.4, 0.9)
	register_tile(water)

	# Grass
	var grass := TileInfo.new()
	grass.tile_name = "grass"
	grass.atlas_coords = Vector2i(0, 2)
	grass.variants = [
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2)
	]
	grass.terrain_type = "grass"
	grass.tile_color_debug = Color(0.3, 0.8, 0.3)
	register_tile(grass)

	# Sand
	var sand := TileInfo.new()
	sand.tile_name = "sand"
	sand.atlas_coords = Vector2i(1, 1)
	sand.variants = [
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 1)
	]
	sand.terrain_type = "sand"
	sand.tile_color_debug = Color(0.9, 0.85, 0.5)
	register_tile(sand)

	# Dirt
	var dirt := TileInfo.new()
	dirt.tile_name = "dirt"
	dirt.atlas_coords = Vector2i(5, 1)
	dirt.variants = [
		Vector2i(5, 1),
		Vector2i(6, 1),
		Vector2i(7, 1)
	]
	dirt.terrain_type = "dirt"
	dirt.tile_color_debug = Color(0.45, 0.25, 0.1)
	register_tile(dirt)

	# Jungle
	var jungle := TileInfo.new()
	jungle.tile_name = "jungle"
	jungle.atlas_coords = Vector2i(0, 3)
	jungle.variants = [
		Vector2i(0, 3),
		Vector2i(1, 3),
		Vector2i(2, 3)
	]
	jungle.terrain_type = "jungle"
	jungle.tile_color_debug = Color(0.1, 0.6, 0.1)
	register_tile(jungle)

	# Snow
	var snow := TileInfo.new()
	snow.tile_name = "snow"
	snow.atlas_coords = Vector2i(0, 1)
	snow.variants = [
		Vector2i(0, 1)
	]
	snow.terrain_type = "snow"
	snow.tile_color_debug = Color(0.9, 0.9, 1.0)
	register_tile(snow)

	# Mountain
	var mountain := TileInfo.new()
	mountain.tile_name = "mountain"
	mountain.atlas_coords = Vector2i(0, 5)
	mountain.variants = [
		Vector2i(0, 5),
		Vector2i(1, 5),
		Vector2i(2, 5)
	]
	mountain.terrain_type = "mountain"
	mountain.tile_color_debug = Color(0.5, 0.5, 0.5)
	register_tile(mountain)

	# Sandblade
	var sandblade := TileInfo.new()
	sandblade.tile_name = "sandblade"
	sandblade.atlas_coords = Vector2i(5, 6)
	sandblade.variants = [
		Vector2i(5, 6),
		Vector2i(6, 6),
		Vector2i(7, 6),
		Vector2i(8, 6),
		Vector2i(9, 6),
		Vector2i(10, 6)
	]
	sandblade.terrain_type = "sandblade"
	sandblade.tile_color_debug = Color(1.0, 0.9, 0.6)
	register_tile(sandblade)

	# Mushroom
	var mushroom := TileInfo.new()
	mushroom.tile_name = "mushroom"
	mushroom.atlas_coords = Vector2i(12, 4)
	mushroom.variants = [
		Vector2i(12, 4),
		Vector2i(13, 4),
		Vector2i(14, 4)
	]
	mushroom.terrain_type = "mushroom"
	mushroom.tile_color_debug = Color(0.8, 0.4, 0.8)
	register_tile(mushroom)

	# Pettle
	var pettle := TileInfo.new()
	pettle.tile_name = "pettle"
	pettle.atlas_coords = Vector2i(12, 3)
	pettle.variants = [
		Vector2i(12, 3),
		Vector2i(13, 3),
		Vector2i(14, 3)
	]
	pettle.terrain_type = "pettle"
	pettle.tile_color_debug = Color(1.0, 0.7, 0.8)
	register_tile(pettle)

	# Flower
	var flower := TileInfo.new()
	flower.tile_name = "flower"
	flower.atlas_coords = Vector2i(8, 5)
	flower.variants = [
		Vector2i(8, 5),
		Vector2i(9, 5),
		Vector2i(10, 5)
	]
	flower.terrain_type = "flower"
	flower.tile_color_debug = Color(1.0, 0.5, 0.7)
	register_tile(flower)


	## Lava
	#var lava := TileInfo.new()
	#lava.tile_name = "lava"
	#lava.atlas_coords = Vector2i(1, 4)
	#lava.walkable = false
	#lava.is_lava = true
	#lava.speed_multiplier = 0.5
	#lava.terrain_type = "lava"
	#lava.tile_color_debug = Color(1.0, 0.4, 0.2)
	#register_tile(lava)
