extends Node

enum TimeOfDay { DAY, NIGHT }
enum Weather { CLEAR, RAIN, SNOW, FOG, STORM }

var current_time: TimeOfDay = TimeOfDay.DAY
var current_weather: Weather = Weather.CLEAR
var rounds_since_change: int = 0

signal time_changed(new_time: TimeOfDay)
signal weather_changed(new_weather: Weather)

# ── Her Tur Sonunda Çağrılır ─────────────────────────────────
func on_round_end() -> void:
	rounds_since_change += 1
	if rounds_since_change >= 3:
		_toggle_time()
		rounds_since_change = 0
	_maybe_change_weather()

# ── Gün / Gece Geçişi ────────────────────────────────────────
func _toggle_time() -> void:
	if current_time == TimeOfDay.DAY:
		current_time = TimeOfDay.NIGHT
	else:
		current_time = TimeOfDay.DAY
	time_changed.emit(current_time)

# ── Hava Durumu ──────────────────────────────────────────────
func _maybe_change_weather() -> void:
	# %30 ihtimalle hava değişir
	if randf() > 0.7:
		var options = [
			Weather.CLEAR,
			Weather.RAIN,
			Weather.SNOW,
			Weather.FOG,
			Weather.STORM
		]
		current_weather = options[randi() % options.size()]
		weather_changed.emit(current_weather)

# ── Mevcut Durumu Döndür ─────────────────────────────────────
func get_time_name() -> String:
	return "Gündüz" if current_time == TimeOfDay.DAY else "Gece"

func get_weather_name() -> String:
	match current_weather:
		Weather.CLEAR: return "Açık"
		Weather.RAIN:  return "Yağmur"
		Weather.SNOW:  return "Kar"
		Weather.FOG:   return "Sis"
		Weather.STORM: return "Fırtına"
	return "Açık"

func _ready() -> void:
	pass
