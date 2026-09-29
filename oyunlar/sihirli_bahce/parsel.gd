extends Node2D
# Toprak parseli: içindeki bitkinin durumu ve büyüme döngüsü.
# Her aşama için önce su (yağmur bulutu altında WATER_TIME sn), sonra güneş gerekir; güneşten sonra bitki
# büyür. Olgun gece bitkisi gündüz kapalı bekler (baloncukta ay). Su istemeyen bitkiye yağmur yağarsa
# yanında su birikintisi olur ve kurbağa gelir; güneş birikintiyi kurutur. Bitki asla ölmez.
# Düğümün (0, 0) noktası toprağın ortası (bitkinin toprağa girdiği yer). Baloncuk ve sepet ışık katmanında.

signal changed                                  # kaydedilecek bir şey değişti
signal harvested(id: String, from: Vector2)
signal plant_event(kind: String, pos: Vector2)  # bitkinin özel olayları (ana sahne yapar)
signal sound(name: String)

const Bitkiler := preload("res://oyunlar/sihirli_bahce/bitkiler.gd")
const Bitki := preload("res://oyunlar/sihirli_bahce/bitki.gd")
const G := "res://oyunlar/sihirli_bahce/gorseller/"
const WATER_TIME := 1.1                         # sulanmak için gereken yağmur süresi
const OVERWATER_TIME := 1.4                     # birikinti için fazladan yağmur süresi
const GROW_DELAY := 0.9                         # güneşten sonra büyümeye kadar
const PUDDLE_DRY_TIME := 60.0
const WIDTH := 210.0                            # parselin dokunma/bırakma genişliği
const BUBBLE_SIZE := 88.0
const BASKET_SIZE := 92.0
const WET_COLOR := Color(0.62, 0.55, 0.52)
const PUDDLE_POS := Vector2(-60, 18)            # birikinti toprağın üstünde, bitkinin solunda
const PUDDLE_WIDTH := 116.0
const FROG_POS := Vector2(-62, -2)
const BUBBLE_MIN_Y := 205.0                     # baloncuk hava düğmelerinin altında kalsın

var index := 0
var plant_id := ""
var stage := 0
var need := ""                                  # "water", "sun", "moon", "grow" (büyüyor) ya da "" (olgun)
var puddle := false
var effects: Node2D
var light_layer: Node2D

var _soil: Sprite2D
var _plant: Node2D
var _puddle: Sprite2D
var _frog: Sprite2D
var _bubble: Node2D
var _bubble_icon: Sprite2D
var _basket: Sprite2D
var _water := 0.0
var _over := 0.0
var _wet := 0.0
var _puddle_time := 0.0
var _night := false
var _time := 0.0


func setup(p_index: int, p_light: Node2D, p_effects: Node2D) -> void:
	index = p_index
	light_layer = p_light
	effects = p_effects
	_soil = Sprite2D.new()
	_soil.texture = load(G + "parsel.svg")
	_soil.scale = Vector2.ONE * 226.0 / _soil.texture.get_width()
	_soil.position = Vector2(0, 30)
	add_child(_soil)
	_puddle = Sprite2D.new()
	_puddle.texture = load(G + "su_birikintisi.svg")
	_puddle.scale = Vector2.ONE * PUDDLE_WIDTH / _puddle.texture.get_width()
	_puddle.position = PUDDLE_POS
	_puddle.visible = false
	add_child(_puddle)
	_frog = Sprite2D.new()
	_frog.texture = load(G + "kurbaga.svg")
	_frog.scale = Vector2.ONE * 80.0 / _frog.texture.get_width()
	_frog.position = FROG_POS
	_frog.z_index = 1              # bitkinin önünde otursun
	_frog.visible = false
	add_child(_frog)
	# Baloncuk ve sepet ışık katmanında (gece de okunaklı)
	_bubble = Node2D.new()
	_bubble.visible = false
	_bubble.draw.connect(_draw_bubble)
	light_layer.add_child(_bubble)
	_bubble_icon = Sprite2D.new()
	_bubble.add_child(_bubble_icon)
	_basket = Sprite2D.new()
	_basket.texture = load(G + "sepet.svg")
	_basket.scale = Vector2.ONE * BASKET_SIZE / _basket.texture.get_width()
	_basket.visible = false
	light_layer.add_child(_basket)


func _exit_tree() -> void:
	for node in [_bubble, _basket]:
		if is_instance_valid(node):
			node.queue_free()


func is_empty() -> bool:
	return plant_id == ""


func is_mature() -> bool:
	return plant_id != "" and stage == 4


func is_open() -> bool:
	return is_mature() and (not Bitkiler.is_night(plant_id) or _night)


func contains(point: Vector2) -> bool:
	return absf(point.x - global_position.x) < WIDTH * 0.5 and point.y > global_position.y - 330.0 and point.y < global_position.y + 110.0


