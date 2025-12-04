extends NodeState

@export var character: NonPlayerCharacter
@export var animated_sprite_2d: AnimatedSprite2D 
@onready var navigation_agent_2d: NavigationAgent2D = character.get_node("NavigationAgent2D")


var radius := 256.0  # how far they wander

@export var min_speed: float = 50.0
@export var max_speed: float = 100.0

var speed: float


func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(on_safe_velocity_computed)

	# Simplify path so it has fewer points
	navigation_agent_2d.simplify_path = true
	navigation_agent_2d.simplify_epsilon = 16
	
	navigation_agent_2d.path_return_max_length = 512.0   # max ~512px path
	navigation_agent_2d.path_return_max_radius = 512.0   # don’t go too far from start
	
	call_deferred("character_setup")



func character_setup() -> void:
	await get_tree().physics_frame
	####################print("character_setup called for ", character)
	set_movement_target()

func set_movement_target() -> void:
	# Pick a local random direction and radius
	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * radius

	var raw_target: Vector2 = character.global_position + offset

	# Just give the raw target to the agent
	navigation_agent_2d.target_position = raw_target
	speed = randf_range(min_speed, max_speed)


	


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if character.is_dead:
		return

	if navigation_agent_2d.is_navigation_finished():
		character.current_walk_cycle += 1
		set_movement_target()
		return
	
	var target_position: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_direction: Vector2 = character.global_position.direction_to(target_position)
	var velocity: Vector2 = target_direction * speed
	
	if navigation_agent_2d.avoidance_enabled:
		animated_sprite_2d.flip_h = velocity.x < 0
		navigation_agent_2d.velocity = velocity
	else:
		character.velocity = velocity
		character.move_and_slide()

func on_safe_velocity_computed(safe_velocity: Vector2) -> void:
	if character.is_dead:
		return

	animated_sprite_2d.flip_h = safe_velocity.x < 0
	character.velocity = safe_velocity
	character.move_and_slide()

func _on_next_transitions() -> void:
	if character.current_walk_cycle == character.walk_cycles:  ##if walk cycles is 3, when the walk cycle = 3 it will go into idle
		character.velocity = Vector2.ZERO
		transition.emit("Idle")


func _on_enter() -> void:
	animated_sprite_2d.play("walk")
	character.current_walk_cycle = 0
	set_movement_target()


func _on_exit() -> void:
	animated_sprite_2d.stop()
