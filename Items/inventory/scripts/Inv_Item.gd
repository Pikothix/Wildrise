extends Resource
class_name InventoryItem

enum ItemCategory { GENERIC, TOOL, WEAPON, CONSUMABLE }

@export var id: StringName = &""      # "axe_wood", "health_potion_small"
@export var name: String = ""
@export var texture: AtlasTexture
@export var max_amount: int = 99


@export var category: ItemCategory = ItemCategory.GENERIC
@export var tool_type: DataTypes.Tools = DataTypes.Tools.None


# Stats for weapons/tools
@export var damage: int = 0           # melee/ranged damage
@export var chop_power: int = 0       # how good it is at chopping trees
@export var mine_power: int = 0       # for rocks, ore, etc.

# Stats for consumables
@export var heal_amount: int = 0      # how much health to restore

# Generic metadata
@export var tags: Array[StringName] = []  # e.g. [&"axe", &"wood", &"tool"]
