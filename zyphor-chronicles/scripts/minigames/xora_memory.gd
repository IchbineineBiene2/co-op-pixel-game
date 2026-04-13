extends MinigameBase

var cols: int = 4
var rows: int = 4
var card_size: float = 16.0
var card_gap: float = 3.0
var cards: Array = []
var flipped: Array = []
var matched_pairs: int = 0
var total_pairs: int = 8
var reveal_time: float = 3.0
var reveal_timer: float = 0.0
var revealing: bool = true
var check_timer: float = 0.0
var checking: bool = false
var cursor_index: int = 0
var score_label: Label = null
var cursor_rect: ColorRect = null

const PAIR_COLORS = [
	Color(1,0.3,0.3), Color(0.3,0.5,1), Color(0.3,0.9,0.3), Color(0.9,0.8,0.2),
	Color(0.8,0.3,0.9), Color(1,0.6,0.2), Color(0.2,0.9,0.9), Color(0.9,0.9,0.9),
	Color(0.6,0.4,0.2), Color(0.4,0.8,0.4), Color(1,0.4,0.7), Color(0.4,0.4,1),
	Color(0.7,1,0.3), Color(1,0.7,0.5), Color(0.5,0.5,0.9), Color(0.9,0.5,0.3),
]

func _ready() -> void:
	var diff = GameManager.get_difficulty()
	start(diff)

func _on_start() -> void:
	match difficulty:
		"easy":
			cols = 4; rows = 4; total_pairs = 8; reveal_time = 3.0; time_left = 180.0
		"medium":
			cols = 6; rows = 4; total_pairs = 12; reveal_time = 2.0; time_left = 150.0
		"hard":
			cols = 8; rows = 4; total_pairs = 16; reveal_time = 1.0; time_left = 120.0
	_create_scene()

func _create_scene() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.08, 0.08, 0.15)
	add_child(bg)

	score_label = Label.new()
	score_label.position = Vector2(120, 2)
	score_label.add_theme_font_size_override("font_size", 7)
	score_label.text = "Pairs: 0/" + str(total_pairs)
	add_child(score_label)

	# Kartları oluştur ve karıştır
	var color_indices: Array = []
	for i in range(total_pairs):
		color_indices.append(i)
		color_indices.append(i)
	color_indices.shuffle()

	var total_cards = cols * rows
	var start_x = (320.0 - cols * (card_size + card_gap)) / 2.0 + card_gap / 2.0
	var start_y = (180.0 - rows * (card_size + card_gap)) / 2.0 + card_gap / 2.0 + 6.0

	for i in range(total_cards):
		var ci = color_indices[i] if i < color_indices.size() else 0
		var col_i = i % cols
		var row_i = i / cols
		var pos = Vector2(start_x + col_i * (card_size + card_gap), start_y + row_i * (card_size + card_gap))

		# Kart arka yüzü
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(card_size, card_size)
		card_bg.position = pos
		card_bg.color = Color(0.3, 0.3, 0.5)
		add_child(card_bg)

		# Kart ön yüzü (renk)
		var card_face = ColorRect.new()
		card_face.size = Vector2(card_size, card_size)
		card_face.position = pos
		card_face.color = PAIR_COLORS[ci]
		card_face.visible = true
		add_child(card_face)

		cards.append({
			"bg": card_bg,
			"face": card_face,
			"color_index": ci,
			"flipped": false,
			"matched": false
		})

	# Cursor
	cursor_rect = ColorRect.new()
	cursor_rect.size = Vector2(card_size + 2, card_size + 2)
	cursor_rect.color = Color(1, 1, 1, 0.5)
	cursor_rect.z_index = 10
	add_child(cursor_rect)
	_update_cursor()

	reveal_timer = reveal_time
	revealing = true

	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _update_cursor() -> void:
	if cursor_rect == null or cards.is_empty():
		return
	var card = cards[cursor_index]
	cursor_rect.position = card["face"].position - Vector2(1, 1)

func _process(delta: float) -> void:
	if not is_running:
		return
	time_left -= delta
	if time_left <= 0:
		is_running = false
		_finish_game()
		return

	# Reveal fazı: kartları kısa süre göster
	if revealing:
		reveal_timer -= delta
		if reveal_timer <= 0:
			revealing = false
			for card in cards:
				card["face"].visible = false
		return

	# Eşleşme kontrolü bekleme
	if checking:
		check_timer -= delta
		if check_timer <= 0:
			checking = false
			_check_match()
		return

	# Cursor hareketi
	if Input.is_action_just_pressed("move_right"):
		cursor_index = (cursor_index + 1) % cards.size()
		_update_cursor()
	elif Input.is_action_just_pressed("move_left"):
		cursor_index = (cursor_index - 1 + cards.size()) % cards.size()
		_update_cursor()
	elif Input.is_action_just_pressed("move_down"):
		cursor_index = (cursor_index + cols) % cards.size()
		_update_cursor()
	elif Input.is_action_just_pressed("move_up"):
		cursor_index = (cursor_index - cols + cards.size()) % cards.size()
		_update_cursor()

	if Input.is_action_just_pressed("action_a"):
		_flip_card(cursor_index)

func _flip_card(index: int) -> void:
	var card = cards[index]
	if card["matched"] or card["flipped"] or flipped.size() >= 2:
		return
	card["flipped"] = true
	card["face"].visible = true
	flipped.append(index)
	if flipped.size() == 2:
		checking = true
		check_timer = 0.8

func _check_match() -> void:
	if flipped.size() < 2:
		flipped.clear()
		return
	var a = cards[flipped[0]]
	var b = cards[flipped[1]]
	if a["color_index"] == b["color_index"]:
		a["matched"] = true
		b["matched"] = true
		matched_pairs += 1
		if score_label:
			score_label.text = "Pairs: " + str(matched_pairs) + "/" + str(total_pairs)
		if matched_pairs >= total_pairs:
			end()
	else:
		a["flipped"] = false
		b["flipped"] = false
		a["face"].visible = false
		b["face"].visible = false
	flipped.clear()

func _on_end() -> void:
	_finish_game()

func _finish_game() -> void:
	var ratio = float(matched_pairs) / float(total_pairs)
	var zkr = int(150 * ratio)
	var medals = 0
	if ratio >= 1.0: medals = 3
	elif ratio >= 0.6: medals = 2
	elif ratio >= 0.3: medals = 1
	PlayerData.add_zkr(zkr)
	PlayerData.add_medals(medals)
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/results.tscn")
