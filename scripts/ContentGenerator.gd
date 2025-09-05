extends Node

# Content Generator - creates procedural maps, factions, and scalable content
signal map_generated(map_data: Dictionary)
signal faction_created(faction_data: Dictionary)

# Map generation parameters
var map_templates = {
	"forest_floor": {
		"name": "Ancient Forest Floor",
		"biome": "forest",
		"size": {"width": 64, "height": 64},
		"resources": ["water_droplets", "leaf_matter", "root_nutrients"],
		"obstacles": ["rocks", "fallen_branches", "root_systems"],
		"special_features": ["mushroom_circles", "fairy_rings"],
		"difficulty_modifier": 1.0
	},
	"compost_heap": {
		"name": "Rich Compost Heap", 
		"biome": "compost",
		"size": {"width": 48, "height": 48},
		"resources": ["organic_matter", "nitrogen_rich_soil", "decomposing_leaves"],
		"obstacles": ["compacted_areas", "heat_vents"],
		"special_features": ["nutrient_geysers", "thermal_zones"],
		"difficulty_modifier": 1.2
	},
	"cave_system": {
		"name": "Underground Cave Network",
		"biome": "cave",
		"size": {"width": 80, "height": 60},
		"resources": ["mineral_deposits", "cave_water", "bat_guano"],
		"obstacles": ["stalagmites", "underground_rivers", "cave_ins"],
		"special_features": ["crystal_formations", "echo_chambers"],
		"difficulty_modifier": 1.5
	},
	"garden_bed": {
		"name": "Cultivated Garden",
		"biome": "garden",
		"size": {"width": 56, "height": 56},
		"resources": ["fertilizer", "irrigation_water", "mulch"],
		"obstacles": ["garden_tools", "plant_roots", "irrigation_pipes"],
		"special_features": ["greenhouse_sections", "raised_beds"],
		"difficulty_modifier": 0.8
	}
}

# Faction generation system
var faction_archetypes = {
	"saprophytic": {
		"name": "Decomposer",
		"description": "Masters of breaking down organic matter",
		"color_scheme": ["brown", "orange", "yellow"],
		"bonuses": {
			"resource_gathering": 1.25,
			"building_cost": 0.9,
			"unit_speed": 0.95
		},
		"unique_units": ["decomposer_hyphae", "spore_recycler"],
		"unique_buildings": ["compost_processor", "decay_accelerator"],
		"special_ability": "organic_breakdown"
	},
	"mycorrhizal": {
		"name": "Symbiotic",
		"description": "Forms beneficial partnerships with other organisms",
		"color_scheme": ["green", "white", "gold"],
		"bonuses": {
			"alliance_benefits": 1.5,
			"healing_rate": 1.3,
			"diplomatic_relations": 1.2
		},
		"unique_units": ["symbiotic_connector", "nutrient_exchanger"],
		"unique_buildings": ["partnership_hub", "mutual_aid_station"],
		"special_ability": "symbiotic_network"
	},
	"parasitic": {
		"name": "Aggressive",
		"description": "Conquers and dominates other organisms",
		"color_scheme": ["red", "black", "purple"],
		"bonuses": {
			"attack_damage": 1.3,
			"unit_production": 1.15,
			"resource_theft": 1.4
		},
		"unique_units": ["parasitic_spore", "host_controller"],
		"unique_buildings": ["infection_lab", "dominance_tower"],
		"special_ability": "hostile_takeover"
	},
	"bioluminescent": {
		"name": "Luminous",
		"description": "Harnesses the power of natural light",
		"color_scheme": ["blue", "cyan", "white"],
		"bonuses": {
			"energy_efficiency": 1.2,
			"night_vision": 2.0,
			"detection_range": 1.4
		},
		"unique_units": ["light_bearer", "glow_scout"],
		"unique_buildings": ["bioluminous_beacon", "light_amplifier"],
		"special_ability": "illumination_burst"
	}
}

