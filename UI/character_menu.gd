extends Control
class_name CharacterMenu

@export var player: Player   # drag the Player node into this in Main scene

@onready var tabs: TabContainer        = $MarginContainer/VBox/Tabs
@onready var inventory_gui: InventoryGui = $MarginContainer/VBox/Tabs/Inventory/InventoryGui
@onready var stats_menu: StatsMenu       = $MarginContainer/VBox/Tabs/StatsMenu
@onready var skills_menu: SkillsMenu     = $MarginContainer/VBox/Tabs/SkillsMenu
@onready var crafting_menu: CraftingMenu = $Panel/MarginContainer/VBox/Tabs/CraftingTab/CraftingMenu


var _is_open: bool = false

const TAB_INVENTORY := 0
const TAB_STATS := 1
const TAB_SKILLS := 2
const TAB_CRAFTING := 3


func _ready() -> void:
	visible = false

	# --- Inventory wiring ---
	if player and inventory_gui:
		inventory_gui.set_inventory(player.inventory)
		if not inventory_gui.drop_requested.is_connected(player.on_inventory_drop_requested):
			inventory_gui.drop_requested.connect(player.on_inventory_drop_requested)
	else:
		push_warning("CharacterMenu: player or inventory_gui not set – inventory will stay empty")

	# --- Stats / Skills wiring ---
	if player:
		if stats_menu and player.stats_component:
			var s := player.stats_component.get_stats()
			stats_menu.set_stats(s)

		if skills_menu and player.skill_set:
			skills_menu.set_skill_set(player.skill_set)

	if stats_menu:
		stats_menu.use_own_input = false
	if skills_menu:
		skills_menu.use_own_input = false

	# --- Tabs setup ---
	if tabs:
		tabs.tab_changed.connect(_on_tab_changed)
		tabs.current_tab = TAB_INVENTORY
		_update_tab_states()

	if player and crafting_menu:
		crafting_menu.set_context(player.inventory, player.skill_set, player.current_tool)
		# optionally assign some starting recipes:
		# crafting_menu.known_recipes = [recipe_axe, recipe_plank, ...]





# ---------- PUBLIC API (called from Player) ----------

func is_open() -> bool:
	return _is_open

func toggle() -> void:
	if _is_open:
		_set_open(false)
	else:
		open_inventory_tab()   # always open on inventory when toggling


func open_inventory_tab() -> void:
	_set_open(true)
	_set_tab(TAB_INVENTORY)

func open_stats_tab() -> void:
	_set_open(true)
	_set_tab(TAB_STATS)

func open_skills_tab() -> void:
	_set_open(true)
	_set_tab(TAB_SKILLS)


func cycle_tab(direction: int) -> void:
	# direction: -1 = left, +1 = right
	if not _is_open or not tabs:
		return

	var count := tabs.get_tab_count()
	if count <= 0:
		return

	var new_index := (tabs.current_tab + direction + count) % count
	_set_tab(new_index)



# ---------- INTERNAL ----------

func _set_open(open: bool) -> void:
	_is_open = open
	visible = open

	if not tabs:
		return

	_update_tab_states()


func _set_tab(tab_index: int) -> void:
	if not tabs:
		return

	tabs.current_tab = tab_index

	if not _is_open:
		return

	_update_tab_states()


func _update_tab_states() -> void:
	var current := tabs.current_tab if tabs else TAB_INVENTORY

	if inventory_gui:
		if _is_open and current == TAB_INVENTORY:
			inventory_gui.open()
		else:
			inventory_gui.close()

	if stats_menu:
		stats_menu.set_open(_is_open and current == TAB_STATS)

	if skills_menu:
		skills_menu.set_open(_is_open and current == TAB_SKILLS)





func _on_tab_changed(_tab_index: int) -> void:
	if not _is_open:
		return
	_update_tab_states()
