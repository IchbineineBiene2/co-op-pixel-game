extends Node

const WAIT_TIME = 30.0  # bölgede bekleme süresi (saniye)

var timer: float = 0.0
var timer_running: bool = false
var players_in_zone: Array = []

signal round_started
signal round_timer_tick(seconds_left: float)
signal player_missed_round(peer_id: int)

# ── Bölge Bekleme Sistemi ────────────────────────────────────
func player_entered_zone(peer_id: int) -> void:
	if not players_in_zone.has(peer_id):
		players_in_zone.append(peer_id)
	if not timer_running:
		_start_timer()

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
	# Gelmeyen oyuncular turu atlar
	for peer_id in GameManager.players.keys():
		if not players_in_zone.has(peer_id):
			player_missed_round.emit(peer_id)
	round_started.emit()
	players_in_zone.clear()

# ── Tur Sonu ─────────────────────────────────────────────────
func end_round(results: Array) -> void:
	# results: [ { "peer_id": x, "rank": x, "zkr": x, "medals": x } ]
	for r in results:
		GameManager.add_zkr(r["peer_id"], r["zkr"])
		GameManager.add_medals(r["peer_id"], r["medals"])
	GameManager.next_round()
