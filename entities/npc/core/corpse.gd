extends Node2D
class_name Corpse

@export var lifetime := 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var source_frames: SpriteFrames
var source_animation: StringName
var source_frame: int

func _ready() -> void:
	if source_frames:
		sprite.sprite_frames = source_frames
		sprite.animation = source_animation

		# Stop first (so nothing is playing)
		sprite.stop()
		# Then force the frame you were given
		sprite.frame = source_frame

		# Optional debug:
		# print("Corpse ready: anim =", sprite.animation, "frame =", sprite.frame)

	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	add_child(timer)
	timer.start()
