extends Control
class_name InventoryGui

signal drop_requested(index: int)

var is_open: bool = false
var using_mouse: bool = true


@export var inventory: Inventory
@export var crafting_menu: CraftingMenu

@onready var item_stack_scene: PackedScene = preload("res://systems/inventory/scenes/inv_items_stack.tscn")

@onready var hotbar_container: HBoxContainer = $Panel/HotbarContainer
@onready var grid_container: GridContainer = $Panel/MainBox/InventoryGrid
@onready var selector: Control = $Panel/Selector

var hotbar_slots: Array = []
var grid_slots: Array = []
var slots: Array = []

const COLUMNS: int = 5

# Crafting navigation support
const REGION_INVENTORY := 0
const REGION_CRAFTING := 1

var current_region: int = REGION_INVENTORY

var crafting_slots: Array[InventorySlotUI] = []
const CRAFT_COLUMNS: int = 2
var craft_rows: int = 0


var item_in_hand: ItemStack = null
var old_index: int = -1
var locked: bool = false

var selected_index: int = 0
var rows: int = 0


func _ready():
	# --- sanity checks for the containers ---
	if hotbar_container == null:
		push_error("InventoryGui: hotbar_container is null. Check that 'Panel/HotbarContainer' exists.")
		return
	if grid_container == null:
		push_error("InventoryGui: grid_container is null. Check that 'Panel/InventoryGrid' exists.")
		return

	hotbar_slots = hotbar_container.get_children()
	grid_slots = grid_container.get_children()

	slots.clear()

	# 🔹 VISUAL ORDER: inventory rows first, then hotbar row
	slots.append_array(grid_slots)
	slots.append_array(hotbar_slots)

	# 🔹 Map slot.index → inventory index
	# Assuming inventory layout: [0..hotbar_size-1] = hotbar, then backpack
	var inv_index := 0

	# First hotbar indices 0..hotbar_slots.size()-1
	for h in hotbar_slots:
		h.index = inv_index
		inv_index += 1

	# Then grid indices hotbar_slots.size()..(hotbar+grid-1)
	for g in grid_slots:
		g.index = inv_index
		inv_index += 1

	connect_slots()

	rows = int(ceil(float(slots.size()) / float(COLUMNS)))
	close()  # start closed
	_update_selector_position()

	if selector:
		selector.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if crafting_menu:
		call_deferred("init_crafting_slots")


func set_inventory(new_inventory: Inventory) -> void:
	# disconnect old inventory if needed
	if inventory != null and inventory.updated.is_connected(refresh_slots):
		inventory.updated.disconnect(refresh_slots)

	inventory = new_inventory

	if inventory != null:
		inventory.updated.connect(refresh_slots)
		refresh_slots()


func open() -> void:
	visible = true
	is_open = true
	current_region = REGION_INVENTORY
	_update_selector_position()



func close() -> void:
	visible = false
	is_open = false
	item_in_hand = null
	old_index = -1
	locked = false


func toggle() -> void:
	if is_open:
		close()
	else:
		open()



func refresh_slots() -> void:
	if inventory == null:
		return

	for ui_slot: InventorySlotUI in slots:
		var inv_idx := ui_slot.index
		if inv_idx < 0 or inv_idx >= inventory.slots.size():
			ui_slot.clear()
			continue

		var inv_slot: InventorySlot = inventory.slots[inv_idx]

		if inv_slot.item == null:
			ui_slot.clear()
			continue

		var ui_stack := ui_slot.item_stack
		if ui_stack == null:
			ui_stack = item_stack_scene.instantiate()
			ui_slot.set_item_stack(ui_stack)

		ui_stack.inventory_slot = inv_slot
		ui_stack.update()

	_update_selector_position()




func connect_slots():
	for i in range(slots.size()):
		var slot: InventorySlotUI = slots[i]
		slot.index = i
		slot.pressed.connect(Callable(on_slot_clicked).bind(slot))


# ----------------------
# EXISTING CLICK LOGIC
# ----------------------

func on_slot_clicked(slot: InventorySlotUI) -> void:
	if locked:
		return

	# If clicking empty slot while holding something → place it
	if slot.is_empty_slot():
		if item_in_hand:
			insert_item_in_slot(slot)
		return

	# If not holding anything → pick up
	if item_in_hand == null:
		take_item_from_slot(slot)
		return

	# Same type → stack
	if slot.item_stack.inventory_slot.item == item_in_hand.inventory_slot.item:
		stack_items(slot)
		return

	# Different type → swap
	swap_items(slot)