# Procedural content pools
var procedural_events = []
var procedural_quests = []
var procedural_challenges = []

# Dynamic difficulty adjustment
var difficulty_factors = {
	"player_skill": 1.0,
	"session_length": 1.0,
	"recent_performance": 1.0,
	"progression_rate": 1.0
}

func _ready():
	initialize_content_pools()
	generate_daily_content()

func initialize_content_pools():
	create_procedural_events()
	create_procedural_quests()
	create_procedural_challenges()

# === MAP GENERATION ===
func generate_random_map(difficulty_level: int = 1, biome_preference: String = "") -> Dictionary:
	var template_keys = map_templates.keys()
	var selected_template_key: String
	
	if biome_preference != "" and biome_preference in map_templates:
		selected_template_key = biome_preference
	else:
		selected_template_key = template_keys[randi() % template_keys.size()]
	
	var base_template = map_templates[selected_template_key]
	var generated_map = generate_map_from_template(base_template, difficulty_level)
	
	emit_signal("map_generated", generated_map)
	return generated_map

func generate_map_from_template(template: Dictionary, difficulty: int) -> Dictionary:
	var map_data = {
		"name": template.name,
		"biome": template.biome,
		"width": template.size.width,
		"height": template.size.height,
		"difficulty": difficulty,
		"tiles": [],
		"resource_nodes": [],
		"spawn_points": [],
		"special_features": [],
		"ai_paths": []
	}
	
	# Generate base terrain
	generate_base_terrain(map_data, template)
	
	# Place resources
	place_resources(map_data, template, difficulty)
	
	# Add obstacles
	place_obstacles(map_data, template, difficulty)
	
	# Create spawn points
	create_spawn_points(map_data)
	
	# Add special features
	add_special_features(map_data, template)
	
	# Generate AI pathfinding data
	generate_ai_paths(map_data)
	
	return map_data

func generate_base_terrain(map_data: Dictionary, template: Dictionary):
	map_data.tiles = []
	
	for y in range(map_data.height):
		var row = []
		for x in range(map_data.width):
			var tile_type = get_base_tile_type(template.biome, x, y, map_data.width, map_data.height)
			row.append({
				"type": tile_type,
				"x": x,
				"y": y,
				"walkable": is_tile_walkable(tile_type),
				"fertility": get_tile_fertility(tile_type, template.biome),
				"elevation": generate_elevation(x, y, map_data.width, map_data.height)
			})
		map_data.tiles.append(row)

func get_base_tile_type(biome: String, x: int, y: int, width: int, height: int) -> String:
	var noise_value = get_noise_value(x, y)
	
	match biome:
		"forest":
			if noise_value > 0.6:
				return "rich_soil"
			elif noise_value > 0.3:
				return "normal_soil"
			else:
				return "leaf_litter"
		"compost":
			if noise_value > 0.7:
				return "nutrient_rich"
			elif noise_value > 0.4:
				return "decomposing_matter"
			else:
				return "compost_base"
		"cave":
			if noise_value > 0.8:
				return "mineral_vein"
			elif noise_value > 0.5:
				return "cave_floor"
			else:
				return "rocky_ground"
		"garden":
			if noise_value > 0.6:
				return "fertile_soil"
			elif noise_value > 0.3:
				return "tilled_earth"
			else:
				return "mulched_area"
	
	return "normal_soil"

func place_resources(map_data: Dictionary, template: Dictionary, difficulty: int):
	var resource_count = int((map_data.width * map_data.height) * 0.15 / difficulty)  # Fewer resources = harder
	var available_resources = template.resources
	
	for i in range(resource_count):
		var x = randi() % map_data.width
		var y = randi() % map_data.height
		
		if map_data.tiles[y][x].walkable:
			var resource_type = available_resources[randi() % available_resources.size()]
			var resource_amount = randi_range(50, 200) * (2.0 - difficulty * 0.1)  # Scale with difficulty
			
			map_data.resource_nodes.append({
				"type": resource_type,
				"x": x,
				"y": y,
				"amount": int(resource_amount),
				"max_amount": int(resource_amount),
				"regen_rate": 1.0
			})

