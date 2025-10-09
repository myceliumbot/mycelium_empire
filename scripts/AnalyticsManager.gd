extends Node

# Analytics Manager - comprehensive data tracking and analysis for optimization
signal analytics_data_collected(event_type: String, data: Dictionary)

# Session tracking
var session_id: String
var session_start_time: float
var current_session_data: Dictionary = {}

# Player behavior tracking
var player_actions: Array[Dictionary] = []
var gameplay_metrics: Dictionary = {}
var monetization_metrics: Dictionary = {}
var retention_metrics: Dictionary = {}

# A/B Testing framework
var ab_test_groups: Dictionary = {}
var active_experiments: Array[Dictionary] = []

# Heatmap data
var click_heatmap: Dictionary = {}
var movement_heatmap: Dictionary = {}

# Performance metrics
var performance_data: Dictionary = {}
var crash_reports: Array[Dictionary] = []

# User journey tracking
var funnel_data: Dictionary = {}
var conversion_tracking: Dictionary = {}

func _ready():
	initialize_analytics()
	start_session()
	setup_performance_monitoring()

func initialize_analytics():
	session_id = generate_session_id()
	
	# Initialize tracking dictionaries
	gameplay_metrics = {
		"games_started": 0,
		"games_completed": 0,
		"games_abandoned": 0,
		"total_playtime": 0.0,
		"average_session_length": 0.0,
		"levels_completed": 0,
		"deaths": 0,
		"buildings_built": 0,
		"resources_collected": 0,
		"battles_won": 0,
		"battles_lost": 0
	}
	
	monetization_metrics = {
		"total_spent": 0.0,
		"purchases_made": 0,
		"ads_watched": 0,
		"premium_currency_earned": 0,
		"premium_currency_spent": 0,
		"first_purchase_time": 0,
		"ltv": 0.0,  # Lifetime value
		"conversion_rate": 0.0
	}
	
	retention_metrics = {
		"day_1_retention": false,
		"day_7_retention": false,
		"day_30_retention": false,
		"total_sessions": 0,
		"days_played": 0,
		"longest_streak": 0,
		"current_streak": 0
	}
	
	# Load existing analytics data
	load_analytics_data()

func start_session():
	session_start_time = Time.get_unix_time_from_system()
	retention_metrics.total_sessions += 1
	
	current_session_data = {
		"session_id": session_id,
		"start_time": session_start_time,
		"player_level": GameManager.player_level,
		"device_info": get_device_info(),
		"game_version": "1.0.0",
		"events": []
	}
	
	track_event("session_start", {
		"session_id": session_id,
		"player_level": GameManager.player_level,
		"total_sessions": retention_metrics.total_sessions
	})

func end_session():
	var session_end_time = Time.get_unix_time_from_system()
	var session_duration = session_end_time - session_start_time
	
	current_session_data.end_time = session_end_time
	current_session_data.duration = session_duration
	
	# Update session metrics
	gameplay_metrics.total_playtime += session_duration
	update_average_session_length()
	
	track_event("session_end", {
		"session_id": session_id,
		"duration": session_duration,
		"events_count": current_session_data.events.size()
	})
	
	# Save session data
	save_session_data()

# === EVENT TRACKING ===
func track_event(event_name: String, properties: Dictionary = {}):
	var event_data = {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"player_id": get_player_id(),
		"properties": properties
	}
	
	# Add to current session
	current_session_data.events.append(event_data)
	
	# Add to player actions for analysis
	player_actions.append(event_data)
	
	# Process specific event types
	process_event_for_metrics(event_name, properties)
	
	emit_signal("analytics_data_collected", event_name, event_data)
	
	# In production, send to analytics service
	send_to_analytics_service(event_data)

