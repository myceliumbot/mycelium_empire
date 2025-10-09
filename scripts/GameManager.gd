extends Node

# Singleton GameManager for handling all core game systems
signal player_level_changed(new_level: int)
signal currency_changed(currency_type: String, amount: int)
signal achievement_unlocked(achievement_id: String)
signal daily_reward_available()

# Player progression
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next_level: int = 100

# Currencies (multiple for monetization)
var soft_currency: int = 1000  # Spores (earned through gameplay)
var premium_currency: int = 0   # Mycelium Crystals (purchased with real money)
var prestige_currency: int = 0  # Ancient Spores (earned through prestige/reset)

# Player stats and progression
var total_playtime: float = 0.0
var games_played: int = 0
var victories: int = 0
var buildings_built: int = 0
var enemies_defeated: int = 0

# Daily systems
var last_daily_reward_claim: String = ""
var daily_streak: int = 0
var daily_quests: Array[Dictionary] = []

# Battle pass / season system
var current_season: int = 1
var season_level: int = 1
var season_xp: int = 0
var season_premium: bool = false

# Achievement system
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}

# Social features
var guild_id: String = ""
var friend_list: Array[String] = []
var player_rating: int = 1000

# Game settings and preferences
var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 0.7,
	"auto_save": true,
	"notifications_enabled": true,
	"graphics_quality": "high"
}

func _ready():
	# Load player data
	load_game_data()
	
	# Set up daily systems
	check_daily_reset()
	generate_daily_quests()
	
	# Connect to achievement system
	connect_achievement_triggers()
	
	# Start analytics tracking
	start_session_tracking()

func _process(delta):
	total_playtime += delta
	
	# Auto-save every 5 minutes
	if int(total_playtime) % 300 == 0 and settings.auto_save:
		save_game_data()

# === PROGRESSION SYSTEM ===
func add_xp(amount: int, source: String = ""):
	player_xp += amount
	
	# Check for level up
	while player_xp >= player_xp_to_next_level:
		level_up()
	
	# Track XP sources for analytics
	track_event("xp_gained", {"amount": amount, "source": source})

func level_up():
	player_xp -= player_xp_to_next_level
	player_level += 1
	player_xp_to_next_level = int(player_xp_to_next_level * 1.2)  # Exponential scaling
	
	# Level up rewards
	var reward_soft_currency = player_level * 50
	var reward_premium_currency = 0
	
	# Every 10 levels, give premium currency
	if player_level % 10 == 0:
		reward_premium_currency = 5
	
	add_currency("soft", reward_soft_currency)
	if reward_premium_currency > 0:
		add_currency("premium", reward_premium_currency)
	
	emit_signal("player_level_changed", player_level)
	
	# Show level up popup
	show_level_up_popup(reward_soft_currency, reward_premium_currency)
	
	track_event("level_up", {"level": player_level})

# === CURRENCY SYSTEM ===
func add_currency(type: String, amount: int):
	match type:
		"soft":
			soft_currency += amount
		"premium":
			premium_currency += amount
		"prestige":
			prestige_currency += amount
	
	emit_signal("currency_changed", type, get_currency(type))
	save_game_data()

func spend_currency(type: String, amount: int) -> bool:
	var current_amount = get_currency(type)
	if current_amount >= amount:
		match type:
			"soft":
				soft_currency -= amount
			"premium":
				premium_currency -= amount
			"prestige":
				prestige_currency -= amount
		
		emit_signal("currency_changed", type, get_currency(type))
		save_game_data()
		return true
	return false

func get_currency(type: String) -> int:
	match type:
		"soft":
			return soft_currency
		"premium":
			return premium_currency
		"prestige":
			return prestige_currency
	return 0

# === DAILY SYSTEMS ===
func check_daily_reset():
	var current_date = Time.get_date_string_from_system()
	
	if last_daily_reward_claim != current_date:
		# Reset daily systems
		if last_daily_reward_claim != "" and is_consecutive_day(last_daily_reward_claim, current_date):
			daily_streak += 1
		else:
			daily_streak = 1
		
		emit_signal("daily_reward_available")
		generate_daily_quests()

