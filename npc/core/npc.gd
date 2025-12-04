extends NonPlayerCharacter

@export var stats: Stats  # optional, sync with Hurtbox if empty

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: NodeStateMachine = $StateMachine

func _ready() -> void:
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)

	# Keep stats / hurtbox.owner_stats in sync
	if stats == null and hurtbox and hurtbox.owner_stats:
		stats = hurtbox.owner_stats
	elif stats != null and hurtbox and hurtbox.owner_stats == null:
		hurtbox.owner_stats = stats

	if stats:
		stats.health_depleted.connect(_on_health_depleted)
	else:
		push_warning("Enemy has no Stats resource assigned; death logic won't run.")

func _on_health_depleted() -> void:
	if is_dead:
		return
	is_dead = true

	
	# Just push into the Death state – it will do the rest.
	if state_machine:
		state_machine.transition_to("Death")
	else:
		# Fallback if for some reason there is no state machine.
		set_physics_process(false)
		set_process(false)
		if hurtbox:
			hurtbox.monitoring = false
			hurtbox.monitorable = false
			hurtbox.collision_layer = 0
			hurtbox.collision_mask = 0
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true

		if anim_sprite and anim_sprite.has_animation("death"):
			anim_sprite.play("death")
			anim_sprite.animation_finished.connect(func():
				queue_free()
			, CONNECT_ONE_SHOT)
		else:
			queue_free()
