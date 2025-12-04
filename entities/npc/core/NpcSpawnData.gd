# res://worldgen/NpcSpawnData.gd
extends Resource
class_name NpcSpawnData

@export_category("Identity")
@export var id: StringName
@export var display_name: String = ""

@export_category("Scene")
@export var npc_scene: PackedScene

@export_category("Spawning")
@export var allowed_biomes: Array[StringName] = []  # ["plains", "jungle", ...]
@export var base_spawn_chance: float = 0.01        # per tile
@export var max_per_chunk: int = 999               # optional cap

# Optional extra knobs:
@export var min_height: float = 0.0  # 0–1 noise range
@export var max_height: float = 1.0
@export var min_temp: float = 0.0
@export var max_temp: float = 1.0
@export var min_moisture: float = 0.0
@export var max_moisture: float = 1.0
