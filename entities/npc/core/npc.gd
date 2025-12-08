extends NonPlayerCharacter

@export var stats_component: StatsComponent
var stats: Stats
@export var death_rewards: DeathRewards


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
	# Keep existing random walk setup
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)

	# --- Resolve stats from StatsComponent ---
	if stats_component:
		stats = stats_component.get_stats()
	else:
		push_warning("Enemy has no StatsComponent assigned; cannot resolve Stats.")
	
	if stats == null:
		push_warning("StatsComponent has no Stats resource; death logic won't run.")
	else:
		# Wire Hurtbox to use the same Stats instance
		if hurtbox:
			hurtbox.owner_stats = stats
			if not hurtbox.hit_received.is_connected(_on_hit_received):
				hurtbox.hit_received.connect(_on_hit_received)
		else:
			push_warning("Enemy has no Hurtbox child; cannot receive damage.")

		# Connect death signal once
		if not stats.health_depleted.is_connected(_on_health_depleted):
			stats.health_depleted.connect(_on_health_depleted)

	# --- Visual setup ---
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

	# Reward XP to the player that killed this enemy
	if _last_attacker is Player:
		var player: Player = _last_attacker

		if death_rewards:
			# Skill XP (slayer, woodcutting, etc.)
			if player.skill_set:
				for skill_reward in death_rewards.skill_rewards:
					if skill_reward.xp_amount > 0.0 and skill_reward.skill_name != &"":
						player.skill_set.add_experience(
							skill_reward.skill_name,
							skill_reward.xp_amount
						)



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
