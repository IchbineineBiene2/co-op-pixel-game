extends Node

# ── Oyuncu Sayısı & Madalyon Eşiği ──────────────────────────
var player_count: int = 0
var medal_threshold: int = 20

func calculate_threshold(count: int) -> int:
	if count <= 2:   return 12
	elif count <= 4: return 16
	elif count <= 6: return 20
	else:            return 25

# ── Tur Sistemi ──────────────────────────────────────────────
var current_round: int = 0
var minigame_order: Array = []
const MINIGAMES = [
	"vrix_race",
	"glonar_fight",
	"nebula_factory",
	"xora_memory",
    "zyphor_bomb"
]

func shuffle_minigames() -> void:
	minigame_order = MINIGAMES.duplicate()
	minigame_order.shuffle()

func get_current_minigame() -> String:
	var idx = current_round % minigame_order.size()
	return minigame_order[idx]

func get_difficulty() -> String:
	if current_round < 2:   return "easy"
	elif current_round < 4: return "medium"
	else:                   return "hard"

func next_round() -> void:
	current_round += 1
	if current_round % MINIGAMES.size() == 0:
		shuffle_minigames()

# ── Oyuncu Verileri ──────────────────────────────────────────
var players: Dictionary = {}
# { peer_id: { "name": "", "zkr": 0, "medals": 0 } }

func register_player(peer_id: int, player_name: String) -> void:
	players[peer_id] = {
		"name": player_name,
		"zkr": 0,
		"medals": 0
	}
	player_count = players.size()
	medal_threshold = calculate_threshold(player_count)

func add_zkr(peer_id: int, amount: int) -> void:
	if players.has(peer_id):
		players[peer_id]["zkr"] += amount

func add_medals(peer_id: int, amount: int) -> void:
	if players.has(peer_id):
		players[peer_id]["medals"] += amount

func check_win_condition(peer_id: int) -> bool:
	if not players.has(peer_id):
		return false
	return players[peer_id]["medals"] >= medal_threshold

# ── Oyunu Sıfırla ────────────────────────────────────────────
func reset_game() -> void:
	current_round = 0
	players.clear()
	player_count = 0
	shuffle_minigames()

func _ready() -> void:
	shuffle_minigames()
