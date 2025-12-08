extends Control
class_name NpcInspectPanel

var target_npc: Node = null
var target_stats: Stats = null

@onready var name_label: Label  = $Panel/MarginContainer/VBox/NameLabel
@onready var level_label: Label = $Panel/MarginContainer/VBox/LevelLabel
@onready var hp_label: Label    = $Panel/MarginContainer/VBox/HpLabel
@onready var stats_label: Label = $Panel/MarginContainer/VBox/StatsLabel

func _ready() -> void:
	visible = false

func set_target(npc: Node) -> void:
	# Toggle: if we're already inspecting this npc and visible, close it
	if npc != null and target_npc == npc and visible:
		clear_inspect()
		return

	# Clear previous target/signals
	_clear_target()

	# If npc is null, just hide and stop
	if npc == null:
		visible = false
		return

	target_npc = npc

	# Try to resolve StatsComponent in a few ways
	var stats_comp: StatsComponent = null

	# 1) If NPC has an exported stats_component property
	if "stats_component" in npc and npc.stats_component is StatsComponent:
		stats_comp = npc.stats_component
	# 2) Fallback: child node named "StatsComponent"
	elif npc.has_node("StatsComponent"):
		stats_comp = npc.get_node("StatsComponent") as StatsComponent

	if stats_comp:
		target_stats = stats_comp.get_stats()
	else:
		target_stats = null

	# Fill basic info
	if name_label:
		if "display_name" in npc:
			name_label.text = str(npc.display_name)
		else:
			name_label.text = npc.name

	# Connect to stats if available
	if target_stats:
		if not target_stats.health_changed.is_connected(_on_health_changed):
			target_stats.health_changed.connect(_on_health_changed)
		if not target_stats.level_changed.is_connected(_on_level_changed):
			target_stats.level_changed.connect(_on_level_changed)

		_on_level_changed(target_stats.level)
		_on_health_changed(target_stats.current_health, target_stats.current_max_health)
		_update_stats_line()
	else:
		if level_label:
			level_label.text = "Lv ?"
		if hp_label:
			hp_label.text = "HP ?"
		if stats_label:
			stats_label.text = ""

	visible = true


func _clear_target() -> void:
	if target_stats:
		if target_stats.health_changed.is_connected(_on_health_changed):
			target_stats.health_changed.disconnect(_on_health_changed)
		if target_stats.level_changed.is_connected(_on_level_changed):
			target_stats.level_changed.disconnect(_on_level_changed)

	target_stats = null
	target_npc = null

func _on_health_changed(current: float, max: float) -> void:
	if hp_label:
		hp_label.text = "HP %d / %d" % [int(current), int(max)]

func _on_level_changed(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv %d" % new_level
	_update_stats_line()

func _update_stats_line() -> void:
	if stats_label and target_stats:
		stats_label.text = """
ATK  %.1f  
DEF  %.1f
AGI  %.1f
ACC  %.1f
CRIT %.0f%%
CRIT DMG x%.2f
SPD  %.2f
""" % [
			target_stats.current_attack,
			target_stats.current_defence,
			target_stats.current_agility,
			target_stats.current_accuracy,
			target_stats.current_crit_chance * 100.0,
			target_stats.current_crit_damage,
			target_stats.current_attack_speed
		]


func clear_inspect() -> void:
	_clear_target()
	visible = false
