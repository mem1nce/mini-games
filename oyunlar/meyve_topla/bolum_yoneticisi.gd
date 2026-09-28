extends Node
# Bölüm yöneticisi: hangi bölümdeyiz, ne zaman ne düşecek, ilerleme ve kayıt.

signal spawn_requested(kind: String, windy: bool)
signal progress_changed(count: int, goal: int)
signal level_completed

const Data := preload("res://oyunlar/meyve_topla/bolumler.gd")
const SAVE_PATH := "user://meyve_topla.cfg"
const POWERUPS := ["buyuk_sepet", "miknatis", "yavas"]
const BAD_ITEMS := ["curuk_elma", "tas"]

var level_index: int = 0       # 0'dan başlar; ekranda +1 gösterilir
var saved_index: int = 0       # kaldığı bölüm
var level: Dictionary = {}
var collected: int = 0
var spawning: bool = false
var _timer: float = 0.0
var _last_fruit: String = ""


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		saved_index = maxi(int(config.get_value("ilerleme", "bolum", 0)), 0)


func save_progress(index: int) -> void:
	saved_index = index
	var config := ConfigFile.new()
	config.set_value("ilerleme", "bolum", index)
	config.save(SAVE_PATH)


func reset_progress() -> void:
	save_progress(0)


func start_level(index: int) -> void:
	level_index = index
	level = Data.get_level(index)
	collected = 0
	spawning = false
	_timer = 0.5  # ilk nesne hemen gelsin
	progress_changed.emit(0, goal())


func goal() -> int:
	return level.get("goal", 10)


func target_fruit() -> String:
	return level.get("target_fruit", "")


func background() -> String:
	return level.get("background", "sabah")


func fall_speed() -> float:
	return level.get("fall_speed", 200.0)


# Bu meyve ilerlemeye sayılır mı? (hedef meyve bölümünde sadece hedef sayılır)
func counts(kind: String) -> bool:
	return target_fruit() == "" or kind == target_fruit()


static func category_of(kind: String) -> String:
	if kind in POWERUPS:
		return "guc"
	if kind in BAD_ITEMS:
		return "kotu"
	return "meyve"


# Her karede çağrılır; delta yavaşlatma güçlendirmesine göre ölçeklenmiş olabilir
func update(delta: float, allow_powerup: bool) -> void:
	if not spawning:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = float(level["spawn_interval"]) * randf_range(0.85, 1.15)
	var kind := _pick_kind(allow_powerup)
	var windy := category_of(kind) == "meyve" and randf() < float(level["wind"])
	spawn_requested.emit(kind, windy)


func _pick_kind(allow_powerup: bool) -> String:
	if allow_powerup and randf() < float(level["powerup_chance"]):
		return POWERUPS.pick_random()
	var bad: Array = level["bad"]
	if not bad.is_empty() and randf() < float(level["bad_chance"]):
		return bad.pick_random()
	if target_fruit() != "" and randf() < float(level["target_share"]):
		return target_fruit()
	# Aynı meyve art arda pek gelmesin
	var fruits: Array = level["fruits"]
	var kind: String = fruits.pick_random()
	if kind == _last_fruit and fruits.size() > 1:
		kind = fruits.pick_random()
	_last_fruit = kind
	return kind


# Sayılan bir meyve yakalandı; hedefe ulaşıldıysa true döner
func add_catch() -> bool:
	collected += 1
	progress_changed.emit(collected, goal())
	if collected >= goal():
		spawning = false
		level_completed.emit()
		return true
	return false
