extends Node

# Monetization Manager - handles all premium purchases and monetization
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal ad_watched(reward_type: String, reward_amount: int)

# Store products
var store_products = {
	# Premium Currency Packs
	"crystal_pack_small": {
		"name": "Small Crystal Pack",
		"description": "100 Mycelium Crystals",
		"price": 0.99,
		"currency_type": "premium",
		"currency_amount": 100,
		"bonus_percentage": 0
	},
	"crystal_pack_medium": {
		"name": "Medium Crystal Pack", 
		"description": "550 Mycelium Crystals",
		"price": 4.99,
		"currency_type": "premium",
		"currency_amount": 550,
		"bonus_percentage": 10  # 10% bonus crystals
	},
	"crystal_pack_large": {
		"name": "Large Crystal Pack",
		"description": "1200 Mycelium Crystals",
		"price": 9.99,
		"currency_type": "premium", 
		"currency_amount": 1200,
		"bonus_percentage": 20  # 20% bonus crystals
	},
	"crystal_pack_mega": {
		"name": "Mega Crystal Pack",
		"description": "3000 Mycelium Crystals",
		"price": 19.99,
		"currency_type": "premium",
		"currency_amount": 3000,
		"bonus_percentage": 50  # 50% bonus crystals
	},
	
	# Battle Pass
	"season_pass": {
		"name": "Mycelium Season Pass",
		"description": "Unlock premium rewards for the current season",
		"price": 9.99,
		"type": "season_pass"
	},
	
	# Premium Subscriptions
	"vip_monthly": {
		"name": "VIP Membership (Monthly)",
		"description": "2x XP, daily crystals, exclusive content",
		"price": 4.99,
		"type": "subscription",
		"duration": "monthly"
	},
	"vip_yearly": {
		"name": "VIP Membership (Yearly)", 
		"description": "2x XP, daily crystals, exclusive content",
		"price": 39.99,
		"type": "subscription",
		"duration": "yearly"
	},
	
	# Starter Packs
	"starter_pack": {
		"name": "Mushroom Starter Pack",
		"description": "500 crystals + exclusive skin + 7-day XP boost",
		"price": 4.99,
		"type": "starter_pack",
		"currency_amount": 500,
		"includes": ["exclusive_starter_skin", "xp_boost_7d"]
	},
	
	# Remove Ads
	"remove_ads": {
		"name": "Remove Ads",
		"description": "Remove all advertisements permanently",
		"price": 2.99,
		"type": "remove_ads"
	}
}

# Premium features and cosmetics
var cosmetic_store = {
	# Mushroom Skins
	"golden_mushroom": {
		"name": "Golden Mushroom",
		"price": 500,
		"currency": "premium",
		"type": "building_skin",
		"rarity": "legendary"
	},
	"crystal_mushroom": {
		"name": "Crystal Mushroom",
		"price": 250,
		"currency": "premium", 
		"type": "building_skin",
		"rarity": "epic"
	},
	"rainbow_spores": {
		"name": "Rainbow Spores",
		"price": 150,
		"currency": "premium",
		"type": "particle_effect",
		"rarity": "rare"
	},
	
	# Unit Skins
	"armored_hyphae": {
		"name": "Armored Hyphae",
		"price": 300,
		"currency": "premium",
		"type": "unit_skin",
		"rarity": "epic"
	},
	
	# Exclusive Buildings
	"ancient_mycelium_tower": {
		"name": "Ancient Mycelium Tower",
		"price": 1000,
		"currency": "premium",
		"type": "exclusive_building",
		"rarity": "legendary",
		"stats_bonus": {"damage": 25, "range": 15}
	}
}

# Player premium status
var has_vip: bool = false
var vip_expires: int = 0
var has_removed_ads: bool = false
var owned_cosmetics: Array[String] = []

# Ad system
var ads_watched_today: int = 0
var max_daily_ads: int = 10
var ad_rewards = {
	"currency": {"type": "soft", "amount": 100},
	"xp": {"amount": 50},
	"crystal": {"type": "premium", "amount": 1}  # Rare reward
}

func _ready():
	load_monetization_data()
	check_vip_status()

# === PURCHASE SYSTEM ===
func purchase_product(product_id: String):
	if not product_id in store_products:
		emit_signal("purchase_failed", product_id, "Product not found")
		return
	
	var product = store_products[product_id]
	
	# In a real implementation, this would integrate with platform stores
	# For now, simulate purchase for testing
	simulate_purchase(product_id, product)

