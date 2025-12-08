extends Node2D

@export var stats_component: StatsComponent
@export var offset := Vector2(0, -20)

var stats: Stats

func _ready() -> void:
	# Try exported StatsComponent first
	if stats_component:
		stats = stats_component.get_stats()
	else:
		# Fallback: try to find a StatsComponent on the parent (enemy)
		if get_parent().has_node("StatsComponent"):
			var comp := get_parent().get_node("StatsComponent") as StatsComponent
			if comp:
				stats = comp.get_stats()

	if stats:
		if not stats.health_changed.is_connected(_update_bar):
			stats.health_changed.connect(_update_bar)
		_update_bar(stats.current_health, stats.current_max_health)
	else:
		push_warning("EnemyHpBar: could not resolve Stats from StatsComponent")

func _process(_delta: float) -> void:
	# Follow the owning enemy
	var owner := get_parent()
	if owner is Node2D:
		global_position = owner.global_position + offset

func _update_bar(current: float, max: float) -> void:
	$Control/Bar.max_value = max
	$Control/Bar.value = current
	visible = current < max
