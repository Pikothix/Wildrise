extends NodeState

var enemy: NonPlayerCharacter
var sprite: AnimatedSprite2D

const CORPSE_SCENE := preload("uid://bwnan6bc2nywc")  # your corpse scene

func _on_enter() -> void:
	enemy = get_parent().get_parent() as NonPlayerCharacter
	if enemy == null:
		return

	if enemy.has_node("AnimatedSprite2D"):
		sprite = enemy.get_node("AnimatedSprite2D") as AnimatedSprite2D

	enemy.is_dead = true
	enemy.set_physics_process(false)
	enemy.set_process(false)
	if "velocity" in enemy:
		enemy.velocity = Vector2.ZERO

	# TODO: disable hurtbox / collisions here if you haven't already

	var frames := sprite.sprite_frames if sprite else null

	if sprite and frames and frames.has_animation("death"):
		sprite.animation = "death"
		sprite.play()
		sprite.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)
	else:
		_on_death_anim_finished()  # no death anim, just go straight to corpse


func _on_death_anim_finished() -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(sprite):
		return

	var frames := sprite.sprite_frames
	if frames == null:
		# No frames at all – just free
		enemy.queue_free()
		return

	# Explicitly pick the last frame of the "death" animation
	var anim_name: StringName = "death"
	if not frames.has_animation(anim_name):
		# Fallback: use whatever animation is active
		anim_name = sprite.animation

	var frame_count := frames.get_frame_count(anim_name)
	if frame_count <= 0:
		frame_count = 1
	var last_frame := frame_count - 1

	# Spawn corpse
	var corpse := CORPSE_SCENE.instantiate() as Corpse
	corpse.global_position = enemy.global_position

	corpse.source_frames    = frames
	corpse.source_animation = anim_name
	corpse.source_frame     = last_frame

	get_tree().current_scene.add_child(corpse)
	enemy.queue_free()


func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	pass

func _on_exit() -> void:
	pass
