extends Node2D

func _ready() -> void:
	# UI'yi kod ile oluştur
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.custom_minimum_size = Vector2(160, 0)
	vbox.add_theme_constant_override("separation", 4)
	canvas.add_child(vbox)

	var title = Label.new()
	title.name = "Title"
	title.text = "LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 8)
	vbox.add_child(title)

	var players_label = Label.new()
	players_label.name = "PlayersLabel"
	players_label.text = tr("MSG_WAITING")
	players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	players_label.add_theme_font_size_override("font_size", 6)
	vbox.add_child(players_label)

	# Sprite seçim butonları
	var sprite_hbox = HBoxContainer.new()
	sprite_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(sprite_hbox)
	for sprite in ["Robot", "Human Male", "Human Female", "Alien"]:
		var btn = Button.new()
		btn.text = sprite
		btn.custom_minimum_size = Vector2(40, 12)
		btn.add_theme_font_size_override("font_size", 5)
		btn.pressed.connect(_on_sprite_selected.bind(sprite.to_lower().replace(" ", "_")))
		sprite_hbox.add_child(btn)

	# Renk seçim butonları
	var color_hbox = HBoxContainer.new()
	color_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(color_hbox)
	for i in range(8):
		var btn = Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(14, 12)
		btn.add_theme_font_size_override("font_size", 5)
		btn.pressed.connect(_on_color_selected.bind(i))
		color_hbox.add_child(btn)

	# Hazır ve Geri butonları
	var btn_ready = Button.new()
	btn_ready.name = "BtnReady"
	btn_ready.text = tr("BTN_READY")
	btn_ready.add_theme_font_size_override("font_size", 6)
	btn_ready.custom_minimum_size = Vector2(60, 14)
	btn_ready.pressed.connect(_on_ready_pressed)
	vbox.add_child(btn_ready)

	var btn_back = Button.new()
	btn_back.name = "BtnBack"
	btn_back.text = tr("BTN_BACK")
	btn_back.add_theme_font_size_override("font_size", 6)
	btn_back.custom_minimum_size = Vector2(60, 14)
	btn_back.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_back)

	# Sinyaller
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

func _on_sprite_selected(sprite_type: String) -> void:
	PlayerData.sprite_type = sprite_type
	print("Sprite seçildi: ", sprite_type)

func _on_color_selected(color_index: int) -> void:
	PlayerData.color_palette = color_index
	print("Renk seçildi: ", color_index)

func _on_ready_pressed() -> void:
	var my_id = multiplayer.get_unique_id()
	GameManager.register_player(my_id, SaveManager.player_name)
	print("Hazır! ID: ", my_id)

func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_player_connected(peer_id: int) -> void:
	print("Oyuncu katıldı: ", peer_id)

func _on_player_disconnected(peer_id: int) -> void:
	print("Oyuncu ayrıldı: ", peer_id)