func place_obstacles(map_data: Dictionary, template: Dictionary, difficulty: int):
	var obstacle_count = int((map_data.width * map_data.height) * 0.08 * difficulty)  # More obstacles = harder
	var available_obstacles = template.obstacles
	
	for i in range(obstacle_count):
		var x = randi() % map_data.width
		var y = randi() % map_data.height
		
		if map_data.tiles[y][x].walkable:
			var obstacle_type = available_obstacles[randi() % available_obstacles.size()]
			
			map_data.tiles[y][x].walkable = false
			map_data.tiles[y][x].obstacle = obstacle_type

func create_spawn_points(map_data: Dictionary):
	var spawn_attempts = 100
	var min_distance = 15
	
	# Player spawn (center-ish)
	var player_spawn = find_valid_spawn_near(map_data, map_data.width / 2, map_data.height / 2)
	if player_spawn:
		map_data.spawn_points.append({
			"type": "player",
			"x": player_spawn.x,
			"y": player_spawn.y,
			"faction": "player"
		})
	
	# AI spawns (corners and edges)
	var ai_spawn_candidates = [
		{"x": 5, "y": 5},
		{"x": map_data.width - 5, "y": 5},
		{"x": 5, "y": map_data.height - 5},
		{"x": map_data.width - 5, "y": map_data.height - 5}
	]
	
	for candidate in ai_spawn_candidates:
		var spawn = find_valid_spawn_near(map_data, candidate.x, candidate.y)
		if spawn:
			map_data.spawn_points.append({
				"type": "ai",
				"x": spawn.x,
				"y": spawn.y,
				"faction": "ai_" + str(map_data.spawn_points.size())
			})

func find_valid_spawn_near(map_data: Dictionary, center_x: int, center_y: int) -> Dictionary:
	var max_search_radius = 10
	
	for radius in range(1, max_search_radius):
		for angle in range(0, 360, 45):
			var x = center_x + int(cos(deg_to_rad(angle)) * radius)
			var y = center_y + int(sin(deg_to_rad(angle)) * radius)
			
			if x >= 0 and x < map_data.width and y >= 0 and y < map_data.height:
				if map_data.tiles[y][x].walkable:
					return {"x": x, "y": y}
	
	return {}

func add_special_features(map_data: Dictionary, template: Dictionary):
	var feature_count = randi_range(2, 5)
	
	for i in range(feature_count):
		var feature_type = template.special_features[randi() % template.special_features.size()]
		var feature_pos = find_random_walkable_position(map_data)
		
		if feature_pos:
			map_data.special_features.append({
				"type": feature_type,
				"x": feature_pos.x,
				"y": feature_pos.y,
				"effect": get_feature_effect(feature_type)
			})

func get_feature_effect(feature_type: String) -> Dictionary:
	match feature_type:
		"mushroom_circles":
			return {"type": "resource_bonus", "multiplier": 1.5, "radius": 3}
		"fairy_rings":
			return {"type": "xp_bonus", "multiplier": 2.0, "radius": 2}
		"nutrient_geysers":
			return {"type": "periodic_resources", "amount": 100, "interval": 30}
		"thermal_zones":
			return {"type": "unit_speed_bonus", "multiplier": 1.3, "radius": 4}
		"crystal_formations":
			return {"type": "energy_regeneration", "rate": 2.0, "radius": 2}
		"echo_chambers":
			return {"type": "detection_bonus", "range": 8}
	
	return {}

