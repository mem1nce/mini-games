extends RefCounted
# WhackGameState: skor, can, seviye ve rekor. Olaylar sinyallerle gider; ekranı oyun sahnesi günceller.
# Rekor user://kostebek.cfg içinde ([rekor] skor). Ana menü rozeti de buradan okur.

signal score_changed(score: int, delta: int, at: Vector2)
signal life_lost(lives_left: int)
signal level_up(level: int)
signal game_over

const SAVE_PATH := "user://kostebek.cfg"

var balance: WhackBalance
var score: int = 0
var lives: int = 3
var level: int = 1
var best: int = 0


func _init(game_balance: WhackBalance) -> void:
	balance = game_balance
	best = load_best()
	reset()


func reset() -> void:
	score = 0
	lives = balance.lives
	level = 1


func add_points(points: int, at: Vector2) -> void:
	if lives <= 0:
		return
	score += points
	score_changed.emit(score, points, at)
	var new_level := balance.level_for_score(score)
	if new_level > level:
		level = new_level
		level_up.emit(level)


func lose_life() -> void:
	if lives <= 0:
		return
	lives -= 1
	life_lost.emit(lives)
	if lives == 0:
		game_over.emit()


# Oyun sonunda çağrılır: rekor kırıldıysa kaydeder ve true döner
func finish() -> bool:
	if score <= best:
		return false
	best = score
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("rekor", "skor", best)
	config.save(SAVE_PATH)
	return true


static func load_best() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value("rekor", "skor", 0))
