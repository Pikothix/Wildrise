extends Control
class_name InventoryRegionView

signal slot_pressed(region: InventoryRegionView, slot_index: int)

@export var inventory: Inventory
@export var slot_indices: Array[int] = []   # e.g. [0,1,2,3,4,5,6,7,8,9]
@export var columns: int = 5

var ui_slots: Array[InventorySlotUI] = []

func setup_from_container(container: Control) -> void:
	ui_slots.clear()
	var i := 0
	for child in container.get_children():
		if child is InventorySlotUI:
			var ui := child as InventorySlotUI
			ui.index = slot_indices[i]   # <-- inventory index
			ui_slots.append(ui)
			ui.pressed.connect(_on_ui_slot_pressed.bind(ui.index))
			i += 1

func refresh() -> void:
	if inventory == null:
		for ui in ui_slots:
			ui.clear()
		return

	for ui in ui_slots:
		var inv_idx := ui.index
		var slot := inventory._get_slot(inv_idx)
		if slot == null or slot.item == null:
			ui.clear()
		else:
			var stack := ui.item_stack
			if stack == null:
				stack = preload("res://systems/inventory/scenes/inv_items_stack.tscn").instantiate()
				ui.set_item_stack(stack)
			stack.inventory_slot = slot
			stack.update()

func _on_ui_slot_pressed(inv_index: int) -> void:
	emit_signal("slot_pressed", self, inv_index)
