extends Node

# ── Karakter Görsel Verisi ───────────────────────────────────
var sprite_type: String = "human_male"   # human_male | human_female | robot | alien
var color_palette: int = 0               # 0-7 arası
var equipped_accessories: Array = []     # max 3 aksesuar

# ── Oyun İçi Ekonomi ─────────────────────────────────────────
var zkr: int = 0
var medals: int = 0

# ── Tur Bazlı Alımlar (oyun bitince sıfırlanır) ──────────────
var active_boosts: Array = []
var purchase_count: Dictionary = {}
# { "item_id": count } — dinamik fiyat için

# ── ZKR İşlemleri ────────────────────────────────────────────
func add_zkr(amount: int) -> void:
	zkr += amount

func spend_zkr(amount: int) -> bool:
	if zkr >= amount:
		zkr -= amount
		return true
	return false

# ── Madalyon İşlemleri ───────────────────────────────────────
func add_medals(amount: int) -> void:
	medals += amount

# ── Boost Sistemi ────────────────────────────────────────────
func add_boost(boost_id: String) -> void:
	if not active_boosts.has(boost_id):
		active_boosts.append(boost_id)

func has_boost(boost_id: String) -> bool:
	return active_boosts.has(boost_id)

func clear_boosts() -> void:
	active_boosts.clear()

# ── Dinamik Fiyat ────────────────────────────────────────────
func get_item_price(base_price: int, item_id: String) -> int:
	var count = purchase_count.get(item_id, 0)
	var multiplier = 1.0 + (count * 0.2)
	multiplier = min(multiplier, 3.0)  # max x3
	return int(base_price * multiplier)

func register_purchase(item_id: String) -> void:
	purchase_count[item_id] = purchase_count.get(item_id, 0) + 1

# ── Aksesuar Donanma ─────────────────────────────────────────
func equip_accessory(accessory_id: String) -> bool:
	if equipped_accessories.size() >= 3:
		return false  # max 3
	if not equipped_accessories.has(accessory_id):
		equipped_accessories.append(accessory_id)
		return true
	return false

func unequip_accessory(accessory_id: String) -> void:
	equipped_accessories.erase(accessory_id)

# ── Oyun Sıfırlama (oyunlar arası) ───────────────────────────
func reset_for_new_game() -> void:
	zkr = 0
	medals = 0
	active_boosts.clear()
	purchase_count.clear()

# ── Veriyi Dictionary'e Çevir (RPC için) ─────────────────────
func to_dict() -> Dictionary:
	return {
		"sprite_type": sprite_type,
		"color_palette": color_palette,
		"equipped_accessories": equipped_accessories,
		"zkr": zkr,
		"medals": medals
	}

func _ready() -> void:
	pass
