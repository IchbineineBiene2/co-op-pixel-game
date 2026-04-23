extends Node2D

const BIN_COLORS  = [Color(1, 0.3, 0.3), Color(0.3, 0.5, 1), Color(0.3, 0.9, 0.3)]
const BIN_POSITIONS = [Vector2(60, 155), Vector2(160, 155), Vector2(260, 155)]

var player: CharacterBody2D = null
var other_players: Dictionary = {}
var falling_items: Array = []
var held_item = null
var score: int = 0
var score_label: Label = null
var timer_label: Label = null
var fall_speed: float = 30.0
var spawn_timer_node: Timer = null
var time_left: float = 60.0
var is_running: bool = false
var difficulty: String = "medium"

func _ready() -> void:
	difficulty = GameManager.get_difficulty()
	_on_start()

func _on_start() -> void:
	var spawn_interval: float
	match difficulty:
		"easy":
			time_left = 90.0
			fall_speed = 30.0
			spawn_interval = 2.0
		"medium":
			time_left = 75.0
			fall_speed = 45.0
			spawn_interval = 1.5
		"hard":
			time_left = 60.0
			fall_speed = 60.0
			spawn_interval = 1.0
	is_running = true
	_create_scene(spawn_interval)
	_setup_multiplayer()

func _create_scene(spawn_interval: float) -> void:
	# Arka plan
	var bg = ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.08, 0.08, 0.14)
	add_child(bg)

	# Kutular
	for i in range(3):
		var bin = ColorRect.new()
		bin.size = Vector2(30, 20)
		bin.position = BIN_POSITIONS[i] - Vector2(15, 0)
		bin.color = BIN_COLORS[i]
		bin.color.a = 0.85
		bin.set_meta("color_index", i)
		add_child(bin)

	# Oyuncu
	player = CharacterBody2D.new()
	player.name = "Player"
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	player.add_child(col)
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.2, 0.6, 1.0)
	player.add_child(sprite)
	player.position = Vector2(160, 120)
	add_child(player)

	# Skor etiketi
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 7)
	score_label.text = "Score: 0"
	score_label.position = Vector2(200, 16)
	add_child(score_label)

	# Süre etiketi (sağ üst)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 7)
	timer_label.position = Vector2(270, 16)
	add_child(timer_label)

	# Spawn timer
	spawn_timer_node = Timer.new()
	spawn_timer_node.wait_time = spawn_interval
	spawn_timer_node.autostart = true
	spawn_timer_node.timeout.connect(_on_spawn_timer)
	add_child(spawn_timer_node)

	# HUD
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _setup_multiplayer() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	NetworkManager.player_connected.connect(_on_mp_player_connected)
	NetworkManager.player_disconnected.connect(_on_mp_player_disconnected)
	var my_id = multiplayer.get_unique_id()
	for peer_id in GameManager.players.keys():
		if peer_id != my_id:
			_spawn_other_player(peer_id)
	if GameManager.players.size() > 1:
		_announce_join.rpc()

func _spawn_other_player(peer_id: int) -> void:
	var my_id = 1
	if multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	if peer_id == my_id or other_players.has(peer_id):
		return
	var other = CharacterBody2D.new()
	other.name = "Player_" + str(peer_id)
	other.collision_layer = 0
	other.collision_mask = 0
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	other.add_child(col)
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.2, 0.6, 1.0) if peer_id == 1 else Color(1.0, 0.5, 0.0)
	other.add_child(sprite)
	other.position = Vector2(160, 120) + Vector2((peer_id % 5) * 20 - 40, 0)
	add_child(other)
	other_players[peer_id] = other

func _on_mp_player_connected(peer_id: int) -> void:
	_spawn_other_player(peer_id)

func _on_mp_player_disconnected(peer_id: int) -> void:
	if other_players.has(peer_id):
		other_players[peer_id].queue_free()
		other_players.erase(peer_id)

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

func _on_spawn_timer() -> void:
	if not is_running:
		return
	if falling_items.size() >= 5:
		return
	var ci = randi() % 3
	var item = ColorRect.new()
	item.size = Vector2(10, 10)
	item.color = BIN_COLORS[ci]
	item.position = Vector2(randf_range(10, 305), 22.0)
	item.set_meta("color_index", ci)
	item.set_meta("falling", true)
	add_child(item)
	falling_items.append(item)

func _physics_process(delta: float) -> void:
	if not is_running or player == null:
		return

	# Oyuncu hareketi
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	if dir.length() > 0:
		dir = dir.normalized()
	player.velocity = dir * 60.0
	player.move_and_slide()
	if multiplayer.has_multiplayer_peer():
		_sync_position.rpc(player.position)

	# Al / bırak
	if Input.is_action_just_pressed("action_a"):
		if held_item == null:
			_try_pick_up()
		else:
			_try_drop()

	# Düşen nesneleri güncelle
	for item in falling_items.duplicate():
		if not is_instance_valid(item):
			falling_items.erase(item)
			continue
		if item.get_meta("falling", false):
			item.position.y += fall_speed * delta
			if item.position.y > 175:
				item.queue_free()
				falling_items.erase(item)

	# Tutulan nesneyi oyuncuyla taşı
	if held_item != null and is_instance_valid(held_item):
		held_item.position = player.position - Vector2(5, 14)

func _try_pick_up() -> void:
	for item in falling_items:
		if is_instance_valid(item) and item.get_meta("falling", false):
			if item.position.distance_to(player.position) < 20:
				held_item = item
				item.set_meta("falling", false)
				falling_items.erase(item)
				return

func _try_drop() -> void:
	if held_item == null:
		return
	# En yakın kutuyu bul
	var best_dist = INF
	var best_bin = null
	for child in get_children():
		if child is ColorRect and child.has_meta("color_index") and not child.has_meta("falling"):
			var bin_center = child.position + child.size / 2.0
			var d = held_item.position.distance_to(bin_center)
			if d < best_dist:
				best_dist = d
				best_bin = child
	if best_bin != null and best_dist < 40:
		if held_item.get_meta("color_index") == best_bin.get_meta("color_index"):
			score += 10
		else:
			score -= 5
		if score_label:
			score_label.text = "Score: " + str(score)
	held_item.queue_free()
	held_item = null

func _process(delta: float) -> void:
	if not is_running:
		return
	time_left -= delta
	if timer_label:
		timer_label.text = "Time: " + str(int(max(time_left, 0)))
	if time_left <= 0.0:
		is_running = false
		_finish_game()

func _finish_game() -> void:
	var zkr = 20
	var medals = 0
	if score > 50:
		zkr = 150
		medals = 2
	elif score > 20:
		zkr = 90
		medals = 1
	PlayerData.add_zkr(zkr)
	PlayerData.add_medals(medals)
	GameManager.add_zkr(1, zkr)
	GameManager.add_medals(1, medals)
	GameManager.next_round()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/results.tscn")