# === FACTION GENERATION ===
func generate_random_faction(base_archetype: String = "") -> Dictionary:
	var archetype_keys = faction_archetypes.keys()
	var selected_archetype: String
	
	if base_archetype != "" and base_archetype in faction_archetypes:
		selected_archetype = base_archetype
	else:
		selected_archetype = archetype_keys[randi() % archetype_keys.size()]
	
	var base_faction = faction_archetypes[selected_archetype]
	var generated_faction = create_faction_variant(base_faction, selected_archetype)
	
	emit_signal("faction_created", generated_faction)
	return generated_faction

func create_faction_variant(base_faction: Dictionary, archetype: String) -> Dictionary:
	var variant_suffixes = ["Clan", "Tribe", "Colony", "Network", "Collective", "Dynasty"]
	var variant_prefixes = ["Ancient", "Noble", "Wild", "Evolved", "Prime", "Elite"]
	
	var faction_name = variant_prefixes[randi() % variant_prefixes.size()] + " " + base_faction.name + " " + variant_suffixes[randi() % variant_suffixes.size()]
	
	var faction_data = {
		"name": faction_name,
		"archetype": archetype,
		"description": base_faction.description,
		"color_primary": get_random_color_from_scheme(base_faction.color_scheme),
		"color_secondary": get_random_color_from_scheme(base_faction.color_scheme),
		"bonuses": create_faction_bonus_variations(base_faction.bonuses),
		"unique_units": base_faction.unique_units.duplicate(),
		"unique_buildings": base_faction.unique_buildings.duplicate(),
		"special_ability": base_faction.special_ability,
		"ai_personality": generate_ai_personality(archetype),
		"lore": generate_faction_lore(faction_name, archetype)
	}
	
	return faction_data

func create_faction_bonus_variations(base_bonuses: Dictionary) -> Dictionary:
	var varied_bonuses = base_bonuses.duplicate()
	
	# Add slight random variations to make each faction unique
	for bonus_key in varied_bonuses.keys():
		var base_value = varied_bonuses[bonus_key]
		var variation = randf_range(-0.05, 0.05)  # ±5% variation
		varied_bonuses[bonus_key] = base_value + variation
	
	return varied_bonuses

func generate_ai_personality(archetype: String) -> Dictionary:
	var base_personalities = {
		"saprophytic": {"aggression": 0.3, "expansion": 0.7, "economic": 0.8, "defensive": 0.6},
		"mycorrhizal": {"aggression": 0.2, "expansion": 0.5, "economic": 0.6, "defensive": 0.8},
		"parasitic": {"aggression": 0.9, "expansion": 0.8, "economic": 0.4, "defensive": 0.3},
		"bioluminescent": {"aggression": 0.5, "expansion": 0.6, "economic": 0.7, "defensive": 0.5}
	}
	
	var base = base_personalities.get(archetype, {"aggression": 0.5, "expansion": 0.5, "economic": 0.5, "defensive": 0.5})
	
	# Add personality variations
	for trait in base.keys():
		base[trait] += randf_range(-0.2, 0.2)
		base[trait] = clamp(base[trait], 0.1, 1.0)
	
	return base

func generate_faction_lore(faction_name: String, archetype: String) -> String:
	var lore_templates = {
		"saprophytic": "The {name} have mastered the ancient art of decomposition, turning decay into prosperity.",
		"mycorrhizal": "The {name} believe in the power of cooperation, forming beneficial alliances wherever they grow.",
		"parasitic": "The {name} are feared across the forest floor for their aggressive expansion tactics.",
		"bioluminescent": "The {name} illuminate the darkness, using their natural light to guide and protect their territory."
	}
	
	var template = lore_templates.get(archetype, "The {name} are a mysterious faction with unknown origins.")
	return template.format({"name": faction_name})

