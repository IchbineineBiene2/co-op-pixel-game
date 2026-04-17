extends Node2D

var vbox: VBoxContainer = null
var ip_input: LineEdit = null
var status_label: Label = null
var player_count_label: Label = null

func _ready() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.custom_minimum_size = Vector2(160, 0)
	vbox.add_theme_constant_override("separation", 4)
	canvas.add_child(vbox)

	var title = Label.new()
	title.text = "LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 8)
	vbox.add_child(title)

	# Sprite seçim
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

	# Renk seçim
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

	var ip_label = Label.new()
	ip_label.text = "Host IP:"
	ip_label.add_theme_font_size_override("font_size", 6)
	ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(ip_label)

	ip_input = LineEdit.new()
	ip_input.placeholder_text = "192.168.1.x"
	ip_input.text = "127.0.0.1"
	ip_input.custom_minimum_size = Vector2(120, 16)
	ip_input.add_theme_font_size_override("font_size", 6)
	ip_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(ip_input)

	var btn_host = Button.new()
	btn_host.text = tr("BTN_HOST")
	btn_host.custom_minimum_size = Vector2(120, 14)
	btn_host.add_theme_font_size_override("font_size", 6)
	btn_host.pressed.connect(_on_host_pressed)
	vbox.add_child(btn_host)

	var btn_join = Button.new()
	btn_join.text = tr("BTN_JOIN")
	btn_join.custom_minimum_size = Vector2(120, 14)
	btn_join.add_theme_font_size_override("font_size", 6)
	btn_join.pressed.connect(_on_join_pressed)
	vbox.add_child(btn_join)

	# Oyuncu sayısı
	player_count_label = Label.new()
	player_count_label.text = ""
	player_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_count_label.add_theme_font_size_override("font_size", 6)
	player_count_label.modulate = Color(0.8, 1, 0.8)
	vbox.add_child(player_count_label)

	# Durum mesajı
	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 6)
	status_label.modulate = Color(1, 1, 0.5)
	vbox.add_child(status_label)

	var btn_ready = Button.new()
	btn_ready.name = "BtnReady"
	btn_ready.text = tr("BTN_READY")
	btn_ready.add_theme_font_size_override("font_size", 6)
	btn_ready.custom_minimum_size = Vector2(60, 14)
	btn_ready.pressed.connect(_on_ready_pressed)
	vbox.add_child(btn_ready)

	var btn_back = Button.new()
	btn_back.text = tr("BTN_BACK")
	btn_back.add_theme_font_size_override("font_size", 6)
	btn_back.custom_minimum_size = Vector2(60, 14)
	btn_back.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_back)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed_handler)

func _on_sprite_selected(sprite_type: String) -> void:
	PlayerData.sprite_type = sprite_type

func _on_color_selected(color_index: int) -> void:
	PlayerData.color_palette = color_index

func _on_host_pressed() -> void:
	NetworkManager.host_game()
	if not multiplayer.has_multiplayer_peer():
		_set_status("Host kurulamadı!", Color(1, 0.3, 0.3))
		return
	GameManager.register_player(1, SaveManager.player_name)
	# Yerel IP'yi bul ve göster
	var local_ip = _get_local_ip()
	_set_status("Host: " + local_ip + "  Diğerleri bu IP'ye bağlansın", Color(0.5, 1, 0.5))
	_update_count()

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	_set_status("Bağlanılıyor: " + ip + "...", Color(1, 1, 0.5))
	NetworkManager.join_game(ip)

func _on_connection_succeeded() -> void:
	var my_id = multiplayer.get_unique_id()
	NetworkManager.sync_player_data.rpc(my_id, SaveManager.player_name)
	_set_status("Bağlandı! Host oyunu başlatana kadar bekle.", Color(0.5, 1, 0.5))
	_update_count()

func _on_connection_failed_handler() -> void:
	_set_status("Bağlantı başarısız! IP doğru mu?", Color(1, 0.3, 0.3))

func _on_ready_pressed() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not multiplayer.is_server():
		_set_status("Sadece host oyunu başlatabilir!", Color(1, 0.6, 0.3))
		return
	NetworkManager.change_scene_for_all.rpc("res://scenes/hub_map.tscn")

func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_player_connected(peer_id: int) -> void:
	print("Oyuncu bağlandı: ", peer_id)
	# Sayım: gerçek peer sayısını kullan, RPC henüz gelmemiş olabilir
	await get_tree().create_timer(0.2).timeout
	_update_count()

func _on_player_disconnected(_peer_id: int) -> void:
	await get_tree().create_timer(0.1).timeout
	_update_count()

func _update_count() -> void:
	if not multiplayer.has_multiplayer_peer():
		player_count_label.text = ""
		return
	var count: int
	if multiplayer.is_server():
		count = multiplayer.get_peers().size() + 1  # peerlar + host
	else:
		count = GameManager.players.size()
	player_count_label.text = "Oyuncular: " + str(count) + "/" + str(NetworkManager.MAX_PLAYERS) + \
		("  (Sen host'sun)" if multiplayer.is_server() else "")

func _set_status(text: String, color: Color = Color(1, 1, 1)) -> void:
	if status_label:
		status_label.text = text
		status_label.modulate = color

func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	return "127.0.0.1"
