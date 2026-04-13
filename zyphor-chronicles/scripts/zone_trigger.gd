extends Area2D

@export var zone_name: String = ""
@export var minigame_scene: String = ""
@export var zone_color: Color = Color(1.0, 0.8, 0.0, 0.3)

var players_inside: Array = []
var label: Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Görsel
	var rect = ColorRect.new()
	rect.size = Vector2(48, 48)
	rect.position = Vector2(-24, -24)
	rect.color = zone_color
	add_child(rect)

	# İsim etiketi
	label = Label.new()
	label.text = zone_name
	label.position = Vector2(-24, -40)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)

	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	collision.shape = shape
	add_child(collision)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		players_inside.append(body)
		var my_id = 1
		if multiplayer != null and multiplayer.has_multiplayer_peer():
			my_id = multiplayer.get_unique_id()
		RoundManager.player_entered_zone(my_id)
		print(zone_name, " bölgesine girildi!")

		# Zyphor Tahtı: kazanma kontrolü
		if zone_name == "Zyphor Tahtı":
			if GameManager.check_win_condition(my_id):
				print("KAZANDIN! Zyphor Tahtı'na ulaştın!")
			else:
				var medals = 0
				if GameManager.players.has(my_id):
					medals = GameManager.players[my_id]["medals"]
				print("Henüz yeterli madalyon yok! Mevcut: ", medals)
			return

		# Onay diyalogu ile mini oyuna geç
		if minigame_scene != "" and zone_name != "Zyphor Tahtı":
			var dialog_label = Label.new()
			dialog_label.text = zone_name + " mini oyununa girmek istiyor musun? (A: Evet, B: Hayır)"
			dialog_label.position = Vector2(20, 80)
			dialog_label.add_theme_font_size_override("font_size", 7)
			dialog_label.name = "ZoneDialog"
			get_tree().current_scene.add_child(dialog_label)
			set_process_input(true)
			set_meta("pending_scene", minigame_scene)
			set_meta("dialog_node", dialog_label)

func _input(event: InputEvent) -> void:
	if not has_meta("pending_scene"):
		return
	if event.is_action_pressed("action_a"):
		var scene = get_meta("pending_scene")
		if has_meta("dialog_node"):
			get_meta("dialog_node").queue_free()
		remove_meta("pending_scene")
		remove_meta("dialog_node")
		set_process_input(false)
		get_tree().call_deferred("change_scene_to_file", scene)
	elif event.is_action_pressed("action_b"):
		if has_meta("dialog_node"):
			get_meta("dialog_node").queue_free()
		remove_meta("pending_scene")
		remove_meta("dialog_node")
		set_process_input(false)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		players_inside.erase(body)
		var my_id = 1
		if multiplayer != null and multiplayer.has_multiplayer_peer():
			my_id = multiplayer.get_unique_id()
		RoundManager.player_left_zone(my_id)
		print(zone_name, " bölgesinden çıkıldı!")
