extends "res://scripts/zone_base.gd"

func _ready() -> void:
	zone_name = "Nebula Fabrikası"
	zone_size = Vector2(480, 360)
	super._ready()

func _create_zone() -> void:
	var bg = ColorRect.new()
	bg.size = zone_size
	bg.color = Color(0.1, 0.12, 0.18)
	add_child(bg)

	var minigame_area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 60)
	col.shape = shape
	minigame_area.add_child(col)
	var visual = ColorRect.new()
	visual.size = Vector2(80, 60)
	visual.position = Vector2(-40, -30)
	visual.color = Color(0.2, 0.6, 1.0, 0.4)
	minigame_area.add_child(visual)
	var label = Label.new()
	label.text = "Fabrika Girişi"
	label.position = Vector2(-28, -42)
	label.add_theme_font_size_override("font_size", 6)
	minigame_area.add_child(label)
	minigame_area.position = Vector2(240, 150)
	minigame_area.body_entered.connect(func(body: Node2D):
		if body.name != "Player":
			return
		var current = GameManager.get_current_minigame()
		if current != "nebula_factory":
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
		get_tree().call_deferred("change_scene_to_file", "res://scenes/minigames/nebula_factory.tscn")
	)
	add_child(minigame_area)

	var shop1 = ColorRect.new()
	shop1.size = Vector2(50, 40)
	shop1.color = Color(0.2, 0.55, 0.3)
	shop1.position = Vector2(60, 100)
	add_child(shop1)
	var shop1_label = Label.new()
	shop1_label.text = "Uzay Hastanesi"
	shop1_label.position = Vector2(60, 90)
	shop1_label.add_theme_font_size_override("font_size", 6)
	add_child(shop1_label)

	var shop2 = ColorRect.new()
	shop2.size = Vector2(50, 40)
	shop2.color = Color(0.45, 0.45, 0.5)
	shop2.position = Vector2(370, 100)
	add_child(shop2)
	var shop2_label = Label.new()
	shop2_label.text = "Mühendis"
	shop2_label.position = Vector2(370, 90)
	shop2_label.add_theme_font_size_override("font_size", 6)
	add_child(shop2_label)
