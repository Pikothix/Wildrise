# res://stats/HarvestStats.gd
extends Resource
class_name HarvestStats

@export_group("Health / Hardness")
@export var max_health: float = 10.0
@export var hardness: int = 1
@export_range(0.0, 1.0) var penalty_damage_multiplier: float = 0.25

@export_group("Loot")
@export var bonus_rolls: int = 0
@export var amount_multiplier: float = 1.0

@export_group("Skills")
@export var skill_reward_name: StringName = &""
@export var skill_reward_xp: float = 5.0
