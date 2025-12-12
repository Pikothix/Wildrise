extends Control
class_name CraftingMenu

@export var known_recipes: Array[CraftingRecipe] = []

@export var item_stack_scene: PackedScene = preload("res://systems/inventory/scenes/inv_items_stack.tscn")

@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Grid
@onready var output_slot_ui: InventorySlotUI = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ResultBox/OutputSlot

var player_inventory: Inventory        # currently only used if you call clear_grid(true)
var player_skill_set: SkillSet
var current_tool: DataTypes.Tools = DataTypes.Tools.None

var grid_slots: Array[InventorySlot] = []
var grid_stacks: Array[ItemStack] = []
var grid_slot_uis: Array[InventorySlotUI] = []

var output_slot: InventorySlot = InventorySlot.new()
var output_stack: ItemStack

const GRID_W := 2
const GRID_H := 2

var _last_matched_recipe: CraftingRecipe = null
var _last_match_ox: int = 0
var _last_match_oy: int = 0
var _last_match_pat_w: int = 0
var _last_match_pat_h: int = 0


func _ready() -> void:
	grid_slots.clear()
	grid_stacks.clear()
	grid_slot_uis.clear()

	for child in grid_container.get_children():
		if child is InventorySlotUI:
			var slot_res := InventorySlot.new()
			var stack := item_stack_scene.instantiate() as ItemStack
			stack.inventory_slot = slot_res
			child.set_item_stack(stack)

			grid_slots.append(slot_res)
			grid_stacks.append(stack)
			grid_slot_uis.append(child)

	output_stack = item_stack_scene.instantiate() as ItemStack
	output_stack.inventory_slot = output_slot
	output_slot_ui.set_item_stack(output_stack)

	_update_output()


func set_context(inventory: Inventory, skill_set: SkillSet, current_tool_in: DataTypes.Tools) -> void:
	player_inventory = inventory
	player_skill_set = skill_set
	current_tool = current_tool_in
	_update_output()


