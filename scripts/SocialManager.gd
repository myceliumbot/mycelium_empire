extends Node

# Social Manager - handles all social features, guilds, tournaments, and competitive systems
signal friend_added(friend_id: String)
signal guild_joined(guild_id: String)
signal tournament_result(placement: int, rewards: Dictionary)
signal leaderboard_updated()

# Player social data
var friend_list: Array[Dictionary] = []
var friend_requests: Array[Dictionary] = []
var blocked_players: Array[String] = []

# Guild system
var current_guild: Dictionary = {}
var guild_members: Array[Dictionary] = []
var guild_chat_history: Array[Dictionary] = []

# Tournament system
var active_tournaments: Array[Dictionary] = []
var tournament_history: Array[Dictionary] = []
var seasonal_ranking: Dictionary = {}

# Leaderboards
var global_leaderboards: Dictionary = {}
var friend_leaderboards: Dictionary = {}
var guild_leaderboards: Dictionary = {}

# Competitive seasons
var current_season: Dictionary = {}
var player_ranking: Dictionary = {}

# Social features
var clan_wars: Array[Dictionary] = []
var community_challenges: Array[Dictionary] = []

func _ready():
	load_social_data()
	initialize_social_systems()
	
	# Connect to game events
	GameManager.connect("player_level_changed", _on_player_progress)
	
	# Set up periodic updates
	var timer = Timer.new()
	timer.wait_time = 60.0  # Update every minute
	timer.timeout.connect(_on_periodic_update)
	add_child(timer)
	timer.start()

func initialize_social_systems():
	setup_leaderboards()
	load_active_tournaments()
	check_seasonal_reset()

# === FRIEND SYSTEM ===
func send_friend_request(player_id: String, player_name: String) -> bool:
	if is_friend(player_id) or is_blocked(player_id):
		return false
	
	# In real implementation, this would send to server
	var request = {
		"id": generate_request_id(),
		"from_id": GameManager.player_id if GameManager.has_method("player_id") else "local_player",
		"to_id": player_id,
		"to_name": player_name,
		"timestamp": Time.get_unix_time_from_system(),
		"status": "pending"
	}
	
	# Simulate sending request
	simulate_friend_request_sent(request)
	return true

func accept_friend_request(request_id: String) -> bool:
	var request = find_friend_request(request_id)
	if not request:
		return false
	
	# Add as friend
	var friend_data = {
		"id": request.from_id,
		"name": request.get("from_name", "Unknown"),
		"level": 1,
		"last_online": Time.get_unix_time_from_system(),
		"status": "online",
		"mutual_friends": 0
	}
	
	friend_list.append(friend_data)
	friend_requests.erase(request)
	
	emit_signal("friend_added", request.from_id)
	
	# Send gifts to new friend
	send_friendship_gift(request.from_id)
	
	save_social_data()
	return true

func remove_friend(friend_id: String) -> bool:
	for i in range(friend_list.size()):
		if friend_list[i].id == friend_id:
			friend_list.remove_at(i)
			save_social_data()
			return true
	return false

func is_friend(player_id: String) -> bool:
	for friend in friend_list:
		if friend.id == player_id:
			return true
	return false

func block_player(player_id: String):
	if not player_id in blocked_players:
		blocked_players.append(player_id)
		remove_friend(player_id)
		save_social_data()

func is_blocked(player_id: String) -> bool:
	return player_id in blocked_players

func send_friendship_gift(friend_id: String):
	# Send welcome gift to new friends
	var gift = {
		"type": "currency",
		"currency_type": "soft",
		"amount": 500,
		"message": "Welcome to my friends list!"
	}
	
	# In real game, this would go through server
	print("Sent friendship gift to ", friend_id)

# === GUILD SYSTEM ===
func create_guild(guild_name: String, description: String) -> bool:
	if current_guild.has("id"):
		return false  # Already in guild
	
	var guild_cost = 1000  # Cost in soft currency
	if not GameManager.spend_currency("soft", guild_cost):
		return false
	
	var new_guild = {
		"id": generate_guild_id(),
		"name": guild_name,
		"description": description,
		"leader_id": GameManager.player_id if GameManager.has_method("player_id") else "local_player",
		"created_date": Time.get_unix_time_from_system(),
		"level": 1,
		"experience": 0,
		"member_count": 1,
		"max_members": 30,
		"trophies": 0,
		"settings": {
			"join_type": "invite_only",  # "open", "invite_only", "closed"
			"min_level": 1,
			"min_trophies": 0
		}
	}
	
	current_guild = new_guild
	join_guild_as_leader()
	
	GameManager.track_event("guild_created", {"guild_name": guild_name})
	save_social_data()
	return true

