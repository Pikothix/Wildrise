extends Area2D
class_name Hitbox

var attacker_stats: Stats
var hitbox_lifetime: float
var shape: Shape2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var hit_damage: int = 0

var instigator: Node = null   # whoever spawned this hitbox


func _init(_attacker_stats: Stats, _hitbox_lifetime: float, _shape: Shape2D) -> void:
	attacker_stats = _attacker_stats
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape

func _ready() -> void:
	monitoring = true
	monitorable = false

	area_entered.connect(_on_area_entered)

	# Lifetime
	if hitbox_lifetime > 0.0:
		var new_timer := Timer.new()
		new_timer.one_shot = true
		new_timer.wait_time = hitbox_lifetime
		add_child(new_timer)
		new_timer.timeout.connect(queue_free)
		new_timer.start()

	# Shape
	if shape:
		var collision_shape := CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	else:
		print("Hitbox has NO SHAPE!")

	# Detect things on layer 1 ONLY
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

func _on_area_entered(area: Area2D) -> void:
	# Only care about Hurtboxes
	if area is Hurtbox:
		var hb := area as Hurtbox

		# Decide damage:
		#  - if hit_damage is set, use that
		#  - otherwise, fall back to attacker_stats.current_attack
		var dmg := hit_damage
		if dmg <= 0 and attacker_stats:
			dmg = int(attacker_stats.current_attack)

		if dmg <= 0:
			return

		hb.receive_hit(dmg, self)
