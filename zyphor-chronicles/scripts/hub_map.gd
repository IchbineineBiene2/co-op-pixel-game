extends Node2D

const ZONE_SCENES = {
	"vrix": "res://scenes/zones/vrix_market.tscn",
	"glonar": "res://scenes/zones/glonar_arena.tscn",
	"nebula": "res://scenes/zones/nebula_factory_zone.tscn",
	"xora": "res://scenes/zones/xora_temple.tscn",
	"throne": "res://scenes/zones/zyphor_throne.tscn",
}

var player: CharacterBody2D = null
var camera: Camera2D = null
var other_players: Dictionary = {}

func _ready() -> void:
	_create_hub()
	_create_player()
	_create_camera()
	_create_zone_portals()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	RoundManager.zone_count_updated.connect(_on_zone_count_updated)
	RoundManager.round_timer_tick.connect(_on_timer_tick)
	RoundManager.zone_entered_alert.connect(_on_zone_entered_alert)
	_create_minigame_info_ui()

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)

	if multiplayer.has_multiplayer_peer():
		var my_id = multiplayer.get_unique_id()
		for peer_id in GameManager.players.keys():
			if peer_id != my_id:
				_spawn_other_player(peer_id)
		if GameManager.players.size() > 1:
			_announce_join.rpc()

func _create_hub() -> void:
	var ground = ColorRect.new()
	ground.size = Vector2(640, 640)
	ground.position = Vector2(-320, -320)
	ground.color = Color(0.15, 0.15, 0.2)
	add_child(ground)

	var center = ColorRect.new()
	center.size = Vector2(120, 120)
	center.position = Vector2(-60, -60)
	center.color = Color(0.25, 0.25, 0.35)
	add_child(center)

	var road_color = Color(0.2, 0.2, 0.28)
	var roads = [
		[Vector2(-20, -320), Vector2(40, 260)],
		[Vector2(-20, 60), Vector2(40, 260)],
		[Vector2(-320, -20), Vector2(260, 40)],
		[Vector2(60, -20), Vector2(260, 40)],
		[Vector2(-260, -260), Vector2(30, 200)],
		[Vector2(60, -260), Vector2(200, 30)],
		[Vector2(-260, 60), Vector2(200, 30)],
		[Vector2(60, 60), Vector2(200, 200)],
	]
	for r in roads:
		var road = ColorRect.new()
		road.position = r[0]
		road.size = r[1]
		road.color = road_color
		add_child(road)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"

	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	player.set_meta("peer_id", my_id)

	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	col.shape = shape
	player.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color(0.2, 0.6, 1.0) if my_id == 1 else Color(1.0, 0.5, 0.0)
	player.add_child(sprite)

	player.position = Vector2(0, 0)
	add_child(player)

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.limit_left = -320
	camera.limit_right = 320
	camera.limit_top = -320
	camera.limit_bottom = 320
	player.add_child(camera)

func _create_zone_portals() -> void:
	var portals = [
		{"name": "Vrix Pazarı", "pos": Vector2(0, -280), "color": Color(1, 0.8, 0, 0.8), "zone": "vrix"},
		{"name": "Glonar Arenası", "pos": Vector2(0, 280), "color": Color(1, 0.3, 0.3, 0.8), "zone": "glonar"},
		{"name": "Nebula Fabrikası", "pos": Vector2(-280, 0), "color": Color(0.3, 0.8, 1, 0.8), "zone": "nebula"},
		{"name": "Xora Tapınağı", "pos": Vector2(280, 0), "color": Color(0.8, 0.3, 1, 0.8), "zone": "xora"},
		{"name": "Zyphor Tahtı", "pos": Vector2(200, -200), "color": Color(1, 0.9, 0, 0.8), "zone": "throne"},
	]

	for portal_data in portals:
		var portal = Area2D.new()
		portal.name = "Portal_" + portal_data["zone"]

		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 24.0
		col.shape = shape
		portal.add_child(col)

		var visual = ColorRect.new()
		visual.size = Vector2(48, 48)
		visual.position = Vector2(-24, -24)
		visual.color = portal_data["color"]
		portal.add_child(visual)

		var label = Label.new()
		label.text = portal_data["name"]
		label.position = Vector2(-30, -40)
		label.add_theme_font_size_override("font_size", 6)
		portal.add_child(label)

		portal.position = portal_data["pos"]
		var zone_key: String = portal_data["zone"]
		var zone_name_text: String = portal_data["name"]
		portal.body_entered.connect(func(body): _on_portal_entered(zone_key, zone_name_text, body))
		add_child(portal)