# === PROCEDURAL CONTENT ===
func create_procedural_events():
	procedural_events = [
		{
			"id": "resource_bloom",
			"name": "Resource Bloom",
			"description": "A sudden abundance of resources appears on the map",
			"type": "positive",
			"duration": 300,  # 5 minutes
			"effects": {"resource_spawn_rate": 2.0}
		},
		{
			"id": "toxic_spill",
			"name": "Toxic Contamination",
			"description": "Toxic substances reduce resource quality temporarily",
			"type": "negative",
			"duration": 180,  # 3 minutes
			"effects": {"resource_value": 0.5}
		},
		{
			"id": "migration_wave",
			"name": "Creature Migration",
			"description": "Neutral creatures migrate across the map, affecting movement",
			"type": "neutral",
			"duration": 240,  # 4 minutes
			"effects": {"unit_speed": 0.8}
		}
	]

func create_procedural_quests():
	procedural_quests = [
		{
			"template": "collect_resources",
			"name": "Resource Gathering",
			"description": "Collect {amount} {resource_type}",
			"reward_base": 500,
			"xp_reward": 100
		},
		{
			"template": "build_structures",
			"name": "Expansion Project", 
			"description": "Build {amount} {building_type}",
			"reward_base": 750,
			"xp_reward": 150
		},
		{
			"template": "defeat_enemies",
			"name": "Territory Defense",
			"description": "Defeat {amount} enemy units",
			"reward_base": 1000,
			"xp_reward": 200
		}
	]

func generate_daily_content():
	# Generate daily quests
	generate_daily_quests()
	
	# Generate random events
	schedule_random_events()
	
	# Create daily challenges
	create_daily_challenges()

func generate_daily_quests():
	var daily_quest_count = 3
	GameManager.daily_quests.clear()
	
	for i in range(daily_quest_count):
		var quest_template = procedural_quests[randi() % procedural_quests.size()]
		var generated_quest = create_quest_from_template(quest_template)
		GameManager.daily_quests.append(generated_quest)

func create_quest_from_template(template: Dictionary) -> Dictionary:
	var quest = template.duplicate()
	
	match template.template:
		"collect_resources":
			quest.target = randi_range(100, 500)
			quest.resource_type = ["water", "nutrients", "spores"][randi() % 3]
			quest.description = quest.description.format({
				"amount": quest.target,
				"resource_type": quest.resource_type
			})
		"build_structures":
			quest.target = randi_range(3, 10)
			quest.building_type = ["basic_structure", "resource_collector", "defensive_tower"][randi() % 3]
			quest.description = quest.description.format({
				"amount": quest.target,
				"building_type": quest.building_type
			})
		"defeat_enemies":
			quest.target = randi_range(10, 50)
			quest.description = quest.description.format({
				"amount": quest.target
			})
	
	quest.progress = 0
	quest.completed = false
	quest.id = "daily_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	
	return quest

func schedule_random_events():
	# Schedule 2-4 random events throughout the day
	var event_count = randi_range(2, 4)
	
	for i in range(event_count):
		var event = procedural_events[randi() % procedural_events.size()].duplicate()
		var delay_time = randi_range(1800, 7200)  # 30 minutes to 2 hours
		
		var timer = Timer.new()
		timer.wait_time = delay_time
		timer.one_shot = true
		timer.timeout.connect(func(): trigger_random_event(event))
		add_child(timer)
		timer.start()

func trigger_random_event(event: Dictionary):
	# Apply event effects
	print("Random event triggered: ", event.name)
	
	# Notify players
	UIManager.show_notification(
		"World Event!",
		event.name + ": " + event.description,
		"event",
		5.0
	)
	
	# Apply effects for duration
	var effect_timer = Timer.new()
	effect_timer.wait_time = event.duration
	effect_timer.one_shot = true
	effect_timer.timeout.connect(func(): end_random_event(event))
	add_child(effect_timer)
	effect_timer.start()

func end_random_event(event: Dictionary):
	print("Random event ended: ", event.name)

