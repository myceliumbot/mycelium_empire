extends Node

# Live Service Manager - handles live events, seasonal content, and dynamic updates
signal event_started(event_data: Dictionary)
signal event_ended(event_data: Dictionary)
signal seasonal_content_updated()
signal live_update_received(update_data: Dictionary)

# Live events system
var active_events: Array[Dictionary] = []
var event_history: Array[Dictionary] = []
var event_templates: Dictionary = {}

# Seasonal content
var current_season_data: Dictionary = {}
var seasonal_rewards: Array[Dictionary] = []
var seasonal_challenges: Array[Dictionary] = []

# Dynamic content updates
var content_updates_queue: Array[Dictionary] = []
var server_config: Dictionary = {}

# Featured content rotation
var featured_content: Dictionary = {}
var daily_featured: Dictionary = {}

# Live tournaments and competitions
var live_tournaments: Array[Dictionary] = []
var global_competitions: Array[Dictionary] = []

# Community goals and events
var community_goals: Array[Dictionary] = []
var global_progress: Dictionary = {}

func _ready():
	initialize_live_service()
	setup_update_timers()
	load_live_service_data()

func initialize_live_service():
	setup_event_templates()
	setup_seasonal_system()
	initialize_server_communication()

func setup_update_timers():
	# Check for updates every 5 minutes
	var update_timer = Timer.new()
	update_timer.wait_time = 300.0
	update_timer.timeout.connect(_on_check_for_updates)
	add_child(update_timer)
	update_timer.start()
	
	# Rotate featured content daily
	var featured_timer = Timer.new()
	featured_timer.wait_time = 86400.0  # 24 hours
	featured_timer.timeout.connect(_on_rotate_featured_content)
	add_child(featured_timer)
	featured_timer.start()
	
	# Check event status every minute
	var event_timer = Timer.new()
	event_timer.wait_time = 60.0
	event_timer.timeout.connect(_on_check_events)
	add_child(event_timer)
	event_timer.start()

# === EVENT SYSTEM ===
func setup_event_templates():
	event_templates = {
		"double_xp_weekend": {
			"name": "Double XP Weekend",
			"description": "Earn 2x XP from all activities!",
			"type": "multiplier",
			"duration": 72 * 60 * 60,  # 72 hours
			"effects": {"xp_multiplier": 2.0},
			"rewards": {"participation": {"soft": 1000, "premium": 5}},
			"frequency": "weekly"
		},
		"resource_rush": {
			"name": "Resource Rush",
			"description": "Resources spawn 3x faster for limited time!",
			"type": "multiplier",
			"duration": 24 * 60 * 60,  # 24 hours
			"effects": {"resource_spawn_rate": 3.0},
			"rewards": {"participation": {"soft": 500}},
			"frequency": "bi-weekly"
		},
		"faction_war": {
			"name": "Great Faction War",
			"description": "Choose your faction and fight for dominance!",
			"type": "competitive",
			"duration": 7 * 24 * 60 * 60,  # 7 days
			"effects": {"pvp_rewards_multiplier": 1.5},
			"rewards": {
				"faction_victory": {"premium": 50, "cosmetic": "war_champion_badge"},
				"participation": {"soft": 2000}
			},
			"frequency": "monthly"
		},
		"building_frenzy": {
			"name": "Building Frenzy",
			"description": "All construction costs reduced by 50%!",
			"type": "discount",
			"duration": 48 * 60 * 60,  # 48 hours
			"effects": {"building_cost_multiplier": 0.5},
			"rewards": {"milestone": {"soft": 1500}},
			"frequency": "bi-weekly"
		},
		"spore_storm": {
			"name": "Legendary Spore Storm",
			"description": "Rare spores rain from the sky!",
			"type": "special",
			"duration": 6 * 60 * 60,  # 6 hours
			"effects": {"legendary_spawn_rate": 10.0},
			"rewards": {"rare_collection": {"premium": 25}},
			"frequency": "monthly"
		}
	}