func claim_daily_reward():
	var current_date = Time.get_date_string_from_system()
	
	if last_daily_reward_claim == current_date:
		return false  # Already claimed today
	
	last_daily_reward_claim = current_date
	
	# Calculate rewards based on streak
	var base_soft_currency = 100
	var streak_multiplier = min(daily_streak, 7)  # Cap at 7x
	var total_reward = base_soft_currency * streak_multiplier
	
	add_currency("soft", total_reward)
	
	# Bonus rewards for long streaks
	if daily_streak >= 7:
		add_currency("premium", 1)
	
	if daily_streak >= 30:
		add_currency("premium", 5)
		unlock_achievement("daily_warrior")
	
	save_game_data()
	return true

func generate_daily_quests():
	daily_quests.clear()
	
	var quest_templates = [
		{"id": "win_games", "desc": "Win %d matches", "target": 3, "reward_soft": 200},
		{"id": "build_structures", "desc": "Build %d structures", "target": 10, "reward_soft": 150},
		{"id": "defeat_enemies", "desc": "Defeat %d enemy units", "target": 25, "reward_soft": 175},
		{"id": "collect_resources", "desc": "Collect %d resources", "target": 500, "reward_soft": 125},
		{"id": "play_time", "desc": "Play for %d minutes", "target": 30, "reward_soft": 100}
	]
	
	# Pick 3 random quests
	quest_templates.shuffle()
	for i in range(3):
		var quest = quest_templates[i].duplicate()
		quest.progress = 0
		quest.completed = false
		daily_quests.append(quest)

# === ACHIEVEMENT SYSTEM ===
func unlock_achievement(achievement_id: String):
	if achievement_id in unlocked_achievements:
		return false
	
	unlocked_achievements.append(achievement_id)
	emit_signal("achievement_unlocked", achievement_id)
	
	# Achievement rewards
	var achievement_data = get_achievement_data(achievement_id)
	if achievement_data.has("reward_soft"):
		add_currency("soft", achievement_data.reward_soft)
	if achievement_data.has("reward_premium"):
		add_currency("premium", achievement_data.reward_premium)
	
	track_event("achievement_unlocked", {"achievement": achievement_id})
	save_game_data()
	return true

func get_achievement_data(achievement_id: String) -> Dictionary:
	var achievements = {
		"first_victory": {"name": "First Victory", "desc": "Win your first match", "reward_soft": 500},
		"builder": {"name": "Master Builder", "desc": "Build 100 structures", "reward_soft": 1000},
		"warrior": {"name": "Mushroom Warrior", "desc": "Defeat 1000 enemies", "reward_premium": 5},
		"daily_warrior": {"name": "Daily Warrior", "desc": "Claim daily rewards for 30 days", "reward_premium": 10},
		"level_10": {"name": "Growing Strong", "desc": "Reach level 10", "reward_soft": 2000},
		"level_50": {"name": "Mycelium Master", "desc": "Reach level 50", "reward_premium": 25},
		"social_butterfly": {"name": "Social Butterfly", "desc": "Add 10 friends", "reward_soft": 1500}
	}
	
	return achievements.get(achievement_id, {})

func connect_achievement_triggers():
	# Connect various game events to achievement progress
	connect("player_level_changed", _on_level_achievement_check)

func _on_level_achievement_check(level: int):
	if level >= 10 and not "level_10" in unlocked_achievements:
		unlock_achievement("level_10")
	if level >= 50 and not "level_50" in unlocked_achievements:
		unlock_achievement("level_50")

# === BATTLE PASS SYSTEM ===
func add_season_xp(amount: int):
	season_xp += amount
	
	# Check for season level up (every 1000 XP)
	var new_season_level = (season_xp / 1000) + 1
	
	if new_season_level > season_level:
		season_level = new_season_level
		unlock_season_reward(season_level)

func unlock_season_reward(level: int):
	var free_rewards = get_free_season_rewards()
	var premium_rewards = get_premium_season_rewards()
	
	if level <= free_rewards.size():
		var reward = free_rewards[level - 1]
		give_season_reward(reward)
	
	if season_premium and level <= premium_rewards.size():
		var reward = premium_rewards[level - 1]
		give_season_reward(reward)

func give_season_reward(reward: Dictionary):
	match reward.type:
		"currency":
			add_currency(reward.currency_type, reward.amount)
		"cosmetic":
			unlock_cosmetic(reward.cosmetic_id)

# === SOCIAL FEATURES ===
func add_friend(friend_id: String):
	if not friend_id in friend_list:
		friend_list.append(friend_id)
		
		if friend_list.size() >= 10:
			unlock_achievement("social_butterfly")
		
		save_game_data()

func join_guild(guild_id_param: String):
	guild_id = guild_id_param
	save_game_data()

