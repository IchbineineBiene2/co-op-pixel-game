extends CanvasLayer

var zkr_label: Label
var medals_label: Label
var round_label: Label
var timer_label: Label

func _ready() -> void:
	_create_hud()

func _create_hud() -> void:
	# Arka plan şeridi
	var bg = ColorRect.new()
	bg.size = Vector2(320, 14)
	bg.position = Vector2(0, 0)
	bg.color = Color(0, 0, 0, 0.6)
	add_child(bg)

	# ZKR
	zkr_label = Label.new()
	zkr_label.position = Vector2(4, 2)
	zkr_label.add_theme_font_size_override("font_size", 7)
	zkr_label.text = "ZKR: 0"
	add_child(zkr_label)

	# Madalyon
	medals_label = Label.new()
	medals_label.position = Vector2(80, 2)
	medals_label.add_theme_font_size_override("font_size", 7)
	medals_label.text = "Medal: 0"
	add_child(medals_label)

	# Tur
	round_label = Label.new()
	round_label.position = Vector2(160, 2)
	round_label.add_theme_font_size_override("font_size", 7)
	round_label.text = "Round: 1"
	add_child(round_label)

	# Timer
	timer_label = Label.new()
	timer_label.position = Vector2(260, 2)
	timer_label.add_theme_font_size_override("font_size", 7)
	timer_label.text = ""
	add_child(timer_label)

func _process(_delta: float) -> void:
	var my_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()

	if GameManager.players.has(my_id):
		zkr_label.text = "ZKR: " + str(GameManager.players[my_id]["zkr"])
		medals_label.text = "Medal: " + str(GameManager.players[my_id]["medals"])
	else:
		zkr_label.text = "ZKR: " + str(PlayerData.zkr)
		medals_label.text = "Medal: " + str(PlayerData.medals)

	round_label.text = "Round: " + str(GameManager.current_round + 1)

	if RoundManager.timer_running:
		timer_label.text = "Start: " + str(int(RoundManager.timer))
	else:
		timer_label.text = ""
