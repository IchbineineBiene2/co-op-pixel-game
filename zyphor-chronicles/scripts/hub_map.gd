extends Node2D

const ZONE_SCENES = {
	"vrix": "res://scenes/zones/vrix_market.tscn",
	"glonar": "res://scenes/zones/glonar_arena.tscn",
	"nebula": "res://scenes/zones/nebula_factory_zone.tscn",
	"xora": "res://scenes/zones/xora_temple.tscn",
	"throne": "res://scenes/zones/zyphor_throne.tscn",
}

var player: CharacterBody2D = null
var camera: Camera2D = null

func _ready() -> void:
	_create_hub()
	_create_player()
	_create_camera()
	_create_zone_portals()
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	RoundManager.zone_count_updated.connect(_on_zone_count_updated)
	RoundManager.round_timer_tick.connect(_on_timer_tick)

func _create_hub() -> void:
	var ground = ColorRect.new()
	ground.size = Vector2(640, 640)
	ground.position = Vector2(-320, -320)
	ground.color = Color(0.15, 0.15, 0.2)
	add_child(ground)

	var center = ColorRect.new()
	center.size = Vector2(120, 120)
	center.position = Vector2(-60, -60)
	center.color = Color(0.25, 0.25, 0.35)
	add_child(center)

	var road_color = Color(0.2, 0.2, 0.28)
	var roads = [
		[Vector2(-20, -320), Vector2(40, 260)],
		[Vector2(-20, 60), Vector2(40, 260)],
		[Vector2(-320, -20), Vector2(260, 40)],
		[Vector2(60, -20), Vector2(260, 40)],
		[Vector2(-260, -260), Vector2(30, 200)],
		[Vector2(60, -260), Vector2(200, 30)],
		[Vector2(-260, 60), Vector2(200, 30)],
		[Vector2(60, 60), Vector2(200, 200)],
	]
	for r in roads:
		var road = ColorRect.new()
		road.position = r[0]
		road.size = r[1]
		road.color = road_color
		add_child(road)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"

	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	col.shape = shape
	player.add_child(col)

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color(0.2, 0.6, 1.0)
	player.add_child(sprite)

	player.position = Vector2(0, 0)
	add_child(player)

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.limit_left = -320
	camera.limit_right = 320
	camera.limit_top = -320
	camera.limit_bottom = 320
	player.add_child(camera)

func _create_zone_portals() -> void:
	var portals = [
		{"name": "Vrix Pazarı", "pos": Vector2(0, -280), "color": Color(1, 0.8, 0, 0.8), "zone": "vrix"},
		{"name": "Glonar Arenası", "pos": Vector2(0, 280), "color": Color(1, 0.3, 0.3, 0.8), "zone": "glonar"},
		{"name": "Nebula Fabrikası", "pos": Vector2(-280, 0), "color": Color(0.3, 0.8, 1, 0.8), "zone": "nebula"},
		{"name": "Xora Tapınağı", "pos": Vector2(280, 0), "color": Color(0.8, 0.3, 1, 0.8), "zone": "xora"},
		{"name": "Zyphor Tahtı", "pos": Vector2(200, -200), "color": Color(1, 0.9, 0, 0.8), "zone": "throne"},
	]

	for portal_data in portals:
		var portal = Area2D.new()
		portal.name = "Portal_" + portal_data["zone"]

		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 24.0
		col.shape = shape
		portal.add_child(col)

		var visual = ColorRect.new()
		visual.size = Vector2(48, 48)
		visual.position = Vector2(-24, -24)
		visual.color = portal_data["color"]
		portal.add_child(visual)

		var label = Label.new()
		label.text = portal_data["name"]
		label.position = Vector2(-30, -40)
		label.add_theme_font_size_override("font_size", 6)
		portal.add_child(label)

		portal.position = portal_data["pos"]
		var zone_key: String = portal_data["zone"]
		var zone_name_text: String = portal_data["name"]
		portal.body_entered.connect(func(body): _on_portal_entered(zone_key, zone_name_text, body))
		add_child(portal)

func _on_portal_entered(zone_key: String, zone_name_text: String, body: Node2D) -> void:
	if body.name != "Player":
		return
	if zone_key == "throne" and not GameManager.check_win_condition(multiplayer.get_unique_id()):
		_show_blocked_message("Yeterli madalyon yok!")
		return
	_show_transition(zone_key, zone_name_text)

func _show_blocked_message(msg: String) -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var label = Label.new()
	label.text = msg
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 10)
	label.modulate = Color(1, 0.3, 0.3, 1)
	canvas.add_child(label)
	var tween = create_tween().set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_callback(canvas.queue_free)

func _show_transition(zone_key: String, zone_name_text: String) -> void:
	set_physics_process(false)

	var canvas = CanvasLayer.new()
	add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var label = Label.new()
	label.text = zone_name_text
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(1, 1, 1, 0)
	canvas.add_child(label)

	var tween = create_tween().set_parallel(false)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.5)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(ZONE_SCENES[zone_key])
	)

func _on_zone_count_updated(current: int, total: int) -> void:
	if not has_node("WaitingCanvas"):
		var canvas = CanvasLayer.new()
		canvas.name = "WaitingCanvas"
		add_child(canvas)
		var lbl = Label.new()
		lbl.name = "WaitingLabel"
		lbl.position = Vector2(110, 8)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.modulate = Color(1, 1, 0)
		canvas.add_child(lbl)
	$WaitingCanvas/WaitingLabel.text = "Bölgede: " + str(current) + "/" + str(total)

func _on_timer_tick(seconds_left: float) -> void:
	if has_node("WaitingCanvas/WaitingLabel"):
		$WaitingCanvas/WaitingLabel.text += "  (" + str(int(seconds_left)) + "sn)"

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var speed = 80.0
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.length() > 0:
		direction = direction.normalized()
	player.velocity = direction * speed
	player.move_and_slide()
