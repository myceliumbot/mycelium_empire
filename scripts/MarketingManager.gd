extends Node

# Marketing Manager - handles viral features, referrals, sharing, and growth hacking
signal referral_completed(referrer_id: String, referee_id: String)
signal content_shared(platform: String, content_type: String)
signal viral_milestone_reached(milestone: String, count: int)

# Referral system
var referral_code: String
var referred_by: String = ""
var referrals_made: Array[Dictionary] = []
var referral_rewards_claimed: Array[String] = []

# Sharing and viral features
var share_count: Dictionary = {}
var viral_content_templates: Dictionary = {}
var screenshot_sharing: Dictionary = {}

# Influencer and streaming features
var streaming_integration: Dictionary = {}
var content_creator_rewards: Dictionary = {}

# Growth campaigns
var active_campaigns: Array[Dictionary] = []
var campaign_participation: Dictionary = {}

# User-generated content
var ugc_submissions: Array[Dictionary] = []
var featured_ugc: Array[Dictionary] = []

# Viral mechanics
var viral_challenges: Array[Dictionary] = []
var community_competitions: Array[Dictionary] = []

func _ready():
	initialize_marketing_systems()
	setup_referral_system()
	create_viral_content_templates()
	load_marketing_data()

func initialize_marketing_systems():
	share_count = {
		"twitter": 0,
		"facebook": 0,
		"instagram": 0,
		"tiktok": 0,
		"youtube": 0,
		"discord": 0,
		"reddit": 0
	}
	
	setup_growth_campaigns()

# === REFERRAL SYSTEM ===
func setup_referral_system():
	if referral_code == "":
		referral_code = generate_referral_code()

func generate_referral_code() -> String:
	var player_id = AnalyticsManager.get_player_id()
	var hash_value = hash(player_id)
	var code_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	
	for i in range(6):
		code += code_chars[abs(hash_value + i) % code_chars.length()]
	
	return code

func use_referral_code(code: String) -> bool:
	if referred_by != "":
		return false  # Already used a referral code
	
	if code == referral_code:
		return false  # Can't refer yourself
	
	# Validate referral code (in production, check with server)
	if validate_referral_code(code):
		referred_by = code
		
		# Give rewards to both referrer and referee
		give_referral_rewards("referee")
		notify_referrer(code)
		
		AnalyticsManager.track_event("referral_used", {
			"referral_code": code,
			"referee_id": AnalyticsManager.get_player_id()
		})
		
		return true
	
	return false

func validate_referral_code(code: String) -> bool:
	# In production, this would validate against server
	# For demo, accept any 6-character alphanumeric code
	return code.length() == 6 and code.is_valid_identifier()

func give_referral_rewards(recipient_type: String):
	match recipient_type:
		"referee":
			# New player rewards
			GameManager.add_currency("soft", 2000)
			GameManager.add_currency("premium", 10)
			GameManager.add_xp(500, "referral_bonus")
			
			UIManager.show_notification(
				"Welcome Bonus!",
				"Thanks for joining through a friend! Enjoy your rewards!",
				"referral",
				5.0
			)
		
		"referrer":
			# Existing player rewards
			GameManager.add_currency("soft", 1500)
			GameManager.add_currency("premium", 5)
			
			UIManager.show_notification(
				"Referral Success!",
				"Your friend joined! Here's your reward!",
				"referral",
				4.0
			)

func notify_referrer(referral_code: String):
	# In production, notify the referrer through server
	print("Notifying referrer of successful referral: ", referral_code)

func track_referral_milestone():
	var referral_count = referrals_made.size()
	
	match referral_count:
		5:
			unlock_referral_milestone("social_connector", {"premium": 25, "cosmetic": "referral_badge_bronze"})
		10:
			unlock_referral_milestone("community_builder", {"premium": 50, "cosmetic": "referral_badge_silver"})
		25:
			unlock_referral_milestone("viral_champion", {"premium": 100, "cosmetic": "referral_badge_gold"})
		50:
			unlock_referral_milestone("growth_master", {"premium": 250, "cosmetic": "legendary_referral_crown"})

