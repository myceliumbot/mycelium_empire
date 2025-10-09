extends Control

# Main Game Controller - orchestrates all systems for maximum addiction and profit

# Game state
var game_state: String = "menu"  # menu, playing, paused, store, social
var current_map: Dictionary = {}
var player_faction: Dictionary = {}
var ai_factions: Array[Dictionary] = []

# UI References
@onready var main_menu: Control
@onready var game_hud: Control
@onready var currency_display: Control
@onready var progress_bars: Control
@onready var notification_area: Control

# Game systems integration
var tutorial_completed: bool = false
var first_session: bool = true
var session_goals: Array[Dictionary] = []

func _ready():
	initialize_game()
	setup_ui_connections()
	start_player_onboarding()

func initialize_game():
	# Connect all manager signals for coordinated responses
	connect_manager_signals()
	
	# Initialize game state
	check_first_time_player()
	setup_session_goals()
	
	# Start background systems
	start_retention_hooks()
	
	# Apply A/B tests
	apply_ab_tests()

func connect_manager_signals():
	# GameManager connections
	GameManager.connect("player_level_changed", _on_player_level_up)
	GameManager.connect("currency_changed", _on_currency_changed)
	GameManager.connect("achievement_unlocked", _on_achievement_unlocked)
	GameManager.connect("daily_reward_available", _on_daily_reward_ready)
	
	# MonetizationManager connections
	MonetizationManager.connect("purchase_completed", _on_purchase_success)
	MonetizationManager.connect("ad_watched", _on_ad_reward_given)
	
	# SocialManager connections
	SocialManager.connect("friend_added", _on_friend_added)
	SocialManager.connect("guild_joined", _on_guild_joined)
	SocialManager.connect("tournament_result", _on_tournament_completed)
	
	# LiveServiceManager connections
	LiveServiceManager.connect("event_started", _on_live_event_started)
	LiveServiceManager.connect("seasonal_content_updated", _on_seasonal_update)
	
	# MarketingManager connections (add to autoload first)
	# MarketingManager.connect("viral_milestone_reached", _on_viral_milestone)

func check_first_time_player():
	first_session = GameManager.total_playtime < 60.0  # Less than 1 minute played
	
	if first_session:
		# First-time player experience
		setup_new_player_experience()
	else:
		# Returning player experience
		setup_returning_player_experience()

func setup_new_player_experience():
	# Immediate gratification for new players
	GameManager.add_currency("soft", 5000)  # Generous starting currency
	GameManager.add_currency("premium", 25)  # Some premium currency to taste
	
	# Queue tutorial
	call_deferred("start_tutorial")
	
	# Set up new player goals
	create_new_player_goals()
	
	# Track new player funnel
	AnalyticsManager.track_funnel_step("new_player_onboarding", "game_started")

func setup_returning_player_experience():
	# Welcome back rewards
	var days_since_last_session = AnalyticsManager.get_days_since_last_session()
	
	if days_since_last_session >= 1:
		give_comeback_rewards(days_since_last_session)
	
	# Show what's new
	show_whats_new_popup()
	
	# Check for pending rewards
	check_offline_progress()

func start_tutorial():
	if not tutorial_completed:
		game_state = "tutorial"
		show_tutorial_popup()

func show_tutorial_popup():
	var tutorial_steps = [
		{
			"title": "Welcome to Mycelium Empire!",
			"text": "Build your mushroom kingdom and conquer the microscopic world!",
			"action": "highlight_build_button",
			"reward": {"soft": 500}
		},
		{
			"title": "Collect Resources",
			"text": "Tap resource nodes to gather spores and nutrients!",
			"action": "highlight_resources",
			"reward": {"soft": 300}
		},
		{
			"title": "Build Your First Structure",
			"text": "Construct a Spore Collector to automate resource gathering!",
			"action": "force_build_tutorial",
			"reward": {"soft": 1000, "xp": 100}
		},
		{
			"title": "Level Up Rewards",
			"text": "Gain XP to level up and unlock new content!",
			"action": "show_progression",
			"reward": {"xp": 200}
		},
		{
			"title": "Daily Rewards",
			"text": "Come back every day for amazing rewards!",
			"action": "show_daily_system",
			"reward": {"premium": 5}
		}
	]
	
	start_guided_tutorial(tutorial_steps)

