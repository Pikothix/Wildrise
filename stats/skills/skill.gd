extends Resource
class_name Skill

signal level_up(new_level: int)
signal experience_changed(current_experience: float)

@export var skill_name: StringName = &""        # e.g. &"woodcutting"
@export var experience: float = 0.0
@export var base_level_exp: float = 100.0       # tweak per-skill if you like
@export var level_exponent: float = 1.6
@export var max_level: int = 100

var level: int:
	get:
		return _get_level_from_experience(experience)

func add_experience(amount: float) -> void:
	if amount <= 0.0:
		return

	var old_level := level
	experience += amount
	experience_changed.emit(experience)

	var new_level := level
	if new_level > old_level:
		level_up.emit(new_level)

func _get_total_exp_for_level(lvl: int) -> float:
	if lvl <= 1:
		return 0.0
	var n := float(lvl - 1)
	return base_level_exp * pow(n, level_exponent)

func _get_level_from_experience(exp: float) -> int:
	var lvl := 1
	for i in range(2, max_level + 1):
		if exp < _get_total_exp_for_level(i):
			break
		lvl = i
	return lvl
