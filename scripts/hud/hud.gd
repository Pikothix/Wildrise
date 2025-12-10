extends CanvasLayer

@export var inventory_gui: InventoryGui
@export var player: Player

func _ready() -> void:
	if inventory_gui == null:
		push_error("HUD: 'inventory_gui' export is null. Drag the InventoryGui node into this field in the Inspector.")
		return
	if player == null:
		push_error("HUD: 'player' export is null. Assign the Player node in the Inspector.")
		return

	# Tell the GUI which inventory to show, but don't handle any input here.
	inventory_gui.set_inventory(player.inventory)
	inventory_gui.close()  # start closed
