extends Node
class_name CraftingSystem

static func can_craft(
	inventory: Inventory,
	recipe: CraftingRecipe,
	current_tool: DataTypes.Tools = DataTypes.Tools.None,
	skill_set: SkillSet = null
) -> bool:
	if inventory == null or recipe == null:
		return false

	# Tool gating
	if recipe.required_tool != DataTypes.Tools.None and current_tool != recipe.required_tool:
		return false

	# Skill gating (optional)
	if recipe.skill_name != &"" and recipe.min_skill_level > 0 and skill_set != null:
		var skill := skill_set.get_skill(recipe.skill_name)
		if skill == null or skill.level < recipe.min_skill_level:
			return false

	# Ingredient check
	for ing: CraftingIngredient in recipe.ingredients:
		if ing == null or ing.item == null or ing.amount <= 0:
			continue

		if not inventory.has_item_amount(ing.item, ing.amount):
			return false

	return true


static func craft(
	inventory: Inventory,
	recipe: CraftingRecipe,
	current_tool: DataTypes.Tools = DataTypes.Tools.None,
	skill_set: SkillSet = null
) -> bool:
	if not can_craft(inventory, recipe, current_tool, skill_set):
		return false

	# 1) Consume ingredients
	for ing: CraftingIngredient in recipe.ingredients:
		if ing == null or ing.item == null or ing.amount <= 0:
			continue

		var removed := inventory.remove_item(ing.item, ing.amount)
		if removed < ing.amount:
			print("CraftingSystem: WARNING - removed only", removed, "of", ing.amount, "for", ing.item.name)

	# 2) Add results
	for res: CraftingIngredient in recipe.results:
		if res == null or res.item == null or res.amount <= 0:
			continue

		if not inventory.insert(res.item, res.amount):
			print("CraftingSystem: not enough space to insert crafted item", res.item.name, "x", res.amount)

	return true
	
