extends Resource
class_name Inventory

signal updated


@export var slots: Array[InventorySlot] = []
#const HOTBAR_SIZE: int = 8 #currently unused, maybe hotbar logic


func _get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]


func _find_first_stackable_index(item: InventoryItem) -> int:
	if item == null:
		return -1

	for i: int in slots.size():
		var slot: InventorySlot = slots[i]
		if slot.item == item and slot.amount < item.max_amount:
			return i

	return -1


func _find_first_empty_index() -> int:
	for i: int in slots.size():
		var slot: InventorySlot = slots[i]
		if slot.is_empty():
			return i
	return -1


# ---------- NEW: capacity check ----------

func can_insert(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var free_capacity: int = 0

	for slot in slots:
		if slot.item == null:
			# completely empty slot → can hold a full stack
			free_capacity += item.max_amount
		elif slot.item == item and slot.amount < item.max_amount:
			free_capacity += (item.max_amount - slot.amount)

		if free_capacity >= amount:
			return true

	return free_capacity >= amount


## Public API ##

# Tries to add `amount` of `item` to the inventory.
# Returns true if everything was inserted, false if there was not enough space.
func insert(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	# 🔒 Hard guard: if there's not enough space, do NOTHING and return false
	if not can_insert(item, amount):
		print("Inventory.insert: NOT ENOUGH SPACE for", item.name, "amount", amount)
		return false

	var remaining: int = amount

	# 1) Fill existing stacks first
	while remaining > 0:
		var stack_index: int = _find_first_stackable_index(item)
		if stack_index == -1:
			break

		var stack_slot: InventorySlot = slots[stack_index]
		var can_add: int = min(item.max_amount - stack_slot.amount, remaining)
		stack_slot.amount += can_add
		remaining -= can_add

	# 2) Then put into empty slots
	while remaining > 0:
		var empty_index: int = _find_first_empty_index()
		if empty_index == -1:
			break

		var empty_slot: InventorySlot = slots[empty_index]
		empty_slot.item = item
		var to_add: int = min(item.max_amount, remaining)
		empty_slot.amount = to_add
		remaining -= to_add

	if remaining != amount:
		updated.emit()

	# If we hit the capacity check above, this *should* always be true.
	var success: bool = (remaining == 0)
	if not success:
		push_warning("Inventory.insert: logic error, can_insert said true but remaining =", remaining)
	return success


# Directly set the slot resource (used by your UI logic).
func insert_slot(index: int, inventory_slot: InventorySlot) -> void:
	if index < 0 or index >= slots.size():
		push_warning("insert_slot: index %d out of range" % index)
		return

	slots[index] = inventory_slot
	updated.emit()


# Clear the slot that matches this InventorySlot resource.
func remove_slot(slot_to_remove: InventorySlot) -> void:
	if slot_to_remove == null:
		return

	for i in slots.size():
		if slots[i] == slot_to_remove:
			slots[i] = InventorySlot.new()
			updated.emit()
			return


#        


# Called by the hotbar / gameplay when using an item.
#func use_item_at_index(index: int, user: Node, target: Node = null) -> void:
	#var slot: InventorySlot = _get_slot(index)
	#if slot == null or slot.item == null:
		#return
#
	#var item := slot.item
	#var should_consume := ItemUseSystem.use_item(item, user, target)
#
	#if should_consume:
		#slot.amount -= 1
		#if slot.amount <= 0:
			#slot.clear()
		#updated.emit()


#func swap_slots(index_a: int, index_b: int) -> void:
	#if index_a == index_b:
		#return
#
	#if index_a < 0 or index_b < 0:
		#return
#
	#if index_a >= slots.size() or index_b >= slots.size():
		#return
#
	#var tmp: InventorySlot = slots[index_a]
	#slots[index_a] = slots[index_b]
	#slots[index_b] = tmp
#
	#updated.emit()


# Takes up to `amount` from slot `index`.
# Returns how many were actually taken (0 if slot empty/invalid).
func take_from_index(index: int, amount: int) -> int:
	var slot: InventorySlot = _get_slot(index)

	if slot == null:
		print("TAKE: slot", index, "is null")
		return 0
	if slot.item == null:
		print("TAKE: slot", index, "item is null")
		return 0
	if amount <= 0:
		print("TAKE: amount <= 0 for index", index)
		return 0

####################
#Add to Debug!!
####################
	#print("TAKE: before → index", index,
		#"item", slot.item.name,
		#"amount", slot.amount)

	var to_take: int = min(amount, slot.amount)
	slot.amount -= to_take

	if slot.amount <= 0:
		slot.clear()

	updated.emit()

	print("TAKE: after → slot.amount", slot.amount, "to_take", to_take)
	return to_take


# Returns how many of this item the player has in total.
func get_total_amount(item: InventoryItem) -> int:
	if item == null:
		return 0

	var total := 0
	for slot: InventorySlot in slots:
		if slot.item == item:
			total += slot.amount
	return total


# Returns true if the inventory contains at least `amount` of `item`.
func has_item_amount(item: InventoryItem, amount: int) -> bool:
	if item == null or amount <= 0:
		return false

	return get_total_amount(item) >= amount


# Remove up to `amount` of `item` from the inventory.
# Returns how many were actually removed.
func remove_item(item: InventoryItem, amount: int) -> int:
	if item == null or amount <= 0:
		return 0

	var remaining := amount
	for slot: InventorySlot in slots:
		if slot.item != item:
			continue

		var to_take = min(slot.amount, remaining)
		slot.amount -= to_take
		remaining -= to_take

		if slot.amount <= 0:
			slot.clear()

		if remaining <= 0:
			updated.emit()
			return amount  # removed everything requested

	# If we get here, we ran out of stacks.
	var removed := amount - remaining
	if removed > 0:
		updated.emit()
	return removed
