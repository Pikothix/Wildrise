# DeathRewards.gd
extends Resource
class_name DeathRewards

# XP that goes to one or more skills (Slayer, Woodcutting, etc.)
@export var skill_rewards: Array[SkillXpReward] = []

# Placeholder for the future – you don't have to hook this up yet.
# Later this could be a LootTable resource.
@export var loot_table: Resource
