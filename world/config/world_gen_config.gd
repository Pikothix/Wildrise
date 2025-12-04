class_name WorldGenConfig
extends Resource

@export var biomes: Array[Dictionary] = [
	{
		"name": "ocean",
		"h_min": 0.0,
		"h_max": 0.46,
	},
	{
		"name": "beach",
		"h_min": 0.46,
		"h_max": 0.48,
	},
	{
		"name": "desert",
		"h_min": 0.48,
		"h_max": 0.52,
		"t_min": 0.5,
		"m_max": 0.5,
	},
	{
		"name": "jungle",
		"h_min": 0.48,
		"h_max": 0.52,
		"t_min": 0.45,
		"m_min": 0.4,
	},
	{
		"name": "plains",
		"h_min": 0.48,
		"h_max": 0.52,
	},
	{
		"name": "mountain",
		"h_min": 0.72,
		"h_max": 0.95,
	},
	{
		"name": "snow",
		"h_min": 0.95,
		"h_max": 1.0,
	},
]

@export var biome_tiles: Dictionary = {
	"ocean": {
		"tiles": ["water"],
		"weights": [1.0],
	},

	"plains": {
		# uses TileLibrary "grass" (which can have variants)
		"tiles": ["grass"],
		"weights": [1.0],
	},

	"beach": {
		# beach is just sand here
		"tiles": ["sand"],
		"weights": [1.0],
	},

	"mountain": {
		"tiles": ["mountain"],
		"weights": [1.0],
	},

	"dirt": {
		"tiles": ["dirt"],
		"weights": [1.0],
	},

	"jungle": {
		"tiles": ["jungle"],
		"weights": [1.0],
	},

	"desert": {
		# same visual as beach, different biome logic
		"tiles": ["sand"],
		"weights": [1.0],
	},

	"lake": {
		"tiles": ["water"],
		"weights": [1.0],
	},

	"snow": {
		"tiles": ["snow"],
		"weights": [1.0],
	},
}


@export var object_tiles: Dictionary = {
	"tree": preload("res://entities/world_objects/tree/tree.tscn"),
	"blue_tree": preload("res://scenes/objects/blue_tree.tscn"),
	"cactus": preload("res://scenes/objects/cactus.tscn"),
	"rock_a": preload("res://scenes/objects/rock_a.tscn"),
	"rock_b": preload("res://scenes/objects/rock_b.tscn"),
}

@export var decoration_rules: Dictionary = {
	"plains": [
		{
			"type": "scene",
			"name": "tree",
			"prob": 0.03,
			"conditions": {
				"h_min": 0.20,
				"h_max": 0.60,
				"tree_min": 0.3,
			}
		},
		{
			"type": "tile",
			"tiles": ["flower"], # flower_arr
			"layer": "EnvLayer",
			"prob": 0.2,
			"conditions": {
				"tree_min": 0.4,
			}
		},
		{
			"type": "tile",
			"tiles": ["pettle"], # pettle_arr
			"layer": "EnvLayer",
			"prob": 0.2,
			"conditions": {
				"tree_min": 0.5,
			}
		},
	],
	"desert": [
		{
			"type": "scene",
			"name": "cactus",
			"prob": 0.009,
			"conditions": {
				"tree_min": 0.3,
			}
		},
	],
	"mountain": [
		{
			"type": "scene",
			"name": "rock_a",
			"prob": 0.01,
			"conditions": {
				"tree_min": 0.4,
			}
		},
	],
	"jungle": [
		{
			"type": "tile",
			"tiles": ["mushroom"], # mushroom_arr
			"layer": "EnvLayer",
			"prob": 0.02,
			"conditions": {
				"m_max": 0.6,
				"t_max": 0.5,
				"tree_min": 0.4,
			}
		},
		{
			"type": "scene",
			"name": "blue_tree",
			"prob": 0.03,
			"conditions": {
				"h_min": 0.20,
				"h_max": 0.60,
				"tree_min": 0.3,
			}
		},
		{
			"type": "tile",
			"tiles": ["flower"], # flower_arr
			"layer": "EnvLayer",
			"prob": 0.1,
			"conditions": {
				"tree_min": 0.4,
			}
		},
		{
			"type": "tile",
			"tiles": ["pettle"], # pettle_arr
			"layer": "EnvLayer",
			"prob": 0.1,
			"conditions": {
				"tree_min": 0.5,
			}
		},
	],

	"beach": [
		{
			"type": "tile",
			"tiles": ["sandblade"], # sandblade_arr
			"layer": "EnvLayer",
			"prob": 0.3,
			"conditions": {
				"h_min": 0.46,
				"h_max": 0.50,
				"m_min": 0.3,
				"tree_min": 0.4,
			},
		},
	],
}