func start_event(event_template_key: String, custom_duration: int = 0) -> bool:
	if not event_template_key in event_templates:
		return false
	
	var template = event_templates[event_template_key]
	var event_data = create_event_from_template(template, custom_duration)
	
	active_events.append(event_data)
	
	# Apply event effects
	apply_event_effects(event_data)
	
	# Notify players
	notify_event_start(event_data)
	
	emit_signal("event_started", event_data)
	
	AnalyticsManager.track_event("live_event_started", {
		"event_name": event_data.name,
		"event_type": event_data.type,
		"duration": event_data.duration
	})
	
	return true

func create_event_from_template(template: Dictionary, custom_duration: int = 0) -> Dictionary:
	var event_data = template.duplicate(true)
	event_data.id = generate_event_id()
	event_data.start_time = Time.get_unix_time_from_system()
	
	if custom_duration > 0:
		event_data.duration = custom_duration
	
	event_data.end_time = event_data.start_time + event_data.duration
	event_data.participants = []
	event_data.progress = {}
	event_data.status = "active"
	
	return event_data

func end_event(event_id: String):
	var event_data = find_event_by_id(event_id)
	if not event_data:
		return
	
	event_data.status = "ended"
	event_data.actual_end_time = Time.get_unix_time_from_system()
	
	# Remove event effects
	remove_event_effects(event_data)
	
	# Distribute rewards
	distribute_event_rewards(event_data)
	
	# Move to history
	event_history.append(event_data)
	
	# Remove from active events
	for i in range(active_events.size()):
		if active_events[i].id == event_id:
			active_events.remove_at(i)
			break
	
	# Notify players
	notify_event_end(event_data)
	
	emit_signal("event_ended", event_data)
	
	AnalyticsManager.track_event("live_event_ended", {
		"event_name": event_data.name,
		"participants": event_data.participants.size(),
		"duration_actual": event_data.actual_end_time - event_data.start_time
	})

func apply_event_effects(event_data: Dictionary):
	# Apply temporary game modifications
	for effect_key in event_data.effects.keys():
		var effect_value = event_data.effects[effect_key]
		apply_global_effect(effect_key, effect_value)

func remove_event_effects(event_data: Dictionary):
	# Remove temporary game modifications
	for effect_key in event_data.effects.keys():
		remove_global_effect(effect_key)

func apply_global_effect(effect_type: String, value: float):
	match effect_type:
		"xp_multiplier":
			GameManager.xp_multiplier = value
		"resource_spawn_rate":
			# Apply to content generator
			pass
		"building_cost_multiplier":
			# Apply to building system
			pass
		"pvp_rewards_multiplier":
			# Apply to PvP rewards
			pass

func remove_global_effect(effect_type: String):
	match effect_type:
		"xp_multiplier":
			GameManager.xp_multiplier = 1.0
		"resource_spawn_rate":
			# Reset to normal
			pass
		"building_cost_multiplier":
			# Reset to normal
			pass

# === SEASONAL SYSTEM ===
func setup_seasonal_system():
	current_season_data = {
		"season_number": 1,
		"theme": "Ancient Awakening",
		"start_time": Time.get_unix_time_from_system(),
		"duration": 90 * 24 * 60 * 60,  # 90 days
		"special_currency": "ancient_spores",
		"exclusive_rewards": [],
		"seasonal_events": []
	}
	
	generate_seasonal_content()

func generate_seasonal_content():
	create_seasonal_rewards()
	create_seasonal_challenges()
	plan_seasonal_events()

func create_seasonal_rewards():
	seasonal_rewards = [
		{
			"tier": 1,
			"requirement": {"type": "xp", "amount": 1000},
			"rewards": {"soft": 2000, "seasonal_currency": 50}
		},
		{
			"tier": 2,
			"requirement": {"type": "xp", "amount": 5000},
			"rewards": {"premium": 10, "cosmetic": "seasonal_badge_bronze"}
		},
		{
			"tier": 3,
			"requirement": {"type": "games_won", "amount": 25},
			"rewards": {"premium": 25, "cosmetic": "seasonal_skin_1"}
		},
		{
			"tier": 4,
			"requirement": {"type": "xp", "amount": 15000},
			"rewards": {"premium": 50, "cosmetic": "seasonal_badge_silver"}
		},
		{
			"tier": 5,
			"requirement": {"type": "community_goals", "amount": 3},
			"rewards": {"premium": 100, "cosmetic": "seasonal_champion_crown"}
		}
	]