func process_event_for_metrics(event_name: String, properties: Dictionary):
	match event_name:
		"game_started":
			gameplay_metrics.games_started += 1
		"game_completed":
			gameplay_metrics.games_completed += 1
			update_completion_rate()
		"game_abandoned":
			gameplay_metrics.games_abandoned += 1
		"level_up":
			gameplay_metrics.levels_completed += 1
		"player_death":
			gameplay_metrics.deaths += 1
		"building_built":
			gameplay_metrics.buildings_built += 1
		"resource_collected":
			gameplay_metrics.resources_collected += properties.get("amount", 1)
		"battle_won":
			gameplay_metrics.battles_won += 1
		"battle_lost":
			gameplay_metrics.battles_lost += 1
		"purchase_completed":
			monetization_metrics.purchases_made += 1
			monetization_metrics.total_spent += properties.get("price", 0.0)
			if monetization_metrics.first_purchase_time == 0:
				monetization_metrics.first_purchase_time = Time.get_unix_time_from_system()
			update_ltv()
		"ad_watched":
			monetization_metrics.ads_watched += 1
		"premium_currency_spent":
			monetization_metrics.premium_currency_spent += properties.get("amount", 0)
		"premium_currency_earned":
			monetization_metrics.premium_currency_earned += properties.get("amount", 0)

# === USER JOURNEY TRACKING ===
func track_funnel_step(funnel_name: String, step_name: String, properties: Dictionary = {}):
	if not funnel_name in funnel_data:
		funnel_data[funnel_name] = {}
	
	if not step_name in funnel_data[funnel_name]:
		funnel_data[funnel_name][step_name] = {
			"count": 0,
			"first_completion": 0,
			"average_time_to_complete": 0.0
		}
	
	funnel_data[funnel_name][step_name].count += 1
	
	if funnel_data[funnel_name][step_name].first_completion == 0:
		funnel_data[funnel_name][step_name].first_completion = Time.get_unix_time_from_system()
	
	track_event("funnel_step", {
		"funnel": funnel_name,
		"step": step_name,
		"properties": properties
	})

func track_conversion(conversion_type: String, value: float = 1.0):
	if not conversion_type in conversion_tracking:
		conversion_tracking[conversion_type] = {
			"count": 0,
			"total_value": 0.0,
			"conversion_rate": 0.0
		}
	
	conversion_tracking[conversion_type].count += 1
	conversion_tracking[conversion_type].total_value += value
	
	track_event("conversion", {
		"type": conversion_type,
		"value": value
	})

# === A/B TESTING ===
func assign_ab_test_group(test_name: String, variants: Array[String]) -> String:
	if test_name in ab_test_groups:
		return ab_test_groups[test_name]
	
	# Assign player to variant based on consistent hash
	var player_hash = hash(get_player_id() + test_name)
	var variant_index = abs(player_hash) % variants.size()
	var assigned_variant = variants[variant_index]
	
	ab_test_groups[test_name] = assigned_variant
	
	track_event("ab_test_assigned", {
		"test_name": test_name,
		"variant": assigned_variant
	})
	
	return assigned_variant

func track_ab_test_conversion(test_name: String, conversion_event: String, value: float = 1.0):
	var variant = ab_test_groups.get(test_name, "control")
	
	track_event("ab_test_conversion", {
		"test_name": test_name,
		"variant": variant,
		"conversion_event": conversion_event,
		"value": value
	})

# === HEATMAP TRACKING ===
func track_click(position: Vector2, ui_element: String = ""):
	var grid_x = int(position.x / 50)  # 50px grid
	var grid_y = int(position.y / 50)
	var grid_key = str(grid_x) + "," + str(grid_y)
	
	if not grid_key in click_heatmap:
		click_heatmap[grid_key] = 0
	
	click_heatmap[grid_key] += 1
	
	track_event("ui_click", {
		"position": {"x": position.x, "y": position.y},
		"grid": grid_key,
		"element": ui_element
	})

func track_movement(position: Vector2):
	var grid_x = int(position.x / 100)  # Larger grid for movement
	var grid_y = int(position.y / 100)
	var grid_key = str(grid_x) + "," + str(grid_y)
	
	if not grid_key in movement_heatmap:
		movement_heatmap[grid_key] = 0
	
	movement_heatmap[grid_key] += 1

# === PERFORMANCE MONITORING ===
func setup_performance_monitoring():
	# Monitor FPS
	var fps_timer = Timer.new()
	fps_timer.wait_time = 5.0  # Check every 5 seconds
	fps_timer.timeout.connect(_on_fps_check)
	add_child(fps_timer)
	fps_timer.start()
	
	# Monitor memory usage
	var memory_timer = Timer.new()
	memory_timer.wait_time = 30.0  # Check every 30 seconds
	memory_timer.timeout.connect(_on_memory_check)
	add_child(memory_timer)
	memory_timer.start()