func start_guided_tutorial(steps: Array[Dictionary]):
	for i in range(steps.size()):
		var step = steps[i]
		
		# Show tutorial step
		UIManager.show_notification(
			step.title,
			step.text,
			"tutorial",
			5.0
		)
		
		# Give step rewards immediately (instant gratification)
		if "reward" in step:
			for reward_type in step.reward.keys():
				match reward_type:
					"soft", "premium":
						GameManager.add_currency(reward_type, step.reward[reward_type])
					"xp":
						GameManager.add_xp(step.reward[reward_type], "tutorial")
		
		# Wait for player action or timeout
		await get_tree().create_timer(3.0).timeout
		
		# Track tutorial progress
		AnalyticsManager.track_funnel_step("tutorial", "step_" + str(i + 1))
	
	complete_tutorial()

func complete_tutorial():
	tutorial_completed = true
	
	# Big completion reward
	GameManager.add_currency("soft", 2000)
	GameManager.add_currency("premium", 10)
	GameManager.add_xp(500, "tutorial_completion")
	
	# Unlock social features
	show_social_introduction()
	
	# Show first purchase offer
	show_starter_pack_offer()
	
	AnalyticsManager.track_funnel_step("tutorial", "completed")
	AnalyticsManager.track_conversion("tutorial_completion")

func show_social_introduction():
	# Introduce social features with immediate benefits
	UIManager.show_notification(
		"Connect with Friends!",
		"Add friends to get bonus rewards and compete on leaderboards!",
		"social_intro",
		6.0
	)
	
	# Show referral code
	show_referral_code_popup()

func show_referral_code_popup():
	var referral_text = "Share your referral code with friends!\n\nYour code: " + MarketingManager.referral_code + "\n\nBoth you and your friend get bonus rewards!"
	
	UIManager.show_notification(
		"Invite Friends!",
		referral_text,
		"referral",
		8.0
	)

func show_starter_pack_offer():
	# Show compelling first purchase offer
	var offer_data = {
		"title": "Welcome Pack - 80% OFF!",
		"original_price": 9.99,
		"discounted_price": 1.99,
		"contents": "500 Crystals + Exclusive Skin + 7-Day XP Boost",
		"urgency": "Limited time offer!",
		"time_remaining": 24 * 60 * 60  # 24 hours
	}
	
	show_monetization_popup(offer_data)

func show_monetization_popup(offer_data: Dictionary):
	# Create urgency and value perception
	UIManager.create_urgency_indicator(get_viewport(), offer_data.urgency)
	
	UIManager.show_notification(
		offer_data.title,
		offer_data.contents + "\n\nNormal: $" + str(offer_data.original_price) + " → NOW: $" + str(offer_data.discounted_price),
		"special_offer",
		10.0
	)

# === RETENTION HOOKS ===
func start_retention_hooks():
	# Set up various hooks to keep players coming back
	schedule_push_notifications()
	create_fomo_events()
	setup_streak_rewards()

func schedule_push_notifications():
	# Schedule notifications for different time intervals
	var notification_schedule = [
		{"delay": 1 * 60 * 60, "message": "Your mushroom kingdom needs you! Resources are ready to collect! 🍄"},
		{"delay": 6 * 60 * 60, "message": "Don't let your enemies get ahead! Come back and defend your territory! ⚔️"},
		{"delay": 24 * 60 * 60, "message": "Daily rewards are waiting! Don't miss out on free crystals! 💎"},
		{"delay": 72 * 60 * 60, "message": "We miss you! Come back for a special comeback bonus! 🎁"}
	]
	
	for notification in notification_schedule:
		schedule_push_notification(notification.message, notification.delay)

func schedule_push_notification(message: String, delay: int):
	# In production, this would schedule actual push notifications
	print("Scheduled notification: ", message, " in ", delay, " seconds")

func create_fomo_events():
	# Create fear of missing out with limited-time events
	var fomo_events = [
		{
			"name": "Flash Sale",
			"duration": 2 * 60 * 60,  # 2 hours
			"discount": 50,
			"message": "Flash Sale! 50% off all premium items for 2 hours only!"
		},
		{
			"name": "Double XP Hour",
			"duration": 1 * 60 * 60,  # 1 hour
			"multiplier": 2.0,
			"message": "Double XP for the next hour! Don't miss out!"
		}
	]
	
	# Randomly trigger FOMO events
	var timer = Timer.new()
	timer.wait_time = randi_range(3600, 7200)  # 1-2 hours
	timer.timeout.connect(func(): trigger_random_fomo_event(fomo_events))
	add_child(timer)
	timer.start()

