extends Node
# PlatformSpawner: basamak havuzu (object pooling). Havuzda sabit sayıda basamak var; kurbağa tırmandıkça
# aşağıda kalan basamaklar en üste taşınıp yeni basamak olarak kurulur. Basamak n'nin dünya konumu
# y = -n * step_gap; genişlik, hız ve ödül olasılığı denge.tres'teki zorluk eğrisinden gelir.

const Platform := preload("res://oyunlar/zipla_zipla/basamak.gd")
const POOL_SIZE := 10         # kurbağanın bir altı + kendisi + üstte 8 basamak
const EDGE_MARGIN := 30.0     # basamak ekran kenarına bundan fazla yaklaşmaz

var balance: JumpBalance
var layer: Node2D             # basamakların ekleneceği düğüm (World/Platforms)
var pool: Array[Node2D] = []

var _by_index: Dictionary = {}    # basamak numarası -> basamak
var _top: int = -1                # kurulan en üst basamak
var _column_x: float = 640.0
var _screen_width: float = 1280.0
var _last_kind: String = "cim"
var _rng := RandomNumberGenerator.new()


# Havuzu bir kez kurar (oyun açılırken)
func build() -> void:
	for k in POOL_SIZE:
		var platform: Node2D = Platform.new()
		layer.add_child(platform)
		platform.hide()
		pool.append(platform)


func set_seed(value: int) -> void:
	_rng.seed = value


# Yeni oyun: bütün basamaklar baştan kurulur (0: sabit çimenli başlangıç basamağı)
func reset(column_x: float, screen_width: float) -> void:
	_column_x = column_x
	_screen_width = screen_width
	_by_index.clear()
	_top = -1
	_last_kind = "cim"
	for platform in pool:
		platform.hide()
	for k in POOL_SIZE:
		_spawn(k)
	# İlk zıplama öğretici olsun: 1. basamak oyun başlayana kadar kurbağanın tam üstünde bekler
	var first: Node2D = _by_index[1]
	first.position.x = column_x
	first.frozen = true


func platform(step: int) -> Node2D:
	return _by_index.get(step)


# Kurbağa `current` basamağına konunca: altta kalanları geri al, üste yenilerini kur
func advance(current: int) -> void:
	for step in _by_index.keys():
		if step < current - 1:
			_by_index.erase(step)
	while _top < current + POOL_SIZE - 2:
		_spawn(_top + 1)


func active_count() -> int:
	return _by_index.size()


func _free_platform() -> Node2D:
	var used := _by_index.values()
	for platform in pool:
		if not used.has(platform):
			return platform
	return null


func _spawn(step: int) -> void:
	var platform := _free_platform()
	if platform == null:
		return
	_top = step
	_by_index[step] = platform
	platform.position.y = -step * balance.step_gap
	if step == 0:
		var start_width := Platform.snap_width(balance.width_start)
		platform.setup(0, "cim", start_width, 0.0, _column_x, 0.0, _column_x, true)
		return
	var width := Platform.snap_width(balance.width_for(step))
	var speed := balance.speed_for(step) * (1.0 + _rng.randf_range(-balance.speed_variation, balance.speed_variation))
	if _rng.randf() < 0.5:
		speed = -speed
	var travel := balance.travel_for(step, _screen_width / 2.0 - EDGE_MARGIN - width / 2.0)
	var start_x := _column_x + _rng.randf_range(-travel, travel)
	platform.setup(step, _next_kind(), width, speed, _column_x, travel, start_x, false)
	if _rng.randf() < balance.reward_chance_for(step):
		platform.reward.setup(balance.pick_reward(_rng))


# Art arda aynı tür gelmesin
func _next_kind() -> String:
	var kinds: Array = Platform.KINDS.duplicate()
	kinds.erase(_last_kind)
	_last_kind = kinds[_rng.randi() % kinds.size()]
	return _last_kind
