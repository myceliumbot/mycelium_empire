extends Control

# UI Manager - handles all UI interactions and addictive design patterns
signal ui_action(action: String, data: Dictionary)

# UI References
@onready var main_hud: Control
@onready var currency_display: Control
@onready var level_progress_bar: ProgressBar
@onready var daily_reward_popup: Control
@onready var achievement_popup: Control
@onready var store_panel: Control
@onready var battle_pass_panel: Control

# Notification system
var notification_queue: Array[Dictionary] = []
var is_showing_notification: bool = false

# Popup management
var popup_stack: Array[Control] = []

# Addictive UI patterns
var celebration_effects: Array[Node] = []
var screen_shake_tween: Tween
var pulse_effects: Dictionary = {}

func _ready():
	setup_ui_connections()
	setup_celebration_effects()
	
	# Connect to game manager signals
	GameManager.connect("player_level_changed", _on_player_level_changed)
	GameManager.connect("currency_changed", _on_currency_changed)
	GameManager.connect("achievement_unlocked", _on_achievement_unlocked)
	GameManager.connect("daily_reward_available", _on_daily_reward_available)
	
	# Connect to monetization signals
	MonetizationManager.connect("purchase_completed", _on_purchase_completed)
	MonetizationManager.connect("ad_watched", _on_ad_watched)
	
	update_all_displays()

func setup_ui_connections():
	# Set up button connections and UI elements
	pass

func setup_celebration_effects():
	# Create reusable celebration particle systems
	pass

# === CURRENCY DISPLAY ===
func update_currency_display():
	if not currency_display:
		return
	
	var soft_currency = GameManager.get_currency("soft")
	var premium_currency = GameManager.get_currency("premium")
	
	# Update currency labels with animations
	animate_currency_change("soft", soft_currency)
	animate_currency_change("premium", premium_currency)

func animate_currency_change(currency_type: String, new_amount: int):
	# Create satisfying currency change animation
	var label = get_currency_label(currency_type)
	if not label:
		return
	
	# Pulse effect for positive changes
	create_pulse_effect(label)
	
	# Number counting animation
	var tween = create_tween()
	var current_value = int(label.text.replace(",", ""))
	
	tween.tween_method(
		func(value): label.text = format_number(int(value)),
		current_value,
		new_amount,
		0.5
	)
	
	# Particle burst for large gains
	if new_amount > current_value + 100:
		create_currency_burst(label, currency_type)

func get_currency_label(currency_type: String) -> Label:
	# Return the appropriate currency label
	match currency_type:
		"soft":
			return currency_display.get_node("SoftCurrencyLabel") if currency_display else null
		"premium":
			return currency_display.get_node("PremiumCurrencyLabel") if currency_display else null
	return null

func format_number(number: int) -> String:
	# Format large numbers with K, M suffixes
	if number >= 1000000:
		return str(number / 1000000.0).pad_decimals(1) + "M"
	elif number >= 1000:
		return str(number / 1000.0).pad_decimals(1) + "K"
	else:
		return str(number)

# === LEVEL PROGRESSION ===
func update_level_display():
	if not level_progress_bar:
		return
	
	var progress = float(GameManager.player_xp) / float(GameManager.player_xp_to_next_level)
	
	# Animate progress bar
	var tween = create_tween()
	tween.tween_property(level_progress_bar, "value", progress, 0.3)
	
	# Update level text
	var level_label = level_progress_bar.get_node("LevelLabel") if level_progress_bar.has_node("LevelLabel") else null
	if level_label:
		level_label.text = "Level " + str(GameManager.player_level)

# === NOTIFICATION SYSTEM ===
func show_notification(title: String, message: String, icon: String = "", duration: float = 3.0):
	var notification = {
		"title": title,
		"message": message,
		"icon": icon,
		"duration": duration
	}
	
	notification_queue.append(notification)
	
	if not is_showing_notification:
		process_notification_queue()

func process_notification_queue():
	if notification_queue.is_empty():
		is_showing_notification = false
		return
	
	is_showing_notification = true
	var notification = notification_queue.pop_front()
	
	display_notification(notification)