func trigger_random_fomo_event(events: Array[Dictionary]):
	var event = events[randi() % events.size()]
	
	UIManager.show_notification(
		"Limited Time Event!",
		event.message,
		"fomo_event",
		8.0
	)
	
	# Apply event effects
	apply_temporary_boost(event)

func apply_temporary_boost(event: Dictionary):
	match event.name:
		"Flash Sale":
			# Apply discount to store items
			pass
		"Double XP Hour":
			# Apply XP multiplier
			GameManager.xp_multiplier = event.multiplier
			
			# Remove after duration
			var timer = Timer.new()
			timer.wait_time = event.duration
			timer.one_shot = true
			timer.timeout.connect(func(): GameManager.xp_multiplier = 1.0)
			add_child(timer)
			timer.start()

func setup_streak_rewards():
	# Escalating rewards for consecutive days
	var streak_rewards = {
		1: {"soft": 100},
		3: {"soft": 300, "premium": 1},
		7: {"soft": 1000, "premium": 5},
		14: {"soft": 2500, "premium": 15},
		30: {"soft": 10000, "premium": 50, "cosmetic": "dedication_crown"}
	}
	
	var current_streak = GameManager.daily_streak
	if current_streak in streak_rewards:
		var rewards = streak_rewards[current_streak]
		give_streak_rewards(rewards, current_streak)

func give_streak_rewards(rewards: Dictionary, streak_days: int):
	for reward_type in rewards.keys():
		match reward_type:
			"soft", "premium":
				GameManager.add_currency(reward_type, rewards[reward_type])
			"cosmetic":
				MonetizationManager.owned_cosmetics.append(rewards[reward_type])
	
	UIManager.show_notification(
		"Streak Reward!",
		str(streak_days) + " day streak! Amazing dedication!",
		"streak_reward",
		5.0
	)

# === SESSION GOALS ===
func setup_session_goals():
	# Create short-term goals to keep players engaged
	session_goals = [
		{"type": "xp", "target": 500, "reward": {"soft": 1000}, "progress": 0},
		{"type": "buildings", "target": 5, "reward": {"premium": 2}, "progress": 0},
		{"type": "playtime", "target": 1800, "reward": {"soft": 1500}, "progress": 0}  # 30 minutes
	]
	
	# Show session goals to player
	display_session_goals()

func display_session_goals():
	var goals_text = "Session Goals:\n"
	for goal in session_goals:
		goals_text += "• " + goal.type.capitalize() + ": " + str(goal.progress) + "/" + str(goal.target) + "\n"
	
	UIManager.show_notification(
		"Session Goals",
		goals_text,
		"session_goals",
		6.0
	)

func update_session_goal_progress(goal_type: String, amount: int):
	for goal in session_goals:
		if goal.type == goal_type and not goal.get("completed", false):
			goal.progress += amount
			
			if goal.progress >= goal.target:
				complete_session_goal(goal)

func complete_session_goal(goal: Dictionary):
	goal.completed = true
	
	# Give rewards
	for reward_type in goal.reward.keys():
		match reward_type:
			"soft", "premium":
				GameManager.add_currency(reward_type, goal.reward[reward_type])
	
	UIManager.show_notification(
		"Goal Complete!",
		goal.type.capitalize() + " goal completed! Great job!",
		"goal_complete",
		4.0
	)
	
	# Create celebration
	UIManager.create_pulse_effect(get_viewport())

# === A/B TESTING ===
func apply_ab_tests():
	# Test different UI layouts, rewards, pricing, etc.
	var ui_variant = AnalyticsManager.assign_ab_test_group("ui_layout", ["classic", "modern", "compact"])
	var reward_variant = AnalyticsManager.assign_ab_test_group("reward_amounts", ["low", "medium", "high"])
	var pricing_variant = AnalyticsManager.assign_ab_test_group("pricing", ["low", "standard", "premium"])
	
	apply_ui_variant(ui_variant)
	apply_reward_variant(reward_variant)
	apply_pricing_variant(pricing_variant)

func apply_ui_variant(variant: String):
	match variant:
		"modern":
			# Apply modern UI theme
			pass
		"compact":
			# Apply compact UI layout
			pass

func apply_reward_variant(variant: String):
	match variant:
		"low":
			GameManager.reward_multiplier = 0.8
		"high":
			GameManager.reward_multiplier = 1.2

func apply_pricing_variant(variant: String):
	match variant:
		"low":
			MonetizationManager.price_multiplier = 0.8
		"premium":
			MonetizationManager.price_multiplier = 1.3