func unlock_referral_milestone(milestone_id: String, rewards: Dictionary):
	if milestone_id in referral_rewards_claimed:
		return
	
	referral_rewards_claimed.append(milestone_id)
	
	# Give rewards
	if "premium" in rewards:
		GameManager.add_currency("premium", rewards.premium)
	if "soft" in rewards:
		GameManager.add_currency("soft", rewards.soft)
	if "cosmetic" in rewards:
		MonetizationManager.owned_cosmetics.append(rewards.cosmetic)
	
	emit_signal("viral_milestone_reached", milestone_id, referrals_made.size())
	
	UIManager.show_notification(
		"Referral Milestone!",
		"You've reached " + milestone_id.replace("_", " ").capitalize() + "!",
		"milestone",
		6.0
	)

# === SHARING SYSTEM ===
func create_viral_content_templates():
	viral_content_templates = {
		"achievement_share": {
			"template": "Just unlocked '{achievement_name}' in Mycelium Empire! 🍄 Can you beat my score?",
			"hashtags": ["#MyceliumEmpire", "#MushroomGame", "#Gaming", "#Achievement"],
			"image_type": "achievement_screenshot"
		},
		"level_up_share": {
			"template": "Level {level} reached in Mycelium Empire! 🚀 My mushroom kingdom is growing strong! 💪",
			"hashtags": ["#MyceliumEmpire", "#LevelUp", "#Gaming", "#Progress"],
			"image_type": "level_screenshot"
		},
		"epic_victory_share": {
			"template": "Epic victory in Mycelium Empire! 🏆 Defeated {enemies_defeated} enemies and built {buildings_built} structures!",
			"hashtags": ["#MyceliumEmpire", "#Victory", "#RTS", "#Gaming"],
			"image_type": "victory_screenshot"
		},
		"rare_discovery_share": {
			"template": "Found a legendary {item_name} in Mycelium Empire! 🌟 This is going to change everything!",
			"hashtags": ["#MyceliumEmpire", "#RareFind", "#Gaming", "#Legendary"],
			"image_type": "discovery_screenshot"
		},
		"guild_achievement_share": {
			"template": "Our guild '{guild_name}' just conquered the leaderboards! 👑 Join us in Mycelium Empire!",
			"hashtags": ["#MyceliumEmpire", "#GuildPower", "#Teamwork", "#Gaming"],
			"image_type": "guild_screenshot"
		}
	}

func share_content(content_type: String, platform: String, custom_data: Dictionary = {}) -> bool:
	if not content_type in viral_content_templates:
		return false
	
	var template = viral_content_templates[content_type]
	var share_text = create_share_text(template, custom_data)
	var share_image = create_share_image(template.image_type, custom_data)
	
	# Execute share (in production, this would use platform APIs)
	execute_share(platform, share_text, share_image)
	
	# Track sharing
	track_share(platform, content_type)
	
	# Give sharing rewards
	give_sharing_rewards(platform, content_type)
	
	return true

func create_share_text(template: Dictionary, data: Dictionary) -> String:
	var text = template.template
	
	# Replace placeholders with actual data
	for key in data.keys():
		text = text.replace("{" + key + "}", str(data[key]))
	
	# Add hashtags
	var hashtag_string = ""
	for hashtag in template.hashtags:
		hashtag_string += hashtag + " "
	
	text += "\n\n" + hashtag_string
	
	# Add referral code
	text += "\n\nUse my code: " + referral_code + " for bonus rewards!"
	
	return text

func create_share_image(image_type: String, data: Dictionary) -> String:
	# In production, this would generate custom share images
	match image_type:
		"achievement_screenshot":
			return capture_achievement_screenshot(data)
		"level_screenshot":
			return capture_level_screenshot(data)
		"victory_screenshot":
			return capture_victory_screenshot(data)
		"discovery_screenshot":
			return capture_discovery_screenshot(data)
		"guild_screenshot":
			return capture_guild_screenshot(data)
	
	return ""

