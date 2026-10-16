class_name BiomeData
extends Resource

@export var biome_name: String = "Plains"

@export_group("Spawning Thresholds")
## Range: -1.0 to 1.0. Lower values = Oceans, Higher values = Land/Mountains
@export_range(-1.0, 1.0) var target_continentalness: float = 0.0
@export_range(0.0, 100.0) var spawn_weight: float = 1.0

@export_group("Terrain & Height")
@export var height_scale: float = 20.0
@export var is_ocean: bool = false
@export var sea_level: float = -2.0

@export_group("Visuals & Scenery")
@export var terrain_color: Color = Color.GREEN
@export var scenery_scenes: Array[PackedScene] = []