func create_seasonal_challenges():
	seasonal_challenges = [
		{
			"name": "Ancient Builder",
			"description": "Build 100 structures during the season",
			"requirement": {"type": "buildings_built", "amount": 100},
			"reward": {"seasonal_currency": 200, "cosmetic": "ancient_builder_title"},
			"progress": 0
		},
		{
			"name": "Spore Collector Supreme",
			"description": "Collect 50,000 spores during the season",
			"requirement": {"type": "spores_collected", "amount": 50000},
			"reward": {"premium": 75, "cosmetic": "spore_collector_aura"},
			"progress": 0
		},
		{
			"name": "Social Mycelium",
			"description": "Add 20 friends during the season",
			"requirement": {"type": "friends_added", "amount": 20},
			"reward": {"seasonal_currency": 150, "cosmetic": "social_connector_badge"},
			"progress": 0
		}
	]

func plan_seasonal_events():
	# Plan major events throughout the season
	var season_duration = current_season_data.duration
	var events_to_schedule = [
		{"template": "faction_war", "day": 14},
		{"template": "double_xp_weekend", "day": 30},
		{"template": "spore_storm", "day": 45},
		{"template": "building_frenzy", "day": 60},
		{"template": "faction_war", "day": 75}
	]
	
	for event_plan in events_to_schedule:
		var event_time = current_season_data.start_time + (event_plan.day * 24 * 60 * 60)
		schedule_event(event_plan.template, event_time)

func schedule_event(template_key: String, start_time: int):
	var timer = Timer.new()
	timer.wait_time = start_time - Time.get_unix_time_from_system()
	timer.one_shot = true
	timer.timeout.connect(func(): start_event(template_key))
	add_child(timer)
	
	if timer.wait_time > 0:
		timer.start()

# === COMMUNITY GOALS ===
func create_community_goal(goal_data: Dictionary) -> String:
	var goal = {
		"id": generate_goal_id(),
		"name": goal_data.name,
		"description": goal_data.description,
		"target": goal_data.target,
		"current_progress": 0,
		"start_time": Time.get_unix_time_from_system(),
		"duration": goal_data.get("duration", 7 * 24 * 60 * 60),  # Default 7 days
		"rewards": goal_data.rewards,
		"contributors": [],
		"status": "active"
	}
	
	community_goals.append(goal)
	
	# Notify players
	UIManager.show_notification(
		"New Community Goal!",
		goal.name + ": " + goal.description,
		"community_goal",
		5.0
	)
	
	return goal.id

func contribute_to_community_goal(goal_id: String, contribution: int, player_id: String = ""):
	var goal = find_community_goal(goal_id)
	if not goal or goal.status != "active":
		return false
	
	goal.current_progress += contribution
	
	# Track contributor
	if player_id != "":
		var contributor_found = false
		for contributor in goal.contributors:
			if contributor.player_id == player_id:
				contributor.contribution += contribution
				contributor_found = true
				break
		
		if not contributor_found:
			goal.contributors.append({
				"player_id": player_id,
				"contribution": contribution
			})
	
	# Check if goal is completed
	if goal.current_progress >= goal.target:
		complete_community_goal(goal)
	
	return true

func complete_community_goal(goal: Dictionary):
	goal.status = "completed"
	goal.completion_time = Time.get_unix_time_from_system()
	
	# Distribute rewards to all players
	distribute_community_rewards(goal)
	
	# Create celebration event
	create_goal_completion_celebration(goal)
	
	AnalyticsManager.track_event("community_goal_completed", {
		"goal_name": goal.name,
		"contributors": goal.contributors.size(),
		"completion_time": goal.completion_time - goal.start_time
	})

func distribute_community_rewards(goal: Dictionary):
	# Give rewards to all contributors
	for contributor in goal.contributors:
		var contribution_percentage = float(contributor.contribution) / float(goal.current_progress)
		var bonus_multiplier = 1.0 + (contribution_percentage * 0.5)  # Up to 50% bonus for top contributors
		
		# Base rewards for everyone
		if "soft" in goal.rewards:
			GameManager.add_currency("soft", int(goal.rewards.soft * bonus_multiplier))
		if "premium" in goal.rewards:
			GameManager.add_currency("premium", int(goal.rewards.premium * bonus_multiplier))
		if "cosmetic" in goal.rewards:
			MonetizationManager.owned_cosmetics.append(goal.rewards.cosmetic)