func execute_share(platform: String, text: String, image_path: String):
	# In production, integrate with platform sharing APIs
	match platform:
		"twitter":
			share_to_twitter(text, image_path)
		"facebook":
			share_to_facebook(text, image_path)
		"instagram":
			share_to_instagram(text, image_path)
		"tiktok":
			share_to_tiktok(text, image_path)
		"discord":
			share_to_discord(text, image_path)
		"reddit":
			share_to_reddit(text, image_path)
	
	print("Shared to ", platform, ": ", text)

func track_share(platform: String, content_type: String):
	share_count[platform] += 1
	
	AnalyticsManager.track_event("content_shared", {
		"platform": platform,
		"content_type": content_type,
		"total_shares": get_total_shares()
	})
	
	emit_signal("content_shared", platform, content_type)
	
	# Check for sharing milestones
	check_sharing_milestones()

func give_sharing_rewards(platform: String, content_type: String):
	var base_reward = 100
	var premium_reward = 0
	
	# Platform-specific bonuses
	match platform:
		"twitter", "tiktok":
			premium_reward = 1  # Higher reach platforms get premium currency
		"instagram", "youtube":
			premium_reward = 2
	
	# Content-specific bonuses
	match content_type:
		"epic_victory_share", "rare_discovery_share":
			base_reward *= 2
		"guild_achievement_share":
			base_reward *= 3
			premium_reward += 1
	
	GameManager.add_currency("soft", base_reward)
	if premium_reward > 0:
		GameManager.add_currency("premium", premium_reward)
	
	UIManager.show_notification(
		"Sharing Reward!",
		"Thanks for sharing! +" + str(base_reward) + " spores" + (" +" + str(premium_reward) + " crystals" if premium_reward > 0 else ""),
		"share_reward",
		3.0
	)

# === VIRAL CHALLENGES ===
func create_viral_challenge(challenge_data: Dictionary) -> String:
	var challenge = {
		"id": generate_challenge_id(),
		"name": challenge_data.name,
		"description": challenge_data.description,
		"hashtag": challenge_data.hashtag,
		"requirements": challenge_data.requirements,
		"rewards": challenge_data.rewards,
		"duration": challenge_data.get("duration", 7 * 24 * 60 * 60),  # 7 days default
		"start_time": Time.get_unix_time_from_system(),
		"participants": [],
		"submissions": []
	}
	
	viral_challenges.append(challenge)
	
	# Announce challenge
	announce_viral_challenge(challenge)
	
	return challenge.id

func announce_viral_challenge(challenge: Dictionary):
	UIManager.show_notification(
		"Viral Challenge!",
		challenge.name + " - Share your best moments with " + challenge.hashtag + "!",
		"viral_challenge",
		8.0
	)
	
	# Auto-share challenge announcement
	var share_data = {
		"challenge_name": challenge.name,
		"hashtag": challenge.hashtag,
		"rewards": str(challenge.rewards.get("premium", 0)) + " crystals"
	}
	
	var challenge_text = "New viral challenge in Mycelium Empire: {challenge_name}! 🏆\n\nJoin the fun with {hashtag} and win {rewards}!\n\nUse my code: " + referral_code
	challenge_text = challenge_text.format(share_data)
	
	# Suggest sharing to players
	show_challenge_share_prompt(challenge_text)

func show_challenge_share_prompt(text: String):
	# Show popup asking player if they want to share the challenge
	UIManager.show_notification(
		"Share Challenge?",
		"Want to invite friends to this challenge?",
		"share_prompt",
		5.0
	)

# === STREAMING INTEGRATION ===
func setup_streaming_features():
	streaming_integration = {
		"twitch_enabled": false,
		"youtube_enabled": false,
		"obs_integration": false,
		"stream_overlays": [],
		"viewer_rewards": true
	}

func enable_streaming_mode():
	# Enable special streaming features
	streaming_integration.obs_integration = true
	
	# Add streaming UI elements
	add_streaming_overlays()
	
	# Enable viewer interaction features
	setup_viewer_rewards()

