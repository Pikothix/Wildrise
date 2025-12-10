extends Node
class_name StatsComponent

@export var stats: Stats

var _runtime_stats: Stats

func get_stats() -> Stats:
	if _runtime_stats == null:
		if stats:
			_runtime_stats = stats.duplicate()
			_runtime_stats.setup_stats()  # curves & health initialised
		else:
			push_warning("StatsComponent: no Stats resource assigned")
	return _runtime_stats
