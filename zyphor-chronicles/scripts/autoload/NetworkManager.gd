extends Node

const PORT = 7777
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
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		push_error("Host kurulamadı: " + str(error))
		return
	multiplayer.multiplayer_peer = peer
	print("Host kuruldu, port: ", PORT)

# ── Join ─────────────────────────────────────────────────────
func join_game(ip: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		push_error("Bağlanılamadı: " + str(error))
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

func _on_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	connection_succeeded.emit()
	print("Sunucuya bağlandı, ID: ", my_id)

func _on_connection_failed() -> void:
	connection_failed.emit()
	push_error("Bağlantı başarısız.")

# ── RPC: Sahne Geçişi ────────────────────────────────────────
@rpc("authority", "call_local", "reliable")
func change_scene_for_all(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