func join_guild(guild_id: String) -> bool:
	if current_guild.has("id"):
		return false  # Already in guild
	
	# Simulate guild lookup and join
	var guild_data = simulate_guild_lookup(guild_id)
	if not guild_data:
		return false
	
	current_guild = guild_data
	emit_signal("guild_joined", guild_id)
	
	# Add guild joining rewards
	GameManager.add_currency("soft", 200)
	
	save_social_data()
	return true

func leave_guild() -> bool:
	if not current_guild.has("id"):
		return false
	
	current_guild.clear()
	guild_members.clear()
	guild_chat_history.clear()
	
	save_social_data()
	return true

func contribute_to_guild(contribution_type: String, amount: int) -> bool:
	if not current_guild.has("id"):
		return false
	
	match contribution_type:
		"currency":
			if GameManager.spend_currency("soft", amount):
				current_guild.experience += amount / 10
				return true
		"resources":
			# Contribute resources to guild projects
			return true
	
	return false

func start_guild_war(target_guild_id: String) -> bool:
	if not current_guild.has("id"):
		return false
	
	var war_data = {
		"id": generate_war_id(),
		"attacker_guild": current_guild.id,
		"defender_guild": target_guild_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": 24 * 60 * 60,  # 24 hours
		"status": "active",
		"attacker_score": 0,
		"defender_score": 0
	}
	
	clan_wars.append(war_data)
	return true

# === TOURNAMENT SYSTEM ===
func join_tournament(tournament_id: String) -> bool:
	var tournament = find_tournament(tournament_id)
	if not tournament:
		return false
	
	# Check entry requirements
	if tournament.entry_fee > 0:
		var currency_type = tournament.get("entry_currency", "soft")
		if not GameManager.spend_currency(currency_type, tournament.entry_fee):
			return false
	
	# Add player to tournament
	tournament.participants.append({
		"player_id": GameManager.player_id if GameManager.has_method("player_id") else "local_player",
		"player_name": "Player",
		"score": 0,
		"matches_played": 0
	})
	
	GameManager.track_event("tournament_joined", {"tournament_id": tournament_id})
	return true

func create_weekly_tournaments():
	active_tournaments.clear()
	
	var tournament_templates = [
		{
			"id": "weekly_conquest",
			"name": "Weekly Conquest",
			"description": "Compete for the highest score in conquest matches",
			"type": "score_based",
			"duration": 7 * 24 * 60 * 60,  # 7 days
			"entry_fee": 0,
			"max_participants": 1000,
			"rewards": {
				"1": {"premium": 100, "soft": 5000},
				"2-10": {"premium": 50, "soft": 2000},
				"11-50": {"premium": 25, "soft": 1000},
				"51-100": {"soft": 500}
			}
		},
		{
			"id": "premium_championship",
			"name": "Premium Championship", 
			"description": "High stakes tournament for premium players",
			"type": "elimination",
			"duration": 3 * 24 * 60 * 60,  # 3 days
			"entry_fee": 10,
			"entry_currency": "premium",
			"max_participants": 64,
			"rewards": {
				"1": {"premium": 500, "cosmetic": "champion_crown"},
				"2": {"premium": 300, "cosmetic": "silver_badge"},
				"3-4": {"premium": 150, "cosmetic": "bronze_badge"}
			}
		}
	]
	
	for template in tournament_templates:
		var tournament = template.duplicate()
		tournament.start_time = Time.get_unix_time_from_system()
		tournament.end_time = tournament.start_time + tournament.duration
		tournament.participants = []
		tournament.status = "active"
		
		active_tournaments.append(tournament)