func _on_portal_entered(zone_key: String, zone_name_text: String, body: Node2D) -> void:
	if body.name != "Player":
		return
	if zone_key == "throne" and not GameManager.check_win_condition(multiplayer.get_unique_id()):
		_show_blocked_message("Yeterli madalyon yok!")
		return
	_show_transition(zone_key, zone_name_text)

func _show_blocked_message(msg: String) -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var label = Label.new()
	label.text = msg
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 10)
	label.modulate = Color(1, 0.3, 0.3, 1)
	canvas.add_child(label)
	var tween = create_tween().set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_callback(canvas.queue_free)

func _show_transition(zone_key: String, zone_name_text: String) -> void:
	set_physics_process(false)

	var canvas = CanvasLayer.new()
	add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var label = Label.new()
	label.text = zone_name_text
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(1, 1, 1, 0)
	canvas.add_child(label)

	var tween = create_tween().set_parallel(false)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.5)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(ZONE_SCENES[zone_key])
	)

func _create_minigame_info_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "MinigameInfoCanvas"
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(200, 14)
	bg.position = Vector2(60, 2)
	canvas.add_child(bg)

	var lbl = Label.new()
	lbl.name = "MinigameInfoLabel"
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.modulate = Color(1, 0.9, 0.3)
	lbl.position = Vector2(62, 3)
	lbl.text = "Bu Tur: " + GameManager.get_current_minigame().replace("_", " ").to_upper()
	canvas.add_child(lbl)

func _on_zone_count_updated(current: int, total: int) -> void:
	if not has_node("WaitingCanvas"):
		var canvas = CanvasLayer.new()
		canvas.name = "WaitingCanvas"
		add_child(canvas)
		var lbl = Label.new()
		lbl.name = "WaitingLabel"
		lbl.position = Vector2(80, 18)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.modulate = Color(1, 1, 0)
		canvas.add_child(lbl)
	$WaitingCanvas/WaitingLabel.text = "Bölgede: " + str(current) + "/" + str(total)

func _on_timer_tick(seconds_left: float) -> void:
	if has_node("WaitingCanvas/WaitingLabel"):
		$WaitingCanvas/WaitingLabel.text = "Bölgede: " + str(RoundManager.players_inside.size()) + \
			"/" + str(GameManager.players.size()) + \
			"  (" + str(int(seconds_left)) + "sn)"

func _on_zone_entered_alert(peer_id: int) -> void:
	var player_name = "Oyuncu " + str(peer_id)
	if GameManager.players.has(peer_id):
		player_name = GameManager.players[peer_id]["name"]
	var minigame = GameManager.get_current_minigame().replace("_", " ").to_upper()

	var canvas = CanvasLayer.new()
	canvas.name = "AlertCanvas"
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0.8, 0.3, 0.0, 0.85)
	bg.size = Vector2(280, 22)
	bg.position = Vector2(20, 75)
	canvas.add_child(bg)

	var lbl = Label.new()
	lbl.text = "! " + player_name + " " + minigame + " bolgesine girdi!"
	lbl.position = Vector2(22, 78)
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.modulate = Color(1, 1, 1)
	canvas.add_child(lbl)

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(canvas.queue_free)

func _on_peer_connected(_id: int) -> void:
	pass

func _on_player_connected(peer_id: int) -> void:
	_spawn_other_player(peer_id)

func _on_player_disconnected(peer_id: int) -> void:
	if other_players.has(peer_id):
		other_players[peer_id].queue_free()
		other_players.erase(peer_id)

func _spawn_other_player(peer_id: int) -> void:
	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		return
	if other_players.has(peer_id):
		return

	var other = CharacterBody2D.new()
	other.name = "Player_" + str(peer_id)
	other.collision_layer = 0
	other.collision_mask = 0

	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	col.shape = shape
	other.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color(0.2, 0.6, 1.0) if peer_id == 1 else Color(1.0, 0.5, 0.0)
	other.add_child(sprite)

	other.position = Vector2(0, 0) + Vector2((peer_id % 5) * 20 - 40, 0)
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
	_spawn_me.rpc_id(sender_id, multiplayer.get_unique_id())

@rpc("any_peer")
func _spawn_me(peer_id: int) -> void:
	if not other_players.has(peer_id):
		_spawn_other_player(peer_id)

func _physics_process(_delta: float) -> void:
	if player == null:
		return
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
