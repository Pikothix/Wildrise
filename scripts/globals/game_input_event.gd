# GameInputEvent.gd
class_name GameInputEvent
extends Node

# --- Movement -------------------------------------------------------------

static func movement_input() -> Vector2:
	# Change action names if you use different ones in your Input Map
	var x := Input.get_action_strength("right") - Input.get_action_strength("left")
	var y := Input.get_action_strength("down") - Input.get_action_strength("up")
	return Vector2(x, y)

static func is_movement_input() -> bool:
	return movement_input() != Vector2.ZERO


# --- Tools / Actions ------------------------------------------------------

static func use_tool() -> bool:
	# "use_tool" should be an action in Project Settings → Input Map
	return Input.is_action_just_pressed("use_tool")

static func use_tool_held() -> bool:
	return Input.is_action_pressed("use_tool")

static func interact() -> bool:
	return Input.is_action_just_pressed("interact")

static func drop_item() -> bool:
	return Input.is_action_just_pressed("drop_item")
