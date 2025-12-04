extends NodeState

@export var player: Player
@export var anim_tree: AnimationTree

var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	playback = anim_tree.get("parameters/StateMachine/MoveState/playback")

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	var input_vec: Vector2 = GameInputEvent.movement_input()

	if input_vec == Vector2.ZERO:
		# Just stop moving and let Idle handle the animation
		player.velocity = Vector2.ZERO
		transition.emit("Idle")
		return

	# movement + facing
	player.last_move_dir = input_vec.normalized()
	player.velocity = player.last_move_dir * player.speed
	player.move_and_slide()

	# update walk direction (remember your Y flip if you use it)
	var anim_dir := player.last_move_dir
	anim_dir.y = -anim_dir.y
	anim_tree.set("parameters/StateMachine/MoveState/Walk/blend_position", anim_dir)
	anim_tree.set("parameters/StateMachine/MoveState/StandState/blend_position", anim_dir)

	playback.travel("Walk")

func _on_next_transitions() -> void:
	if player.current_tool == DataTypes.Tools.AxeWood and GameInputEvent.use_tool():
		transition.emit("Chop")

func _on_enter() -> void:
	# when entering Move, keep current facing and start walking
	var anim_dir := player.last_move_dir
	anim_dir.y = -anim_dir.y
	anim_tree.set("parameters/StateMachine/MoveState/Walk/blend_position", anim_dir)
	playback.travel("Walk")

func _on_exit() -> void:
	player.velocity = Vector2.ZERO