# === GAME LOOP ===
func start_new_game():
	game_state = "playing"
	
	# Generate new map
	current_map = ContentGenerator.generate_random_map(GameManager.player_level)
	
	# Create AI opponents
	generate_ai_opponents()
	
	# Set up game session
	setup_game_session()
	
	# Track game start
	AnalyticsManager.track_event("game_started", {
		"map_type": current_map.biome,
		"player_level": GameManager.player_level,
		"session_number": AnalyticsManager.retention_metrics.total_sessions
	})

func generate_ai_opponents():
	ai_factions.clear()
	
	var opponent_count = min(3, GameManager.player_level / 5 + 1)  # Scale with level
	
	for i in range(opponent_count):
		var ai_faction = ContentGenerator.generate_random_faction()
		ai_factions.append(ai_faction)

func setup_game_session():
	# Set up session-specific goals and challenges
	create_session_challenges()
	
	# Start session tracking
	AnalyticsManager.start_session()

func create_session_challenges():
	# Dynamic challenges based on player behavior
	var challenges = []
	
	if GameManager.buildings_built < 50:
		challenges.append({
			"type": "build_focus",
			"description": "Build 10 structures this match",
			"target": 10,
			"reward": {"soft": 1000, "xp": 200}
		})
	
	if GameManager.enemies_defeated < 100:
		challenges.append({
			"type": "combat_focus", 
			"description": "Defeat 20 enemies this match",
			"target": 20,
			"reward": {"soft": 1200, "xp": 250}
		})
	
	# Show challenges to player
	for challenge in challenges:
		UIManager.show_notification(
			"Match Challenge",
			challenge.description,
			"challenge",
			4.0
		)

# === EVENT HANDLERS ===
func _on_player_level_up(new_level: int):
	# Level up is a major retention moment
	UIManager.create_level_up_celebration()
	
	# Unlock new content
	unlock_level_content(new_level)
	
	# Update session goals
	update_session_goal_progress("level", 1)
	
	# Check for monetization opportunities
	check_level_monetization_offers(new_level)

func unlock_level_content(level: int):
	var unlocks = []
	
	match level:
		5:
			unlocks.append("Guild System")
		10:
			unlocks.append("PvP Tournaments")
		15:
			unlocks.append("Advanced Buildings")
		20:
			unlocks.append("Faction Customization")
		25:
			unlocks.append("Legendary Units")
	
	for unlock in unlocks:
		UIManager.show_notification(
			"New Feature Unlocked!",
			unlock + " is now available!",
			"feature_unlock",
			5.0
		)

func check_level_monetization_offers(level: int):
	# Show targeted offers at key levels
	if level % 10 == 0:  # Every 10 levels
		var offer = {
			"title": "Level " + str(level) + " Celebration Pack!",
			"discount": 30,
			"contents": "Exclusive skin + " + str(level * 10) + " crystals"
		}
		
		show_level_offer(offer)

func show_level_offer(offer: Dictionary):
	UIManager.show_notification(
		offer.title,
		offer.contents + "\n" + str(offer.discount) + "% OFF for 24 hours!",
		"level_offer",
		8.0
	)

func _on_currency_changed(currency_type: String, amount: int):
	# Update UI displays
	update_currency_displays()
	
	# Check for spending opportunities
	if currency_type == "premium" and amount > 50:
		suggest_premium_purchases()

func suggest_premium_purchases():
	UIManager.show_notification(
		"Spend Your Crystals!",
		"Check out the exclusive items in the premium store!",
		"spend_suggestion",
		4.0
	)

func _on_achievement_unlocked(achievement_id: String):
	# Achievements are great sharing moments
	create_achievement_share_opportunity(achievement_id)
	
	# Chain achievements for continued engagement
	suggest_related_achievements(achievement_id)

func create_achievement_share_opportunity(achievement_id: String):
	var achievement_data = GameManager.get_achievement_data(achievement_id)
	
	# Show share prompt
	UIManager.show_notification(
		"Share Your Achievement!",
		"Show off your " + achievement_data.get("name", "achievement") + " to friends!",
		"share_prompt",
		6.0
	)

func suggest_related_achievements(achievement_id: String):
	# Suggest next achievements to work towards
	var suggestions = get_achievement_suggestions(achievement_id)
	
	for suggestion in suggestions:
		UIManager.show_notification(
			"Next Goal",
			"Work towards: " + suggestion,
			"next_achievement",
			3.0
		)

