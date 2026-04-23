extends Node2D
class_name ZoneBase

var player: CharacterBody2D = null
var camera: Camera2D = null
var zone_name: String = "Zone"
var zone_size: Vector2 = Vector2(480, 360)
var other_players: Dictionary = {}

func _ready() -> void:
	_create_zone()
	_create_player()
	_create_camera()
	_create_back_portal()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

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

func _create_zone() -> void:
	pass

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
	player.position = Vector2(zone_size.x / 2, zone_size.y - 40)
	add_child(player)

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = int(zone_size.x)
	camera.limit_top = 0
	camera.limit_bottom = int(zone_size.y)
	player.add_child(camera)

func _create_back_portal() -> void:
	var portal = Area2D.new()
	portal.name = "BackPortal"
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 20)
	col.shape = shape
	portal.add_child(col)
	var visual = ColorRect.new()
	visual.size = Vector2(40, 20)
	visual.position = Vector2(-20, -10)
	visual.color = Color(0.5, 0.5, 1.0, 0.8)
	portal.add_child(visual)
	var label = Label.new()
	label.text = "< Meydan"
	label.position = Vector2(-20, -24)
	label.add_theme_font_size_override("font_size", 6)
	portal.add_child(label)
	portal.position = Vector2(zone_size.x / 2, zone_size.y - 20)
	portal.body_entered.connect(_on_back_portal_entered)
	add_child(portal)

func _on_back_portal_entered(body: Node2D) -> void:
	if body.name == "Player":
		_show_return_transition()

func _show_return_transition() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var overlay = ColorRect.new()
	overlay.size = Vector2(320, 180)
	overlay.color = Color(0, 0, 0, 0)
	canvas.add_child(overlay)
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/hub_map.tscn")
	)

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

	other.position = Vector2(zone_size.x / 2, zone_size.y - 40) + Vector2((peer_id % 5) * 20 - 40, 0)
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