func _on_fps_check():
	var current_fps = Engine.get_frames_per_second()
	
	if not "fps_samples" in performance_data:
		performance_data.fps_samples = []
	
	performance_data.fps_samples.append(current_fps)
	
	# Keep only last 100 samples
	if performance_data.fps_samples.size() > 100:
		performance_data.fps_samples.pop_front()
	
	# Track low FPS events
	if current_fps < 30:
		track_event("low_fps", {"fps": current_fps})

func _on_memory_check():
	var memory_usage = OS.get_static_memory_usage_by_type()
	
	if not "memory_samples" in performance_data:
		performance_data.memory_samples = []
	
	performance_data.memory_samples.append(memory_usage)
	
	if performance_data.memory_samples.size() > 50:
		performance_data.memory_samples.pop_front()

func report_crash(error_message: String, stack_trace: String = ""):
	var crash_report = {
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"error_message": error_message,
		"stack_trace": stack_trace,
		"player_level": GameManager.player_level,
		"device_info": get_device_info(),
		"game_version": "1.0.0"
	}
	
	crash_reports.append(crash_report)
	
	track_event("crash", {
		"error": error_message,
		"session_duration": Time.get_unix_time_from_system() - session_start_time
	})

# === RETENTION ANALYSIS ===
func update_retention_metrics():
	var current_time = Time.get_unix_time_from_system()
	var install_time = get_install_time()
	
	if install_time == 0:
		set_install_time(current_time)
		return
	
	var days_since_install = (current_time - install_time) / (24 * 60 * 60)
	
	if days_since_install >= 1 and not retention_metrics.day_1_retention:
		retention_metrics.day_1_retention = true
		track_event("day_1_retention", {})
	
	if days_since_install >= 7 and not retention_metrics.day_7_retention:
		retention_metrics.day_7_retention = true
		track_event("day_7_retention", {})
	
	if days_since_install >= 30 and not retention_metrics.day_30_retention:
		retention_metrics.day_30_retention = true
		track_event("day_30_retention", {})

# === ENGAGEMENT METRICS ===
func calculate_engagement_score() -> float:
	var score = 0.0
	
	# Session frequency (0-30 points)
	var sessions_per_day = float(retention_metrics.total_sessions) / max(retention_metrics.days_played, 1)
	score += min(sessions_per_day * 10, 30)
	
	# Session length (0-25 points)
	var avg_session = gameplay_metrics.average_session_length / 60.0  # Convert to minutes
	score += min(avg_session * 2.5, 25)
	
	# Completion rate (0-20 points)
	var completion_rate = get_completion_rate()
	score += completion_rate * 20
	
	# Social engagement (0-15 points)
	var social_score = min(SocialManager.friend_list.size() * 2, 15)
	score += social_score
	
	# Monetization (0-10 points)
	if monetization_metrics.purchases_made > 0:
		score += 10
	elif monetization_metrics.ads_watched > 0:
		score += 5
	
	return score

# === DATA ANALYSIS ===
func get_completion_rate() -> float:
	if gameplay_metrics.games_started == 0:
		return 0.0
	return float(gameplay_metrics.games_completed) / float(gameplay_metrics.games_started)

func get_average_session_length() -> float:
	return gameplay_metrics.average_session_length

func get_churn_risk() -> float:
	var days_since_last_session = get_days_since_last_session()
	
	if days_since_last_session == 0:
		return 0.0
	elif days_since_last_session <= 1:
		return 0.1
	elif days_since_last_session <= 3:
		return 0.3
	elif days_since_last_session <= 7:
		return 0.6
	else:
		return 0.9

func get_ltv_estimate() -> float:
	if retention_metrics.total_sessions == 0:
		return 0.0
	
	var avg_revenue_per_session = monetization_metrics.total_spent / retention_metrics.total_sessions
	var estimated_future_sessions = estimate_future_sessions()
	
	return avg_revenue_per_session * estimated_future_sessions

func estimate_future_sessions() -> int:
	# Simple estimation based on current retention
	var base_sessions = 50
	
	if retention_metrics.day_1_retention:
		base_sessions += 30
	if retention_metrics.day_7_retention:
		base_sessions += 50
	if retention_metrics.day_30_retention:
		base_sessions += 100
	
	return base_sessions