func plant_contains(point: Vector2) -> bool:
	if _plant == null:
		return false
	var top: float = _plant.top_local().y
	return absf(point.x - global_position.x) < 115.0 and point.y > global_position.y + top - 20.0 and point.y < global_position.y + 40.0


func basket_contains(point: Vector2) -> bool:
	return _basket.visible and _basket.global_position.distance_to(point) < BASKET_SIZE * 0.62


func frog_contains(point: Vector2) -> bool:
	return _frog.visible and (_frog.global_position + Vector2(0, -10)).distance_to(point) < 60.0


func plant_global_top() -> Vector2:
	return global_position + (_plant.top_local() if _plant else Vector2(0, -40))


# --- Durum ---

func to_dict() -> Dictionary:
	if plant_id == "":
		return {}
	return {"bitki": plant_id, "asama": stage, "ihtiyac": "sun" if need == "grow" else need, "birikinti": puddle}


func from_dict(data: Dictionary, night: bool) -> void:
	_night = night
	var id := str(data.get("bitki", ""))
	if not Bitkiler.PLANTS.has(id):
		return
	plant_id = id
	stage = clampi(int(data.get("asama", 0)), 0, 4)
	need = str(data.get("ihtiyac", "water"))
	_make_plant()
	if bool(data.get("birikinti", false)):
		_show_puddle(false)
	_refresh_need()


func _make_plant() -> void:
	if _plant:
		_plant.queue_free()
	_plant = Bitki.new()
	_plant.effects = effects
	_plant.light_layer = light_layer
	add_child(_plant)
	_plant.setup(plant_id, stage, is_open() or stage < 4)
	_plant.special_event.connect(func(kind: String, pos: Vector2) -> void: plant_event.emit(kind, pos))


# --- Ekme ---

func plant_seed(id: String) -> void:
	plant_id = id
	stage = 0
	need = "water"
	_water = 0.0
	_make_plant()
	_plant.scale = Vector2(0.3, 0.3)
	var tween := _plant.create_tween()
	tween.tween_property(_plant, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	effects.soil_bits(global_position + Vector2(0, -4), 8)
	sound.emit("tohum")
	_refresh_need()
	changed.emit()


# --- Yağmur ve güneş ---

# Bulut bu parselin üstündeyken her kare çağrılır
func rain(delta: float) -> void:
	_wet = minf(1.0, _wet + delta * 1.5)
	if plant_id == "":
		return
	if need == "water":
		_water += delta
		if _water >= WATER_TIME:
			_water = 0.0
			need = "sun"
			effects.sparkles(global_position + Vector2(0, -20), Color("9ed8ff"), 10, 60.0)
			sound.emit("sulandi")
			_refresh_need()
			changed.emit()
	elif not puddle:
		_over += delta
		if _over >= OVERWATER_TIME:
			_over = 0.0
			_show_puddle(true)
			changed.emit()


# Güneş huzmesi iner: güneş isteyen bitki büyür, birikinti kurur. Huzme gerekiyorsa true döner.
func shine() -> bool:
	var wanted := need == "sun"
	if puddle:
		_dry_puddle()
		wanted = true
	if need == "sun":
		need = "grow"
		_refresh_need()
		get_tree().create_timer(GROW_DELAY).timeout.connect(_grow)
	return wanted


func wants_sun() -> bool:
	return need == "sun" or puddle


func _grow() -> void:
	if plant_id == "" or need != "grow":
		return
	stage += 1
	if stage == 4 and Bitkiler.is_night(plant_id):
		_plant.open = _night         # gece bitkisi gündüz kapalı olgunlaşır
	_plant.grow_to(stage)
	if stage < 4:
		need = ""
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			if plant_id != "" and need == "":
				need = "water"
				_refresh_need()
				changed.emit())
	else:
		need = ""
	sound.emit("buyume")
	_refresh_need()
	changed.emit()


func set_night(value: bool) -> void:
	_night = value
	if is_mature() and Bitkiler.is_night(plant_id):
		_plant.set_open(value, true)
		if value:
			sound.emit("acilma")
	_refresh_need()


# --- Toplama ve dokunma ---