func simulate_purchase(product_id: String, product: Dictionary):
	# Simulate purchase processing
	await get_tree().create_timer(1.0).timeout
	
	# Process purchase
	match product.get("type", "currency"):
		"currency", "crystal_pack":
			process_currency_purchase(product)
		"season_pass":
			process_season_pass_purchase()
		"subscription":
			process_subscription_purchase(product)
		"starter_pack":
			process_starter_pack_purchase(product)
		"remove_ads":
			process_remove_ads_purchase()
	
	emit_signal("purchase_completed", product_id)
	save_monetization_data()
	
	# Track purchase for analytics
	GameManager.track_event("purchase_completed", {
		"product_id": product_id,
		"price": product.price,
		"currency_received": product.get("currency_amount", 0)
	})

func process_currency_purchase(product: Dictionary):
	var base_amount = product.currency_amount
	var bonus_percentage = product.get("bonus_percentage", 0)
	var bonus_amount = int(base_amount * bonus_percentage / 100.0)
	var total_amount = base_amount + bonus_amount
	
	GameManager.add_currency(product.currency_type, total_amount)

func process_season_pass_purchase():
	GameManager.season_premium = true

func process_subscription_purchase(product: Dictionary):
	has_vip = true
	var duration_seconds = 30 * 24 * 60 * 60  # 30 days
	if product.duration == "yearly":
		duration_seconds = 365 * 24 * 60 * 60  # 365 days
	
	vip_expires = Time.get_unix_time_from_system() + duration_seconds

func process_starter_pack_purchase(product: Dictionary):
	# Give crystals
	GameManager.add_currency("premium", product.currency_amount)
	
	# Unlock included items
	for item in product.get("includes", []):
		unlock_premium_item(item)

func process_remove_ads_purchase():
	has_removed_ads = true

# === COSMETIC STORE ===
func purchase_cosmetic(cosmetic_id: String) -> bool:
	if not cosmetic_id in cosmetic_store:
		return false
	
	var cosmetic = cosmetic_store[cosmetic_id]
	var currency_type = cosmetic.currency
	var price = cosmetic.price
	
	if GameManager.spend_currency(currency_type, price):
		owned_cosmetics.append(cosmetic_id)
		save_monetization_data()
		
		GameManager.track_event("cosmetic_purchased", {
			"cosmetic_id": cosmetic_id,
			"price": price,
			"currency": currency_type
		})
		
		return true
	
	return false

func owns_cosmetic(cosmetic_id: String) -> bool:
	return cosmetic_id in owned_cosmetics

# === VIP SYSTEM ===
func check_vip_status():
	if has_vip and vip_expires > 0:
		var current_time = Time.get_unix_time_from_system()
		if current_time >= vip_expires:
			has_vip = false
			vip_expires = 0
			save_monetization_data()

func get_vip_multiplier() -> float:
	return 2.0 if has_vip else 1.0

func give_daily_vip_rewards():
	if has_vip:
		GameManager.add_currency("premium", 5)  # 5 crystals daily for VIP
		GameManager.add_currency("soft", 500)   # Bonus soft currency

# === AD SYSTEM ===
func can_watch_ad() -> bool:
	return ads_watched_today < max_daily_ads and not has_removed_ads

func watch_rewarded_ad(reward_type: String = "currency"):
	if not can_watch_ad():
		return false
	
	# Simulate ad watching
	show_ad_simulation(reward_type)
	return true

func show_ad_simulation(reward_type: String):
	# In real implementation, this would show actual ads
	print("Showing rewarded ad...")
	await get_tree().create_timer(2.0).timeout  # Simulate ad duration
	
	ads_watched_today += 1
	process_ad_reward(reward_type)

func process_ad_reward(reward_type: String):
	if not reward_type in ad_rewards:
		reward_type = "currency"
	
	var reward = ad_rewards[reward_type]
	
	match reward_type:
		"currency":
			GameManager.add_currency(reward.type, reward.amount)
		"xp":
			GameManager.add_xp(reward.amount, "ad_reward")
		"crystal":
			# Rare crystal reward (10% chance)
			if randf() < 0.1:
				GameManager.add_currency(reward.type, reward.amount)
				reward_type = "crystal"
			else:
				# Fallback to currency
				GameManager.add_currency("soft", 100)
				reward_type = "currency"
	
	emit_signal("ad_watched", reward_type, reward.get("amount", 100))
	
	GameManager.track_event("ad_watched", {
		"reward_type": reward_type,
		"daily_count": ads_watched_today
	})
	
	save_monetization_data()