func create_goal_completion_celebration(goal: Dictionary):
	# Create special celebration event
	var celebration_event = {
		"name": "Community Victory Celebration",
		"description": "Celebrating the completion of: " + goal.name,
		"type": "celebration",
		"duration": 24 * 60 * 60,  # 24 hours
		"effects": {"xp_multiplier": 1.5, "resource_spawn_rate": 1.5},
		"rewards": {"participation": {"soft": 1000}}
	}
	
	start_custom_event(celebration_event)

# === FEATURED CONTENT ===
func setup_daily_featured_content():
	daily_featured = {
		"featured_cosmetic": select_random_cosmetic(),
		"featured_building": select_random_building(),
		"featured_challenge": create_daily_challenge(),
		"discount_item": select_discount_item()
	}
	
	emit_signal("seasonal_content_updated")

func select_random_cosmetic() -> Dictionary:
	var cosmetics = MonetizationManager.cosmetic_store.values()
	return cosmetics[randi() % cosmetics.size()] if cosmetics.size() > 0 else {}

func select_random_building() -> Dictionary:
	# Select a random building to feature
	return {"name": "Featured Spore Tower", "bonus": "25% faster production"}

func create_daily_challenge() -> Dictionary:
	var challenges = [
		{"name": "Speed Builder", "target": 10, "type": "buildings", "reward": {"soft": 500}},
		{"name": "Resource Hunter", "target": 1000, "type": "resources", "reward": {"soft": 750}},
		{"name": "Victory Streak", "target": 3, "type": "wins", "reward": {"premium": 2}}
	]
	
	return challenges[randi() % challenges.size()]

func select_discount_item() -> Dictionary:
	var items = MonetizationManager.store_products.values()
	var selected_item = items[randi() % items.size()] if items.size() > 0 else {}
	
	if selected_item:
		selected_item = selected_item.duplicate()
		selected_item.discount_percentage = randi_range(20, 50)
		selected_item.original_price = selected_item.price
		selected_item.price *= (1.0 - selected_item.discount_percentage / 100.0)
	
	return selected_item

# === LIVE TOURNAMENTS ===
func create_live_tournament(tournament_data: Dictionary) -> String:
	var tournament = {
		"id": generate_tournament_id(),
		"name": tournament_data.name,
		"description": tournament_data.description,
		"type": tournament_data.type,  # "elimination", "score_based", "time_attack"
		"entry_fee": tournament_data.get("entry_fee", 0),
		"entry_currency": tournament_data.get("entry_currency", "soft"),
		"max_participants": tournament_data.get("max_participants", 100),
		"start_time": tournament_data.start_time,
		"duration": tournament_data.duration,
		"rewards": tournament_data.rewards,
		"participants": [],
		"status": "registration",
		"live_updates": true
	}
	
	live_tournaments.append(tournament)
	
	# Notify players
	UIManager.show_notification(
		"New Tournament!",
		tournament.name + " - Registration open!",
		"tournament",
		6.0
	)
	
	return tournament.id

# === SERVER COMMUNICATION ===
func initialize_server_communication():
	# In production, this would establish connection to live service backend
	server_config = {
		"update_frequency": 300,  # 5 minutes
		"event_sync": true,
		"community_sync": true,
		"tournament_sync": true
	}

func _on_check_for_updates():
	# Simulate checking for live updates
	check_for_content_updates()
	sync_community_progress()
	update_live_tournaments()

func check_for_content_updates():
	# Simulate receiving content updates from server
	if randf() < 0.1:  # 10% chance of update
		var update_data = {
			"type": "balance_update",
			"changes": {"xp_rates": 1.1, "building_costs": 0.95},
			"version": "1.0.1"
		}
		
		process_content_update(update_data)

func process_content_update(update_data: Dictionary):
	content_updates_queue.append(update_data)
	
	emit_signal("live_update_received", update_data)
	
	# Apply update immediately or queue for next restart
	match update_data.type:
		"balance_update":
			apply_balance_changes(update_data.changes)
		"new_content":
			queue_new_content(update_data)
		"event_update":
			update_event_data(update_data)