func add_streaming_overlays():
	# Add overlays for streamers (follower count, donations, etc.)
	var overlays = [
		"current_level_overlay",
		"achievement_popup_overlay",
		"viewer_challenge_overlay",
		"donation_goal_overlay"
	]
	
	streaming_integration.stream_overlays = overlays

func setup_viewer_rewards():
	# Allow viewers to influence gameplay
	content_creator_rewards = {
		"follower_milestone_rewards": {
			"100": {"premium": 10, "cosmetic": "streamer_badge_bronze"},
			"500": {"premium": 25, "cosmetic": "streamer_badge_silver"},
			"1000": {"premium": 50, "cosmetic": "streamer_badge_gold"}
		},
		"viewer_interaction_rewards": {
			"per_new_follower": {"soft": 100},
			"per_donation": {"premium": 1},
			"per_subscriber": {"premium": 5}
		}
	}

# === USER-GENERATED CONTENT ===
func submit_ugc(content_type: String, content_data: Dictionary) -> String:
	var submission = {
		"id": generate_ugc_id(),
		"type": content_type,  # "screenshot", "video", "build", "strategy"
		"data": content_data,
		"player_id": AnalyticsManager.get_player_id(),
		"submission_time": Time.get_unix_time_from_system(),
		"votes": 0,
		"featured": false
	}
	
	ugc_submissions.append(submission)
	
	# Give submission reward
	GameManager.add_currency("soft", 200)
	GameManager.add_xp(50, "ugc_submission")
	
	AnalyticsManager.track_event("ugc_submitted", {
		"content_type": content_type,
		"player_level": GameManager.player_level
	})
	
	return submission.id

func feature_ugc(submission_id: String) -> bool:
	var submission = find_ugc_submission(submission_id)
	if not submission:
		return false
	
	submission.featured = true
	featured_ugc.append(submission)
	
	# Give featuring rewards
	GameManager.add_currency("premium", 10)
	GameManager.add_currency("soft", 1000)
	
	UIManager.show_notification(
		"Content Featured!",
		"Your content was featured! Enjoy the rewards!",
		"featured_content",
		5.0
	)
	
	return true

# === GROWTH CAMPAIGNS ===
func setup_growth_campaigns():
	active_campaigns = [
		{
			"name": "Bring a Friend Week",
			"description": "Invite friends and get double referral rewards!",
			"type": "referral_boost",
			"multiplier": 2.0,
			"duration": 7 * 24 * 60 * 60,  # 7 days
			"start_time": Time.get_unix_time_from_system()
		},
		{
			"name": "Social Media Blitz",
			"description": "Share on 3 different platforms for bonus rewards!",
			"type": "sharing_challenge",
			"target": 3,
			"rewards": {"premium": 15, "soft": 2000},
			"duration": 3 * 24 * 60 * 60,  # 3 days
			"start_time": Time.get_unix_time_from_system() + (24 * 60 * 60)  # Start tomorrow
		}
	]

func participate_in_campaign(campaign_name: String) -> bool:
	var campaign = find_campaign(campaign_name)
	if not campaign:
		return false
	
	if not campaign_name in campaign_participation:
		campaign_participation[campaign_name] = {
			"joined": true,
			"progress": 0,
			"completed": false
		}
		
		return true
	
	return false

# === SCREENSHOT AND MEDIA SHARING ===
func capture_achievement_screenshot(data: Dictionary) -> String:
	# Generate achievement screenshot
	var screenshot_path = "user://screenshots/achievement_" + str(Time.get_unix_time_from_system()) + ".png"
	
	# In production, capture actual screenshot with achievement overlay
	print("Capturing achievement screenshot: ", data.get("achievement_name", "Unknown"))
	
	return screenshot_path

func capture_level_screenshot(data: Dictionary) -> String:
	var screenshot_path = "user://screenshots/level_" + str(data.get("level", 1)) + "_" + str(Time.get_unix_time_from_system()) + ".png"
	
	# Capture level up moment
	print("Capturing level screenshot for level: ", data.get("level", 1))
	
	return screenshot_path

