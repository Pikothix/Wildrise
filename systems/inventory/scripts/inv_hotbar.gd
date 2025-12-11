extends Panel
class_name HotbarUI

@export var columns: int = 5    # instead of const COLUMNS

@export var inventory_gui: InventoryGui   # add at top, drag it in inspector
@export var inventory: Inventory
@onready var selector: Sprite2D = $Selector
@onready var container: Control = $Container

var slots: Array[HotbarSlot] = []
var currently_selected: int = 0   # column within the row (0..4)
var active_row: int = 0           # which inventory row is being used as hotbar (0..N-1)

var blocked: bool = false

func _ready() -> void:
	# Build a strongly-typed slots array from the container children
	for child in container.get_children():
		if child is HotbarSlot:
			slots.append(child as HotbarSlot)

	if inventory == null:
		push_warning("inv_hotbar.gd: 'inventory' is not assigned. Set it in the Inspector.")
		return

	inventory.updated.connect(update)
	update()

	if not slots.is_empty():
		selector.global_position = slots[currently_selected].global_position

func set_blocked(value: bool) -> void:
	blocked = value


func _get_row_count() -> int:
	if inventory == null:
		return 0
	# ceil(slots.size() / COLUMNS)
	return (inventory.slots.size() + columns - 1) / columns


func update() -> void:
	if inventory == null:
		return
	if slots.is_empty():
		return

	var base_index: int = active_row * columns

	for i in slots.size():
		var inv_index: int = base_index + i
		var inv_slot: InventorySlot

		if inv_index >= inventory.slots.size():
			# Out of range: show an empty slot
			inv_slot = InventorySlot.new()
		else:
			inv_slot = inventory.slots[inv_index]

		slots[i].update_to_slot(inv_slot)


func move_selector(offset: int = 1) -> void:
	if slots.is_empty():
		return

	currently_selected = (currently_selected + offset + slots.size()) % slots.size()
	selector.global_position = slots[currently_selected].global_position
	print("Hotbar: selected col =", currently_selected, "row =", active_row)


func cycle_row(offset: int = 1) -> void:
	if inventory == null:
		return

	var row_count := _get_row_count()
	if row_count <= 0:
		return

	active_row = (active_row + offset + row_count) % row_count
	print("Hotbar: active row =", active_row)
	update()  # refresh icons for the new row


func _unhandled_input(event: InputEvent) -> void:
	if blocked:
		return
		
	# Block hotbar movement when inventory is open
	if inventory_gui != null and inventory_gui.is_open:
		return

	if inventory == null:
		return

	# Left/right on D-pad (or whatever you mapped)
	if event.is_action_pressed("hotbar_left"):
		move_selector(-1)

	if event.is_action_pressed("hotbar_right"):
		move_selector(1)

	# Up/down on D-pad to switch hotbar rows
	if event.is_action_pressed("hotbar_row_up"):
		cycle_row(-1)

	if event.is_action_pressed("hotbar_row_down"):
		cycle_row(1)