func apply_balance_changes(changes: Dictionary):
	# Apply live balance changes
	for change_key in changes.keys():
		var change_value = changes[change_key]
		print("Applying balance change: ", change_key, " = ", change_value)

# === EVENT SCHEDULING ===
func schedule_weekend_events():
	# Automatically schedule weekend events
	var now = Time.get_unix_time_from_system()
	var current_weekday = Time.get_datetime_dict_from_unix_time(now).weekday
	
	# If it's Friday, schedule weekend event
	if current_weekday == 5:  # Friday
		var weekend_start = now + (24 - Time.get_datetime_dict_from_unix_time(now).hour) * 3600  # Next midnight
		schedule_event("double_xp_weekend", weekend_start)

func schedule_monthly_events():
	# Schedule major monthly events
	var now = Time.get_unix_time_from_system()
	var current_date = Time.get_datetime_dict_from_unix_time(now)
	
	# First Friday of month = Faction War
	if current_date.day <= 7 and current_date.weekday == 5:
		schedule_event("faction_war", now + 3600)  # Start in 1 hour

# === UTILITY FUNCTIONS ===
func find_event_by_id(event_id: String) -> Dictionary:
	for event in active_events:
		if event.id == event_id:
			return event
	return {}

func find_community_goal(goal_id: String) -> Dictionary:
	for goal in community_goals:
		if goal.id == goal_id:
			return goal
	return {}

func generate_event_id() -> String:
	return "event_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func generate_goal_id() -> String:
	return "goal_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func generate_tournament_id() -> String:
	return "tournament_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func notify_event_start(event_data: Dictionary):
	UIManager.show_notification(
		"Event Started!",
		event_data.name + ": " + event_data.description,
		"event_start",
		6.0
	)

func notify_event_end(event_data: Dictionary):
	UIManager.show_notification(
		"Event Ended",
		event_data.name + " has concluded. Check your rewards!",
		"event_end",
		4.0
	)

func start_custom_event(event_data: Dictionary):
	var custom_event = create_event_from_template(event_data)
	active_events.append(custom_event)
	apply_event_effects(custom_event)
	notify_event_start(custom_event)

func _on_check_events():
	var current_time = Time.get_unix_time_from_system()
	
	# Check for events that should end
	for event in active_events.duplicate():
		if current_time >= event.end_time:
			end_event(event.id)

func _on_rotate_featured_content():
	setup_daily_featured_content()

func sync_community_progress():
	# Simulate syncing community progress with server
	for goal in community_goals:
		if goal.status == "active":
			# Add some simulated global progress
			goal.current_progress += randi_range(10, 100)

func update_live_tournaments():
	# Update tournament states and progress
	var current_time = Time.get_unix_time_from_system()
	
	for tournament in live_tournaments:
		if tournament.status == "registration" and current_time >= tournament.start_time:
			tournament.status = "active"
		elif tournament.status == "active" and current_time >= tournament.start_time + tournament.duration:
			tournament.status = "completed"

func distribute_event_rewards(event_data: Dictionary):
	# Distribute participation and performance rewards
	if "participation" in event_data.rewards:
		var participation_rewards = event_data.rewards.participation
		
		if "soft" in participation_rewards:
			GameManager.add_currency("soft", participation_rewards.soft)
		if "premium" in participation_rewards:
			GameManager.add_currency("premium", participation_rewards.premium)

# === SAVE/LOAD ===
func save_live_service_data():
	var save_data = {
		"active_events": active_events,
		"event_history": event_history,
		"current_season_data": current_season_data,
		"seasonal_rewards": seasonal_rewards,
		"seasonal_challenges": seasonal_challenges,
		"community_goals": community_goals,
		"featured_content": featured_content,
		"daily_featured": daily_featured
	}
	
	var save_file = FileAccess.open("user://live_service.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_live_service_data():
	var save_file = FileAccess.open("user://live_service.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			active_events = save_data.get("active_events", [])
			event_history = save_data.get("event_history", [])
			current_season_data = save_data.get("current_season_data", current_season_data)
			seasonal_rewards = save_data.get("seasonal_rewards", [])
			seasonal_challenges = save_data.get("seasonal_challenges", [])
			community_goals = save_data.get("community_goals", [])
			featured_content = save_data.get("featured_content", {})
			daily_featured = save_data.get("daily_featured", {})