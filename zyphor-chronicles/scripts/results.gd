extends Node2D

func _ready() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var bg = ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0, 0, 0, 0.85)
	canvas.add_child(bg)

	var title = Label.new()
	title.text = "ROUND COMPLETE!"
	title.position = Vector2(90, 20)
	title.add_theme_font_size_override("font_size", 14)
	canvas.add_child(title)

	var zkr_label = Label.new()
	zkr_label.text = "ZKR: " + str(PlayerData.zkr)
	zkr_label.position = Vector2(110, 60)
	zkr_label.add_theme_font_size_override("font_size", 10)
	canvas.add_child(zkr_label)

	var medals_label = Label.new()
	medals_label.text = "Medals: " + str(PlayerData.medals)
	medals_label.position = Vector2(110, 80)
	medals_label.add_theme_font_size_override("font_size", 10)
	canvas.add_child(medals_label)

	var round_label = Label.new()
	round_label.text = "Round: " + str(GameManager.current_round + 1)
	round_label.position = Vector2(110, 100)
	round_label.add_theme_font_size_override("font_size", 10)
	canvas.add_child(round_label)

	var continue_label = Label.new()
	continue_label.text = "Press A to continue"
	continue_label.position = Vector2(90, 140)
	continue_label.add_theme_font_size_override("font_size", 8)
	canvas.add_child(continue_label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_a"):
		get_tree().change_scene_to_file("res://scenes/main_map.tscn")
