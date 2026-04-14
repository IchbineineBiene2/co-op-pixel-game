extends Node2D

const SPEED = 80.0

var player: CharacterBody2D = null
var other_players: Dictionary = {}

func _ready() -> void:
	_create_player()
	_create_zones()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

	# Tur başlangıcında aktif mini oyunu göster
	var announce = Label.new()
	announce.name = "TurAnnounce"
	announce.text = "Bu Tur: " + GameManager.get_current_minigame().replace("_", " ").to_upper()
	announce.position = Vector2(80, 165)
	announce.add_theme_font_size_override("font_size", 7)
	announce.modulate = Color(1, 0.9, 0.2)
	add_child(announce)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)

	# Mevcut bağlı oyuncuları spawn et
	if multiplayer.has_multiplayer_peer():
		var my_id = multiplayer.get_unique_id()
		for peer_id in GameManager.players.keys():
			if peer_id != my_id:
				_spawn_other_player(peer_id)
		if GameManager.players.size() > 1:
			_announce_join.rpc()

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"

	# Peer ID sakla
	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	player.set_meta("peer_id", my_id)

	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	collision.shape = shape
	player.add_child(collision)

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	# Host mavi, join turuncu
	if my_id == 1:
		sprite.color = Color(0.2, 0.6, 1.0)
	else:
		sprite.color = Color(1.0, 0.5, 0.0)
	player.add_child(sprite)

	player.position = Vector2(30, 160)
	add_child(player)

func _physics_process(_delta: float) -> void:
	if player == null:
		return

	# Sadece kendi karakterini kontrol et
	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()

	if player.get_meta("peer_id") != my_id:
		return

	var speed = 80.0
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 0:
		direction = direction.normalized()

	player.velocity = direction * speed
	player.move_and_slide()

	if multiplayer.has_multiplayer_peer():
		_sync_position.rpc(player.position)

func _on_peer_connected(id: int) -> void:
	print("Peer bağlandı: ", id)

func _on_player_connected(peer_id: int) -> void:
	_spawn_other_player(peer_id)

func _on_player_disconnected(peer_id: int) -> void:
	if other_players.has(peer_id):
		other_players[peer_id].queue_free()
		other_players.erase(peer_id)

func _spawn_other_player(peer_id: int) -> void:
	# Kendini spawn etme
	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		return

	# Zaten spawn edilmişse tekrar ekleme
	if other_players.has(peer_id):
		return

	var other = CharacterBody2D.new()
	other.name = "Player_" + str(peer_id)

	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	collision.shape = shape
	other.add_child(collision)

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	# Host mavi, diğerleri turuncu
	sprite.color = Color(1.0, 0.5, 0.0) if peer_id != 1 else Color(0.2, 0.6, 1.0)
	other.add_child(sprite)

	other.position = Vector2(160, 90)
	add_child(other)
	other_players[peer_id] = other

@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if other_players.has(sender_id):
		other_players[sender_id].position = pos

@rpc("any_peer", "call_local")
func _announce_join() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		return
	if not other_players.has(sender_id):
		_spawn_other_player(sender_id)
	# Karşı tarafa da bizi spawn ettir
	_spawn_me.rpc_id(sender_id, multiplayer.get_unique_id())

@rpc("any_peer")
func _spawn_me(peer_id: int) -> void:
	if not other_players.has(peer_id):
		_spawn_other_player(peer_id)

func _create_zones() -> void:
	var zones = [
		{"name": "Vrix Pazarı",      "pos": Vector2(60, 50),   "color": Color(1,0.8,0,0.3),   "scene": "res://scenes/minigames/vrix_race.tscn"},
		{"name": "Glonar Arenası",   "pos": Vector2(260, 50),  "color": Color(1,0.3,0.3,0.3), "scene": "res://scenes/minigames/glonar_fight.tscn"},
		{"name": "Nebula Fabrikası", "pos": Vector2(60, 130),  "color": Color(0.3,0.8,1,0.3), "scene": "res://scenes/minigames/nebula_factory.tscn"},
		{"name": "Xora Tapınağı",    "pos": Vector2(260, 130), "color": Color(0.8,0.3,1,0.3), "scene": "res://scenes/minigames/xora_memory.tscn"},
		{"name": "Merkez Meydan",    "pos": Vector2(160, 50),  "color": Color(0.5,0.8,0.5,0.3), "scene": "res://scenes/minigames/zyphor_bomb.tscn"},
		{"name": "Zyphor Tahtı",     "pos": Vector2(160, 130), "color": Color(1,0.9,0,0.5),   "scene": ""},
	]

	for z in zones:
		var zone = preload("res://scripts/zone_trigger.gd")
		var area = Area2D.new()
		area.set_script(zone)
		area.zone_name = z["name"]
		area.zone_color = z["color"]
		area.position = z["pos"]
		area.minigame_scene = z.get("scene", "")
		add_child(area)