func display_notification(notification: Dictionary):
	# Create notification UI element
	var notification_panel = preload("res://ui/NotificationPanel.tscn").instantiate()
	add_child(notification_panel)
	
	# Set up notification content
	notification_panel.setup(notification.title, notification.message, notification.icon)
	
	# Animate in
	notification_panel.modulate.a = 0.0
	notification_panel.position.y -= 50
	
	var tween = create_tween()
	tween.parallel().tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(notification_panel, "position:y", notification_panel.position.y + 50, 0.3)
	
	# Wait and animate out
	tween.tween_delay(notification.duration)
	tween.parallel().tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(notification_panel, "position:y", notification_panel.position.y - 50, 0.3)
	
	tween.tween_callback(func(): 
		notification_panel.queue_free()
		process_notification_queue()
	)

# === POPUP MANAGEMENT ===
func show_popup(popup: Control, modal: bool = true):
	if popup in popup_stack:
		return
	
	popup_stack.append(popup)
	add_child(popup)
	
	if modal:
		popup.set_process_mode(Node.PROCESS_MODE_WHEN_PAUSED)
		get_tree().paused = true
	
	# Animate popup in
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.3)

func close_popup(popup: Control):
	if not popup in popup_stack:
		return
	
	popup_stack.erase(popup)
	
	# Animate out
	var tween = create_tween()
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(popup, "scale", Vector2(0.8, 0.8), 0.2)
	
	tween.tween_callback(func():
		popup.queue_free()
		
		# Unpause if no more modal popups
		if popup_stack.is_empty():
			get_tree().paused = false
	)

# === CELEBRATION EFFECTS ===
func create_level_up_celebration():
	# Screen shake
	screen_shake(0.5, 10.0)
	
	# Particle explosion
	create_celebration_particles("level_up")
	
	# UI glow effects
	create_screen_flash(Color.GOLD, 0.3)
	
	# Sound effect
	play_celebration_sound("level_up")

func create_achievement_celebration(achievement_id: String):
	# Different celebration based on achievement rarity
	var achievement_data = GameManager.get_achievement_data(achievement_id)
	
	screen_shake(0.3, 5.0)
	create_celebration_particles("achievement")
	create_screen_flash(Color.CYAN, 0.2)
	play_celebration_sound("achievement")

func create_purchase_celebration(product_id: String):
	# VIP purchase effects
	screen_shake(0.4, 7.0)
	create_celebration_particles("purchase")
	create_screen_flash(Color.PURPLE, 0.25)
	play_celebration_sound("purchase")

func screen_shake(duration: float, strength: float):
	if screen_shake_tween:
		screen_shake_tween.kill()
	
	screen_shake_tween = create_tween()
	var original_position = position
	
	for i in range(int(duration * 60)):  # 60 FPS
		var shake_offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		screen_shake_tween.tween_property(self, "position", original_position + shake_offset, 1.0/60.0)
	
	screen_shake_tween.tween_property(self, "position", original_position, 0.1)

func create_screen_flash(color: Color, duration: float):
	var flash_overlay = ColorRect.new()
	flash_overlay.color = color
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash_overlay)
	
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): flash_overlay.queue_free())

func create_celebration_particles(type: String):
	# Create particle system based on celebration type
	var particles = preload("res://effects/CelebrationParticles.tscn").instantiate() if ResourceLoader.exists("res://effects/CelebrationParticles.tscn") else null
	
	if particles:
		add_child(particles)
		particles.setup_for_type(type)

