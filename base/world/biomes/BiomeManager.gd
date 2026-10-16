class_name BiomeManager
extends Resource

@export var biomes: Array[BiomeData] = []

## Selects a biome based on cumulative weights
func get_random_biome(rng: RandomNumberGenerator) -> BiomeData:
	if biomes.is_empty():
		print("No Biomes in array!")
		return null

	var total_weight: float = 0.0
	for biome in biomes:
		if biome:
			total_weight += biome.spawn_weight

	var roll := rng.randf_range(0.0, total_weight)
	var current_sum: float = 0.0

	for biome in biomes:
		if biome == null:
			continue
		current_sum += biome.spawn_weight
		if roll <= current_sum:
			return biome

	return biomes[0]