func take_item_from_slot(slot: InventorySlotUI) -> void:
	# Grab the stack from the UI
	item_in_hand = slot.take_item()
	add_child(item_in_hand)
	update_item_in_hand()

	# Remove the item data from the Inventory
	inventory.remove_slot(inventory.slots[slot.index])

	old_index = slot.index


func insert_item_in_slot(slot: InventorySlotUI) -> void:
	var stack := item_in_hand

	remove_child(item_in_hand)
	item_in_hand = null

	slot.insert(stack)

	# Write into Inventory
	inventory.insert_slot(slot.index, stack.inventory_slot)

	old_index = -1


func swap_items(slot: InventorySlotUI) -> void:
	var temp_stack := slot.take_item()

	insert_item_in_slot(slot)

	item_in_hand = temp_stack
	add_child(item_in_hand)
	update_item_in_hand()


func stack_items(slot: InventorySlotUI) -> void:
	var slot_stack: ItemStack = slot.item_stack

	var max_amount := slot_stack.inventory_slot.item.max_amount
	var total := slot_stack.inventory_slot.amount + item_in_hand.inventory_slot.amount

	if total <= max_amount:
		slot_stack.inventory_slot.amount = total
		remove_child(item_in_hand)
		item_in_hand = null
		old_index = -1
	else:
		slot_stack.inventory_slot.amount = max_amount
		item_in_hand.inventory_slot.amount = total - max_amount

	slot_stack.update()
	if item_in_hand:
		item_in_hand.update()


func put_item_back() -> void:
	locked = true

	if old_index < 0:
		# No original slot → find first empty
		var empty := slots.filter(func (s): return s.is_empty_slot())
		if empty.is_empty():
			return
		old_index = empty[0].index  # this is an inventory index

	# Find the UI slot that corresponds to this inventory index
	var target_slot: InventorySlotUI = null
	for s: InventorySlotUI in slots:
		if s.index == old_index:
			target_slot = s
			break

	if target_slot == null:
		locked = false
		return

	var tween := create_tween()
	var pos := target_slot.global_position + target_slot.size / 2

	tween.tween_property(item_in_hand, "global_position", pos, 0.2)
	await tween.finished

	insert_item_in_slot(target_slot)
	locked = false



func update_item_in_hand() -> void:
	if item_in_hand == null:
		return

	if using_mouse:
		# original behaviour – follow the mouse
		item_in_hand.global_position = get_global_mouse_position() - item_in_hand.size / 2
	else:
		# controller behaviour – stick to the currently selected slot
		if selected_index >= 0 and selected_index < slots.size():
			var slot: Control = slots[selected_index]
			item_in_hand.global_position = slot.global_position + slot.size / 2 - item_in_hand.size / 2







# ----------------------
# SELECTOR + D-PAD NAV
# ----------------------

func _update_selector_position() -> void:
	if current_region == REGION_INVENTORY:
		if slots.is_empty():
			return
		selected_index = clamp(selected_index, 0, slots.size() - 1)
		var slot: Control = slots[selected_index]
		selector.global_position = slot.global_position + slot.size / 2 - selector.size / 2
	else:
		if crafting_slots.is_empty():
			return
		selected_index = clamp(selected_index, 0, crafting_slots.size() - 1)
		var cslot: Control = crafting_slots[selected_index]
		selector.global_position = cslot.global_position + cslot.size / 2 - selector.size / 2



func _move_selection(dx: int, dy: int) -> void:
	if current_region == REGION_INVENTORY:
		if slots.is_empty():
			return

		var row: int = selected_index / COLUMNS
		var col: int = selected_index % COLUMNS

		row += dy
		col += dx

		row = clamp(row, 0, rows - 1)
		col = clamp(col, 0, COLUMNS - 1)

		var new_index: int = row * COLUMNS + col
		if new_index >= slots.size():
			return

		selected_index = new_index
	else:
		if crafting_slots.is_empty():
			return

		var row: int = selected_index / CRAFT_COLUMNS
		var col: int = selected_index % CRAFT_COLUMNS

		row += dy
		col += dx

		row = clamp(row, 0, craft_rows - 1)
		col = clamp(col, 0, CRAFT_COLUMNS - 1)

		var new_index: int = row * CRAFT_COLUMNS + col
		if new_index >= crafting_slots.size():
			return

		selected_index = new_index

	_update_selector_position()


func _controller_select_current_slot() -> void:
	if current_region == REGION_INVENTORY:
		if selected_index < 0 or selected_index >= slots.size():
			return
		var ui_slot: InventorySlotUI = slots[selected_index]
		on_slot_clicked(ui_slot)
	else:
		# For now, no direct per-slot interaction in crafting grid.
		# Craft / Clear buttons are used instead.
		return



