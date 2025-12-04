extends Panel
class_name ItemStack

@onready var item_sprite: Sprite2D = $item
@onready var amount_label: Label = $Label

var _inventory_slot: InventorySlot

var inventory_slot: InventorySlot:
	get:
		return _inventory_slot
	set(value):
		_inventory_slot = value
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var slot := _inventory_slot

	# No slot or no item → hide and bail
	if slot == null or slot.item == null:
		item_sprite.visible = false
		amount_label.visible = false
		return

	# There is an item → show sprite
	item_sprite.visible = true
	item_sprite.texture = slot.item.texture

	# Handle stack amount
	if slot.amount > 1:
		amount_label.visible = true
		amount_label.text = str(slot.amount)
	else:
		amount_label.visible = false


# Backwards compatibility: existing code can still call `update()`
func update() -> void:
	_refresh()
