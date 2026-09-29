extends Node2D
# Bahçenin canlıları: kelebek, arı (çiçeklere uğrar), uğur böceği ve salyangoz (çitin dibinde yürür),
# gece ateşböcekleri (ışık katmanında parlar). Ara sıra gelir, bir süre dolaşıp giderler.
# Dokununca: kelebek kanat çırpıp uçar, arı takla atar, uğur böceği zıplar, salyangoz kabuğuna saklanır.

signal sound(name: String)

const G := "res://oyunlar/sihirli_bahce/gorseller/"
const WING_COLORS := [Color("ff9fd0"), Color("9ed0ff"), Color("ffd86a"), Color("b8f09a"), Color("d6b0ff"), Color("ffb08a")]
const GROUND_Y := 500.0            # çitin dibi: uğur böceği ve salyangozun yolu
const MAX_CRITTERS := 4
const FIREFLIES := 12


class Critter extends Node2D:
	var kind := ""
	var body: Sprite2D
	var wings: Sprite2D
	var t := 0.0
	var life := 14.0
	var target := Vector2.ZERO
	var speed := 90.0
	var dir := 1.0
	var busy := 0.0               # tepki süresince normal hareket durur
	var leaving := false
	var hover := 0.0              # arının çiçekte bekleme süresi


var effects: Node2D
var light_layer: Node2D
var flower_points: Callable        # olgun, açık bitkilerin tepe noktaları (arılar için)
var night := false

var _critters: Array[Critter] = []
var _fireflies: Array[Sprite2D] = []
var _spawn_timer := 4.0
var _size := Vector2(1280, 720)
var _night_amount := 0.0


func setup(p_effects: Node2D, p_light: Node2D) -> void:
	effects = p_effects
	light_layer = p_light
	_size = get_viewport_rect().size
	for i in FIREFLIES:
		var fly: Sprite2D = effects.glow_sprite(Color(0.85, 1.0, 0.5, 0.0), randf_range(26, 44))
		fly.position = Vector2(randf_range(0, _size.x), randf_range(220, 600))
		fly.set_meta("phase", randf() * TAU)
		fly.set_meta("home", fly.position)
		light_layer.add_child(fly)
		_fireflies.append(fly)


func set_night(value: bool) -> void:
	night = value
	var tween := create_tween()
	tween.tween_method(func(a: float) -> void: _night_amount = a, _night_amount, 1.0 if value else 0.0, 1.6)
	# Gündüz canlıları gece yavaşça gider
	if value:
		for critter in _critters:
			if critter.kind in ["kelebek", "ari"]:
				critter.leaving = true


# --- Oluşturma ---

func _make(kind: String) -> Critter:
	var c := Critter.new()
	c.kind = kind
	match kind:
		"kelebek":
			c.wings = _part("kelebek_kanat.svg", 76.0)
			c.wings.modulate = WING_COLORS.pick_random()
			c.add_child(c.wings)
			c.body = _part("kelebek_govde.svg", 76.0)
			c.add_child(c.body)
			c.speed = randf_range(80, 110)
		"ari":
			c.body = _part("ari_govde.svg", 70.0)
			c.add_child(c.body)
			c.wings = _part("ari_kanat.svg", 70.0)
			c.wings.modulate.a = 0.85
			c.add_child(c.wings)
			c.speed = randf_range(120, 150)
		"ugur":
			c.body = _part("ugur_bocegi.svg", 58.0)
			c.add_child(c.body)
			c.speed = 34.0
			c.life = 30.0
		"salyangoz":
			c.body = _part("salyangoz_govde.svg", 96.0)
			c.add_child(c.body)
			c.wings = _part("salyangoz_kabuk.svg", 96.0)   # salyangozda "wings" kabuktur
			c.add_child(c.wings)
			c.speed = 16.0
			c.life = 60.0
	add_child(c)
	_critters.append(c)
	return c


func _part(file: String, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + file)
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()   # width: tuvalin ekrandaki genişliği
	return sprite


func spawn(kind: String, from: Vector2 = Vector2.INF) -> Critter:
	var c := _make(kind)
	var side := -1.0 if randf() < 0.5 else 1.0
	match kind:
		"kelebek", "ari":
			c.position = from if from != Vector2.INF else Vector2(_size.x * 0.5 + side * (_size.x * 0.5 + 60.0), randf_range(200, 420))
			c.target = _air_point()
		_:
			c.position = Vector2(_size.x * 0.5 + side * (_size.x * 0.5 + 60.0), GROUND_Y)
			c.dir = -side
			c.scale.x = c.dir
	return c


# Kelebek çiçeğinin animasyonu: çiçekten kelebekler çıkar
func spawn_butterflies(pos: Vector2, count: int) -> void:
	for i in count:
		var c := spawn("kelebek", pos)
		c.target = pos + Vector2(randf_range(-260, 260), randf_range(-180, -40))
		c.scale = Vector2.ONE * 0.3
		c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Rüzgar: gündüz kelebek ve arılar gelir
func breeze() -> void:
	if night:
		return
	spawn("kelebek")
	spawn("kelebek")
	spawn("ari")


# Arı çoğu zaman açmış bir çiçeğe uğrar
func _bee_target() -> Vector2:
	if flower_points.is_valid() and randf() < 0.65:
		var flowers: Array = flower_points.call()
		if not flowers.is_empty():
			return flowers.pick_random() + Vector2(randf_range(-20, 20), -12)
	return _air_point()


