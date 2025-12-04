class_name HurtComponent
extends Area2D

@export var tool : DataTypes.Tools = DataTypes.Tools.None

signal hurt

func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null:
		return

	if tool == hitbox.current_tool:
		hurt.emit(hitbox.hit_damage)
