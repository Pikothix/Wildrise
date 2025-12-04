extends Button
class_name HotbarSlot

@onready var background_sprite: Sprite2D = $background
@onready var item_stack: ItemStack = $CenterContainer/Panel


func update_to_slot(slot: InventorySlot) -> void:
	# No slot, or empty slot → hide item visuals and show empty background
	if slot == null or slot.item == null:
		item_stack.visible = false
		background_sprite.frame = 0
		return

	# There is an item: show the stack UI
	item_stack.inventory_slot = slot
	item_stack.update()  # still works with your current ItemStack script
	item_stack.visible = true

	background_sprite.frame = 1
