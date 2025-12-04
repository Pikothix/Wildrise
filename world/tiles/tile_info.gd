# TileInfo.gd
class_name TileInfo
extends Resource

@export var tile_name: String                     # "grass", "sand", etc.
@export var atlas_coords: Vector2i                # Base tile atlas coordinate
@export var variants: Array[Vector2i] = []        # Optional variant coords
@export var terrain_type: String = ""             # e.g. "grass", "water", "sand"
@export var walkable: bool = true                 # Movement allowed?
@export var is_water: bool = false
@export var is_lava: bool = false
@export var speed_multiplier: float = 1.0         # Slow/fast tiles
@export var tile_color_debug: Color = Color.WHITE # Used in debug biome map

func get_random_variant() -> Vector2i:
	if variants.size() == 0:
		return atlas_coords
	return variants[randi() % variants.size()]
