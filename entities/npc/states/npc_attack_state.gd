extends NodeState

@export var npc: NonPlayerCharacter
@export var hitbox_scene: PackedScene   # assign your Hitbox.tscn here
@export var animated_sprite_2d: AnimatedSprite2D
@export var attack_range: float = 20.0
@export var attack_windup: float = 0.1
@export var attack_recover: float = 0.2
@export var attack_cooldown: float = 1.5  # seconds between attacks (tweak per NPC)


var _done: bool = false


func _ready() -> void:
	if npc == null:
		npc = owner as NonPlayerCharacter


func _on_enter() -> void:
	_done = false

	if npc.target == null or !is_instance_valid(npc.target):
		transition.emit("Idle")
		return
		
	npc.is_attacking = true 

	# stop moving while attacking
	npc.velocity = Vector2.ZERO

	if animated_sprite_2d \
	and animated_sprite_2d.sprite_frames \
	and animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.play("attack")

	_do_attack()


func _on_exit() -> void:
	npc.is_attacking = false

	if animated_sprite_2d:
		animated_sprite_2d.stop()

	_start_attack_cooldown()

func _start_attack_cooldown() -> void:
	if attack_cooldown <= 0.0:
		return

	npc.can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	npc.can_attack = true



func _do_attack() -> void:
	
	await get_tree().create_timer(attack_windup).timeout

	if npc.target == null or !is_instance_valid(npc.target):
		_done = true
		return

	var target_node := npc.target as Node2D
	var target_pos: Vector2 = target_node.global_position

	# Only bite if still in range
	var dist := npc.global_position.distance_to(target_pos)
	if dist > attack_range:
		_done = true
		return

	if hitbox_scene == null:
		push_warning("NpcAttackState: hitbox_scene not assigned")
		_done = true
		return

	var bite: Hitbox = hitbox_scene.instantiate()

	# Drive damage from NPC stats
	if npc.stats:
		bite.attacker_stats = npc.stats
		bite.hit_damage = max(1, npc.stats.current_attack)
	else:
		bite.hit_damage = 1

	bite.hitbox_lifetime = 0.15
	bite.instigator = npc

	# Position the hitbox between NPC and target
	var dir: Vector2 = (target_pos - npc.global_position).normalized()
	npc.update_facing_from_vector(dir)
	var offset: Vector2 = dir * 12.0
	bite.global_position = npc.global_position + offset

	npc.get_tree().current_scene.add_child(bite)

	# Recovery before allowing next transition
	await get_tree().create_timer(attack_recover).timeout
	_done = true


func _on_next_transitions() -> void:
	# If target is gone, go idle
	if npc.target == null or !is_instance_valid(npc.target):
		transition.emit("Idle")
		return

	# When attack sequence is done, go back to Chase (so it can re-attack)
	if _done:
		transition.emit("Chase")
