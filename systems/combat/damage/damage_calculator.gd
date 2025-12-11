# systems/combat/damage/damage_calculator.gd
extends Resource
class_name DamageCalculator

static func compute_damage(
	attacker_stats: Stats,
	defender_stats: Stats,
	base_weapon_damage: int
) -> int:
	var attack_value := 0

	# Prefer weapon/tool damage if set, otherwise use the attack stat
	if base_weapon_damage > 0:
		attack_value = base_weapon_damage
	elif attacker_stats:
		attack_value = int(attacker_stats.current_attack)

	# No attack value? No damage.
	if attack_value <= 0:
		return 0

	var defence_value := 0
	if defender_stats:
		defence_value = int(defender_stats.current_defence)

	# Simple formula for now: damage = attack - defence (min 1)
	var final_damage := attack_value - defence_value
	if final_damage < 1:
		final_damage = 1

	return final_damage
