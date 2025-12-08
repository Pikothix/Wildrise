extends Resource
class_name Stats



signal health_depleted
signal health_changed(current_health: float, max_health: float)
signal level_changed(new_level: int)



enum BuffableStats {
	MAX_HEALTH,
	DEFENCE,
	ATTACK,
}

enum Faction {
	PLAYER,
	ENEMY,
}

const STAT_CURVES: Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://d3e0fgsnbi0um"),
	BuffableStats.DEFENCE:    preload("uid://g46w5p1p4cri"),
	BuffableStats.ATTACK:     preload("uid://dgukgkkhkfej0"),
}

const BASE_LEVEL_EXP: float = 150.0
const LEVEL_EXPONENT: float = 1.8
const MAX_LEVEL: int = 100


@export var base_agility: float = 5.0
@export var base_accuracy: float = 5.0
@export var base_crit_chance: float = 0.05
@export var base_crit_damage: float = 1.5
@export var base_attack_speed: float = 1.0



@export var base_max_health: float = 100.0
@export var speed: float = 50
@export var base_strength: float = 10.0
@export var base_defence: float = 10.0
@export var base_attack: float = 10.0
@export var experience: float = 0.0  
@export var faction: Faction = Faction.PLAYER


var current_agility: float = 0.0
var current_accuracy: float = 0.0
var current_crit_chance: float = 0.0
var current_crit_damage: float = 0.0
var current_attack_speed: float = 0.0



var level: int:
	get():
		return _get_level_from_experience(experience)

var current_defence: float = 10.0
var current_strength: float = 10.0
var current_attack: float = 10.0
var current_max_health: float = 100.0

var stat_buffs: Array[StatBuff] = []

var _current_health: float = 0.0

var current_health: float:
	get:
		return _current_health
	set(value):
		_set_current_health(value)

func _init() -> void:
	# Initial setup AFTER curves/values exist
	setup_stats.call_deferred()


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	var prev := _current_health
	current_health = _current_health - amount  # will call _set_current_health

	#print("Stats.take_damage:", self,
		#"amount =", amount,
		#"prev =", prev,
		#"new =", _current_health)


func _set_current_health(value: float) -> void:
	var prev := _current_health
	_current_health = clampf(value, 0.0, current_max_health)
	health_changed.emit(_current_health, current_max_health)

	#print("Stats._set_current_health:", self,
		#"prev =", prev,
		#"after clamp =", _current_health,
		#"max =", current_max_health)

	# Only emit death when we actually cross the boundary from >0 to <=0
	if prev > 0.0 and _current_health <= 0.0:
		print("Stats: health_depleted emitted for", self)
		health_depleted.emit()



func setup_stats() -> void:
	recalculate_stats()
	# Set to full HP on setup, but don’t emit death here
	_current_health = current_max_health
	health_changed.emit(_current_health, current_max_health)
	#print(_current_health)


func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()


func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()


func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}

	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()

		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount

			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount

				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0

	var stat_sample_pos: float = clampf(float(level) / 100.0, 0.0, 0.99)

	# Base stats from curves
	current_max_health = base_max_health * STAT_CURVES[BuffableStats.MAX_HEALTH].sample(stat_sample_pos)
	current_defence    = base_defence    * STAT_CURVES[BuffableStats.DEFENCE].sample(stat_sample_pos)
	current_attack     = base_attack     * STAT_CURVES[BuffableStats.ATTACK].sample(stat_sample_pos)

	# base values for your extra stats (no curves yet)
	current_agility       = base_agility
	current_accuracy      = base_accuracy
	current_crit_chance   = base_crit_chance
	current_crit_damage   = base_crit_damage
	current_attack_speed  = base_attack_speed


	# Apply multiplicative buffs
	for stat_name in stat_multipliers:
		var cur_property_name: String = "current_" + stat_name
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])

	# Apply additive buffs
	for stat_name in stat_addends:
		var cur_property_name: String = "current_" + stat_name
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])

	# Clamp internal health WITHOUT firing death
	_current_health = clampf(_current_health, 0.0, current_max_health)
	health_changed.emit(_current_health, current_max_health)



func add_experience(amount: float) -> void:
	if amount <= 0.0:
		return

	var old_level: int = level
	experience += amount

	print("XP DEBUG: Added", amount, "XP. Total XP =", experience, "Level =", level)

	var new_level: int = level
	if new_level != old_level:
		recalculate_stats()
		level_changed.emit(new_level)
		print("XP DEBUG: Level up! New level =", new_level)




func _get_total_exp_for_level(lvl: int) -> float:
	if lvl <= 1:
		return 0.0
	var n := float(lvl - 1)
	return BASE_LEVEL_EXP * pow(n, LEVEL_EXPONENT)


func _get_level_from_experience(exp: float) -> int:
	var lvl := 1
	for i in range(2, MAX_LEVEL + 1):
		if exp < _get_total_exp_for_level(i):
			break
		lvl = i
	return lvl


func set_level(new_level: int) -> void:
	# Clamp to valid range
	new_level = clamp(new_level, 1, MAX_LEVEL)

	# Set XP to the minimum for that level
	experience = _get_total_exp_for_level(new_level)

	# Recalculate stats and notify
	recalculate_stats()
	level_changed.emit(level)
