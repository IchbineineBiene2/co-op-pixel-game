extends MinigameBase

var player: CharacterBody2D = null
var enemies: Array = []
var player_hp: float = 100.0
var max_hp: float = 100.0
var hp_bar: ColorRect = null
var hp_label: Label = null
var timer_label: Label = null
var enemies_defeated: int = 0

func _ready() -> void:
	var diff = GameManager.get_difficulty()
	start(diff)

func _on_start() -> void:
	match difficulty:
		"easy":
			time_left = 120.0
			max_hp = 100.0
		"medium":
			time_left = 100.0
			max_hp = 80.0
		"hard":
			time_left = 90.0
			max_hp = 70.0
	player_hp = max_hp
	_create_arena()

func _create_arena() -> void:
	# Zemin
	var bg = ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.2, 0.1, 0.1)
	add_child(bg)

	# Arena sınırları
	var border_color = Color(0.6, 0.2, 0.2)
	for border in [
		[Vector2(0, 0), Vector2(320, 8)],
		[Vector2(0, 172), Vector2(320, 8)],
		[Vector2(0, 0), Vector2(8, 180)],
		[Vector2(312, 0), Vector2(8, 180)],
	]:
		var wall = ColorRect.new()
		wall.position = border[0]
		wall.size = border[1]
		wall.color = border_color
		add_child(wall)

	# HP bar
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(80, 8)
	hp_bg.position = Vector2(4, 16)
	hp_bg.color = Color(0.4, 0, 0)
	add_child(hp_bg)

	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(80, 8)
	hp_bar.position = Vector2(4, 16)
	hp_bar.color = Color(0, 0.8, 0.2)
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.position = Vector2(4, 26)
	hp_label.add_theme_font_size_override("font_size", 6)
	hp_label.text = "HP: " + str(int(player_hp))
	add_child(hp_label)

	# Düşmanlar
	var enemy_count = 2
	if difficulty == "medium": enemy_count = 3
	if difficulty == "hard":   enemy_count = 4

	for i in range(enemy_count):
		_spawn_enemy(Vector2(randf_range(30, 290), randf_range(30, 150)))

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

	player.position = Vector2(160, 140)
	add_child(player)

	# HUD
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _spawn_enemy(pos: Vector2) -> void:
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy"

	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	enemy.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(1.0, 0.3, 0.3)
	enemy.add_child(sprite)

	enemy.position = pos
	enemy.set_meta("hp", 30.0)
	add_child(enemy)
	enemies.append(enemy)

func _physics_process(delta: float) -> void:
	if not is_running or player == null:
		return

	# Oyuncu hareketi
	var speed = 70.0
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.length() > 0:
		direction = direction.normalized()
	player.velocity = direction * speed
	player.move_and_slide()

	# Saldırı
	if Input.is_action_just_pressed("action_a"):
		_attack()

	# Düşman AI
	for enemy in enemies:
		if is_instance_valid(enemy):
			var e_dir = (player.position - enemy.position).normalized()
			enemy.velocity = e_dir * 25.0
			enemy.move_and_slide()

			# Çarpışma hasarı
			if enemy.position.distance_to(player.position) < 14:
				player_hp -= 8.0 * delta
				_update_hp_bar()
				if player_hp <= 0:
					_game_over()

func _attack() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.position.distance_to(player.position) < 24:
				var hp = enemy.get_meta("hp") - 15.0
				enemy.set_meta("hp", hp)
				if hp <= 0:
					enemy.queue_free()
					enemies.erase(enemy)
					enemies_defeated += 1
					if enemies.is_empty():
						_victory()

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.size.x = 80.0 * (player_hp / max_hp)
	if hp_label:
		hp_label.text = "HP: " + str(int(max(player_hp, 0)))

func _victory() -> void:
	var my_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	results.append({
		"peer_id": my_id,
		"rank": 1,
		"zkr": 150,
		"medals": 3
	})
	PlayerData.add_zkr(150)
	PlayerData.add_medals(3)
	is_running = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/results.tscn")

func _game_over() -> void:
	var my_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	results.append({
		"peer_id": my_id,
		"rank": 4,
		"zkr": 20,
		"medals": 0
	})
	PlayerData.add_zkr(20)
	is_running = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/results.tscn")

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
