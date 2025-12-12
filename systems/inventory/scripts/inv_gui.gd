extends Control
class_name InventoryGui

signal drop_requested(index: int)

var is_open: bool = false
var using_mouse: bool = true

var crafting_grid_count: int = 0   # how many slots are actual grid slots

@export var inventory: Inventory
@export var crafting_menu: CraftingMenu

@onready var item_stack_scene: PackedScene = preload("res://systems/inventory/scenes/inv_items_stack.tscn")

@onready var hotbar_container: HBoxContainer = $Panel/HotbarContainer
@onready var grid_container: GridContainer = $Panel/MainBox/InventoryGrid
@onready var selector: Control = $Panel/Selector

var hotbar_slots: Array = []
var grid_slots: Array = []
var slots: Array = []          # all inventory UI slots (grid+hotbar)

const COLUMNS: int = 5

# Crafting navigation support
const REGION_INVENTORY := 0
const REGION_CRAFTING := 1

var current_region: int = REGION_INVENTORY

var crafting_slots: Array = []     # grid slots + output slot
const CRAFT_COLUMNS: int = 2
var craft_rows: int = 0

var item_in_hand: ItemStack = null
var old_index: int = -1
var locked: bool = false

var selected_index: int = 0
var rows: int = 0


func _ready() -> void:
	if hotbar_container == null:
		push_error("InventoryGui: hotbar_container is null. Check that 'Panel/HotbarContainer' exists.")
		return
	if grid_container == null:
		push_error("InventoryGui: grid_container is null. Check that 'Panel/InventoryGrid' exists.")
		return

	hotbar_slots = hotbar_container.get_children()
	grid_slots = grid_container.get_children()

	slots.clear()

	# VISUAL ORDER: inventory rows (grid) first, then hotbar row at the bottom
	slots.append_array(grid_slots)
	slots.append_array(hotbar_slots)

	# Map UI slots to inventory indices:
	# [0..hotbar_size-1] are hotbar in the Inventory resource
	# grid rows are after that.
	var inv_index := 0

	for h in hotbar_slots:
		h.index = inv_index
		inv_index += 1

	for g in grid_slots:
		g.index = inv_index
		inv_index += 1

	connect_slots()

	rows = int(ceil(float(slots.size()) / float(COLUMNS)))
	close()
	_update_selector_position()

	if selector:
		selector.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if crafting_menu:
		call_deferred("init_crafting_slots")


func set_inventory(new_inventory: Inventory) -> void:
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


func connect_slots() -> void:
	# Do not overwrite slot.index here – it already stores the inventory index.
	for slot in slots:
		var ui_slot: InventorySlotUI = slot
		ui_slot.pressed.connect(Callable(on_slot_clicked).bind(ui_slot))


# ----------------------
# CLICK / HAND LOGIC
# ----------------------

func on_slot_clicked(slot: InventorySlotUI) -> void:
	if locked:
		return

	if slot.is_empty_slot():
		if item_in_hand:
			insert_item_in_slot(slot)
		return

	if item_in_hand == null:
		take_item_from_slot(slot)
		return

	if slot.item_stack.inventory_slot.item == item_in_hand.inventory_slot.item:
		stack_items(slot)
		return

	swap_items(slot)

func take_item_from_slot(slot: InventorySlotUI) -> void:
	if inventory == null:
		return

	var inv_idx := slot.index
	if inv_idx < 0 or inv_idx >= inventory.slots.size():
		return

	var backing_slot: InventorySlot = inventory.slots[inv_idx]
	if backing_slot == null or backing_slot.item == null or backing_slot.amount <= 0:
		return

	# 1) Take the visual stack from the UI
	item_in_hand = slot.take_item()
	if item_in_hand == null:
		return

	# 2) Create a **separate** InventorySlot for the hand
	var hand_slot := InventorySlot.new()
	hand_slot.item = backing_slot.item
	hand_slot.amount = backing_slot.amount

	# 3) Attach that to the ItemStack in hand
	item_in_hand.inventory_slot = hand_slot

	# 4) Clear the backing inventory slot
	backing_slot.item = null
	backing_slot.amount = 0

	# 5) Finish up
	add_child(item_in_hand)
	update_item_in_hand()

	old_index = inv_idx




