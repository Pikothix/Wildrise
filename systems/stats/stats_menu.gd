extends Control
class_name StatsMenu

@export var stats: Stats   # overridden at runtime

@onready var stats_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/StatsList
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel

var _is_open: bool = false
var _stats_connected: bool = false


func _ready() -> void:
	visible = false
	title_label.text = "Stats"
	print("StatsMenu: _ready called")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_stats"):
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	_is_open = not _is_open
	visible = _is_open

	if _is_open:
		print("StatsMenu: opening, resolving Stats...")
		_ensure_stats()
		_refresh_stats()
	else:
		print("StatsMenu: closing")

func _ensure_stats() -> void:
	# Prefer Player's Stats
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.stats:
		if stats != player.stats:
			print("StatsMenu: overriding exported Stats with Player's Stats:", player.stats)
		stats = player.stats
		_connect_stats_signals()     # NEW
		return

	# Fallback: use exported
	if stats != null:
		print("StatsMenu: using exported Stats:", stats)
		_connect_stats_signals()     # NEW
	else:
		push_warning("StatsMenu: no Stats found (no Player and none exported)")


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
