class_name CollectableComponent
extends Area2D

@export var item_resource: InventoryItem
@export var collectable_name: String
@export var amount: int = 1

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var pickup_enabled: bool = false   # gates when we allow pickup

# Bobbing settings
var bob_amplitude: float = 1    # how many pixels up/down
var bob_speed: float = 0.5         # cycles per second (higher = faster)



func _ready() -> void:
	# Allow this area to detect PhysicsBodies immediately
	monitoring = true
	monitorable = true

	# Make sure the signal is connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Set name + sprite RIGHT AWAY (no await)
	if item_resource and collectable_name == "":
		collectable_name = item_resource.name

	_update_visual()

	# 🔹 Fade in on spawn
	_fade_in()

	# 🔹 Delay pickup
	_start_pickup_delay()

	# 🔹 Optional: bobbing effect
	_start_bobbing()

func _start_pickup_delay() -> void:
	pickup_enabled = false
	await get_tree().create_timer(0.2).timeout
	pickup_enabled = true


func _update_visual() -> void:
	if sprite == null:
		return
	if item_resource == null:
		return
	if item_resource.texture == null:
		return

	sprite.texture = item_resource.texture


func _on_body_entered(body: Node) -> void:
	# 🔹 Ignore all bodies until delay has passed
	if not pickup_enabled:
		return

	if not (body is Player):
		return

	var player := body as Player
	_try_give_to_inventory(player.inventory)


func collect(inventory: Inventory) -> void:
	# If you want scripted collect() to bypass the delay, leave as-is.
	# If you want *everything* to respect the delay, uncomment the next 3 lines:
	# if not pickup_enabled:
	#     return
	_try_give_to_inventory(inventory)


func _try_give_to_inventory(inventory: Inventory) -> void:
	if inventory == null or item_resource == null:
		return

	var ok := inventory.insert(item_resource, amount)

	if ok:
		print("Collectable: picked up", amount, "x", item_resource.name)
		queue_free()
	else:
		print("Collectable: inventory full, cannot pick up", item_resource.name)

func _start_bobbing() -> void:
	if sprite == null:
		return

	# base Y position of the sprite
	var base_y := sprite.position.y
	var up_y := base_y - bob_amplitude
	var down_y := base_y + bob_amplitude

	# one half-cycle duration (up or down)
	var half_cycle := 1.0 / (bob_speed * 2.0)

	# small random offset so multiple items don't sync perfectly
	var initial_offset := randf_range(-half_cycle, half_cycle)
	sprite.position.y = lerp(up_y, down_y, randf())

	var tween := create_tween()
	tween.set_loops()  # loop forever

	# optional: start after a tiny random delay so items are out of phase
	if initial_offset > 0.0:
		tween.tween_interval(initial_offset)

	# up
	tween.tween_property(
		sprite,
		"position:y",
		up_y,
		half_cycle
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# down
	tween.tween_property(
		sprite,
		"position:y",
		down_y,
		half_cycle
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _fade_in() -> void:
	if sprite == null:
		return

	# Start fully transparent
	sprite.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(
		sprite,
		"modulate:a",
		1.0,          # final alpha
		0.25          # duration (¼ second)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
