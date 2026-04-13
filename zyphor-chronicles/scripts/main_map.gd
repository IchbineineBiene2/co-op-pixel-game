extends Node2D

const SPEED = 80.0

var player: CharacterBody2D = null

func _ready() -> void:
	_create_player()
	_create_zones()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	collision.shape = shape
	player.add_child(collision)

	# Görsel (şimdilik renkli kutu)
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color(0.2, 0.6, 1.0)
	player.add_child(sprite)

	player.position = Vector2(30, 160)
	add_child(player)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 0:
		direction = direction.normalized()

	player.velocity = direction * SPEED
	player.move_and_slide()

func _create_zones() -> void:
	var zones = [
		{"name": "Vrix Pazarı", "pos": Vector2(60, 50),  "color": Color(1,0.8,0,0.3), "scene": "res://scenes/minigames/vrix_race.tscn"},
		{"name": "Glonar Arenası", "pos": Vector2(260, 50),  "color": Color(1,0.3,0.3,0.3), "scene": "res://scenes/minigames/glonar_fight.tscn"},
		{"name": "Nebula Fabrikası", "pos": Vector2(60, 130), "color": Color(0.3,0.8,1,0.3), "scene": "res://scenes/minigames/nebula_factory.tscn"},
		{"name": "Xora Tapınağı", "pos": Vector2(260, 130), "color": Color(0.8,0.3,1,0.3), "scene": "res://scenes/minigames/xora_memory.tscn"},
		{"name": "Zyphor Tahtı", "pos": Vector2(160, 90),  "color": Color(1,0.9,0,0.5), "scene": ""},
	]

	for z in zones:
		var zone = preload("res://scripts/zone_trigger.gd")
		var area = Area2D.new()
		area.set_script(zone)
		area.zone_name = z["name"]
		area.zone_color = z["color"]
		area.position = z["pos"]
		area.minigame_scene = z.get("scene", "")
		add_child(area)
