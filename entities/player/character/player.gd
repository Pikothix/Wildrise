# Player.gd
class_name Player
extends CharacterBody2D

@export var skill_set: SkillSet
@onready var Woodcutting: Label = $Woodcutting
@onready var Slayer: Label = $Slayer

@export var inventory_gui: InventoryGui   
@export var inventory: Inventory
@export var hotbar: HotbarUI  

var last_move_dir: Vector2 = Vector2.DOWN

@export var drop_collectable_scene: PackedScene

@export var respawn_delay: float = 0.0  # seconds; set > 0 later for death anim

@export var stats_component: StatsComponent

var stats: Stats


@export var hitbox_scene: PackedScene

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sprite: Sprite2D = $Sprite2D
var _base_modulate: Color = Color.WHITE


@export var speed: float = 50.0
var input_vector = Vector2.ZERO

@onready var anim_tree: AnimationTree = $AnimationTree 

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

var equipped_damage: int = 1
var equipped_tool: DataTypes.Tools = DataTypes.Tools.None
var is_dead: bool = false



func _input(event: InputEvent) -> void:

	# ---------------------------------------
	# PREVENT HOTBAR-ONLY ACTIONS WHEN INVENTORY IS OPEN
	# ---------------------------------------
	var hotbar_blocked := (inventory_gui != null and inventory_gui.is_open)

	# ---------------------------------------
	# Attack / Hitbox
	# ---------------------------------------
	if event.is_action_pressed("hit2"):
		_equip_from_hotbar_selection()

		if hitbox_scene == null:
			push_warning("Player has no hitbox_scene assigned")
			return

		var hitbox: Hitbox = hitbox_scene.instantiate()
		hitbox.attacker_stats = stats
		hitbox.hitbox_lifetime = 0.5              
		hitbox.current_tool = equipped_tool
		hitbox.hit_damage = equipped_damage

		hitbox.instigator = self
		hitbox.global_position = global_position

		# I prefer adding to the main scene, but you can keep it under the player if you want
		get_tree().current_scene.add_child(hitbox)



	# ---------------------------------------
	# Hotbar drop ONLY works when inventory is closed
	# ---------------------------------------
	if not hotbar_blocked and event.is_action_pressed("drop_item"):
		_drop_from_hotbar()


func _ready() -> void:
	# --- Resolve stats from component ---
	if stats_component == null:
		push_warning("Player has NO StatsComponent assigned!")
	else:
		stats = stats_component.get_stats()
		if stats == null:
			push_warning("StatsComponent has NO Stats resource assigned!")
		else:
			print("Player Stats (from StatsComponent):", stats)

	if sprite:
		_base_modulate = sprite.modulate

	print("Player _ready. stats =", stats, "hurtbox =", hurtbox)

	# --- Wire hurtbox to use the same Stats instance ---
	if hurtbox:
		hurtbox.owner_stats = stats
		print("Player Hurtbox owner_stats after assign:", hurtbox.owner_stats)
		hurtbox.hit_received.connect(_on_hit_received)
	else:
		push_warning("Player has NO Hurtbox node (HurtBox) as a child")

	# --- Stats signals / setup, same as before ---
	if stats:
		stats.setup_stats()

		var callable := Callable(self, "_on_health_depleted")
		if not stats.is_connected("health_depleted", callable):
			stats.health_depleted.connect(callable)
			print("Player: connected health_depleted for Stats:", stats)

	add_to_group("player")
	ToolManager.tool_selected.connect(on_tool_selected)

	# Find the InventoryGui in the scene tree
	var inv_gui := get_tree().root.find_child("InventoryGui", true, false) as InventoryGui
	if inv_gui:
		inventory_gui = inv_gui
		inv_gui.drop_requested.connect(on_inventory_drop_requested)
	else:
		push_warning("Player: could not find InventoryGui to connect drop_requested")

func _on_hit_received(damage: int, from: Area2D) -> void:
	#print("Player took", damage, "damage from", from)  # debug
	# Visual feedback: flash red
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", _base_modulate, 0.1)

	# Tiny knockback away from the attacker (optional)
	if from is Node2D:
		var attacker_pos := (from as Node2D).global_position
		var dir := (global_position - attacker_pos).normalized()
		velocity += dir * 40.0

