class_name LootTable
extends Resource

@export var rolls: int = 1
@export var entries: Array[LootEntry] = []


func generate_loot(
	rng: RandomNumberGenerator = RandomNumberGenerator.new(),
	extra_rolls: int = 0
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	rng.randomize()

	var total_rolls: int = max(0, rolls + extra_rolls)

	for roll in range(total_rolls):
		for entry in entries:
			if entry.item == null:
				continue

			if rng.randf() <= entry.drop_chance:
				var amount: int = rng.randi_range(entry.min_amount, entry.max_amount)
				if amount > 0:
					results.append({
						"item": entry.item,
						"amount": amount,
					})

	return results
