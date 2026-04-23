extends Node

const PORT = 7779
const MAX_PLAYERS = 8

var peer = null

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal connection_failed
signal connection_succeeded

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# ── Host ─────────────────────────────────────────────────────
func host_game() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		peer = null
		push_error("Host kurulamadı, port: " + str(PORT) + " hata: " + str(error))
		return
	multiplayer.multiplayer_peer = peer
	print("Host kuruldu, port: ", PORT)

# ── Join ─────────────────────────────────────────────────────
func join_game(ip: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		push_error("Bağlanılamadı: " + str(error))
		peer = null
		return
	multiplayer.multiplayer_peer = peer
	print("Bağlanılıyor: ", ip)

# ── Disconnect ───────────────────────────────────────────────
func disconnect_game() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	GameManager.reset_game()

# ── Callbacks ────────────────────────────────────────────────
func _on_peer_connected(id: int) -> void:
	print("Oyuncu bağlandı: ", id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("Oyuncu ayrıldı: ", id)
	GameManager.players.erase(id)
	player_disconnected.emit(id)

# ── RPC: Oyun Durumu Senkronizasyonu ─────────────────────────
@rpc("any_peer", "reliable")
func request_game_state() -> void:
	if not multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	GameManager.sync_minigame_order.rpc_id(sender, GameManager.minigame_order)
	GameManager.sync_round.rpc_id(sender, GameManager.current_round)

func _on_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	connection_succeeded.emit()
	print("Sunucuya bağlandı, ID: ", my_id)
	request_game_state.rpc_id(1)

func _on_connection_failed() -> void:
	connection_failed.emit()
	push_error("Bağlantı başarısız.")

# ── RPC: Sahne Geçişi ────────────────────────────────────────
@rpc("authority", "call_local", "reliable")
func change_scene_for_all(scene_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", scene_path)

@rpc("any_peer", "reliable")
func request_scene_change(scene_path: String) -> void:
	if not multiplayer.is_server():
		return
	change_scene_for_all.rpc(scene_path)

# ── RPC: Oyuncu Verisi Sync ──────────────────────────────────
@rpc("any_peer", "call_local", "reliable")
func sync_player_data(peer_id: int, player_name: String) -> void:
	GameManager.register_player(peer_id, player_name)
	print("Oyuncu sync: ", peer_id, " - ", player_name)