func get_achievement_suggestions(completed_achievement: String) -> Array[String]:
	var suggestions = {
		"first_victory": ["Win 10 matches", "Build 50 structures"],
		"builder": ["Build 500 structures", "Unlock all buildings"],
		"warrior": ["Defeat 5000 enemies", "Win 100 PvP matches"]
	}
	
	return suggestions.get(completed_achievement, [])

func _on_daily_reward_ready():
	# Daily rewards are critical for retention
	show_daily_reward_popup()

func show_daily_reward_popup():
	var reward_amount = GameManager.daily_streak * 100
	
	UIManager.show_notification(
		"Daily Reward Ready!",
		"Day " + str(GameManager.daily_streak) + " reward: " + str(reward_amount) + " spores!",
		"daily_reward",
		6.0
	)

func _on_purchase_success(product_id: String):
	# Successful purchases should feel amazing
	UIManager.create_purchase_celebration(product_id)
	
	# Track conversion for analytics
	AnalyticsManager.track_conversion("purchase", MonetizationManager.store_products[product_id].price)
	
	# Suggest related purchases
	suggest_complementary_purchases(product_id)

func suggest_complementary_purchases(product_id: String):
	# Cross-sell related items
	var suggestions = {
		"crystal_pack_small": ["season_pass", "remove_ads"],
		"season_pass": ["crystal_pack_medium", "vip_monthly"],
		"remove_ads": ["crystal_pack_small", "starter_pack"]
	}
	
	var related_products = suggestions.get(product_id, [])
	if related_products.size() > 0:
		var suggestion = related_products[randi() % related_products.size()]
		
		UIManager.show_notification(
			"Complete Your Collection!",
			"Consider adding " + MonetizationManager.store_products[suggestion].name,
			"cross_sell",
			5.0
		)

func _on_ad_reward_given(reward_type: String, reward_amount: int):
	# Make ad watching feel rewarding
	UIManager.create_currency_burst(get_viewport(), reward_type)
	
	# Encourage more ad watching
	if MonetizationManager.can_watch_ad():
		UIManager.show_notification(
			"More Rewards Available!",
			"Watch another ad for more rewards?",
			"ad_prompt",
			3.0
		)

func _on_friend_added(friend_id: String):
	# Social connections boost retention
	UIManager.create_celebration_particles("social")
	
	# Give social rewards
	GameManager.add_currency("soft", 500)
	
	# Encourage more social activity
	suggest_social_features()

func suggest_social_features():
	var suggestions = [
		"Join a guild for team rewards!",
		"Challenge friends to matches!",
		"Share your achievements!"
	]
	
	var suggestion = suggestions[randi() % suggestions.size()]
	
	UIManager.show_notification(
		"Social Features",
		suggestion,
		"social_suggestion",
		4.0
	)

func _on_guild_joined(guild_id: String):
	# Guild joining is a major retention milestone
	UIManager.create_screen_flash(Color.GOLD, 0.5)
	
	# Give joining bonus
	GameManager.add_currency("soft", 2000)
	GameManager.add_currency("premium", 10)

func _on_tournament_completed(placement: int, rewards: Dictionary):
	# Tournaments create competitive engagement
	var placement_text = get_placement_text(placement)
	
	UIManager.show_notification(
		"Tournament Complete!",
		"You placed " + placement_text + "! Great job!",
		"tournament_result",
		6.0
	)

func get_placement_text(placement: int) -> String:
	match placement:
		1:
			return "1st"
		2:
			return "2nd" 
		3:
			return "3rd"
		_:
			return str(placement) + "th"

func _on_live_event_started(event_data: Dictionary):
	# Live events create urgency and engagement
	UIManager.create_urgency_indicator(get_viewport(), "Limited Time Event!")
	
	UIManager.show_notification(
		"Live Event Started!",
		event_data.name + " - " + event_data.description,
		"live_event",
		8.0
	)

func _on_seasonal_update():
	# Seasonal content keeps the game fresh
	UIManager.show_notification(
		"New Seasonal Content!",
		"Check out the latest seasonal rewards and challenges!",
		"seasonal_update",
		6.0
	)

# === COMEBACK MECHANICS ===
func give_comeback_rewards(days_away: int):
	var base_reward = min(days_away * 500, 10000)  # Cap at 10k
	var premium_reward = min(days_away, 20)  # Cap at 20
	
	GameManager.add_currency("soft", base_reward)
	GameManager.add_currency("premium", premium_reward)
	
	UIManager.show_notification(
		"Welcome Back!",
		"We missed you! Here's " + str(base_reward) + " spores and " + str(premium_reward) + " crystals!",
		"comeback_reward",
		7.0
	)

