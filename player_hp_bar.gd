extends Control

@export var stats_component: StatsComponent
var stats: Stats

@onready var health_bar: ProgressBar = $MarginContainer/HealthBar
@onready var level_label: Label = $MarginContainer/LevelLabel

func _ready() -> void:
	# 1) Prefer the exported StatsComponent
	if stats_component:
		stats = stats_component.get_stats()
	else:
		# 2) Fallback: find the Player by group
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.stats_component:
			stats_component = player.stats_component
			stats = stats_component.get_stats()

	if stats:
		if not stats.health_changed.is_connected(_on_health_changed):
			stats.health_changed.connect(_on_health_changed)
		_on_health_changed(stats.current_health, stats.current_max_health)

		if not stats.level_changed.is_connected(_on_level_changed):
			stats.level_changed.connect(_on_level_changed)
		_on_level_changed(stats.level)
	else:
		push_warning("HUD: no Stats resolved; HP/level will not update")

func _on_health_changed(current: float, max: float) -> void:
	if health_bar:
		health_bar.max_value = max
		health_bar.value = current

func _on_level_changed(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv " + str(new_level)
