extends Area2D

@export var zone_name: String = ""
@export var minigame_scene: String = ""
@export var zone_color: Color = Color(1.0, 0.8, 0.0, 0.3)

var players_inside: Array = []
var label: Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Görsel
	var rect = ColorRect.new()
	rect.size = Vector2(48, 48)
	rect.position = Vector2(-24, -24)
	rect.color = zone_color
	add_child(rect)

	# İsim etiketi
	label = Label.new()
	label.text = zone_name
	label.position = Vector2(-24, -40)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)

	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	collision.shape = shape
	add_child(collision)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		players_inside.append(body)
		RoundManager.player_entered_zone(multiplayer.get_unique_id())
		print(zone_name, " bölgesine girildi!")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		players_inside.erase(body)
		RoundManager.player_left_zone(multiplayer.get_unique_id())
		print(zone_name, " bölgesinden çıkıldı!")
