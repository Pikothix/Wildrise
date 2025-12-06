extends NodeState

@export var player: Player
@export var hit_comp_collision: CollisionShape2D
@export var chop_duration: float = 0.30

var _done := false

func _ready() -> void:
	_done = false

func _on_enter() -> void:
	_done = false
	
	_chop_window()

func _chop_window() -> void:
	await get_tree().create_timer(0.30).timeout
	_done = true

func _on_next_transitions() -> void:
	# PRIORITY: movement cancels chop immediately
	if GameInputEvent.is_movement_input():
		transition.emit("Move")
		return
	# otherwise leave chop when the short window ends
	if _done:
		transition.emit("Idle")

func _on_exit() -> void:
	pass