# === ANALYTICS AND TRACKING ===
func track_event(event_name: String, parameters: Dictionary = {}):
	# In a real game, this would send to analytics service
	print("Analytics: ", event_name, " - ", parameters)

func start_session_tracking():
	track_event("session_start", {
		"player_level": player_level,
		"playtime": total_playtime,
		"version": "1.0.0"
	})

# === SAVE/LOAD SYSTEM ===
func save_game_data():
	var save_data = {
		"player_level": player_level,
		"player_xp": player_xp,
		"player_xp_to_next_level": player_xp_to_next_level,
		"soft_currency": soft_currency,
		"premium_currency": premium_currency,
		"prestige_currency": prestige_currency,
		"total_playtime": total_playtime,
		"games_played": games_played,
		"victories": victories,
		"buildings_built": buildings_built,
		"enemies_defeated": enemies_defeated,
		"last_daily_reward_claim": last_daily_reward_claim,
		"daily_streak": daily_streak,
		"daily_quests": daily_quests,
		"current_season": current_season,
		"season_level": season_level,
		"season_xp": season_xp,
		"season_premium": season_premium,
		"unlocked_achievements": unlocked_achievements,
		"achievement_progress": achievement_progress,
		"guild_id": guild_id,
		"friend_list": friend_list,
		"player_rating": player_rating,
		"settings": settings
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_game_data():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			player_level = save_data.get("player_level", 1)
			player_xp = save_data.get("player_xp", 0)
			player_xp_to_next_level = save_data.get("player_xp_to_next_level", 100)
			soft_currency = save_data.get("soft_currency", 1000)
			premium_currency = save_data.get("premium_currency", 0)
			prestige_currency = save_data.get("prestige_currency", 0)
			total_playtime = save_data.get("total_playtime", 0.0)
			games_played = save_data.get("games_played", 0)
			victories = save_data.get("victories", 0)
			buildings_built = save_data.get("buildings_built", 0)
			enemies_defeated = save_data.get("enemies_defeated", 0)
			last_daily_reward_claim = save_data.get("last_daily_reward_claim", "")
			daily_streak = save_data.get("daily_streak", 0)
			daily_quests = save_data.get("daily_quests", [])
			current_season = save_data.get("current_season", 1)
			season_level = save_data.get("season_level", 1)
			season_xp = save_data.get("season_xp", 0)
			season_premium = save_data.get("season_premium", false)
			unlocked_achievements = save_data.get("unlocked_achievements", [])
			achievement_progress = save_data.get("achievement_progress", {})
			guild_id = save_data.get("guild_id", "")
			friend_list = save_data.get("friend_list", [])
			player_rating = save_data.get("player_rating", 1000)
			settings = save_data.get("settings", settings)

# === UTILITY FUNCTIONS ===
func is_consecutive_day(last_date: String, current_date: String) -> bool:
	# Simple date comparison - in production, use proper date handling
	var last_parts = last_date.split("-")
	var current_parts = current_date.split("-")
	
	if last_parts.size() != 3 or current_parts.size() != 3:
		return false
	
	var last_day = int(last_parts[2])
	var current_day = int(current_parts[2])
	
	return current_day == last_day + 1

func show_level_up_popup(soft_reward: int, premium_reward: int):
	# This would show a celebratory popup - implement in UI
	print("LEVEL UP! Level ", player_level, " - Rewards: ", soft_reward, " spores, ", premium_reward, " crystals")

func get_free_season_rewards() -> Array:
	# Define free battle pass rewards
	return [
		{"type": "currency", "currency_type": "soft", "amount": 500},
		{"type": "cosmetic", "cosmetic_id": "mushroom_hat_1"},
		{"type": "currency", "currency_type": "soft", "amount": 750},
		{"type": "currency", "currency_type": "premium", "amount": 1},
		{"type": "cosmetic", "cosmetic_id": "spore_trail_1"}
	]

func get_premium_season_rewards() -> Array:
	# Define premium battle pass rewards
	return [
		{"type": "currency", "currency_type": "premium", "amount": 2},
		{"type": "cosmetic", "cosmetic_id": "golden_mushroom_hat"},
		{"type": "currency", "currency_type": "premium", "amount": 3},
		{"type": "cosmetic", "cosmetic_id": "legendary_spore_trail"},
		{"type": "currency", "currency_type": "premium", "amount": 5}
	]

func unlock_cosmetic(cosmetic_id: String):
	# Implement cosmetic unlocking system
	print("Unlocked cosmetic: ", cosmetic_id)