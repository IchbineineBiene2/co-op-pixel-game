extends Node2D
class_name MinigameBase

var difficulty: String = "easy"
var results: Array = []
var time_left: float = 90.0
var is_running: bool = false

signal minigame_ended(results)

func start(diff: String) -> void:
	difficulty = diff
	is_running = true
	_on_start()

func end() -> void:
	is_running = false
	minigame_ended.emit(results)
	_on_end()

func get_results() -> Array:
	return results

func _on_start() -> void:
	pass

func _on_end() -> void:
	pass
