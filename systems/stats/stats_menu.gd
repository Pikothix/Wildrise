extends Control
class_name StatsMenu

@export var stats: Stats   # can still be set in the inspector if you want
@export var use_own_input: bool = true

@onready var stats_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/StatsList
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel

var _is_open: bool = false
var _stats_connected: bool = false


func _ready() -> void:
	visible = false
	title_label.text = "Stats"
	print("StatsMenu: _ready called")


func set_open(open: bool) -> void:
	_is_open = open
	visible = open

	if _is_open:
		print("StatsMenu: opening (from parent)")
		_connect_stats_signals()
		_refresh_stats()
	else:
		print("StatsMenu: closing (from parent)")


func set_stats(new_stats: Stats) -> void:
	# Called by CharacterMenu / whoever owns this menu
	if stats == new_stats:
		return

	stats = new_stats
	_stats_connected = false
	_connect_stats_signals()

	if _is_open:
		_refresh_stats()


func _refresh_stats() -> void:
	if stats == null:
		push_warning("StatsMenu: no Stats; nothing to display")
		return

	if stats_list == null:
		push_warning("StatsMenu: StatsList VBox not found")
		return

	# Clear old rows
	for child in stats_list.get_children():
		child.queue_free()

	print("StatsMenu: refreshing stats for", stats)

	# --- Basic character summary ---
	_add_stat_row("Level", str(stats.level))
	_add_stat_row("XP", "%.1f" % stats.experience)

	# --- Health ---
	var hp_text := "%d / %d" % [int(stats.current_health), int(stats.current_max_health)]
	_add_stat_row("Health", hp_text)

	# --- Core combat stats ---
	_add_stat_row("Attack", "%.1f" % stats.current_attack)
	_add_stat_row("Defence", "%.1f" % stats.current_defence)
	_add_stat_row("Strength", "%.1f" % stats.current_strength)

	# --- Movement (from Stats.speed) ---
	_add_stat_row("Speed", "%.1f" % stats.speed)

	# Give the list some height so ScrollContainer behaves nicely
	var row_height := 24.0
	stats_list.custom_minimum_size.y = stats_list.get_child_count() * row_height
	print("StatsMenu: StatsList now has", stats_list.get_child_count(), "rows")


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 24

	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 120

	row.add_child(name_label)
	row.add_child(value_label)
	stats_list.add_child(row)


func _connect_stats_signals() -> void:
	if _stats_connected or stats == null:
		return

	if not stats.health_changed.is_connected(_on_stats_health_changed):
		stats.health_changed.connect(_on_stats_health_changed)

	if not stats.level_changed.is_connected(_on_stats_level_changed):
		stats.level_changed.connect(_on_stats_level_changed)

	_stats_connected = true


func _on_stats_health_changed(_current: float, _max: float) -> void:
	if _is_open:
		_refresh_stats()


func _on_stats_level_changed(_new_level: int) -> void:
	if _is_open:
		_refresh_stats()