func _process(_delta: float) -> void:
	_update_skill_debug_label()

func _update_skill_debug_label() -> void:
	if Woodcutting == null or skill_set == null:
		return

	var wood_skill := skill_set.get_skill(&"woodcutting")  # match your skill name
	if wood_skill == null:
		Woodcutting.text = "Woodcutting: (no skill)"
	var slayer_skill := skill_set.get_skill(&"slayer")
	if slayer_skill:
		Slayer.text = "Slayer Lv.%d  XP: %.1f" % [slayer_skill.level, slayer_skill.experience]

		return

	# You can format however you like
	Woodcutting.text = "Woodcutting Lv.%d  XP: %.1f" % [
		wood_skill.level,
		wood_skill.experience
	]



func _on_health_depleted() -> void:
	if is_dead:
		return
	is_dead = true

	var death_pos := global_position
	print("PLAYER DIED at", death_pos)

	# Drop all items at the death location
	_drop_all_inventory_at(death_pos)

	# Stop input / movement
	set_physics_process(false)
	set_process(false)

	# Visual feedback – grey out / hide
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5)

	# If no delay, respawn instantly (current behaviour you want)
	if respawn_delay <= 0.0:
		_respawn(Vector2.ZERO)
		return

	# Otherwise, wait – later this can be replaced with a death animation
	await get_tree().create_timer(respawn_delay).timeout
	_respawn(Vector2.ZERO)

func _respawn(respawn_position: Vector2) -> void:
	global_position = respawn_position

	# Reset stats to full health
	if stats:
		stats.setup_stats()

	# Reset flags & visuals
	is_dead = false

	if sprite:
		sprite.modulate = _base_modulate

	set_physics_process(true)
	set_process(true)

	print("PLAYER RESPAWNED at", respawn_position)





##inventory##

func on_tool_selected(tool: DataTypes.Tools) -> void:
	current_tool = tool
	equipped_tool = tool
	#print("Tool (from ToolManager):", tool)

func update_current_tool_from_inventory_item(item: InventoryItem) -> void:
	if item == null:
		current_tool = DataTypes.Tools.None
		equipped_tool = DataTypes.Tools.None
		equipped_damage = 0

		#print("Player: cleared tool")
		return

	current_tool = item.tool_type
	equipped_tool = item.tool_type
	equipped_damage = max(1, item.chop_power)

	#print("Player: equipped item", item.name, 
		#"tool =", current_tool, 
		#"hit_damage =", hit_component.hit_damage)
	#print("EQUIP DEBUG:",
		#"item =", item.name,
		#"tool_type =", item.tool_type,
		#"item_chop_power =", item.chop_power,
		#"player_attack_stat =", stats.current_attack)

func _equip_from_hotbar_selection() -> void:
	if inventory == null or hotbar == null:
		return

	var columns := hotbar.columns  # or just 5 if COLUMNS is not exported
	var row: int = hotbar.active_row
	var col: int = hotbar.currently_selected

	var slot_index: int = row * columns + col

	if slot_index < 0 or slot_index >= inventory.slots.size():
		print("Player: hotbar index out of range:", slot_index)
		update_current_tool_from_inventory_item(null)
		return

	var slot: InventorySlot = inventory.slots[slot_index]
	if slot == null or slot.item == null:
		#print("Player: hotbar slot", slot_index, "is empty.")
		update_current_tool_from_inventory_item(null)
		return

	var item: InventoryItem = slot.item
	print("Player: equipping from inv index", slot_index, "item:", item.name)
	update_current_tool_from_inventory_item(item)

