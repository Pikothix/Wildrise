extends NodeState

@export var player: Player
@export var hit_comp_collision: CollisionShape2D

var _done := false

func _ready() -> void:
	hit_comp_collision.disabled = true
	hit_comp_collision.position = Vector2(0,-7)

func _on_enter() -> void:
	_done = false
	hit_comp_collision.disabled = false

	# You can optionally trigger an animation state here
	# anim_tree["parameters/StateMachine/transition_request"] = "Chop"

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
	hit_comp_collision.disabled = true