func insert_item_in_slot(slot: InventorySlotUI) -> void:
	var stack := item_in_hand

	remove_child(item_in_hand)
	item_in_hand = null

	slot.insert(stack)

	var inv_idx := slot.index
	if inventory != null and inv_idx >= 0 and inv_idx < inventory.slots.size():
		# Overwrite the backing slot instead of inserting/removing
		inventory.slots[inv_idx] = stack.inventory_slot

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
		var empty := slots.filter(func (s): return (s as InventorySlotUI).is_empty_slot())
		if empty.is_empty():
			return
		old_index = (empty[0] as InventorySlotUI).index

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
		item_in_hand.global_position = get_global_mouse_position() - item_in_hand.size / 2
	else:
		if current_region == REGION_INVENTORY:
			if selected_index >= 0 and selected_index < slots.size():
				var slot: Control = slots[selected_index]
				item_in_hand.global_position = slot.global_position + slot.size / 2 - item_in_hand.size / 2
		else:
			if selected_index >= 0 and selected_index < crafting_slots.size():
				var cslot: Control = crafting_slots[selected_index]
				item_in_hand.global_position = cslot.global_position + cslot.size / 2 - item_in_hand.size / 2


# ----------------------
# SPECIAL HAND PLACE (ONE / HALF)
# ----------------------

func _hand_place_single() -> void:
	if item_in_hand == null:
		return
	_hand_place_amount(1)


func _hand_place_half() -> void:
	if item_in_hand == null:
		return

	var hand_slot: InventorySlot = item_in_hand.inventory_slot
	if hand_slot == null:
		return

	# Only makes sense if we have 2 or more
	if hand_slot.amount <= 1:
		return

	# Place floor(half) into the slot, keep ceil(half) in hand
	var amount := hand_slot.amount / 2  # integer division: 5 -> 2, 4 -> 2
	_hand_place_amount(amount)



func _hand_place_amount(amount: int) -> void:
	if amount <= 0 or item_in_hand == null:
		return

	var hand_slot: InventorySlot = item_in_hand.inventory_slot
	if hand_slot == null or hand_slot.item == null or hand_slot.amount <= 0:
		return

	if current_region == REGION_INVENTORY:
		if selected_index < 0 or selected_index >= slots.size():
			return
		var ui_slot: InventorySlotUI = slots[selected_index]
		var inv_idx := ui_slot.index
		if inv_idx < 0 or inv_idx >= inventory.slots.size():
			return
		var dest: InventorySlot = inventory.slots[inv_idx]
		_hand_place_into_slot(dest, ui_slot, amount, false)
	else:
		if crafting_slots.is_empty():
			return
		if selected_index < 0 or selected_index >= crafting_slots.size():
			return

		var ctrl: Control = crafting_slots[selected_index]
		if not (ctrl is InventorySlotUI):
			return
		var ui_slot: InventorySlotUI = ctrl
		if crafting_menu and ui_slot == crafting_menu.get_output_slot_ui():
			return  # don't place into result slot

		var dest: InventorySlot = crafting_menu.get_slot_resource(ui_slot)
		if dest == null:
			return
		_hand_place_into_slot(dest, ui_slot, amount, true)


