extends Control
class_name SkillsMenu

@export var skill_set: SkillSet   # overridden at runtime
@export var use_own_input: bool = true   # <- NEW

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
		print("SkillsMenu: opening (from parent), resolving SkillSet...")
		_ensure_skill_set()
		_refresh_skills()
	else:
		print("SkillsMenu: closing (from parent)")




func _ensure_skill_set() -> void:
	# Prefer Player's SkillSet
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.skill_set:
		if skill_set != player.skill_set:
			print("SkillsMenu: overriding exported SkillSet with Player's SkillSet:", player.skill_set)
		skill_set = player.skill_set
		_connect_skill_signals()   
		return

	# Fallback: use exported
	if skill_set != null:
		print("SkillsMenu: using exported SkillSet:", skill_set)
		_connect_skill_signals()    
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


func _connect_skill_signals() -> void:
	if _skills_connected or skill_set == null:
		return

	for s in skill_set.skills:
		if not s.level_up.is_connected(_on_skill_changed):
			s.level_up.connect(_on_skill_changed)
		if not s.experience_changed.is_connected(_on_skill_changed):
			s.experience_changed.connect(_on_skill_changed)

	_skills_connected = true


func _on_skill_changed(_value) -> void:
	# Called when any skill gains XP or levels up
	if _is_open:
		_refresh_skills()
