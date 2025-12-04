class_name LootEntry
extends Resource

@export var item: InventoryItem
@export_range(0.0, 1.0) var drop_chance: float = 1.0   # 1.0 = always, 0.5 = 50%
@export var min_amount: int = 1
@export var max_amount: int = 1