func _hand_place_into_slot(dest: InventorySlot, ui_slot: InventorySlotUI, amount: int, is_crafting: bool) -> void:
	var hand_slot: InventorySlot = item_in_hand.inventory_slot
	if hand_slot == null or hand_slot.item == null or hand_slot.amount <= 0:
		return

	if dest == null:
		return

	# Empty destination → move up to `amount`
	if dest.item == null or dest.amount <= 0:
		var move_amount = min(amount, hand_slot.amount)
		dest.item = hand_slot.item
		dest.amount = move_amount
		hand_slot.amount -= move_amount

	# Same item → stack
	elif dest.item == hand_slot.item:
		var max_amount := dest.item.max_amount
		var space := max_amount - dest.amount
		if space <= 0:
			return
		var move_amount = min(min(amount, hand_slot.amount), space)
		if move_amount <= 0:
			return
		dest.amount += move_amount
		hand_slot.amount -= move_amount

	# Different item type → ignore special action
	else:
		return

	# If hand is empty now, drop the hand stack
	if hand_slot.amount <= 0:
		hand_slot.item = null
		remove_child(item_in_hand)
		item_in_hand = null
		old_index = -1
	else:
		item_in_hand.update()

	# Update visuals
	if is_crafting and crafting_menu:
		crafting_menu.update_slot_visual(ui_slot)
	else:
		if dest.item == null or dest.amount <= 0:
			ui_slot.clear()
		else:
			var ui_stack := ui_slot.item_stack
			if ui_stack == null:
				ui_stack = item_stack_scene.instantiate()
				ui_slot.set_item_stack(ui_stack)
			ui_stack.inventory_slot = dest
			ui_stack.update()

	update_item_in_hand()


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
		# --- INVENTORY NAV (unchanged) ---
		if slots.is_empty():
			return

		var row: int = selected_index / COLUMNS
		var col: int = selected_index % COLUMNS
		var old_row := row
		var old_col := col

		row += dy
		col += dx

		# Cross over to crafting region when moving right from the rightmost column
		if dx > 0 and old_col == COLUMNS - 1 and not crafting_slots.is_empty():
			current_region = REGION_CRAFTING

			var target_row = clamp(old_row, 0, craft_rows - 1)
			var target_index = target_row * CRAFT_COLUMNS
			if target_index >= crafting_slots.size():
				target_index = crafting_slots.size() - 1

			selected_index = target_index
			_update_selector_position()
			return

		row = clamp(row, 0, rows - 1)
		col = clamp(col, 0, COLUMNS - 1)

		var new_index: int = row * COLUMNS + col
		if new_index >= slots.size():
			return

		selected_index = new_index
	else:
		# --- CRAFTING NAV (grid + result) ---
		if crafting_slots.is_empty():
			return

		var output_index := crafting_grid_count   # result slot is right after the grid

		# If we're currently on the RESULT slot
		if selected_index == output_index:
			# LEFT from result -> jump to top-right grid slot
			if dx < 0 and crafting_grid_count > 0:
				var target = min(CRAFT_COLUMNS - 1, crafting_grid_count - 1)
				selected_index = target
				_update_selector_position()
				return
			# For now, ignore up/down/right from result
			_update_selector_position()
			return

		# We're in the GRID (0 .. crafting_grid_count - 1)
		var row: int = selected_index / CRAFT_COLUMNS
		var col: int = selected_index % CRAFT_COLUMNS
		var old_col := col

		row += dy
		col += dx

		# Cross back to inventory when moving left from LEFTMOST grid column
		if dx < 0 and old_col == 0 and not slots.is_empty():
			current_region = REGION_INVENTORY

			var target_row = clamp(row, 0, rows - 1)
			var target_index = target_row * COLUMNS + (COLUMNS - 1)
			if target_index >= slots.size():
				target_index = slots.size() - 1

			selected_index = target_index
			_update_selector_position()
			return

		# Move RIGHT from rightmost grid column -> jump to RESULT slot
		if dx > 0 and old_col == CRAFT_COLUMNS - 1:
			selected_index = output_index
			_update_selector_position()
			return

		row = clamp(row, 0, craft_rows - 1)
		col = clamp(col, 0, CRAFT_COLUMNS - 1)

		var new_index: int = row * CRAFT_COLUMNS + col
		if new_index >= crafting_grid_count:
			new_index = crafting_grid_count - 1  # clamp to last grid slot

		selected_index = new_index

	_update_selector_position()



func _controller_select_current_slot() -> void:
	if current_region == REGION_INVENTORY:
		if selected_index < 0 or selected_index >= slots.size():
			return
		var ui_slot: InventorySlotUI = slots[selected_index]
		on_slot_clicked(ui_slot)
	else:
		if selected_index < 0 or selected_index >= crafting_slots.size():
			return

		var ctrl: Control = crafting_slots[selected_index]

		# Crafting grid slots
		if ctrl is InventorySlotUI and ctrl != crafting_menu.get_output_slot_ui():
			_on_crafting_slot_selected(ctrl as InventorySlotUI)
			return

		# Output slot → pick up crafted result (MC-style)
		if ctrl == crafting_menu.get_output_slot_ui():
			_on_crafting_output_selected()


# MC-like behaviour over crafting grid using the same "hand"
func _on_crafting_slot_selected(slot: InventorySlotUI) -> void:
	if locked or crafting_menu == null:
		return

	# Hand empty → pick up from this crafting slot
	if item_in_hand == null:
		var taken: InventorySlot = crafting_menu.take_from_slot(slot, false)
		if taken == null or taken.item == null or taken.amount <= 0:
			return

		item_in_hand = item_stack_scene.instantiate()
		item_in_hand.inventory_slot = taken
		add_child(item_in_hand)
		update_item_in_hand()
		old_index = -1
		return

	# Hand full → per-slot placement / stacking / swap
	var hand_slot: InventorySlot = item_in_hand.inventory_slot
	if hand_slot == null or hand_slot.item == null or hand_slot.amount <= 0:
		return

	var dest_res: InventorySlot = crafting_menu.get_slot_resource(slot)
	if dest_res == null:
		return

	# Empty destination → move whole stack
	if dest_res.item == null or dest_res.amount <= 0:
		dest_res.item = hand_slot.item
		dest_res.amount = hand_slot.amount
		crafting_menu.update_slot_visual(slot)

		remove_child(item_in_hand)
		item_in_hand = null
		old_index = -1
		update_item_in_hand()
		return

	# Same item → stack up to max
	if dest_res.item == hand_slot.item:
		var max_amount := dest_res.item.max_amount
		var can_add = min(max_amount - dest_res.amount, hand_slot.amount)
		if can_add > 0:
			dest_res.amount += can_add
			hand_slot.amount -= can_add
			crafting_menu.update_slot_visual(slot)

			if hand_slot.amount <= 0:
				remove_child(item_in_hand)
				item_in_hand = null
				old_index = -1
				update_item_in_hand()
		return

	# Different item → swap
	var temp_item := dest_res.item
	var temp_amount := dest_res.amount

	dest_res.item = hand_slot.item
	dest_res.amount = hand_slot.amount

	hand_slot.item = temp_item
	hand_slot.amount = temp_amount

	crafting_menu.update_slot_visual(slot)
	item_in_hand.update()
	update_item_in_hand()


