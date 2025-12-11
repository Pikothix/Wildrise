# tree.gd
extends Sprite2D

var _last_hit_attacker: Node = null


@onready var hurtbox: Hurtbox = $Hurtbox
@onready var damage_component: DamageComponent = $DamageComponent

@export var harvest_stats: HarvestStats
@export var loot_table: LootTable
@export var drop_collectable_scene: PackedScene
@export var required_tool: DataTypes.Tools = DataTypes.Tools.None  # NEW: tool gate

const TREE_SHADER := preload("res://shaders/tree_shake.gdshader")

func _ready():
	# Ensure a unique ShaderMaterial per instance
	if material:
		material = material.duplicate()
	else:
		var sm := ShaderMaterial.new()
		sm.shader = TREE_SHADER
		material = sm
	material.resource_local_to_scene = true

	# Connect to the Hurtbox instead of HurtComponent
	if hurtbox:
		hurtbox.hit_received.connect(on_hurt)

	damage_component.max_damage_reached.connect(on_max_damaged_reached)

	# hook harveststats
	if harvest_stats:
		damage_component.max_damage = harvest_stats.max_health

func on_hurt(raw_damage: int, from: Area2D) -> void:
	var hitbox := from as Hitbox

	# Track attacker for XP reward later
	if hitbox != null and hitbox.instigator != null:
		_last_hit_attacker = hitbox.instigator

	# Tool gating
	var tool_used := hitbox.current_tool if hitbox != null else DataTypes.Tools.None
	if required_tool != DataTypes.Tools.None and tool_used != required_tool:
		return

	print("Tree hurt: raw_damage =", raw_damage,
		" hardness =", harvest_stats.hardness if harvest_stats else -1,
		" max_damage =", damage_component.max_damage)

	var final_damage := float(raw_damage)

	# Hardened object logic:
	if harvest_stats:
		# If tool power (raw_damage) < hardness → apply penalty
		if raw_damage < harvest_stats.hardness:
			# either do zero damage:
			final_damage = 0.0
			# or do reduced damage:
			#final_damage *= harvest_stats.penalty_damage_multiplier

	# Apply damage
	damage_component.apply_damage(final_damage)

	# shake effect
	if material is ShaderMaterial:
		material.set_shader_parameter("shake_intensity", 0.5)
		await get_tree().create_timer(0.25).timeout
		material.set_shader_parameter("shake_intensity", 0.0)

# Called when this breakable hits max damage (tree "dies")
func on_max_damaged_reached() -> void:
	_reward_harvest_xp()
	call_deferred("drop_loot")
	queue_free()

func _reward_harvest_xp() -> void:
	if harvest_stats == null:
		return
	if harvest_stats.skill_reward_xp <= 0.0:
		return
	if harvest_stats.skill_reward_name == &"":
		return
	if _last_hit_attacker == null:
		return

	# We expect the attacker to be a Player
	var player := _last_hit_attacker as Player
	if player == null:
		return

	if player.skill_set:
		player.skill_set.add_experience(harvest_stats.skill_reward_name, harvest_stats.skill_reward_xp)
		print("Gave", harvest_stats.skill_reward_xp, "XP to", harvest_stats.skill_reward_name, "for", player)




func drop_loot() -> void:
	if loot_table == null:
		print("Tree: no loot_table assigned")
		return
	if drop_collectable_scene == null:
		print("Tree: no drop_collectable_scene assigned")
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# --- base extra rolls from harvest stats ---
	var extra_rolls := 0
	if harvest_stats:
		extra_rolls += harvest_stats.bonus_rolls

	var loot_results: Array[Dictionary] = loot_table.generate_loot(rng, extra_rolls)
	if loot_results.is_empty():
		print("Tree: loot table rolled nothing")
		return

	for result in loot_results:
		var item: InventoryItem = result["item"]
		var amount: int = result["amount"]

		# Apply amount multiplier from harvest stats (if any)
		if harvest_stats and harvest_stats.amount_multiplier != 1.0:
			amount = int(ceil(amount * harvest_stats.amount_multiplier))

		var dropped := drop_collectable_scene.instantiate() as Node2D
		if dropped == null:
			continue

		var cc: CollectableComponent = dropped as CollectableComponent
		if cc == null:
			cc = dropped.get_node_or_null("CollectableComponent")

		if cc != null:
			cc.item_resource = item
			cc.amount = amount

		var offset := Vector2(
			rng.randf_range(-8.0, 8.0),
			rng.randf_range(-4.0, 12.0)
		)

		get_parent().add_child(dropped)
		dropped.global_position = global_position + offset