# === LOOT BOXES / GACHA SYSTEM ===
var loot_box_types = {
	"basic_crate": {
		"name": "Basic Spore Crate",
		"price": 50,
		"currency": "soft",
		"rewards": [
			{"type": "currency", "currency_type": "soft", "amount": 100, "weight": 50},
			{"type": "currency", "currency_type": "premium", "amount": 1, "weight": 20},
			{"type": "cosmetic", "cosmetic_id": "rainbow_spores", "weight": 5},
			{"type": "xp", "amount": 200, "weight": 25}
		]
	},
	"premium_crate": {
		"name": "Premium Crystal Crate",
		"price": 10,
		"currency": "premium",
		"rewards": [
			{"type": "currency", "currency_type": "premium", "amount": 15, "weight": 40},
			{"type": "cosmetic", "cosmetic_id": "crystal_mushroom", "weight": 15},
			{"type": "cosmetic", "cosmetic_id": "golden_mushroom", "weight": 5},
			{"type": "cosmetic", "cosmetic_id": "armored_hyphae", "weight": 20},
			{"type": "currency", "currency_type": "soft", "amount": 1000, "weight": 20}
		]
	}
}

func open_loot_box(box_type: String) -> Dictionary:
	if not box_type in loot_box_types:
		return {}
	
	var box = loot_box_types[box_type]
	
	# Check if player can afford
	if not GameManager.spend_currency(box.currency, box.price):
		return {}
	
	# Roll for reward
	var reward = roll_loot_box_reward(box.rewards)
	process_loot_box_reward(reward)
	
	GameManager.track_event("loot_box_opened", {
		"box_type": box_type,
		"reward_type": reward.type,
		"reward_value": reward.get("amount", 1)
	})
	
	return reward

func roll_loot_box_reward(rewards: Array) -> Dictionary:
	var total_weight = 0
	for reward in rewards:
		total_weight += reward.weight
	
	var roll = randf() * total_weight
	var current_weight = 0
	
	for reward in rewards:
		current_weight += reward.weight
		if roll <= current_weight:
			return reward
	
	return rewards[0]  # Fallback

func process_loot_box_reward(reward: Dictionary):
	match reward.type:
		"currency":
			GameManager.add_currency(reward.currency_type, reward.amount)
		"cosmetic":
			if not owns_cosmetic(reward.cosmetic_id):
				owned_cosmetics.append(reward.cosmetic_id)
		"xp":
			GameManager.add_xp(reward.amount, "loot_box")

# === SPECIAL OFFERS ===
var active_offers: Array[Dictionary] = []

func generate_daily_offers():
	active_offers.clear()
	
	# Generate 3 random daily offers
	var offer_templates = [
		{
			"id": "double_xp",
			"name": "Double XP Boost",
			"description": "2x XP for 4 hours",
			"price": 2,
			"currency": "premium",
			"discount": 50
		},
		{
			"id": "resource_bundle",
			"name": "Resource Bundle",
			"description": "1000 spores + 100 crystals",
			"original_price": 5,
			"price": 3,
			"currency": "premium",
			"discount": 40
		},
		{
			"id": "cosmetic_deal",
			"name": "Cosmetic Flash Sale",
			"description": "50% off premium cosmetics",
			"discount": 50,
			"duration": 24 * 60 * 60  # 24 hours
		}
	]
	
	offer_templates.shuffle()
	for i in range(min(3, offer_templates.size())):
		var offer = offer_templates[i].duplicate()
		offer.expires = Time.get_unix_time_from_system() + (24 * 60 * 60)  # 24 hours
		active_offers.append(offer)

# === SAVE/LOAD ===
func save_monetization_data():
	var save_data = {
		"has_vip": has_vip,
		"vip_expires": vip_expires,
		"has_removed_ads": has_removed_ads,
		"owned_cosmetics": owned_cosmetics,
		"ads_watched_today": ads_watched_today,
		"active_offers": active_offers
	}
	
	var save_file = FileAccess.open("user://monetization.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_monetization_data():
	var save_file = FileAccess.open("user://monetization.save", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			
			has_vip = save_data.get("has_vip", false)
			vip_expires = save_data.get("vip_expires", 0)
			has_removed_ads = save_data.get("has_removed_ads", false)
			owned_cosmetics = save_data.get("owned_cosmetics", [])
			ads_watched_today = save_data.get("ads_watched_today", 0)
			active_offers = save_data.get("active_offers", [])

func unlock_premium_item(item_id: String):
	match item_id:
		"exclusive_starter_skin":
			owned_cosmetics.append("starter_exclusive_skin")
		"xp_boost_7d":
			# Activate 7-day XP boost
			pass

# === ANALYTICS HELPERS ===
func get_monetization_stats() -> Dictionary:
	return {
		"has_vip": has_vip,
		"owned_cosmetics_count": owned_cosmetics.size(),
		"ads_watched_today": ads_watched_today,
		"total_premium_currency": GameManager.premium_currency
	}