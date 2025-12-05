#extends Resource
#class_name NpcSpawnConfig
#
#@export var npc_definitions: Array[Dictionary] = [
	#{
		#"id": "chicken",
		#"display_name": "Chicken",
		#"scene": preload("res://entities/npc/entity/lizard/lizard.tscn"),
		#"allowed_biomes": ["plains", "jungle"],
		#"base_spawn_chance": 0.001,   # per tile
		#"max_per_chunk": 10,
		## NEW: flock settings
		#"group_min": 3,
		#"group_max": 8,
		#"group_radius": 1,  # in tiles around the anchor tile
		#
		#"min_height": 0.0,
		#"max_height": 1.0,
		#"min_temp": 0.0,
		#"max_temp": 1.0,
		#"min_moisture": 0.0,
		#"max_moisture": 1.0,
	#},
	#{
		#"id": "squirrel",
		#"display_name": "squirrel",
		#"scene": preload("res://entities/npc/entity/squirrel/squirrel.tscn"),
		#"allowed_biomes": ["plains", "jungle"],
		#"base_spawn_chance": 0.007,   # per tile
		#"max_per_chunk": 10,
		#"min_height": 0.0,
		#"max_height": 1.0,
		#"min_temp": 0.0,
		#"max_temp": 1.0,
		#"min_moisture": 0.0,
		#"max_moisture": 1.0,
	#},
	#{
		#"id": "cobra",
		#"display_name": "cobra",
		#"scene": preload("res://entities/npc/entity/cobra/cobra.tscn"),
		#"allowed_biomes": ["plains", "jungle", "ocean"],
		#"base_spawn_chance": 0.005,   # per tile
		#"max_per_chunk": 10,
		#"min_height": 0.0,
		#"max_height": 1.0,
		#"min_temp": 0.0,
		#"max_temp": 1.0,
		#"min_moisture": 0.0,
		#"max_moisture": 1.0,
	#},
	#{
		#"id": "crab",
		#"display_name": "crab",
		#"scene": preload("res://entities/npc/entity//crab/crab.tscn"),
		#"allowed_biomes": ["beach"],
		#"base_spawn_chance": 0.01,   # per tile
		#"max_per_chunk": 10,
		#"min_height": 0.0,
		#"max_height": 1.0,
		#"min_temp": 0.0,
		#"max_temp": 1.0,
		#"min_moisture": 0.0,
		#"max_moisture": 1.0,
	#},
	#{
		##"id": "villager",
		##"display_name": "Villager",
		##"scene": preload("res://scenes/npc/villager.tscn"),
		##"allowed_biomes": ["plains"],
		##"base_spawn_chance": 0.005,
		##"max_per_chunk": 3,
		##"min_height": 0.48,
		##"max_height": 0.70,
		##"min_temp": 0.2,
		##"max_temp": 0.8,
		##"min_moisture": 0.2,
		##"max_moisture": 0.8,
	#},
	## add more NPCs here
#]