func _air_point() -> Vector2:
	return Vector2(randf_range(80, _size.x - 80), randf_range(190, 440))


# --- Dokunma ---

func tap(point: Vector2) -> bool:
	for c in _critters:
		if c.busy > 0.0:
			continue
		var radius := 58.0 if c.kind in ["kelebek", "ari", "salyangoz"] else 46.0
		if c.global_position.distance_to(point + Vector2(0, 0)) < radius:
			_react(c)
			return true
	for fly in _fireflies:
		if fly.modulate.a > 0.2 and fly.global_position.distance_to(point) < 40.0:
			effects.sparkles(fly.global_position, Color(0.85, 1.0, 0.5), 8, 20.0)
			sound.emit("pirilti")
			return true
	return false


func _react(c: Critter) -> void:
	effects.hearts(c.global_position + Vector2(0, -40), 2)
	match c.kind:
		"kelebek":
			sound.emit("kanat")
			c.busy = 0.6
			c.target = c.position + Vector2(randf_range(-120, 120), -200)
			c.speed *= 2.2
			c.life = minf(c.life, 3.0)
		"ari":
			sound.emit("vizz")
			c.busy = 0.9
			var center := c.position + Vector2(0, -50)
			var start_angle := PI * 0.5
			var tween := c.create_tween()
			tween.tween_method(func(a: float) -> void:
				c.position = center + Vector2(cos(start_angle + a), sin(start_angle + a)) * 50.0
				c.rotation = a, 0.0, TAU, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_callback(func() -> void: c.rotation = 0.0)
		"ugur":
			sound.emit("hop")
			c.busy = 0.5
			var y := c.position.y
			var tween := c.create_tween()
			tween.tween_property(c, "position:y", y - 40.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(c, "position:y", y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"salyangoz":
			sound.emit("saklan")
			c.busy = 2.8
			var tween := c.body.create_tween()
			var full := c.body.scale
			tween.tween_property(c.body, "scale", Vector2(full.x * 0.05, full.y * 0.4), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_interval(2.2)
			tween.tween_property(c.body, "scale", full, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Hareket ---

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(7.0, 13.0)
		if _critters.size() < MAX_CRITTERS:
			var roll := randf()
			if night:
				if roll < 0.35:
					spawn("salyangoz")
			elif roll < 0.35:
				spawn("kelebek")
			elif roll < 0.6:
				spawn("ari")
			elif roll < 0.8:
				spawn("ugur")
			else:
				spawn("salyangoz")
	for c in _critters.duplicate():
		_move(c, delta)
	for fly in _fireflies:
		var phase: float = fly.get_meta("phase")
		var home: Vector2 = fly.get_meta("home")
		var t := Time.get_ticks_msec() / 1000.0
		fly.position = home + Vector2(sin(t * 0.4 + phase) * 70.0, cos(t * 0.55 + phase * 1.3) * 40.0)
		fly.modulate.a = _night_amount * (0.35 + 0.65 * pow(sin(t * 1.3 + phase) * 0.5 + 0.5, 2.0))


func _move(c: Critter, delta: float) -> void:
	c.t += delta
	c.life -= delta
	c.busy = maxf(0.0, c.busy - delta)
	if c.life <= 0.0:
		c.leaving = true
	match c.kind:
		"kelebek", "ari":
			if c.wings:
				if c.kind == "kelebek":
					c.wings.scale.x = absf(c.wings.scale.y) * (0.25 + 0.75 * absf(sin(c.t * 11.0)))
				else:
					c.wings.scale.y = absf(c.wings.scale.x) * (0.6 + 0.4 * absf(sin(c.t * 40.0)))
			if c.busy > 0.0 and c.kind == "ari":
				return
			if c.leaving:
				c.target = Vector2(-120.0 if c.position.x < _size.x * 0.5 else _size.x + 120.0, c.position.y - 60.0)
			if c.hover > 0.0:
				c.hover -= delta
				c.position += Vector2(sin(c.t * 5.0) * 20.0, cos(c.t * 4.0) * 10.0) * delta
				return
			var to := c.target - c.position
			if to.length() < 20.0:
				if c.kind == "ari":
					c.hover = 1.3               # çiçekte ya da havada biraz oyalanır
					c.target = _bee_target()
				else:
					c.target = _air_point()
			else:
				var step := to.normalized() * c.speed * delta
				var bob := sin(c.t * 6.0) * 40.0 if c.kind == "kelebek" else sin(c.t * 9.0) * 18.0
				c.position += step + Vector2(0, bob * delta)
				if c.kind == "ari" and absf(step.x) > 0.3:
					c.scale.x = absf(c.scale.x) * signf(step.x)
			if c.leaving and (c.position.x < -100.0 or c.position.x > _size.x + 100.0):
				_remove(c)
		"ugur", "salyangoz":
			if c.busy > 0.0:
				return
			c.position.x += c.dir * c.speed * delta
			if c.kind == "ugur":
				c.body.rotation = sin(c.t * 14.0) * 0.04
			else:
				c.body.scale.y = c.wings.scale.y * (1.0 + sin(c.t * 3.0) * 0.03)
			if c.position.x < -110.0 or c.position.x > _size.x + 110.0:
				_remove(c)


func _remove(c: Critter) -> void:
	_critters.erase(c)
	c.queue_free()
