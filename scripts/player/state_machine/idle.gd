extends NodeState

@export var player: Player
@export var anim_tree: AnimationTree

var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	playback = anim_tree.get("parameters/StateMachine/MoveState/playback")

func _on_physics_process(_delta: float) -> void:
	var input_vec: Vector2 = GameInputEvent.movement_input()
	if input_vec != Vector2.ZERO:
		transition.emit("Move")

func _on_enter() -> void:
	# Use last facing direction for idle, with the same Y flip
	var anim_dir := player.last_move_dir
	anim_dir.y = -anim_dir.y
	anim_tree.set("parameters/StateMachine/MoveState/StandState/blend_position", anim_dir)
	playback.travel("StandState")

func _on_exit() -> void:
	pass