func end_tournament(tournament_id: String):
	var tournament = find_tournament(tournament_id)
	if not tournament:
		return
	
	tournament.status = "completed"
	
	# Calculate final rankings
	tournament.participants.sort_custom(func(a, b): return a.score > b.score)
	
	# Distribute rewards
	distribute_tournament_rewards(tournament)
	
	# Move to history
	tournament_history.append(tournament)
	
	# Remove from active tournaments
	for i in range(active_tournaments.size()):
		if active_tournaments[i].id == tournament_id:
			active_tournaments.remove_at(i)
			break

func distribute_tournament_rewards(tournament: Dictionary):
	for i in range(tournament.participants.size()):
		var participant = tournament.participants[i]
		var placement = i + 1
		var reward_key = get_reward_key_for_placement(placement, tournament.rewards)
		
		if reward_key in tournament.rewards:
			var rewards = tournament.rewards[reward_key]
			give_tournament_rewards(participant.player_id, rewards, placement)

func get_reward_key_for_placement(placement: int, rewards: Dictionary) -> String:
	# Find the appropriate reward tier
	for key in rewards.keys():
		if "-" in key:
			var parts = key.split("-")
			var min_place = int(parts[0])
			var max_place = int(parts[1])
			if placement >= min_place and placement <= max_place:
				return key
		elif str(placement) == key:
			return key
	return ""

func give_tournament_rewards(player_id: String, rewards: Dictionary, placement: int):
	# Give rewards to tournament participants
	if "premium" in rewards:
		GameManager.add_currency("premium", rewards.premium)
	if "soft" in rewards:
		GameManager.add_currency("soft", rewards.soft)
	if "cosmetic" in rewards:
		MonetizationManager.owned_cosmetics.append(rewards.cosmetic)
	
	emit_signal("tournament_result", placement, rewards)

# === LEADERBOARDS ===
func setup_leaderboards():
	global_leaderboards = {
		"level": [],
		"trophies": [],
		"guild_contribution": [],
		"tournament_wins": []
	}
	
	friend_leaderboards = {
		"level": [],
		"trophies": [],
		"weekly_score": []
	}

func update_leaderboard(board_type: String, score: int):
	var player_entry = {
		"player_id": GameManager.player_id if GameManager.has_method("player_id") else "local_player",
		"player_name": "Player",
		"score": score,
		"rank": 0
	}
	
	# Update appropriate leaderboard
	match board_type:
		"level":
			update_leaderboard_entry(global_leaderboards.level, player_entry)
			update_leaderboard_entry(friend_leaderboards.level, player_entry)
		"trophies":
			update_leaderboard_entry(global_leaderboards.trophies, player_entry)

func update_leaderboard_entry(leaderboard: Array, entry: Dictionary):
	# Remove existing entry
	for i in range(leaderboard.size()):
		if leaderboard[i].player_id == entry.player_id:
			leaderboard.remove_at(i)
			break
	
	# Add new entry
	leaderboard.append(entry)
	
	# Sort by score
	leaderboard.sort_custom(func(a, b): return a.score > b.score)
	
	# Update ranks
	for i in range(leaderboard.size()):
		leaderboard[i].rank = i + 1
	
	# Keep only top 100
	if leaderboard.size() > 100:
		leaderboard.resize(100)
	
	emit_signal("leaderboard_updated")

# === SEASONAL SYSTEM ===
func check_seasonal_reset():
	var current_time = Time.get_unix_time_from_system()
	var season_duration = 30 * 24 * 60 * 60  # 30 days
	
	if not current_season.has("start_time") or current_time >= current_season.start_time + season_duration:
		start_new_season()

func start_new_season():
	# End previous season
	if current_season.has("number"):
		end_season_rewards()
	
	# Start new season
	current_season = {
		"number": current_season.get("number", 0) + 1,
		"start_time": Time.get_unix_time_from_system(),
		"theme": get_seasonal_theme(),
		"special_events": generate_seasonal_events()
	}
	
	# Reset seasonal rankings
	seasonal_ranking.clear()
	
	# Create seasonal tournaments
	create_seasonal_tournaments()

func end_season_rewards():
	# Give rewards based on seasonal ranking
	var player_rank = seasonal_ranking.get("rank", 1000)
	
	if player_rank <= 100:
		var reward_crystals = max(100 - player_rank, 10)
		GameManager.add_currency("premium", reward_crystals)
	
	if player_rank <= 10:
		MonetizationManager.owned_cosmetics.append("seasonal_champion_" + str(current_season.number))

