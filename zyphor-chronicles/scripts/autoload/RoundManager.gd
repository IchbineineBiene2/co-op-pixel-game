extends Node

const WAIT_TIME = 30.0  # bölgede bekleme süresi (saniye)

var timer: float = 0.0
var timer_running: bool = false
var players_in_zone: Array = []
var players_inside: Array = []
var players_ready: Dictionary = {}
var minigame_scene: String = ""

signal round_started
signal round_timer_tick(seconds_left: float)
signal player_missed_round(peer_id: int)
signal zone_count_updated(current: int, total: int)
signal zone_entered_alert(peer_id: int)

# ── Bölge Bekleme Sistemi ────────────────────────────────────
func player_entered_zone(peer_id: int, _zone: String = "") -> void:
	if not players_inside.has(peer_id):
		players_inside.append(peer_id)

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		update_zone_count.rpc(players_inside.size(), GameManager.players.size())

	if not timer_running:
		_start_timer()

# Tüm oyunculara zone girişini ve sayacı yayınlar
@rpc("any_peer", "call_local", "reliable")
func broadcast_zone_entered(peer_id: int) -> void:
	if not players_inside.has(peer_id):
		players_inside.append(peer_id)
	if not timer_running:
		_start_timer()
	zone_count_updated.emit(players_inside.size(), GameManager.players.size())
	zone_entered_alert.emit(peer_id)

@rpc("authority", "call_local", "reliable")
func update_zone_count(current: int, total: int) -> void:
	print("Bölgede: ", current, "/", total)
	zone_count_updated.emit(current, total)

func player_left_zone(peer_id: int) -> void:
	players_in_zone.erase(peer_id)

func _start_timer() -> void:
	timer = WAIT_TIME
	timer_running = true

func _process(delta: float) -> void:
	if not timer_running:
		return
	timer -= delta
	round_timer_tick.emit(timer)
	if timer <= 0.0:
		_launch_minigame()

func _launch_minigame() -> void:
	timer_running = false
	for peer_id in GameManager.players.keys():
		if not players_inside.has(peer_id):
			player_missed_round.emit(peer_id)
	round_started.emit()
	players_in_zone.clear()
	players_inside.clear()

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var scene = "res://scenes/minigames/" + GameManager.get_current_minigame() + ".tscn"
		NetworkManager.change_scene_for_all.rpc(scene)
	elif not multiplayer.has_multiplayer_peer():
		var scene = "res://scenes/minigames/" + GameManager.get_current_minigame() + ".tscn"
		get_tree().call_deferred("change_scene_to_file", scene)

# ── Tur Sonu ─────────────────────────────────────────────────
func end_round(results: Array) -> void:
	# results: [ { "peer_id": x, "rank": x, "zkr": x, "medals": x } ]
	for r in results:
		GameManager.add_zkr(r["peer_id"], r["zkr"])
		GameManager.add_medals(r["peer_id"], r["medals"])
	GameManager.next_round()
