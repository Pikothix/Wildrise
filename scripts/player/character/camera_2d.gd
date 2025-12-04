extends Camera2D

@export var target: Node2D  # drag your Player here

func _ready() -> void:
	# enable built-in smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0  # higher = snappier, lower = floatier

func _physics_process(_delta: float) -> void:
	if target:
		global_position = target.global_position