# --- helper for quick-send from inventory ---
func add_ingredient(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var remaining := amount

	# stack into same item
	for i in range(grid_slots.size()):
		var slot_res := grid_slots[i]
		if slot_res.item == item and slot_res.amount < item.max_amount:
			var can_add = min(item.max_amount - slot_res.amount, remaining)
			slot_res.amount += can_add
			remaining -= can_add
			grid_stacks[i].update()
			if remaining <= 0:
				_update_output()
				return true

	# empty slots
	for i in range(grid_slots.size()):
		var slot_res := grid_slots[i]
		if slot_res.item == null:
			slot_res.item = item
			slot_res.amount = remaining
			remaining = 0
			grid_stacks[i].update()
			_update_output()
			return true

	_update_output()
	return false


func clear_grid(return_to_inventory: bool = false) -> void:
	for i in range(grid_slots.size()):
		var slot_res := grid_slots[i]
		if slot_res.item != null and slot_res.amount > 0 and return_to_inventory and player_inventory:
			if not player_inventory.insert(slot_res.item, slot_res.amount):
				print("CraftingMenu: failed to return", slot_res.amount, "x", slot_res.item.name, "to inventory")

		slot_res.clear()
		grid_stacks[i].update()

	_update_output()


# ---------- core crafting helpers ----------

func _update_output() -> void:
	_last_matched_recipe = null
	_last_match_ox = 0
	_last_match_oy = 0
	_last_match_pat_w = 0
	_last_match_pat_h = 0

	output_slot.clear()
	output_stack.update()

	var recipe := _find_matching_recipe()
	if recipe == null:
		return

	for res: CraftingIngredient in recipe.results:
		if res != null and res.item != null and res.amount > 0:
			output_slot.item = res.item
			output_slot.amount = res.amount
			output_stack.update()
			break


func _build_grid_item_counts() -> Dictionary:
	var counts: Dictionary = {}
	for slot_res in grid_slots:
		if slot_res.item == null or slot_res.amount <= 0:
			continue

		var item: InventoryItem = slot_res.item
		if not counts.has(item):
			counts[item] = 0
		counts[item] += slot_res.amount

	return counts


func _grid_satisfies_recipe(grid_counts: Dictionary, recipe: CraftingRecipe) -> bool:
	var required: Dictionary = {}

	# Build "required" dict: item -> total required amount from recipe
	for ing: CraftingIngredient in recipe.ingredients:
		if ing == null or ing.item == null or ing.amount <= 0:
			continue
		if not required.has(ing.item):
			required[ing.item] = 0
		required[ing.item] += ing.amount

	# 1) No extra item TYPES in the grid (junk kills recipe)
	for item in grid_counts.keys():
		if not required.has(item):
			return false

	# 2) Each required item must be present with AT LEAST the required amount
	for item in required.keys():
		if not grid_counts.has(item):
			return false
		if grid_counts[item] < required[item]:
			return false

	return true


func _find_matching_recipe() -> CraftingRecipe:
	if known_recipes.is_empty():
		return null

	var grid_counts := _build_grid_item_counts()

	for recipe in known_recipes:
		if recipe == null:
			continue
		if not _passes_gates(recipe):
			continue

		if recipe.shaped:
			if _grid_matches_shaped(recipe):
				return recipe
		else:
			if _grid_satisfies_recipe(grid_counts, recipe):
				return recipe

	return null






func _passes_gates(recipe: CraftingRecipe) -> bool:
	if recipe.required_tool != DataTypes.Tools.None:
		if current_tool != recipe.required_tool:
			return false

	if recipe.skill_name != &"" and recipe.min_skill_level > 0 and player_skill_set != null:
		var skill := player_skill_set.get_skill(recipe.skill_name)
		if skill == null or skill.level < recipe.min_skill_level:
			return false

	return true


func _consume_ingredients_from_grid(recipe: CraftingRecipe) -> bool:
	# --- Shaped: consume 1 per non-null pattern cell at the matched offset ---
	if recipe.shaped:
		# Ensure we are consuming for the recipe that was actually matched
		if _last_matched_recipe != recipe:
			# safety: try to match again (so offset is set)
			if not _grid_matches_shaped(recipe):
				return false

		var pattern := recipe.pattern
		var ox := _last_match_ox
		var oy := _last_match_oy
		var pat_w := _last_match_pat_w
		var pat_h := _last_match_pat_h

		# First pass: verify enough amounts exist in each required cell
		for py in range(pat_h):
			for px in range(pat_w):
				var p_item: InventoryItem = pattern[py * pat_w + px]
				if p_item == null:
					continue

				var grid_index := (oy + py) * GRID_W + (ox + px)
				var slot_res := grid_slots[grid_index]

				# Must be the right item and have at least 1 to consume
				if slot_res.item != p_item or slot_res.amount < 1:
					return false

		# Second pass: consume 1 from each required cell
		for py in range(pat_h):
			for px in range(pat_w):
				var p_item: InventoryItem = pattern[py * pat_w + px]
				if p_item == null:
					continue

				var grid_index := (oy + py) * GRID_W + (ox + px)
				var slot_res := grid_slots[grid_index]

				slot_res.amount -= 1
				if slot_res.amount <= 0:
					slot_res.clear()

		return true

	# --- Shapeless: your existing "total counts" consumption ---
	for ing: CraftingIngredient in recipe.ingredients:
		if ing == null or ing.item == null or ing.amount <= 0:
			continue

		var remaining := ing.amount

		for i in range(grid_slots.size()):
			var slot_res := grid_slots[i]
			if slot_res.item != ing.item:
				continue

			var take = min(slot_res.amount, remaining)
			slot_res.amount -= take
			remaining -= take

			if slot_res.amount <= 0:
				slot_res.clear()

			if remaining <= 0:
				break

		if remaining > 0:
			return false

	return true



# Called by InventoryGui when you "pick up" from the result slot
func take_result() -> InventorySlot:
	var recipe := _find_matching_recipe()
	if recipe == null:
		return null
	if not _passes_gates(recipe):
		return null
	if not _consume_ingredients_from_grid(recipe):
		return null

	for res: CraftingIngredient in recipe.results:
		if res != null and res.item != null and res.amount > 0:
			var out := InventorySlot.new()
			out.item = res.item
			out.amount = res.amount

			for s in grid_stacks:
				s.update()
			_update_output()
			return out

	_update_output()
	return null


# ---------- Slot helpers for InventoryGui ----------

func take_from_slot(slot_ui: InventorySlotUI, one_only: bool) -> InventorySlot:
	var idx := grid_slot_uis.find(slot_ui)
	if idx == -1:
		return null

	var slot_res := grid_slots[idx]
	if slot_res.item == null or slot_res.amount <= 0:
		return null

	var amount := slot_res.amount
	if one_only:
		amount = 1

	var taken := InventorySlot.new()
	taken.item = slot_res.item
	taken.amount = amount

	slot_res.amount -= amount
	if slot_res.amount <= 0:
		slot_res.clear()

	grid_stacks[idx].update()
	_update_output()
	return taken


func get_grid_slots() -> Array[InventorySlotUI]:
	return grid_slot_uis


func get_slot_resource(slot_ui: InventorySlotUI) -> InventorySlot:
	var idx := grid_slot_uis.find(slot_ui)
	if idx == -1:
		return null
	return grid_slots[idx]


func update_slot_visual(slot_ui: InventorySlotUI) -> void:
	var idx := grid_slot_uis.find(slot_ui)
	if idx == -1:
		return
	grid_stacks[idx].update()
	_update_output()


func get_output_slot_ui() -> InventorySlotUI:
	return output_slot_ui
	
func _grid_item_at(x: int, y: int) -> InventoryItem:
	var i := y * GRID_W + x
	if i < 0 or i >= grid_slots.size():
		return null
	return grid_slots[i].item

func _is_grid_empty_at(x: int, y: int) -> bool:
	return _grid_item_at(x, y) == null


func _grid_matches_shaped(recipe: CraftingRecipe) -> bool:
	if recipe.pattern.is_empty():
		return false

	var pat_len := recipe.pattern.size()
	var pat_w := 0
	var pat_h := 0

	if pat_len == 4:
		pat_w = 2; pat_h = 2
	elif pat_len == 1:
		pat_w = 1; pat_h = 1
	elif pat_len == 2:
		pat_w = 2; pat_h = 1
	else:
		push_warning("Unsupported pattern size: %s" % pat_len)
		return false

	for oy in range(GRID_H - pat_h + 1):
		for ox in range(GRID_W - pat_w + 1):
			if _matches_pattern_at_offset(recipe.pattern, pat_w, pat_h, ox, oy):
				_last_matched_recipe = recipe
				_last_match_ox = ox
				_last_match_oy = oy
				_last_match_pat_w = pat_w
				_last_match_pat_h = pat_h
				return true

	return false



func _matches_pattern_at_offset(pattern: Array[InventoryItem], pat_w: int, pat_h: int, ox: int, oy: int) -> bool:
	# 1) Pattern cells must match exactly at the offset
	for py in range(pat_h):
		for px in range(pat_w):
			var p_item: InventoryItem = pattern[py * pat_w + px]
			var g_item: InventoryItem = _grid_item_at(ox + px, oy + py)

			if p_item == null:
				if g_item != null:
					return false
			else:
				if g_item != p_item:
					return false

	# 2) Everything OUTSIDE the pattern area must be empty (no junk allowed)
	for y in range(GRID_H):
		for x in range(GRID_W):
			var inside := (x >= ox and x < ox + pat_w and y >= oy and y < oy + pat_h)
			if inside:
				continue
			if _grid_item_at(x, y) != null:
				return false

	return true