func _move_selected_to_crafting(one_only: bool) -> void:
	if crafting_menu == null:
		return
	if inventory == null:
		return
	if current_region != REGION_INVENTORY:
		return
	if selected_index < 0 or selected_index >= slots.size():
		return

	var ui_slot: InventorySlotUI = slots[selected_index]
	var inv_idx := ui_slot.index
	if inv_idx < 0 or inv_idx >= inventory.slots.size():
		return

	var slot: InventorySlot = inventory.slots[inv_idx]
	if slot == null or slot.item == null or slot.amount <= 0:
		return

	var amount_to_move := slot.amount
	if one_only:
		amount_to_move = 1

	var accepted := crafting_menu.add_ingredient(slot.item, amount_to_move)
	if not accepted:
		return

	inventory.take_from_index(inv_idx, amount_to_move)



func _input(event: InputEvent) -> void:
	# ----- detect input source -----
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		using_mouse = true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		using_mouse = false
	# (keyboard-only navigation could also set using_mouse = false
	
	# --- INVENTORY CLOSED ---
	if not is_open:
		# item is in hand while inventory is closed:
		if item_in_hand and not locked:
			# mouse cancel
			if Input.is_action_just_pressed("right_click"):
				put_item_back()
			# controller cancel
			if event.is_action_pressed("inv_cancel"):
				put_item_back()

		update_item_in_hand()
		return

	# --- INVENTORY OPEN ---

	if item_in_hand and not locked:
		# mouse cancel
		if Input.is_action_just_pressed("right_click"):
			put_item_back()
		# controller cancel
		if event.is_action_pressed("inv_cancel"):
			put_item_back()

	# D-Pad / keyboard navigation
	if event.is_action_pressed("inv_left"):
		_move_selection(-1, 0)
	if event.is_action_pressed("inv_right"):
		_move_selection(1, 0)
	if event.is_action_pressed("inv_up"):
		_move_selection(0, -1)
	if event.is_action_pressed("inv_down"):
		_move_selection(0, 1)

	# Confirm / interact (use the same logic as clicking the slot)
	if event.is_action_pressed("inv_select"):
		_controller_select_current_slot()

	# Switch selector between inventory and crafting grids
	if event.is_action_pressed("inv_toggle_region"):
		_toggle_region()

	# Drop from the currently selected slot
	if event.is_action_pressed("inv_drop"):
		drop_current_slot()

	# Send items to crafting grid or back, depending on region
	if event.is_action_pressed("inv_to_craft_one"):
		if current_region == REGION_INVENTORY:
			_move_selected_to_crafting(true)
		else:
			_move_selected_from_crafting_to_inventory(true)

	if event.is_action_pressed("inv_to_craft_stack"):
		if current_region == REGION_INVENTORY:
			_move_selected_to_crafting(false)
		else:
			_move_selected_from_crafting_to_inventory(false)

	update_item_in_hand()


func drop_current_slot() -> void:
	if not is_open:
		return
	if selected_index < 0 or selected_index >= slots.size():
		return

	var ui_slot: InventorySlotUI = slots[selected_index]
	emit_signal("drop_requested", ui_slot.index)



func init_crafting_slots() -> void:
	if crafting_menu == null:
		return

	crafting_slots = crafting_menu.get_grid_slots()
	if crafting_slots.is_empty():
		return

	craft_rows = int(ceil(float(crafting_slots.size()) / float(CRAFT_COLUMNS)))


func _toggle_region() -> void:
	if crafting_slots.is_empty():
		return

	if current_region == REGION_INVENTORY:
		current_region = REGION_CRAFTING
		selected_index = clamp(selected_index, 0, crafting_slots.size() - 1)
	else:
		current_region = REGION_INVENTORY
		selected_index = clamp(selected_index, 0, slots.size() - 1)

	_update_selector_position()


func _move_selected_from_crafting_to_inventory(one_only: bool) -> void:
	if crafting_menu == null:
		return
	if inventory == null:
		return
	if current_region != REGION_CRAFTING:
		return
	if selected_index < 0 or selected_index >= crafting_slots.size():
		return

	var ui_slot: InventorySlotUI = crafting_slots[selected_index]
	var taken_slot: InventorySlot = crafting_menu.take_from_slot(ui_slot, one_only)
	if taken_slot == null:
		return

	# Try to insert into inventory; if it fails, put it back in crafting
	if not inventory.insert(taken_slot.item, taken_slot.amount):
		# inventory full → push it back to crafting
		crafting_menu.add_ingredient(taken_slot.item, taken_slot.amount)
