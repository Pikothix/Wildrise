extends NonPlayerCharacter

@export var stats: Stats  # optional, sync with Hurtbox if empty

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: NodeStateMachine = $StateMachine

var _base_modulate: Color = Color.WHITE
var _last_attacker: Node = null
var target: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var _facing_left: bool = false


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

	if anim_sprite:
		_base_modulate = anim_sprite.modulate

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)


func _on_hit_received(damage: int, from: Area2D) -> void:
	if is_dead:
		return

	var hitbox := from as Hitbox
	if hitbox and hitbox.instigator:
		_last_attacker = hitbox.instigator
		if hitbox.instigator is Player:
			target = hitbox.instigator as Player

			# only start aggro if we're not already in the middle of an attack
			if not is_attacking:
				_start_aggro_after_hurt()

	# --- VISUAL FEEDBACK ---
	if anim_sprite:
		anim_sprite.modulate = Color(1.0, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(anim_sprite, "modulate", _base_modulate, 0.1)

		# only play hurt if not attacking (don't override attack animation)
		if not is_attacking \
		and anim_sprite.sprite_frames \
		and anim_sprite.sprite_frames.has_animation("hurt"):
			anim_sprite.play("hurt")

	# --- SMALL KNOCKBACK ---
	if hitbox and hitbox.instigator is Node2D:
		var attacker_pos := (hitbox.instigator as Node2D).global_position
		var dir := (global_position - attacker_pos).normalized()
		velocity += dir * 40.0



func _start_aggro_after_hurt() -> void:
	# tiny delay so hurt is visible
	await get_tree().create_timer(0.15).timeout

	if is_dead:
		return
	if target == null or !is_instance_valid(target):
		return
	if state_machine:
		state_machine.transition_to("Chase")



func _on_health_depleted() -> void:
	if is_dead:
		return
	is_dead = true

	if state_machine:
		state_machine.transition_to("Death")
	else:
		set_physics_process(false)
		set_process(false)
		if hurtbox:
			hurtbox.monitoring = false
			hurtbox.monitorable = false
			hurtbox.collision_layer = 0
			hurtbox.collision_mask = 0
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true

		if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("death"):
			anim_sprite.play("death")
			anim_sprite.animation_finished.connect(func():
				queue_free()
			, CONNECT_ONE_SHOT)
		else:
			queue_free()


func update_facing_from_vector(dir: Vector2) -> void:
	# Only care about horizontal direction
	if dir.x == 0.0:
		return

	_facing_left = dir.x < 0.0

	if anim_sprite:
		anim_sprite.flip_h = _facing_left 
