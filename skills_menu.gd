extends Control
class_name SkillsMenu

@export var skill_set: SkillSet   # overridden at runtime

@onready var skills_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/SkillList
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel

var _is_open: bool = false

func _ready() -> void:
	visible = false
	title_label.text = "Skills"
	print("SkillsMenu: _ready called")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_skills"):
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	_is_open = not _is_open
	visible = _is_open

	if _is_open:
		print("SkillsMenu: opening, resolving SkillSet...")
		_ensure_skill_set()
		_refresh_skills()
	else:
		print("SkillsMenu: closing")

func _ensure_skill_set() -> void:
	# Prefer Player's SkillSet
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.skill_set:
		if skill_set != player.skill_set:
			print("SkillsMenu: overriding exported SkillSet with Player's SkillSet:", player.skill_set)
		skill_set = player.skill_set
		return

	# Fallback: use exported
	if skill_set != null:
		print("SkillsMenu: using exported SkillSet:", skill_set)
	else:
		push_warning("SkillsMenu: no SkillSet found (no Player and none exported)")

func _refresh_skills() -> void:
	if skill_set == null:
		push_warning("SkillsMenu: no SkillSet; nothing to display")
		return

	if skills_list == null:
		push_warning("SkillsMenu: SkillList VBox not found")
		return

	# Clear old rows
	for child in skills_list.get_children():
		child.queue_free()

	print("SkillsMenu: refreshing skills...")
	print("  SkillSet resource:", skill_set)
	print("  skills array size:", skill_set.skills.size())

	if skill_set.skills.is_empty():
		print("SkillsMenu: SkillSet has no skills")
		return

	for i in range(skill_set.skills.size()):
		var s: Skill = skill_set.skills[i]
		print("  skill[", i, "] name =", s.skill_name, "level =", s.level, "xp =", s.experience)
		_add_skill_row(s)

	# 🔹 Ensure the list actually has some height so ScrollContainer can show it
	var row_height := 24.0
	skills_list.custom_minimum_size.y = skills_list.get_child_count() * row_height
	print("SkillsMenu: SkillList now has", skills_list.get_child_count(), "rows")

func _add_skill_row(skill: Skill) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 24  # give it a visible height

	var name_label := Label.new()
	name_label.text = str(skill.skill_name).capitalize()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var level_label := Label.new()
	level_label.text = "Lv %d" % skill.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.custom_minimum_size.x = 50

	var xp_label := Label.new()
	xp_label.text = "XP: %.1f" % skill.experience
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_label.custom_minimum_size.x = 100

	row.add_child(name_label)
	row.add_child(level_label)
	row.add_child(xp_label)

	skills_list.add_child(row)
