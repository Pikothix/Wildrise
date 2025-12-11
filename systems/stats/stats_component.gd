extends Node
class_name StatsComponent

@export var stats: Stats

var _runtime_stats: Stats

func get_stats() -> Stats:
	# Lazily create the runtime copy the first time we're asked for it
	if _runtime_stats == null:
		if stats:
			_runtime_stats = stats.duplicate()
			# Ensure the runtime copy has proper derived values & full HP
			_runtime_stats.setup_stats()
		else:
			push_warning("StatsComponent: no Stats resource assigned")
	return _runtime_stats