func create_pulse_effect(node: Node):
	if node in pulse_effects:
		pulse_effects[node].kill()
	
	var tween = create_tween()
	pulse_effects[node] = tween
	
	var original_scale = node.scale
	tween.tween_property(node, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(node, "scale", original_scale, 0.1)
	
	tween.tween_callback(func(): pulse_effects.erase(node))

func create_currency_burst(label: Node, currency_type: String):
	# Create floating currency icons
	for i in range(5):
		var currency_icon = preload("res://ui/FloatingCurrency.tscn").instantiate() if ResourceLoader.exists("res://ui/FloatingCurrency.tscn") else null
		
		if currency_icon:
			add_child(currency_icon)
			currency_icon.setup(currency_type, label.global_position)

func play_celebration_sound(sound_type: String):
	# Play appropriate celebration sound
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	var sound_path = "res://audio/celebrations/" + sound_type + ".ogg"
	if ResourceLoader.exists(sound_path):
		audio_player.stream = load(sound_path)
		audio_player.play()
		
		audio_player.finished.connect(func(): audio_player.queue_free())

# === DAILY REWARD UI ===
func show_daily_reward_popup():
	var daily_popup = preload("res://ui/DailyRewardPopup.tscn").instantiate() if ResourceLoader.exists("res://ui/DailyRewardPopup.tscn") else null
	
	if daily_popup:
		show_popup(daily_popup)
		daily_popup.setup_rewards(GameManager.daily_streak)

# === STORE UI ===
func show_store(tab: String = "currency"):
	if not store_panel:
		store_panel = preload("res://ui/StorePanel.tscn").instantiate() if ResourceLoader.exists("res://ui/StorePanel.tscn") else null
		
	if store_panel:
		show_popup(store_panel, false)
		store_panel.show_tab(tab)

# === BATTLE PASS UI ===
func show_battle_pass():
	if not battle_pass_panel:
		battle_pass_panel = preload("res://ui/BattlePassPanel.tscn").instantiate() if ResourceLoader.exists("res://ui/BattlePassPanel.tscn") else null
	
	if battle_pass_panel:
		show_popup(battle_pass_panel, false)
		battle_pass_panel.update_progress()

# === ADDICTIVE UI PATTERNS ===
func create_urgency_indicator(element: Control, text: String = "Limited Time!"):
	# Add pulsing red indicator for urgency
	var urgency_label = Label.new()
	urgency_label.text = text
	urgency_label.add_theme_color_override("font_color", Color.RED)
	element.add_child(urgency_label)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(urgency_label, "modulate:a", 0.3, 0.5)
	tween.tween_property(urgency_label, "modulate:a", 1.0, 0.5)

func create_progress_bar_with_rewards(container: Control, current: int, target: int, rewards: Array):
	# Create visually appealing progress bar with reward milestones
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = target
	progress_bar.value = current
	container.add_child(progress_bar)
	
	# Add reward icons at milestones
	for i in range(rewards.size()):
		var milestone = (target / rewards.size()) * (i + 1)
		var reward_icon = TextureRect.new()
		# Position reward icon on progress bar
		container.add_child(reward_icon)

func show_limited_time_offer(offer: Dictionary):
	# Show compelling limited-time offer popup
	var offer_popup = preload("res://ui/SpecialOfferPopup.tscn").instantiate() if ResourceLoader.exists("res://ui/SpecialOfferPopup.tscn") else null
	
	if offer_popup:
		show_popup(offer_popup)
		offer_popup.setup_offer(offer)
		create_urgency_indicator(offer_popup, "Limited Time: " + format_time_remaining(offer.expires))

func format_time_remaining(expires_timestamp: int) -> String:
	var current_time = Time.get_unix_time_from_system()
	var remaining = expires_timestamp - current_time
	
	if remaining <= 0:
		return "Expired"
	
	var hours = int(remaining / 3600)
	var minutes = int((remaining % 3600) / 60)
	
	if hours > 0:
		return str(hours) + "h " + str(minutes) + "m"
	else:
		return str(minutes) + "m"

# === SIGNAL HANDLERS ===
func _on_player_level_changed(new_level: int):
	update_level_display()
	create_level_up_celebration()
	
	show_notification(
		"LEVEL UP!",
		"You reached level " + str(new_level) + "!",
		"level_up",
		4.0
	)

func _on_currency_changed(currency_type: String, amount: int):
	update_currency_display()

func _on_achievement_unlocked(achievement_id: String):
	var achievement_data = GameManager.get_achievement_data(achievement_id)
	create_achievement_celebration(achievement_id)
	
	show_notification(
		"Achievement Unlocked!",
		achievement_data.get("name", "Unknown Achievement"),
		"achievement",
		5.0
	)

func _on_daily_reward_available():
	show_daily_reward_popup()

func _on_purchase_completed(product_id: String):
	create_purchase_celebration(product_id)
	show_notification(
		"Purchase Successful!",
		"Thank you for your support!",
		"purchase",
		3.0
	)

func _on_ad_watched(reward_type: String, reward_amount: int):
	show_notification(
		"Reward Earned!",
		"You earned " + str(reward_amount) + " " + reward_type,
		"ad_reward",
		2.0
	)

# === UTILITY FUNCTIONS ===
func update_all_displays():
	update_currency_display()
	update_level_display()

func create_floating_text(text: String, position: Vector2, color: Color = Color.WHITE):
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.add_theme_color_override("font_color", color)
	floating_label.position = position
	add_child(floating_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(floating_label, "position:y", position.y - 100, 1.0)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): floating_label.queue_free())