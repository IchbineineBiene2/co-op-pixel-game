extends MinigameBase

var npcs: Array = []
var bomb: ColorRect = null
var bomb_holder = null
var bomb_fuse: float = 5.0
var bomb_fuse_max: float = 5.0
var bomb_flying: bool = false
var bomb_velocity: Vector2 = Vector2.ZERO
var bomb_label: Label = null
var status_label: Label = null
var timer_label: Label = null

func _ready() -> void:
	var diff = GameManager.get_difficulty()
	start(diff)

func _on_start() -> void:
	match difficulty:
		"easy":   bomb_fuse_max = 5.0;   time_left = 120.0
		"medium": bomb_fuse_max = 3.5;   time_left = 100.0
		"hard":   bomb_fuse_max = 2.0;   time_left = 90.0
	bomb_fuse = bomb_fuse_max
	_create_scene()

func _create_scene() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.05, 0.08, 0.05)
	add_child(bg)

	status_label = Label.new()
	status_label.position = Vector2(100, 2)
	status_label.add_theme_font_size_override("font_size", 7)
	status_label.text = "Bombayı fırlat! (A)"
	add_child(status_label)

	# NPC'ler
	var npc_count = 2
	if difficulty == "medium": npc_count = 3
	if difficulty == "hard":   npc_count = 3
	var npc_positions = [Vector2(60, 60), Vector2(260, 60), Vector2(160, 130)]
	for i in range(npc_count):
		_spawn_npc(npc_positions[i])

	# Oyuncu
	player = CharacterBody2D.new()
	player.name = "Player"
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
	player.position = Vector2(160, 90)
	add_child(player)

	# Bomba
	bomb = ColorRect.new()
	bomb.size = Vector2(10, 10)
	bomb.color = Color(1, 0.9, 0.1)
	bomb.position = player.position - Vector2(5, 14)
	add_child(bomb)
	bomb_holder = player

	bomb_label = Label.new()
	bomb_label.add_theme_font_size_override("font_size", 6)
	bomb_label.position = Vector2(0, -12)
	bomb.add_child(bomb_label)

	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _spawn_npc(pos: Vector2) -> void:
	var npc = CharacterBody2D.new()
	npc.name = "NPC"
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	col.shape = shape
	npc.add_child(col)
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(1.0, 0.3, 0.3)
	npc.add_child(sprite)
	npc.position = pos
	npc.set_meta("move_dir", Vector2(randf_range(-1,1), randf_range(-1,1)).normalized())
	npc.set_meta("move_timer", randf_range(1.0, 3.0))
	add_child(npc)
	npcs.append(npc)

func _physics_process(delta: float) -> void:
	if not is_running or player == null:
		return

	# Oyuncu hareketi
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.length() > 0:
		direction = direction.normalized()
	player.velocity = direction * 70.0
	player.move_and_slide()
	if multiplayer.has_multiplayer_peer():
		_sync_position.rpc(player.position)

	# Bomba fırlat
	if Input.is_action_just_pressed("action_a") and bomb_holder == player and not bomb_flying:
		_throw_bomb()

	# Bomba hareketi
	if bomb_flying and is_instance_valid(bomb):
		bomb.position += bomb_velocity * delta
		bomb.position.x = clamp(bomb.position.x, 0, 310)
		bomb.position.y = clamp(bomb.position.y, 0, 170)
		_check_bomb_hit()

	# Bomba tutuluyorsa oyuncuyla taşı
	if not bomb_flying and bomb_holder == player and is_instance_valid(bomb):
		bomb.position = player.position - Vector2(5, 14)

	# Fitil sayacı
	bomb_fuse -= delta
	if bomb_label:
		bomb_label.text = str(snappedf(bomb_fuse, 0.1))
	if bomb_fuse <= 0:
		_bomb_explode_on_holder()

	# NPC hareketi
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var t = npc.get_meta("move_timer") - delta
		if t <= 0:
			npc.set_meta("move_dir", Vector2(randf_range(-1,1), randf_range(-1,1)).normalized())
			t = randf_range(1.0, 3.0)
		npc.set_meta("move_timer", t)
		npc.velocity = npc.get_meta("move_dir") * 35.0
		npc.move_and_slide()
		npc.position.x = clamp(npc.position.x, 10, 310)
		npc.position.y = clamp(npc.position.y, 10, 170)

func _throw_bomb() -> void:
	# En yakın NPC'yi bul
	var target = null
	var min_dist = INF
	for npc in npcs:
		if is_instance_valid(npc):
			var d = npc.position.distance_to(player.position)
			if d < min_dist:
				min_dist = d
				target = npc
	if target == null:
		return
	bomb_flying = true
	bomb_holder = null
	var dir = (target.position - bomb.position).normalized()
	bomb_velocity = dir * 140.0
	if status_label:
		status_label.text = "Bomba havada!"

func _check_bomb_hit() -> void:
	for npc in npcs.duplicate():
		if is_instance_valid(npc):
			if bomb.position.distance_to(npc.position) < 16:
				npc.queue_free()
				npcs.erase(npc)
				_reset_bomb()
				if npcs.is_empty():
					_victory()
					return
				# Bomba sonraki NPC'ye geç
				if status_label:
					status_label.text = "NPC elendi! Fırlat! (A)"
				return

func _reset_bomb() -> void:
	bomb_flying = false
	bomb_fuse = bomb_fuse_max
	bomb_holder = player

func _bomb_explode_on_holder() -> void:
	if bomb_holder == player:
		_game_over()
	else:
		# NPC'de patlarsa NPC elenir
		for npc in npcs.duplicate():
			if is_instance_valid(npc):
				if bomb.position.distance_to(npc.position) < 20:
					npc.queue_free()
					npcs.erase(npc)
					_reset_bomb()
					if npcs.is_empty():
						_victory()
					return
		_reset_bomb()

func _victory() -> void:
	var my_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	results.append({"peer_id": my_id, "rank": 1, "zkr": 150, "medals": 3})
	PlayerData.add_zkr(150)
	PlayerData.add_medals(3)
	is_running = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/results.tscn")

func _game_over() -> void:
	var my_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		my_id = multiplayer.get_unique_id()
	results.append({"peer_id": my_id, "rank": 4, "zkr": 20, "medals": 0})
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
