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
		if multiplayer.has_multiplayer_peer():
				RoundManager.broadcast_zone_entered.rpc(my_id)
			else:
				RoundManager.broadcast_zone_entered(my_id)
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

		# Aktif tur kontrolü - sadece doğru bölgeye girilebilir
		if zone_name != "Zyphor Tahtı" and minigame_scene != "":
			var current_game = GameManager.get_current_minigame()
			var zone_game_map = {
				"Vrix Pazarı": "vrix_race",
				"Glonar Arenası": "glonar_fight",
				"Nebula Fabrikası": "nebula_factory",
				"Xora Tapınağı": "xora_memory",
				"Merkez Meydan": "zyphor_bomb",
				"Zyphor Tahtı": ""
			}
			var expected_game = zone_game_map.get(zone_name, "")
			if expected_game != current_game:
				# Yanlış bölge - kilitli mesajı göster
				var locked_label = Label.new()
				locked_label.name = "LockedLabel"
				locked_label.text = "Bu tur: " + current_game.replace("_", " ").to_upper()
				locked_label.position = Vector2(20, 80)
				locked_label.add_theme_font_size_override("font_size", 7)
				locked_label.modulate = Color(1, 0.3, 0.3)
				get_tree().current_scene.add_child(locked_label)
				await get_tree().create_timer(2.0).timeout
				if is_instance_valid(locked_label):
					locked_label.queue_free()
				return

		# Onay diyalogu ile mini oyuna geç
		if minigame_scene != "" and zone_name != "Zyphor Tahtı":
			# Zaten bekleyen bir dialog varsa yeni dialog açma
			if has_meta("pending_scene"):
				return

			# Sahnede başka bir ZoneDialog varsa önce onu temizle
			var existing = get_tree().current_scene.find_child("ZoneDialog", true, false)
			if existing:
				existing.queue_free()

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
		if multiplayer.has_multiplayer_peer():
			NetworkManager.request_scene_change.rpc_id(1, scene)
		else:
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

		# Bölgeden çıkınca bekleyen dialog varsa iptal et
		if has_meta("pending_scene"):
			if has_meta("dialog_node"):
				var d = get_meta("dialog_node")
				if is_instance_valid(d):
					d.queue_free()
			remove_meta("pending_scene")
			if has_meta("dialog_node"):
				remove_meta("dialog_node")
			set_process_input(false)
