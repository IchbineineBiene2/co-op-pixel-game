extends MinigameBase

func _ready() -> void:
	var diff = GameManager.get_difficulty()
	start(diff)

const PLAYER_SPEED_EASY = 60.0
const PLAYER_SPEED_MEDIUM = 72.0
const PLAYER_SPEED_HARD = 84.0

var player: CharacterBody2D = null
var finish_line_y: float = 20.0
var rank: int = 1
var timer_label: Label = null

func _on_start() -> void:
	match difficulty:
		"easy":   time_left = 90.0
		"medium": time_left = 75.0
		"hard":   time_left = 60.0
	_create_race_scene()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _create_race_scene() -> void:
	# Zemin
	var ground = ColorRect.new()
	ground.size = Vector2(320, 180)
	ground.color = Color(0.15, 0.15, 0.2)
	add_child(ground)

	# Bitiş çizgisi
	var finish = ColorRect.new()
	finish.size = Vector2(320, 4)
	finish.position = Vector2(0, finish_line_y)
	finish.color = Color(1, 1, 0)
	add_child(finish)

	# Başlangıç çizgisi
	var start_line = ColorRect.new()
	start_line.size = Vector2(320, 4)
	start_line.position = Vector2(0, 150)
	start_line.color = Color(1, 1, 1)
	add_child(start_line)

	# Engeller (zorluk seviyesine göre)
	_create_obstacles()

	# Oyuncu
	player = CharacterBody2D.new()
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	player.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.2, 0.6, 1.0)
	player.add_child(sprite)

	player.position = Vector2(160, 150)
	add_child(player)

func _create_obstacles() -> void:
	var obstacle_count = 3
	if difficulty == "medium": obstacle_count = 5
	if difficulty == "hard":   obstacle_count = 8

	for i in range(obstacle_count):
		var obs = StaticBody2D.new()
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 10)
		col.shape = shape
		obs.add_child(col)

		var rect = ColorRect.new()
		rect.size = Vector2(30, 10)
		rect.position = Vector2(-15, -5)
		rect.color = Color(0.8, 0.3, 0.1)
		obs.add_child(rect)

		obs.position = Vector2(
			randf_range(20, 300),
			randf_range(40, 140)
		)
		add_child(obs)

func _physics_process(delta: float) -> void:
	if not is_running or player == null:
		return

	var speed = PLAYER_SPEED_EASY
	if difficulty == "medium": speed = PLAYER_SPEED_MEDIUM
	if difficulty == "hard":   speed = PLAYER_SPEED_HARD

	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 0:
		direction = direction.normalized()

	player.velocity = direction * speed
	player.move_and_slide()

	# Bitiş kontrolü
	if player.position.y <= finish_line_y + 10:
		_player_finished()

func _player_finished() -> void:
	var my_id = multiplayer.get_unique_id()
	results.append({
		"peer_id": my_id,
		"rank": rank,
		"zkr": _zkr_for_rank(rank),
		"medals": _medals_for_rank(rank)
	})
	rank += 1
	is_running = false
	print("Bitirdi! Sıra: ", rank - 1)
	get_tree().change_scene_to_file("res://scenes/ui/results.tscn")

func _zkr_for_rank(r: int) -> int:
	match r:
		1: return 150
		2: return 90
		3: return 50
		_: return 20

func _medals_for_rank(r: int) -> int:
	match r:
		1: return 3
		2: return 2
		3: return 1
		_: return 0

func _process(delta: float) -> void:
	if not is_running:
		return
	time_left -= delta
	if timer_label:
		timer_label.text = "Time: " + str(int(max(time_left, 0)))
	if time_left <= 0:
		is_running = false
		_finish_game()

func _finish_game() -> void:
	var zkr = 20
	var medals = 0
	PlayerData.add_zkr(zkr)
	PlayerData.add_medals(medals)
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/results.tscn")