func harvest() -> String:
	var id := plant_id
	var from := plant_global_top() * 0.5 + global_position * 0.5
	plant_id = ""
	stage = 0
	need = ""
	var old := _plant
	_plant = null
	var tween := old.create_tween()
	tween.tween_property(old, "scale", Vector2(1.15, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(old.queue_free)
	effects.soil_bits(global_position, 8)
	_refresh_need()
	harvested.emit(id, from)
	changed.emit()
	return id


func tap_plant(sun_pos: Vector2) -> void:
	if _plant == null:
		return
	if is_open():
		_plant.special(sun_pos)
		sound.emit("sihir")
	else:
		_plant.wiggle()
		sound.emit("kipir")


func tap_frog() -> void:
	sound.emit("kurbaga")
	var home := FROG_POS
	var tween := _frog.create_tween()
	tween.tween_property(_frog, "position", home + Vector2(0, -60), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_frog, "scale", _frog.scale * Vector2(0.9, 1.1), 0.22)
	tween.tween_property(_frog, "position", home, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_frog, "scale", _frog.scale, 0.22)
	tween.tween_callback(func() -> void: effects.hearts(_frog.global_position + Vector2(0, -50), 2))


func gust(strength: float) -> void:
	if _plant:
		_plant.gust(strength)


# --- Birikinti ve kurbağa ---

func _show_puddle(animate: bool) -> void:
	puddle = true
	_puddle_time = 0.0
	_puddle.visible = true
	if animate:
		_puddle.scale = Vector2.ONE * 0.01
		_puddle.create_tween().tween_property(_puddle, "scale", Vector2.ONE * PUDDLE_WIDTH / _puddle.texture.get_width(), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		get_tree().create_timer(0.9).timeout.connect(_frog_arrives)
	else:
		_frog.visible = true


func _frog_arrives() -> void:
	if not puddle:
		return
	_frog.visible = true
	var home := FROG_POS
	var start := home + Vector2(-260, 30)
	_frog.position = start
	# Üç zıplamayla birikintiye gelir
	var tween := _frog.create_tween()
	for k in 3:
		var a := start.lerp(home, k / 3.0)
		var b := start.lerp(home, (k + 1) / 3.0)
		tween.tween_property(_frog, "position", (a + b) * 0.5 + Vector2(0, -50), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_frog, "position", b, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		sound.emit("kurbaga")
		effects.hearts(_frog.global_position + Vector2(0, -50), 2))


func _dry_puddle() -> void:
	puddle = false
	var frog_tween := _frog.create_tween()
	if _frog.visible:
		frog_tween.tween_property(_frog, "position", _frog.position + Vector2(-120, -60), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		frog_tween.tween_property(_frog, "position", _frog.position + Vector2(-260, 40), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		frog_tween.tween_callback(func() -> void: _frog.visible = false)
	var tween := _puddle.create_tween()
	tween.tween_property(_puddle, "scale", Vector2.ONE * 0.01, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _puddle.visible = false)
	changed.emit()


# --- Görünüm ---

func _refresh_need() -> void:
	var icon := ""
	match need:
		"water":
			icon = "damla.svg"
		"sun":
			icon = "gunes.svg"
	if is_mature() and Bitkiler.is_night(plant_id) and not _night:
		icon = "ay.svg"
	if icon == "":
		_bubble.visible = false
	else:
		var was := _bubble.visible
		_bubble_icon.texture = load(G + icon)
		_bubble_icon.scale = Vector2.ONE * BUBBLE_SIZE * 0.62 / maxf(_bubble_icon.texture.get_width(), _bubble_icon.texture.get_height())
		_bubble.visible = true
		if not was:
			_bubble.scale = Vector2.ZERO
			_bubble.create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var show_basket := is_open()
	if show_basket and not _basket.visible:
		_basket.visible = true
		_basket.scale = Vector2.ZERO
		_basket.create_tween().tween_property(_basket, "scale", Vector2.ONE * BASKET_SIZE / _basket.texture.get_width(), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif not show_basket:
		_basket.visible = false


func _draw_bubble() -> void:
	var r := BUBBLE_SIZE * 0.5
	_bubble.draw_circle(Vector2(0, 5), r, Color(0.2, 0.15, 0.3, 0.18))
	_bubble.draw_colored_polygon(PackedVector2Array([Vector2(-12, r - 6), Vector2(12, r - 6), Vector2(0, r + 16)]), Color.WHITE)
	_bubble.draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.96))
	_bubble.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color("6a5a8e"), 4.0, true)
	_bubble.draw_polyline(PackedVector2Array([Vector2(-13, r - 5), Vector2(0, r + 14), Vector2(13, r - 5)]), Color("6a5a8e"), 4.0, true)


func _process(delta: float) -> void:
	_time += delta
	# Toprak ıslakken koyulaşır, sonra yavaşça kurur
	_wet = maxf(0.0, _wet - delta * 0.05)
	_soil.modulate = Color.WHITE.lerp(WET_COLOR, _wet)
	if puddle:
		_puddle_time += delta
		if _puddle_time > PUDDLE_DRY_TIME:
			_dry_puddle()
	if _bubble.visible and _plant:
		var pos := plant_global_top() + Vector2(0, -BUBBLE_SIZE * 0.72)
		pos.y = maxf(pos.y, BUBBLE_MIN_Y)
		_bubble.global_position = pos + Vector2(0, sin(_time * 2.4 + index) * 5.0)
	if _basket.visible:
		_basket.global_position = global_position + Vector2(96, -8 + sin(_time * 3.0 + index) * 3.0)
