extends NodeState

@export var npc: NonPlayerCharacter
@export var animated_sprite_2d: AnimatedSprite2D
@export var move_speed: float = 45.0
@export var attack_range: float = 20.0
@export var give_up_distance: float = 200.0

var agent: NavigationAgent2D



func _ready() -> void:
	if npc == null:
		npc = owner as NonPlayerCharacter

	agent = npc.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	# We don't actually need velocity_computed here; Walk already uses it.
	# So don't connect it in Chase to avoid fighting with Walk.
	# if agent:
	#     agent.velocity_computed.connect(_on_velocity_computed)


func _on_enter() -> void:
	if npc.target == null or !is_instance_valid(npc.target):
		transition.emit("Idle")
		return

	if animated_sprite_2d \
	and animated_sprite_2d.sprite_frames \
	and animated_sprite_2d.sprite_frames.has_animation("walk"):
		animated_sprite_2d.play("walk")



func _on_exit() -> void:
	if animated_sprite_2d:
		animated_sprite_2d.stop()



func _on_physics_process(delta: float) -> void:
	if npc.target == null or !is_instance_valid(npc.target):
		transition.emit("Idle")
		return

	var target_node := npc.target as Node2D
	var target_pos: Vector2 = target_node.global_position
	var dist := npc.global_position.distance_to(target_pos)

	# If close enough, stop and maybe attack
	if dist <= attack_range:
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
		# don't change facing here; it keeps last direction
		if npc.can_attack:
			transition.emit("Attack")
		return


	# If too far, lose aggro
	if dist > give_up_distance:
		npc.target = null
		transition.emit("Idle")
		return

	# Move towards the target
	if agent:
		agent.target_position = target_pos
		var next_pos: Vector2 = agent.get_next_path_position()
		var dir: Vector2 = (next_pos - npc.global_position)
		if dir.length() > 1.0:
			dir = dir.normalized()

		npc.velocity = dir * move_speed
		npc.update_facing_from_vector(dir)
		npc.move_and_slide()
	else:
		var dir: Vector2 = (target_pos - npc.global_position)
		if dir.length() > 1.0:
			dir = dir.normalized()

		npc.velocity = dir * move_speed
		npc.update_facing_from_vector(dir)
		npc.move_and_slide()




func _on_velocity_computed(safe_velocity: Vector2) -> void:
	# Only needed if you decide to use agent.velocity_computed in Chase.
	npc.velocity = safe_velocity
