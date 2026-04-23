extends Node2D
class_name MinigameBase

var difficulty: String = "easy"
var results: Array = []
var time_left: float = 90.0
var is_running: bool = false
var player: CharacterBody2D = null
var other_players: Dictionary = {}

signal minigame_ended(results)

func start(diff: String) -> void:
	difficulty = diff
	is_running = true
	_on_start()
	_setup_multiplayer()

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
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	other.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.2, 0.6, 1.0) if peer_id == 1 else Color(1.0, 0.5, 0.0)
	other.add_child(sprite)

	other.position = Vector2(160, 150) + Vector2((peer_id % 5) * 20 - 40, 0)
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

func end() -> void:
	is_running = false
	minigame_ended.emit(results)
	_on_end()

func get_results() -> Array:
	return results

func _on_start() -> void:
	pass

func _on_end() -> void:
	pass
