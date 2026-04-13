extends Node

const SAVE_PATH = "user://player_data.json"

var unlocked_accessories: Array = []
var player_name: String = "Player"

# ── Yükle ────────────────────────────────────────────────────
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_init_default_data()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Save dosyası okunamadı.")
		_init_default_data()
		return

	var data = json.get_data()
	player_name = data.get("player_name", "Player")
	unlocked_accessories = data.get("unlocked_accessories", _default_accessories())

# ── Kaydet ───────────────────────────────────────────────────
func save_data() -> void:
	var data = {
		"player_name": player_name,
		"unlocked_accessories": unlocked_accessories
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

# ── Aksesuar Unlock ──────────────────────────────────────────
func unlock_accessory(accessory_id: String) -> void:
	if not unlocked_accessories.has(accessory_id):
		unlocked_accessories.append(accessory_id)
		save_data()

func has_accessory(accessory_id: String) -> bool:
	return unlocked_accessories.has(accessory_id)

# ── Varsayılan Veri ──────────────────────────────────────────
func _init_default_data() -> void:
	player_name = "Player"
	unlocked_accessories = _default_accessories()
	save_data()

func _default_accessories() -> Array:
	# Başlangıçta açık olan 5 aksesuar
	return [
		"standart_kask",
		"gezgin_cantasi",
		"basit_gozluk",
		"kucuk_pelerin",
        "renkli_bant"
	]

func _ready() -> void:
	load_data()
