extends "res://scripts/zone_base.gd"

func _ready() -> void:
	zone_name = "Zyphor Tahtı"
	zone_size = Vector2(480, 360)
	super._ready()

func _create_zone() -> void:
	var bg = ColorRect.new()
	bg.size = zone_size
	bg.color = Color(0.18, 0.16, 0.08)
	add_child(bg)

	# Mini oyun alanı
	var minigame_area = Area2D.new()
	var mg_col = CollisionShape2D.new()
	var mg_shape = RectangleShape2D.new()
	mg_shape.size = Vector2(80, 60)
	mg_col.shape = mg_shape
	minigame_area.add_child(mg_col)
	var mg_visual = ColorRect.new()
	mg_visual.size = Vector2(80, 60)
	mg_visual.position = Vector2(-40, -30)
	mg_visual.color = Color(1.0, 0.85, 0.1, 0.4)
	minigame_area.add_child(mg_visual)
	var mg_label = Label.new()
	mg_label.text = "Zyphor Bombası"
	mg_label.position = Vector2(-32, -42)
	mg_label.add_theme_font_size_override("font_size", 6)
	minigame_area.add_child(mg_label)
	minigame_area.position = Vector2(160, 180)
	minigame_area.body_entered.connect(func(body: Node2D):
		if body.name != "Player":
			return
		var current = GameManager.get_current_minigame()
		if current != "zyphor_bomb":
			var canvas = CanvasLayer.new()
			add_child(canvas)
			var msg = Label.new()
			msg.text = "Bu tur bu değil! Şu an: " + current.replace("_", " ").to_upper()
			msg.position = Vector2(60, 80)
			msg.add_theme_font_size_override("font_size", 7)
			msg.modulate = Color(1, 0.3, 0.3)
			canvas.add_child(msg)
			await get_tree().create_timer(2.0).timeout
			canvas.queue_free()
			return
		get_tree().call_deferred("change_scene_to_file", "res://scenes/minigames/zyphor_bomb.tscn")
	)
	add_child(minigame_area)

	# Zyphor Tahtı (kazanma kapısı)
	var throne_area = Area2D.new()
	var th_col = CollisionShape2D.new()
	var th_shape = RectangleShape2D.new()
	th_shape.size = Vector2(60, 80)
	th_col.shape = th_shape
	throne_area.add_child(th_col)
	var th_visual = ColorRect.new()
	th_visual.size = Vector2(60, 80)
	th_visual.position = Vector2(-30, -40)
	th_visual.color = Color(1.0, 0.9, 0.2, 0.6)
	throne_area.add_child(th_visual)
	var th_label = Label.new()
	th_label.text = "Zyphor Tahtı"
	th_label.position = Vector2(-26, -54)
	th_label.add_theme_font_size_override("font_size", 6)
	throne_area.add_child(th_label)
	throne_area.position = Vector2(340, 150)
	throne_area.body_entered.connect(func(body: Node2D):
		if body.name != "Player":
			return
		var peer_id = multiplayer.get_unique_id()
		var canvas = CanvasLayer.new()
		add_child(canvas)
		var msg = Label.new()
		msg.set_anchors_preset(Control.PRESET_CENTER)
		msg.add_theme_font_size_override("font_size", 10)
		canvas.add_child(msg)
		if GameManager.check_win_condition(peer_id):
			msg.text = "Tebrikler! Zyphor'u fethettiniz!"
			msg.modulate = Color(1, 0.9, 0.2)
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			var medals = 0
			if GameManager.players.has(peer_id):
				medals = GameManager.players[peer_id]["medals"]
			var threshold = GameManager.medal_threshold
			msg.text = "Yeterli madalyon yok! (" + str(medals) + "/" + str(threshold) + ")"
			msg.modulate = Color(1, 0.3, 0.3)
			await get_tree().create_timer(2.0).timeout
			canvas.queue_free()
	)
	add_child(throne_area)

	# Uzay Kuyumcusu dükkanı
	var shop = ColorRect.new()
	shop.size = Vector2(50, 40)
	shop.color = Color(0.75, 0.6, 0.1)
	shop.position = Vector2(215, 260)
	add_child(shop)
	var shop_label = Label.new()
	shop_label.text = "Uzay Kuyumcusu"
	shop_label.position = Vector2(200, 250)
	shop_label.add_theme_font_size_override("font_size", 6)
	add_child(shop_label)