func drop_item_from_inventory(index: int, amount: int = 1) -> void:
	print("DROP: index =", index, "amount =", amount)
	if inventory == null or drop_collectable_scene == null:
		print("DROP: missing inventory or drop_collectable_scene")
		return

	if index < 0 or index >= inventory.slots.size():
		print("DROP: index out of range")
		return

	var slot: InventorySlot = inventory.slots[index]
	if slot == null or slot.item == null:
		print("DROP: slot empty")
		return

	var item: InventoryItem = slot.item

	var taken: int = inventory.take_from_index(index, amount)
	print("DROP: item =", item.name, "taken =", taken)
	#print("PLAYER POS DURING DROP:", global_position)
	if taken <= 0:
		return

	var dropped := drop_collectable_scene.instantiate()
	if dropped == null:
		print("DROP: instantiate returned null")
		return

	var cc: CollectableComponent = dropped as CollectableComponent
	if cc == null:
		cc = dropped.get_node_or_null("CollectableComponent")
	if cc != null:
		cc.item_resource = item
		cc.amount = taken

		# 🔹 Ensure dropped items behave like tree logs
		cc.collision_layer = 1 << 5      # Layer 6: "Collectable"
		cc.collision_mask  = 1 << 1      # Mask 2: "player_hurtbox"

	else:
		print("DROP: no CollectableComponent found on dropped scene")

	var drop_offset := Vector2(0, 16)

	var parent := get_parent()
	if parent == null:
		print("DROP: player has no parent, using current_scene instead")
		parent = get_tree().current_scene

	parent.add_child(dropped)
	_animate_drop(dropped)

	print("DROP: spawned", item.name, "as", dropped, "under parent", parent, "path:", dropped.get_path())

func _animate_drop(dropped: Node2D) -> void:
	# Base direction: where the player last moved / is facing
	var base_dir := last_move_dir
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.DOWN

	# Add a bit of random spread so drops don't all stack perfectly
	var spread_deg := 35.0
	var rand_angle := deg_to_rad(randf_range(-spread_deg, spread_deg))
	var dir := base_dir.rotated(rand_angle).normalized()

	var distance := 20.0  # how far it pops out
	var start := global_position
	var end := start + dir * distance

	dropped.global_position = start

	var tween := create_tween()
	tween.tween_property(
		dropped,
		"global_position",
		end,
		0.18
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func _drop_from_hotbar() -> void:
	if inventory == null or hotbar == null:
		print("DROP HOTBAR: missing inventory or hotbar")
		return

	var columns: int = hotbar.columns
	var row: int = hotbar.active_row
	var col: int = hotbar.currently_selected 
	var index: int = row * columns + col

	print("DROP HOTBAR: row =", row, "col =", col, "index =", index)

	drop_item_from_inventory(index, 9999)



func on_inventory_drop_requested(index: int) -> void:
	print("INV DROP REQUESTED: index =", index)
	drop_item_from_inventory(index, 9999)


func _drop_all_inventory_at(position: Vector2) -> void:
	if inventory == null or drop_collectable_scene == null:
		print("DEATH DROP: missing inventory or drop_collectable_scene")
		return

	var slots_count := inventory.slots.size()

	for i in range(slots_count):
		var slot: InventorySlot = inventory.slots[i]
		if slot == null or slot.item == null:
			continue

		# Grab the item *before* we remove it
		var item: InventoryItem = slot.item

		# Take everything from this slot (9999 = effectively "all")
		var taken: int = inventory.take_from_index(i, 9999)
		if taken <= 0:
			continue

		var dropped := drop_collectable_scene.instantiate()
		if dropped == null:
			continue

		var cc: CollectableComponent = dropped as CollectableComponent
		if cc == null:
			cc = dropped.get_node_or_null("CollectableComponent")

		if cc != null:
			cc.item_resource = item
			cc.amount = taken
			cc.collision_layer = 1 << 5      # Layer 6: "Collectable"
			cc.collision_mask  = 1 << 1      # Mask 2: "player_hurtbox"

		var parent := get_parent()
		if parent == null:
			parent = get_tree().current_scene
		parent.add_child(dropped)

		# Scatter them a bit around the death position
		var offset := Vector2(
			randf_range(-16.0, 16.0),
			randf_range(-16.0, 16.0)
		)
		dropped.global_position = position + offset

		print("DEATH DROP: dropped", item.name, "x", taken, "from slot", i)
