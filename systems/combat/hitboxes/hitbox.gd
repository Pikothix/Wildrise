extends Area2D
class_name Hitbox

@export var hitbox_lifetime: float = 0.5
@export var hit_damage: int = 0
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

var attacker_stats: Stats
var instigator: Node = null   # whoever spawned this hitbox

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = true
	monitorable = false

	area_entered.connect(_on_area_entered)

	# Lifetime (we can keep your Timer approach or use a tree timer)
	if hitbox_lifetime > 0.0:
		var new_timer := Timer.new()
		new_timer.one_shot = true
		new_timer.wait_time = hitbox_lifetime
		add_child(new_timer)
		new_timer.timeout.connect(queue_free)
		new_timer.start()

	# Detect things on layer 1 ONLY (same as before)
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)


func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return

	var hb := area as Hurtbox
	var owner_node := hb.get_parent()

	# 🔹 Don't hit our own owner (prevents self-damage)
	if attacker_stats != null and hb.owner_stats == attacker_stats:
		return

	# Decide actual damage to apply
	var dmg := hit_damage
	if dmg <= 0 and attacker_stats:
		dmg = int(attacker_stats.current_attack)

	if dmg <= 0:
		return

	print("Hitbox from", instigator, 
		"hit Hurtbox node", hb.name, 
		"parent:", owner_node, 
		"owner_stats:", hb.owner_stats, 
		"for", dmg, "damage")

	hb.receive_hit(dmg, self)
