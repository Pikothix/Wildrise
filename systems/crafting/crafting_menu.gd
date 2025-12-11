extends Control
class_name CraftingMenu

@export var known_recipes: Array[CraftingRecipe] = []

# Path to your ItemStack scene (same as in InventoryGui)
@export var item_stack_scene: PackedScene = preload("res://systems/inventory/scenes/inv_items_stack.tscn")

@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Grid
@onready var output_slot_ui: InventorySlotUI = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ResultBox/OutputSlot
@onready var craft_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsBox/CraftButton
@onready var clear_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsBox/ClearButton

var player_inventory: Inventory
var player_skill_set: SkillSet
var current_tool: DataTypes.Tools = DataTypes.Tools.None

# Backing data for the grid
var grid_slots: Array[InventorySlot] = []
var grid_stacks: Array[ItemStack] = []
var grid_slot_uis: Array[InventorySlotUI] = []

# Backing data for output / preview
var output_slot: InventorySlot = InventorySlot.new()
var output_stack: ItemStack



func _ready() -> void:

	# --- Set up 2×2 grid backing slots + ItemStacks ---
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

	# --- Set up output slot ---
	output_stack = item_stack_scene.instantiate() as ItemStack
	output_stack.inventory_slot = output_slot
	output_slot_ui.set_item_stack(output_stack)

	# --- Hook buttons ---
	craft_button.pressed.connect(_on_craft_pressed)
	clear_button.pressed.connect(_on_clear_pressed)

	_update_output()


func set_context(inventory: Inventory, skill_set: SkillSet, current_tool_in: DataTypes.Tools) -> void:
	player_inventory = inventory
	player_skill_set = skill_set
	current_tool = current_tool_in
	_update_output()



# --- Public helper: we can later call this when clicking inventory slots ---
func add_ingredient(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var remaining := amount

	# 1) Try stacking onto existing same-item slots
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

	# 2) Use empty slots
	for i in range(grid_slots.size()):
		var slot_res := grid_slots[i]
		if slot_res.item == null:
			slot_res.item = item
			slot_res.amount = remaining
			remaining = 0
			grid_stacks[i].update()
			_update_output()
			return true

	# No space
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


# --- Button handlers ---
func _on_craft_pressed() -> void:
	if player_inventory == null:
		print("CraftingMenu: no player_inventory set")
		return

	var recipe := _find_matching_recipe()
	if recipe == null:
		print("CraftingMenu: no matching recipe")
		return

	if not _passes_gates(recipe):
		print("CraftingMenu: gates failed (tool/skill)")
		return

	# Consume ingredients from the grid
	if not _consume_ingredients_from_grid(recipe):
		print("CraftingMenu: failed to consume ingredients (should not happen)")
		return

	# Give results to player inventory
	for res: CraftingIngredient in recipe.results:
		if res == null or res.item == null or res.amount <= 0:
			continue
		if not player_inventory.insert(res.item, res.amount):
			print("CraftingMenu: not enough space to insert crafted item", res.item.name, "x", res.amount)

	# Refresh visuals
	for stack in grid_stacks:
		stack.update()
	_update_output()


func _on_clear_pressed() -> void:
	# Return items to player inventory if possible
	clear_grid(true)


# --- Internal helpers ---

func _update_output() -> void:
	# Clear output
	output_slot.clear()
	output_stack.update()

	var recipe := _find_matching_recipe()
	if recipe == null:
		return

	# Just preview the first result
	for res: CraftingIngredient in recipe.results:
		if res != null and res.item != null and res.amount > 0:
			output_slot.item = res.item
			output_slot.amount = res.amount
			output_stack.update()
			break


func _find_matching_recipe() -> CraftingRecipe:
	if known_recipes.is_empty():
		return null

	var grid_counts := _build_grid_item_counts()

	for recipe in known_recipes:
		if recipe == null:
			continue
		if not _passes_gates(recipe):
			continue
		if _grid_satisfies_recipe(grid_counts, recipe):
			return recipe

	return null


func _build_grid_item_counts() -> Dictionary:
	var counts: Dictionary = {}
	for slot_res in grid_slots:
		if slot_res.item == null or slot_res.amount <= 0:
			continue
		if not counts.has(slot_res.item):
			counts[slot_res.item] = 0
		counts[slot_res.item] += slot_res.amount
	return counts


func _grid_satisfies_recipe(grid_counts: Dictionary, recipe: CraftingRecipe) -> bool:
	for ing: CraftingIngredient in recipe.ingredients:
		if ing == null or ing.item == null or ing.amount <= 0:
			continue

		if not grid_counts.has(ing.item):
			return false
		if grid_counts[ing.item] < ing.amount:
			return false

	return true


func _passes_gates(recipe: CraftingRecipe) -> bool:
	# Tool gate
	if recipe.required_tool != DataTypes.Tools.None:
		if current_tool != recipe.required_tool:
			return false

	# Skill gate
	if recipe.skill_name != &"" and recipe.min_skill_level > 0 and player_skill_set != null:
		var skill := player_skill_set.get_skill(recipe.skill_name)
		if skill == null or skill.level < recipe.min_skill_level:
			return false

	return true


func _consume_ingredients_from_grid(recipe: CraftingRecipe) -> bool:
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