# === UTILITY FUNCTIONS ===
func generate_session_id() -> String:
	return "session_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func get_player_id() -> String:
	# In production, this would be a unique player identifier
	return "player_" + str(OS.get_unique_id())

func get_device_info() -> Dictionary:
	return {
		"platform": OS.get_name(),
		"version": OS.get_version(),
		"screen_size": DisplayServer.screen_get_size(),
		"locale": OS.get_locale()
	}

func update_average_session_length():
	if retention_metrics.total_sessions > 0:
		gameplay_metrics.average_session_length = gameplay_metrics.total_playtime / retention_metrics.total_sessions

func update_completion_rate():
	# Trigger completion rate recalculation
	pass

func update_ltv():
	monetization_metrics.ltv = get_ltv_estimate()

func get_install_time() -> int:
	# Load from saved data
	var save_file = FileAccess.open("user://install_time.save", FileAccess.READ)
	if save_file:
		var install_time = save_file.get_64()
		save_file.close()
		return install_time
	return 0

func set_install_time(time: float):
	var save_file = FileAccess.open("user://install_time.save", FileAccess.WRITE)
	if save_file:
		save_file.store_64(int(time))
		save_file.close()

func get_days_since_last_session() -> int:
	# Calculate days since last session
	var last_session = get_last_session_time()
	if last_session == 0:
		return 0
	
	var current_time = Time.get_unix_time_from_system()
	return int((current_time - last_session) / (24 * 60 * 60))

func get_last_session_time() -> int:
	# Load from saved data
	var save_file = FileAccess.open("user://last_session.save", FileAccess.READ)
	if save_file:
		var last_session = save_file.get_64()
		save_file.close()
		return last_session
	return 0

func set_last_session_time(time: float):
	var save_file = FileAccess.open("user://last_session.save", FileAccess.WRITE)
	if save_file:
		save_file.store_64(int(time))
		save_file.close()

func send_to_analytics_service(event_data: Dictionary):
	# In production, send to analytics service (Firebase, GameAnalytics, etc.)
	print("Analytics: ", event_data.event, " - ", event_data.properties)

# === SAVE/LOAD ===
func save_analytics_data():
	var save_data = {
		"gameplay_metrics": gameplay_metrics,
		"monetization_metrics": monetization_metrics,
		"retention_metrics": retention_metrics,
		"ab_test_groups": ab_test_groups,
		"click_heatmap": click_heatmap,
		"performance_data": performance_data,
		"funnel_data": funnel_data,
		"conversion_tracking": conversion_tracking
	}
	
	var save_file = FileAccess.open("user://analytics.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_analytics_data():
	var save_file = FileAccess.open("user://analytics.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			gameplay_metrics = save_data.get("gameplay_metrics", gameplay_metrics)
			monetization_metrics = save_data.get("monetization_metrics", monetization_metrics)
			retention_metrics = save_data.get("retention_metrics", retention_metrics)
			ab_test_groups = save_data.get("ab_test_groups", {})
			click_heatmap = save_data.get("click_heatmap", {})
			performance_data = save_data.get("performance_data", {})
			funnel_data = save_data.get("funnel_data", {})
			conversion_tracking = save_data.get("conversion_tracking", {})

func save_session_data():
	# Save individual session data
	var session_file = FileAccess.open("user://session_" + session_id + ".json", FileAccess.WRITE)
	if session_file:
		session_file.store_string(JSON.stringify(current_session_data))
		session_file.close()
	
	# Update last session time
	set_last_session_time(Time.get_unix_time_from_system())
	
	# Save analytics data
	save_analytics_data()

# === REPORTING ===
func generate_daily_report() -> Dictionary:
	return {
		"date": Time.get_date_string_from_system(),
		"engagement_score": calculate_engagement_score(),
		"completion_rate": get_completion_rate(),
		"churn_risk": get_churn_risk(),
		"ltv_estimate": get_ltv_estimate(),
		"sessions_today": get_sessions_today(),
		"revenue_today": get_revenue_today()
	}

func get_sessions_today() -> int:
	# Count sessions from today
	return 1  # Simplified for demo

func get_revenue_today() -> float:
	# Calculate revenue from today
	return 0.0  # Simplified for demo

func _exit_tree():
	end_session()