# === COMMUNITY CHALLENGES ===
func create_community_challenges():
	community_challenges = [
		{
			"id": "global_building_challenge",
			"name": "Global Building Challenge",
			"description": "Community goal: Build 1,000,000 structures together",
			"type": "community",
			"target": 1000000,
			"current_progress": 0,
			"duration": 7 * 24 * 60 * 60,  # 7 days
			"rewards": {
				"community": {"premium": 50},
				"individual": {"soft": 1000}
			}
		}
	]

func contribute_to_community_challenge(challenge_id: String, amount: int):
	for challenge in community_challenges:
		if challenge.id == challenge_id:
			challenge.current_progress += amount
			
			if challenge.current_progress >= challenge.target:
				complete_community_challenge(challenge)
			
			break

func complete_community_challenge(challenge: Dictionary):
	# Give rewards to all participants
	var individual_rewards = challenge.rewards.individual
	
	if "soft" in individual_rewards:
		GameManager.add_currency("soft", individual_rewards.soft)
	if "premium" in individual_rewards:
		GameManager.add_currency("premium", individual_rewards.premium)

# === UTILITY FUNCTIONS ===
func find_friend_request(request_id: String) -> Dictionary:
	for request in friend_requests:
		if request.id == request_id:
			return request
	return {}

func find_tournament(tournament_id: String) -> Dictionary:
	for tournament in active_tournaments:
		if tournament.id == tournament_id:
			return tournament
	return {}

func generate_request_id() -> String:
	return "req_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func generate_guild_id() -> String:
	return "guild_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func generate_war_id() -> String:
	return "war_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func simulate_guild_lookup(guild_id: String) -> Dictionary:
	# Simulate finding a guild
	return {
		"id": guild_id,
		"name": "Test Guild",
		"description": "A test guild",
		"level": 5,
		"member_count": 15,
		"trophies": 5000
	}

func simulate_friend_request_sent(request: Dictionary):
	# Simulate successful friend request
	print("Friend request sent to ", request.to_name)

func join_guild_as_leader():
	guild_members = [{
		"id": GameManager.player_id if GameManager.has_method("player_id") else "local_player",
		"name": "Player",
		"role": "leader",
		"contribution": 0,
		"join_date": Time.get_unix_time_from_system()
	}]

func get_seasonal_theme() -> String:
	var themes = ["Spring Growth", "Summer Bloom", "Autumn Harvest", "Winter Dormancy"]
	return themes[current_season.get("number", 1) % themes.size()]

func generate_seasonal_events() -> Array:
	return [
		{
			"name": "Double XP Weekend",
			"type": "xp_boost",
			"multiplier": 2.0,
			"duration": 48 * 60 * 60  # 48 hours
		}
	]

func create_seasonal_tournaments():
	# Create special seasonal tournaments
	pass

func _on_player_progress(level: int):
	update_leaderboard("level", level)

func _on_periodic_update():
	# Update friend statuses, tournament progress, etc.
	update_friend_statuses()
	check_tournament_endings()

func update_friend_statuses():
	# Simulate friend activity updates
	for friend in friend_list:
		friend.last_online = Time.get_unix_time_from_system() - randi() % (24 * 60 * 60)

func check_tournament_endings():
	var current_time = Time.get_unix_time_from_system()
	
	for tournament in active_tournaments:
		if current_time >= tournament.end_time:
			end_tournament(tournament.id)

# === SAVE/LOAD ===
func save_social_data():
	var save_data = {
		"friend_list": friend_list,
		"friend_requests": friend_requests,
		"blocked_players": blocked_players,
		"current_guild": current_guild,
		"tournament_history": tournament_history,
		"seasonal_ranking": seasonal_ranking,
		"current_season": current_season
	}
	
	var save_file = FileAccess.open("user://social.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_social_data():
	var save_file = FileAccess.open("user://social.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			friend_list = save_data.get("friend_list", [])
			friend_requests = save_data.get("friend_requests", [])
			blocked_players = save_data.get("blocked_players", [])
			current_guild = save_data.get("current_guild", {})
			tournament_history = save_data.get("tournament_history", [])
			seasonal_ranking = save_data.get("seasonal_ranking", {})
			current_season = save_data.get("current_season", {})