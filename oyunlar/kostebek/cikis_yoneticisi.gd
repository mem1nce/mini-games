extends Node
# Spawner: ne zaman, hangi çukurdan, ne çıkacağına karar verir. Değerler denge.tres'ten (WhackBalance).
# Kurallar: aynı anda en fazla max_active nesne; boşalan çukur hole_cooldown kadar dinlenir ve
# bir önceki çukur (başka seçenek varsa) seçilmez; bomba art arda max_bombs_in_row'dan fazla gelmez
# ve ekranda max_bombs_on_screen'den fazla bomba olmaz.

signal item_spawned(item: Node2D)

const Item := preload("res://oyunlar/kostebek/cikan_nesne.gd")
const Mole := preload("res://oyunlar/kostebek/kostebek_nesne.gd")
const Fruit := preload("res://oyunlar/kostebek/meyve_nesne.gd")
const Bomb := preload("res://oyunlar/kostebek/bomba_nesne.gd")

var balance: WhackBalance
var level: WhackLevelData
var holes: Array[Node2D] = []
var running: bool = false
var holding: bool = false        # çukurlar yeniden dizilirken yeni çıkış yok

var clock: float = 0.0
var _wait: float = 0.0
var _last_hole: Node2D = null
var _bombs_in_row: int = 0


func start(first_delay: float = 0.4) -> void:
	running = true
	holding = false
	_wait = first_delay
	_bombs_in_row = 0
	_last_hole = null


func stop() -> void:
	running = false


func set_holes(new_holes: Array[Node2D]) -> void:
	holes = new_holes
	_last_hole = null
	for hole in holes:
		hole.free_since = clock
		hole.emptied.connect(_on_hole_emptied)


func _on_hole_emptied(hole: Node2D) -> void:
	hole.free_since = clock


func active_count() -> int:
	var count := 0
	for hole in holes:
		if not hole.is_free():
			count += 1
	return count


func _process(delta: float) -> void:
	clock += delta
	if not running or holding or level == null:
		return
	_wait -= delta
	if _wait > 0.0 or active_count() >= level.max_active:
		return
	var hole := _pick_hole()
	if hole == null:
		return
	_spawn(hole)
	_wait = randf_range(level.spawn_interval_min, level.spawn_interval_max)


func _pick_hole() -> Node2D:
	var ready_holes: Array[Node2D] = []
	for hole in holes:
		if hole.is_free() and clock - hole.free_since >= balance.hole_cooldown:
			ready_holes.append(hole)
	if ready_holes.size() > 1:
		ready_holes.erase(_last_hole)
	if ready_holes.is_empty():
		return null
	return ready_holes.pick_random()


func _pick_kind() -> int:
	var roll := randf()
	var bomb_allowed := _bombs_in_row < balance.max_bombs_in_row and _bombs_on_screen() < balance.max_bombs_on_screen
	if roll < level.bomb_chance:
		if bomb_allowed:
			return Item.Kind.BOMB
		roll = randf() # bomba olamadı: köstebek ya da meyve arasında yeniden seç
		return Item.Kind.FRUIT if roll < level.fruit_chance / maxf(1.0 - level.bomb_chance, 0.01) else Item.Kind.MOLE
	if roll < level.bomb_chance + level.fruit_chance:
		return Item.Kind.FRUIT
	return Item.Kind.MOLE


func _bombs_on_screen() -> int:
	var count := 0
	for hole in holes:
		if hole.item and hole.item.kind == Item.Kind.BOMB:
			count += 1
	return count


func _spawn(hole: Node2D) -> void:
	var kind := _pick_kind()
	spawn(hole, kind, kind == Item.Kind.MOLE and randf() < level.helmet_chance)


# Verilen çukurdan verilen türde nesne çıkarır (testler de doğrudan çağırabilir)
func spawn(hole: Node2D, kind: int, with_helmet: bool = false) -> Node2D:
	var item: Node2D
	match kind:
		Item.Kind.BOMB:
			item = Bomb.new()
			item.setup()
			_bombs_in_row += 1
		Item.Kind.FRUIT:
			item = Fruit.new()
			item.setup()
			_bombs_in_row = 0
		_:
			item = Mole.new()
			item.setup(with_helmet)
			_bombs_in_row = 0
	_last_hole = hole
	hole.put(item)
	var stay := maxf(level.stay_time, balance.min_stay_time)
	item.pop_up(stay, balance.rise_time, balance.hide_time)
	item_spawned.emit(item)
	return item
