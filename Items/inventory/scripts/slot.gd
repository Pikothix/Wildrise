extends Button
class_name InventorySlotUI

@onready var background_sprite: Sprite2D = $background
@onready var container: CenterContainer = $CenterContainer

var item_stack: ItemStack = null
var index: int


func set_item_stack(stack: ItemStack) -> void:
	item_stack = stack

	# Clear any previous stack node
	for child in container.get_children():
		container.remove_child(child)

	if stack:
		container.add_child(stack)
		background_sprite.frame = 1
	else:
		background_sprite.frame = 0


func clear() -> void:
	set_item_stack(null)


func is_empty_slot() -> bool:
	return item_stack == null


func take_item() -> ItemStack:
	var stack := item_stack
	set_item_stack(null)
	return stack


func insert(stack: ItemStack) -> void:
	set_item_stack(stack)