# === DIFFICULTY ADJUSTMENT ===
func adjust_difficulty_based_on_performance(win_rate: float, average_game_time: float):
	# Adjust difficulty factors based on player performance
	if win_rate > 0.7:  # Player winning too much
		difficulty_factors.player_skill = min(difficulty_factors.player_skill + 0.1, 2.0)
	elif win_rate < 0.3:  # Player losing too much
		difficulty_factors.player_skill = max(difficulty_factors.player_skill - 0.1, 0.5)
	
	# Adjust based on game session length
	if average_game_time < 300:  # Games too short (5 minutes)
		difficulty_factors.session_length = min(difficulty_factors.session_length + 0.05, 1.5)
	elif average_game_time > 1800:  # Games too long (30 minutes)
		difficulty_factors.session_length = max(difficulty_factors.session_length - 0.05, 0.7)

func get_adjusted_difficulty() -> float:
	var base_difficulty = 1.0
	
	for factor in difficulty_factors.values():
		base_difficulty *= factor
	
	return clamp(base_difficulty, 0.5, 2.0)

# === UTILITY FUNCTIONS ===
func get_noise_value(x: int, y: int) -> float:
	# Simple noise function for terrain generation
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.1
	return noise.get_noise_2d(x, y)

func is_tile_walkable(tile_type: String) -> bool:
	var unwalkable_types = ["water", "lava", "deep_pit", "solid_rock"]
	return not tile_type in unwalkable_types

func get_tile_fertility(tile_type: String, biome: String) -> float:
	var fertility_map = {
		"rich_soil": 1.0,
		"fertile_soil": 0.9,
		"normal_soil": 0.7,
		"poor_soil": 0.4,
		"rocky_ground": 0.2
	}
	
	return fertility_map.get(tile_type, 0.5)

func generate_elevation(x: int, y: int, width: int, height: int) -> float:
	# Generate realistic elevation using multiple noise octaves
	var noise = FastNoiseLite.new()
	noise.seed = 54321
	noise.frequency = 0.05
	
	var elevation = noise.get_noise_2d(x, y)
	elevation += noise.get_noise_2d(x * 2, y * 2) * 0.5
	elevation += noise.get_noise_2d(x * 4, y * 4) * 0.25
	
	return (elevation + 1.0) / 2.0  # Normalize to 0-1

func get_random_color_from_scheme(color_scheme: Array) -> Color:
	var color_map = {
		"brown": Color(0.6, 0.4, 0.2),
		"orange": Color(1.0, 0.5, 0.0),
		"yellow": Color(1.0, 1.0, 0.0),
		"green": Color(0.0, 0.8, 0.0),
		"white": Color(1.0, 1.0, 1.0),
		"gold": Color(1.0, 0.8, 0.0),
		"red": Color(0.8, 0.0, 0.0),
		"black": Color(0.1, 0.1, 0.1),
		"purple": Color(0.5, 0.0, 0.5),
		"blue": Color(0.0, 0.0, 1.0),
		"cyan": Color(0.0, 1.0, 1.0)
	}
	
	var color_name = color_scheme[randi() % color_scheme.size()]
	return color_map.get(color_name, Color.WHITE)

func find_random_walkable_position(map_data: Dictionary) -> Dictionary:
	var attempts = 100
	
	for i in range(attempts):
		var x = randi() % map_data.width
		var y = randi() % map_data.height
		
		if map_data.tiles[y][x].walkable:
			return {"x": x, "y": y}
	
	return {}

func create_daily_challenges():
	# Create special daily challenges with unique rewards
	var challenges = [
		{
			"name": "Speed Builder",
			"description": "Build 20 structures in under 10 minutes",
			"type": "timed",
			"target": 20,
			"time_limit": 600,
			"reward": {"premium": 5, "soft": 1000}
		},
		{
			"name": "Resource Master",
			"description": "Collect 5000 total resources in a single match",
			"type": "accumulation",
			"target": 5000,
			"reward": {"soft": 2000, "xp": 500}
		}
	]
	
	# Add to daily quest system
	for challenge in challenges:
		challenge.id = "challenge_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
		challenge.progress = 0
		challenge.completed = false
		GameManager.daily_quests.append(challenge)