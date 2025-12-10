extends Control
class_name SkillsMenu

@export var skill_set: SkillSet   # can still be set in inspector
@export var use_own_input: bool = true

@onready var skills_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/SkillList
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel

var _is_open: bool = false
var _skills_connected: bool = false


func _ready() -> void:
	visible = false
	title_label.text = "Skills"
	print("SkillsMenu: _ready called")


func set_open(open: bool) -> void:
	_is_open = open
	visible = open

	if _is_open:
		print("SkillsMenu: opening (from parent)")
		_connect_skill_signals()
		_refresh_skills()
	else:
		print("SkillsMenu: closing (from parent)")


func set_skill_set(new_skill_set: SkillSet) -> void:
	if skill_set == new_skill_set:
		return

	skill_set = new_skill_set
	_skills_connected = false
	_connect_skill_signals()

	if _is_open:
		_refresh_skills()


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

	var row_height := 24.0
	skills_list.custom_minimum_size.y = skills_list.get_child_count() * row_height
	print("SkillsMenu: SkillList now has", skills_list.get_child_count(), "rows")


func _add_skill_row(skill: Skill) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 24

	var name_label := Label.new()
	name_label.text = str(skill.skill_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_label := Label.new()
	value_label.text = "Lv %d (%.1f XP)" % [skill.level, skill.experience]
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 160

	row.add_child(name_label)
	row.add_child(value_label)
	skills_list.add_child(row)


func _connect_skill_signals() -> void:
	if _skills_connected or skill_set == null:
		return

	for s in skill_set.skills:
		if not s.level_up.is_connected(_on_skill_level_up.bind(s)):
			s.level_up.connect(_on_skill_level_up.bind(s))
		if not s.experience_changed.is_connected(_on_skill_xp_changed.bind(s)):
			s.experience_changed.connect(_on_skill_xp_changed.bind(s))

	_skills_connected = true


func _on_skill_level_up(_new_level: int, _skill: Skill) -> void:
	if _is_open:
		_refresh_skills()

func _on_skill_xp_changed(_new_xp: float, _skill: Skill) -> void:
	if _is_open:
		_refresh_skills()
