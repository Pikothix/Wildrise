extends Resource
class_name SkillSet

@export var skills: Array[Skill] = []   # assign in inspector

func get_skill(skill_name: StringName) -> Skill:
	for s in skills:
		if s.skill_name == skill_name:
			return s
	return null

func add_experience(skill_name: StringName, amount: float) -> void:
	var skill := get_skill(skill_name)
	if skill:
		skill.add_experience(amount)