func show_whats_new_popup():
	var whats_new = [
		"New seasonal event: Spore Storm!",
		"Guild wars now available!",
		"Daily challenges updated!",
		"New premium cosmetics added!"
	]
	
	var news_text = ""
	for item in whats_new:
		news_text += "• " + item + "\n"
	
	UIManager.show_notification(
		"What's New",
		news_text,
		"whats_new",
		8.0
	)

func check_offline_progress():
	# Calculate offline earnings (limited to encourage active play)
	var offline_time = min(AnalyticsManager.get_days_since_last_session() * 24, 48)  # Max 48 hours
	var offline_earnings = int(offline_time * GameManager.player_level * 10)
	
	if offline_earnings > 0:
		GameManager.add_currency("soft", offline_earnings)
		
		UIManager.show_notification(
			"Offline Progress!",
			"Your mushrooms collected " + str(offline_earnings) + " spores while you were away!",
			"offline_progress",
			5.0
		)

# === GAME FLOW OPTIMIZATION ===
func create_new_player_goals():
	var new_player_goals = [
		{"type": "reach_level_5", "reward": {"premium": 10}, "urgency": "3 days"},
		{"type": "add_first_friend", "reward": {"soft": 1000}, "urgency": "7 days"},
		{"type": "join_guild", "reward": {"premium": 15}, "urgency": "7 days"},
		{"type": "first_purchase", "reward": {"premium": 25}, "urgency": "14 days"}
	]
	
	for goal in new_player_goals:
		show_new_player_goal(goal)

func show_new_player_goal(goal: Dictionary):
	UIManager.show_notification(
		"New Player Goal",
		goal.type.replace("_", " ").capitalize() + " within " + goal.urgency + " for bonus rewards!",
		"new_player_goal",
		5.0
	)

func start_player_onboarding():
	# Comprehensive onboarding flow
	if first_session:
		# Immediate engagement
		show_opening_rewards()
		
		# Quick wins
		create_easy_early_goals()
		
		# Social integration
		prompt_social_connection()

func show_opening_rewards():
	UIManager.show_notification(
		"Welcome Gift!",
		"Here's 5000 spores and 25 crystals to get you started!",
		"welcome_gift",
		5.0
	)

func create_easy_early_goals():
	# Very easy goals for immediate satisfaction
	var easy_goals = [
		{"action": "tap_screen_5_times", "reward": {"soft": 100}},
		{"action": "open_build_menu", "reward": {"soft": 200}},
		{"action": "place_first_building", "reward": {"soft": 500, "xp": 100}}
	]
	
	for goal in easy_goals:
		setup_micro_goal(goal)

func setup_micro_goal(goal: Dictionary):
	# Track micro-interactions for immediate feedback
	print("Micro goal set up: ", goal.action)

func prompt_social_connection():
	# Gentle social prompts
	await get_tree().create_timer(300.0).timeout  # After 5 minutes
	
	UIManager.show_notification(
		"Play with Friends!",
		"Games are more fun with friends! Want to invite someone?",
		"social_prompt",
		6.0
	)

func update_currency_displays():
	# Keep UI always updated with satisfying number changes
	UIManager.update_currency_display()

# === MAIN LOOP ===
func _process(_delta):
	# Continuous engagement monitoring
	update_session_goal_progress("playtime", int(_delta))
	
	# Check for engagement opportunities
	check_engagement_opportunities()

func check_engagement_opportunities():
	# Look for moments to re-engage the player
	var current_time = Time.get_unix_time_from_system()
	
	# Check for idle players
	if GameManager.total_playtime > 300 and current_time % 60 == 0:  # Every minute after 5 minutes
		check_for_idle_prompts()

func check_for_idle_prompts():
	# Re-engage idle players
	var prompts = [
		"Don't forget to collect your resources!",
		"Your enemies might be planning an attack!",
		"New daily quests are available!",
		"Check out the latest store offers!"
	]
	
	if randf() < 0.1:  # 10% chance per minute
		var prompt = prompts[randi() % prompts.size()]
		UIManager.show_notification("Reminder", prompt, "idle_prompt", 3.0)

# Initialize the addictive game loop
func _enter_tree():
	# Set up the most addictive game possible
	print("Mycelium Empire: Maximum Addiction Mode Activated!")
	print("Features: Progression loops, social competition, FOMO events, premium monetization")
	print("Goal: Create the most engaging and profitable mushroom empire game!")