# ----------------------
# INVENTORY <-> CRAFTING SHORTCUTS
# ----------------------

func _on_crafting_output_selected() -> void:
	if crafting_menu == null:
		return
	if locked:
		return
	# Must have empty hand to take result (simple behaviour)
	if item_in_hand != null:
		return

	var result_slot: InventorySlot = crafting_menu.take_result()
	if result_slot == null or result_slot.item == null or result_slot.amount <= 0:
		return

	item_in_hand = item_stack_scene.instantiate()
	item_in_hand.inventory_slot = result_slot
	add_child(item_in_hand)
	update_item_in_hand()
	old_index = -1


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


func _move_selected_from_crafting_to_inventory(one_only: bool) -> void:
	if crafting_menu == null:
		return
	if inventory == null:
		return
	if current_region != REGION_CRAFTING:
		return
	if selected_index < 0 or selected_index >= crafting_slots.size():
		return

	var ctrl: Control = crafting_slots[selected_index]
	if not (ctrl is InventorySlotUI):
		return

	var ui_slot: InventorySlotUI = ctrl
	var taken_slot: InventorySlot = crafting_menu.take_from_slot(ui_slot, one_only)
	if taken_slot == null or taken_slot.item == null or taken_slot.amount <= 0:
		return

	if not inventory.insert(taken_slot.item, taken_slot.amount):
		# inventory full → push it back to crafting
		crafting_menu.add_ingredient(taken_slot.item, taken_slot.amount)


# ----------------------
# INPUT
# ----------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		using_mouse = true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		using_mouse = false

	# INVENTORY CLOSED
	if not is_open:
		if item_in_hand and not locked:
			if Input.is_action_just_pressed("right_click"):
				put_item_back()
			if event.is_action_pressed("inv_cancel"):
				put_item_back()

		update_item_in_hand()
		return

	# INVENTORY OPEN
	if item_in_hand and not locked:
		if Input.is_action_just_pressed("right_click"):
			put_item_back()
		if event.is_action_pressed("inv_cancel"):
			put_item_back()

		# 🔹 SPECIAL HAND ACTIONS: place into CURRENTLY SELECTED SLOT
		if event.is_action_pressed("inv_hand_one"):
			_hand_place_single()
		if event.is_action_pressed("inv_hand_half"):
			_hand_place_half()

	# D-pad / arrows navigation
	if event.is_action_pressed("inv_left"):
		_move_selection(-1, 0)
	if event.is_action_pressed("inv_right"):
		_move_selection(1, 0)
	if event.is_action_pressed("inv_up"):
		_move_selection(0, -1)
	if event.is_action_pressed("inv_down"):
		_move_selection(0, 1)

	# Confirm / “click” on selected slot
	if event.is_action_pressed("inv_select"):
		_controller_select_current_slot()

	# Toggle between inventory region and crafting region
	if event.is_action_pressed("inv_toggle_region"):
		_toggle_region()

	# Drop from currently selected inventory slot (world drop)
	if event.is_action_pressed("inv_drop"):
		drop_current_slot()

	# 🔹 QUICK SEND INVENTORY <-> CRAFTING
	# These should ONLY work when hand is EMPTY,
	# so they don't fight with the hand-place-one/half behaviour.
	#if item_in_hand == null:
		#if event.is_action_pressed("inv_to_craft_one"):
			#if current_region == REGION_INVENTORY:
				#_move_selected_to_crafting(true)
			#else:
				#_move_selected_from_crafting_to_inventory(true)
#
		#if event.is_action_pressed("inv_to_craft_stack"):
			#if current_region == REGION_INVENTORY:
				#_move_selected_to_crafting(false)
			#else:
				#_move_selected_from_crafting_to_inventory(false)

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

	crafting_slots.clear()

	var grid := crafting_menu.get_grid_slots()
	crafting_grid_count = grid.size()    
	crafting_slots.append_array(grid)

	# last index is the output slot
	crafting_slots.append(crafting_menu.get_output_slot_ui())

	# rows only for the actual grid, NOT including the result slot
	craft_rows = int(ceil(float(crafting_grid_count) / float(CRAFT_COLUMNS)))



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
	update_item_in_hand()
