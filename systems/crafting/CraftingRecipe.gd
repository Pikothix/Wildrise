extends Resource
class_name CraftingRecipe

@export var recipe_name: String = ""
@export var description: String = ""

@export var ingredients: Array[CraftingIngredient] = []
@export var results: Array[CraftingIngredient] = []

@export var required_tool: DataTypes.Tools = DataTypes.Tools.None

@export var min_skill_level: int = 0
@export var skill_name: StringName = &""
