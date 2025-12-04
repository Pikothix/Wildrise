extends Node
class_name ItemUseSystem

static func use_item(item: InventoryItem, user: Node, target: Node = null) -> bool:
	if item == null:
		return false

	match item.category:
		InventoryItem.ItemCategory.CONSUMABLE:
			return _use_consumable(item, user)

		InventoryItem.ItemCategory.WEAPON:
			return _use_weapon(item, user, target)

		InventoryItem.ItemCategory.TOOL:
			return _use_tool(item, user, target)

		_:
			return false


static func _use_consumable(item: InventoryItem, user: Node) -> bool:
	if item.heal_amount > 0 and user != null and "heal" in user:
		user.heal(item.heal_amount)
		return true
	return false


static func _use_weapon(item: InventoryItem, user: Node, target: Node) -> bool:
	if target != null and item.damage > 0 and "take_damage" in target:
		target.take_damage(item.damage, user)
	return false


static func _use_tool(item: InventoryItem, user: Node, target: Node) -> bool:
	if target != null and item.chop_power > 0 and "hit_by_tool" in target:
		target.hit_by_tool(item, user)
	return false
