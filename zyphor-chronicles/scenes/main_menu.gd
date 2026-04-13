extends Node2D

func _ready() -> void:
	$CanvasLayer/VBoxContainer/Label.text = tr("GAME_TITLE")
	$CanvasLayer/VBoxContainer/Button.text = tr("BTN_HOST")
	$CanvasLayer/VBoxContainer/Button2.text = tr("BTN_JOIN")
	$CanvasLayer/VBoxContainer/Button3.text = tr("BTN_QUIT")

	$CanvasLayer/VBoxContainer/Button.pressed.connect(_on_host_pressed)
	$CanvasLayer/VBoxContainer/Button2.pressed.connect(_on_join_pressed)
	$CanvasLayer/VBoxContainer/Button3.pressed.connect(_on_quit_pressed)

func _on_host_pressed() -> void:
	NetworkManager.host_game()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_join_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
