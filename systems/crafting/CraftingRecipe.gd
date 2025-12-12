extends Resource
class_name CraftingRecipe

@export var results: Array[CraftingIngredient] = []
@export var ingredients: Array[CraftingIngredient] = [] # keep for shapless ones

@export var shaped: bool = false

# Pattern is row-major, using 4 items for 2x2, or 9 for 3x3.
# Use null for empty cells.
@export var pattern: Array[InventoryItem] = []

@export var required_tool: DataTypes.Tools = DataTypes.Tools.None
@export var skill_name: StringName = &""
@export var min_skill_level: int = 0