func capture_victory_screenshot(data: Dictionary) -> String:
	var screenshot_path = "user://screenshots/victory_" + str(Time.get_unix_time_from_system()) + ".png"
	
	# Capture victory screen with stats
	print("Capturing victory screenshot")
	
	return screenshot_path

func capture_discovery_screenshot(data: Dictionary) -> String:
	var screenshot_path = "user://screenshots/discovery_" + str(Time.get_unix_time_from_system()) + ".png"
	
	# Capture rare item discovery
	print("Capturing discovery screenshot: ", data.get("item_name", "Unknown"))
	
	return screenshot_path

func capture_guild_screenshot(data: Dictionary) -> String:
	var screenshot_path = "user://screenshots/guild_" + str(Time.get_unix_time_from_system()) + ".png"
	
	# Capture guild achievement
	print("Capturing guild screenshot: ", data.get("guild_name", "Unknown"))
	
	return screenshot_path

# === PLATFORM-SPECIFIC SHARING ===
func share_to_twitter(text: String, image_path: String):
	# Twitter API integration
	print("Sharing to Twitter: ", text)

func share_to_facebook(text: String, image_path: String):
	# Facebook API integration
	print("Sharing to Facebook: ", text)

func share_to_instagram(text: String, image_path: String):
	# Instagram API integration
	print("Sharing to Instagram: ", text)

func share_to_tiktok(text: String, image_path: String):
	# TikTok API integration
	print("Sharing to TikTok: ", text)

func share_to_discord(text: String, image_path: String):
	# Discord webhook integration
	print("Sharing to Discord: ", text)

func share_to_reddit(text: String, image_path: String):
	# Reddit API integration
	print("Sharing to Reddit: ", text)

# === UTILITY FUNCTIONS ===
func get_total_shares() -> int:
	var total = 0
	for count in share_count.values():
		total += count
	return total

func check_sharing_milestones():
	var total_shares = get_total_shares()
	
	match total_shares:
		5:
			unlock_sharing_milestone("social_starter", {"soft": 1000})
		25:
			unlock_sharing_milestone("content_creator", {"premium": 10, "cosmetic": "creator_badge"})
		100:
			unlock_sharing_milestone("viral_master", {"premium": 50, "cosmetic": "viral_crown"})

func unlock_sharing_milestone(milestone_id: String, rewards: Dictionary):
	# Similar to referral milestones
	GameManager.unlock_achievement(milestone_id)
	
	for reward_type in rewards.keys():
		match reward_type:
			"soft", "premium":
				GameManager.add_currency(reward_type, rewards[reward_type])
			"cosmetic":
				MonetizationManager.owned_cosmetics.append(rewards[reward_type])

func generate_challenge_id() -> String:
	return "challenge_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func generate_ugc_id() -> String:
	return "ugc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func find_ugc_submission(submission_id: String) -> Dictionary:
	for submission in ugc_submissions:
		if submission.id == submission_id:
			return submission
	return {}

func find_campaign(campaign_name: String) -> Dictionary:
	for campaign in active_campaigns:
		if campaign.name == campaign_name:
			return campaign
	return {}

# === SAVE/LOAD ===
func save_marketing_data():
	var save_data = {
		"referral_code": referral_code,
		"referred_by": referred_by,
		"referrals_made": referrals_made,
		"referral_rewards_claimed": referral_rewards_claimed,
		"share_count": share_count,
		"ugc_submissions": ugc_submissions,
		"campaign_participation": campaign_participation,
		"streaming_integration": streaming_integration
	}
	
	var save_file = FileAccess.open("user://marketing.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_marketing_data():
	var save_file = FileAccess.open("user://marketing.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			referral_code = save_data.get("referral_code", generate_referral_code())
			referred_by = save_data.get("referred_by", "")
			referrals_made = save_data.get("referrals_made", [])
			referral_rewards_claimed = save_data.get("referral_rewards_claimed", [])
			share_count = save_data.get("share_count", share_count)
			ugc_submissions = save_data.get("ugc_submissions", [])
			campaign_participation = save_data.get("campaign_participation", {})
			streaming_integration = save_data.get("streaming_integration", streaming_integration)