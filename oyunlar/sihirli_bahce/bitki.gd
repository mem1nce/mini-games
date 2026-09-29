extends Node2D
# Bitki görünümü: büyüme aşamasının çizimi, zıplayarak büyüme, hafif sallanma (rüzgarda güçlü),
# gece bitkilerinin açıp kapanması ve dokununca yapılan özel animasyonlar.
# Düğümün (0, 0) noktası bitkinin toprağa girdiği yerdir. Işık ve efektler ayrı katmanda (gece kararmaz).

signal special_event(kind: String, pos: Vector2)   # ana sahnenin yapacağı işler (ör. kelebekler)

const Bitkiler := preload("res://oyunlar/sihirli_bahce/bitkiler.gd")
const G := "res://oyunlar/sihirli_bahce/gorseller/"
const SCALE := 1.12                     # tuval pikseli → ekran pikseli
const BASE := Vector2(120, 288)         # tuvalde bitkinin toprağa girdiği nokta
const LALE_HEADS := [Vector2(82, 128), Vector2(120, 100), Vector2(160, 126)]
const LALE_COLORS := [Color("ff6fa0"), Color("ffcf3a"), Color("ff6f5e"), Color("b98cff"), Color("5ab8ff"), Color("7ed65a")]
const BALLOONS := [[Vector2(78, 116), 26.0, Color("ff8fbe")], [Vector2(120, 84), 30.0, Color("7cc4ff")],
	[Vector2(162, 112), 26.0, Color("ffd84a")], [Vector2(98, 158), 22.0, Color("8ee07a")], [Vector2(144, 158), 22.0, Color("b98cff")]]
const STAR_FRUITS := [Vector2(80, 104), Vector2(118, 70), Vector2(158, 96), Vector2(98, 138), Vector2(146, 140), Vector2(176, 126)]
# Gece bitkilerinin ışığı: tuvaldeki merkezi ve boyu
const GLOWS := {"mantar": [Vector2(128, 238), 300.0], "ay_cicegi": [Vector2(120, 110), 230.0]}

var id := ""
var stage := 0
var open := true
var effects: Node2D                     # efektler.gd (ışık katmanında)
var light_layer: Node2D                 # gece ışıkları için

var _body: Node2D                       # sallanan kısım
var _back: Node2D                       # bitkinin arkasında (kabaktaki tavşan)
var _sprite: Sprite2D
var _glow: Sprite2D
var _time := 0.0
var _phase := 0.0
var _gust := 0.0
var _busy := false


func _init() -> void:
	_body = Node2D.new()
	add_child(_body)
	_back = Node2D.new()
	_body.add_child(_back)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_body.add_child(_sprite)
	_phase = randf() * TAU


func setup(plant_id: String, plant_stage: int, is_open: bool) -> void:
	id = plant_id
	stage = plant_stage
	open = is_open
	_apply_texture()
	_update_glow(false)


func _exit_tree() -> void:
	if _glow:
		_glow.queue_free()


static func to_local_canvas(p: Vector2) -> Vector2:
	return (p - BASE) * SCALE


func _apply_texture() -> void:
	var tex := Bitkiler.texture(id, stage, open)
	var k := tex.get_width() / 240.0
	_sprite.texture = tex
	_sprite.scale = Vector2.ONE * SCALE / k
	_sprite.offset = -BASE * k


# Bitkinin tepesi (yerel): ihtiyaç baloncuğu bunun üstüne konur
func top_local() -> Vector2:
	return Vector2(0, (Bitkiler.top_y(id, stage, open) - BASE.y) * SCALE)


func head_global() -> Vector2:
	return global_position + top_local() * 0.6


# --- Büyüme ---

func grow_to(new_stage: int) -> void:
	stage = new_stage
	_apply_texture()
	_pop(0.7)
	if effects:
		effects.soil_bits(global_position + Vector2(0, -6), 10)
		effects.sparkles(global_position + top_local() * 0.5, Bitkiler.PLANTS[id]["color"], 10, 50.0)
	_update_glow(true)


func set_open(value: bool, animate: bool) -> void:
	if value == open:
		return
	open = value
	_apply_texture()
	if animate:
		_pop(0.85)
		if value and effects:
			effects.sparkles(head_global(), Bitkiler.PLANTS[id]["color"], 16, 60.0)
	_update_glow(animate)


# Aşağıdan esneyerek büyüme (TRANS_BACK)
func _pop(from: float) -> void:
	_body.scale = Vector2(1.0 + (1.0 - from) * 0.4, from)
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2(0.94, 1.08), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Gece bitkisi açıkken ışık saçar (ışık katmanında, kararmaz)
func _update_glow(animate: bool) -> void:
	var want := GLOWS.has(id) and stage == 4 and open and light_layer != null
	if want and _glow == null:
		var info: Array = GLOWS[id]
		_glow = effects.glow_sprite(Color(Bitkiler.PLANTS[id]["color"], 0.0), info[1])
		light_layer.add_child(_glow)
		_glow.global_position = global_position + to_local_canvas(info[0])
		var tween := _glow.create_tween()
		tween.tween_property(_glow, "modulate:a", 0.75, 0.8 if animate else 0.01)
	elif not want and _glow:
		var old := _glow
		_glow = null
		var tween := old.create_tween()
		tween.tween_property(old, "modulate:a", 0.0, 0.6)
		tween.tween_callback(old.queue_free)


func gust(strength: float) -> void:
	_gust = maxf(_gust, strength)


# Olgun olmayan bitkiye dokununca küçük bir kıpırdanma
func wiggle() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "rotation", 0.12, 0.08)
	tween.tween_property(_body, "rotation", -0.1, 0.12)
	tween.tween_property(_body, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	_gust = maxf(0.0, _gust - delta * 0.35)
	if not _busy:
		var amount := 0.022 + _gust * 0.09
		_body.rotation = sin(_time * (1.3 + _gust * 2.0) + _phase) * amount
	if _glow:
		_glow.modulate.a = 0.62 + sin(_time * 2.2 + _phase) * 0.12


# --- Özel animasyonlar (olgun bitkiye dokununca) ---

func special(sun_pos: Vector2) -> void:
	if _busy or stage != 4 or not open:
		return
	_busy = true
	match Bitkiler.PLANTS[id]["special"]:
		"gunese_don":
			await _turn_to_sun(sun_pos)
		"renk_degistir":
			await _tulip_colors()
		"jole":
			await _jelly()
		"tavsan":
			await _bunny()
		"balonlar":
			await _balloons()
		"gokkusagi":
			await _rainbow()
		"kelebekler":
			special_event.emit("kelebekler", head_global())
			await _jelly(0.08)
		"isik_sac", "ay_tozu":
			await _glow_burst()
		"parilti":
			await _crystal()
		"yildiz_dus":
			await _falling_star()
		"sekerler":
			await _candy()
	_busy = false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _turn_to_sun(sun_pos: Vector2) -> void:
	var angle := clampf((sun_pos.x - global_position.x) / 700.0, -1.0, 1.0) * 0.3
	var tween := create_tween()
	tween.tween_property(_body, "rotation", angle, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: effects.sparkles(head_global() + Vector2(angle * 200.0, -40), Color("ffe27a"), 14, 50.0))
	tween.tween_property(_body, "rotation", angle + 0.05, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_body, "rotation", angle, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(1.2)
	tween.tween_property(_body, "rotation", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _tulip_colors() -> void:
	var tex: Texture2D = load(G + "lale_bas.svg")
	var heads: Array[Sprite2D] = []
	for i in LALE_HEADS.size():
		var head := Sprite2D.new()
		head.texture = tex
		head.scale = Vector2.ONE * SCALE * 70.0 / tex.get_width()
		head.position = to_local_canvas(LALE_HEADS[i]) + Vector2(0, -7) * SCALE
		head.modulate = Color(LALE_COLORS[i], 0.0)
		_body.add_child(head)
		heads.append(head)
	var tween := create_tween()
	for step in 5:
		for i in heads.size():
			var color: Color = LALE_COLORS[(i + step * 2) % LALE_COLORS.size()]
			tween.parallel().tween_property(heads[i], "modulate", Color(color, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func() -> void: effects.sparkles(head_global(), Color.WHITE, 5, 60.0))
		tween.tween_interval(0.25)
	for head in heads:
		tween.parallel().tween_property(head, "modulate:a", 0.0, 0.5)
	await tween.finished
	for head in heads:
		head.queue_free()


func _jelly(extra: float = 0.0) -> void:
	effects.hearts(head_global() + Vector2(0, -20), 3)
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2(1.18 + extra, 0.82), 0.14).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_body, "scale", Vector2(0.88, 1.14), 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_body, "scale", Vector2(1.06, 0.95), 0.14).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_body, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func _bunny() -> void:
	var bunny := Sprite2D.new()
	bunny.texture = load(G + "tavsan.svg")
	bunny.scale = Vector2.ONE * 110.0 / bunny.texture.get_width()
	var home := to_local_canvas(Vector2(120, 250))
	bunny.position = home
	_back.add_child(bunny)
	var up := home + Vector2(0, -95)
	var tween := create_tween()
	tween.tween_property(_body, "rotation", 0.06, 0.1)
	tween.tween_property(_body, "rotation", -0.06, 0.12)
	tween.tween_property(_body, "rotation", 0.0, 0.1)
	tween.tween_property(bunny, "position", up, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: effects.hearts(global_position + up + Vector2(30, -60), 2))
	tween.tween_property(bunny, "rotation", 0.15, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bunny, "rotation", -0.15, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bunny, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.6)
	tween.tween_property(bunny, "position", home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	bunny.queue_free()


func _balloons() -> void:
	var tex: Texture2D = load(G + "balon.svg")
	for data in BALLOONS:
		var balloon := Sprite2D.new()
		balloon.texture = tex
		var r: float = data[1]
		balloon.scale = Vector2.ONE * SCALE * r * 2.1 / 74.0 * 90.0 / tex.get_width()
		balloon.modulate = data[2]
		balloon.global_position = global_position + to_local_canvas(data[0]) + Vector2(0, r * 0.3)
		effects.add_child(balloon)
		var drift := randf_range(-80.0, 80.0)
		var time := randf_range(2.6, 3.4)
		var start := balloon.position
		var tween := balloon.create_tween()
		tween.tween_method(func(t: float) -> void:
			balloon.position = start + Vector2(sin(t * TAU * 1.5) * 18.0 + drift * t, -620.0 * t)
			balloon.rotation = sin(t * TAU * 1.5) * 0.15, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(balloon, "modulate:a", 0.0, 0.6).set_delay(time - 0.6)
		tween.tween_callback(balloon.queue_free)
	# Balonlar uçunca yerlerinde küçük tomurcuklar kalır, sonra yeniden şişer
	_sprite.texture = Bitkiler.texture(id, 3)
	await _wait(2.4)
	_apply_texture()
	_pop(0.85)
	effects.sparkles(head_global(), Color("ffffff"), 12, 60.0)
	await _wait(0.6)


func _rainbow() -> void:
	var arc := Sprite2D.new()
	arc.texture = load(G + "gokkusagi.svg")
	arc.global_position = global_position + top_local() + Vector2(0, -40)
	arc.scale = Vector2.ZERO
	var full := Vector2.ONE * 260.0 / arc.texture.get_width()
	effects.add_child(arc)
	var tween := arc.create_tween()
	tween.tween_property(arc, "scale", full, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: effects.sparkles(arc.global_position + Vector2(0, -40), Color.WHITE, 14, 90.0))
	tween.tween_interval(1.8)
	tween.tween_property(arc, "modulate:a", 0.0, 0.7)
	tween.tween_callback(arc.queue_free)
	await _jelly(0.02)
	await _wait(1.8)


func _glow_burst() -> void:
	var color: Color = Bitkiler.PLANTS[id]["color"]
	effects.glow_dust(head_global(), color, 24)
	if _glow:
		var tween := _glow.create_tween()
		tween.tween_property(_glow, "scale", _glow.scale * 1.5, 0.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_glow, "scale", _glow.scale, 0.8).set_trans(Tween.TRANS_SINE)
	var body := create_tween()
	body.tween_property(_body, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
	body.tween_property(_body, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	await body.finished


func _crystal() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "modulate", Color(1.35, 1.35, 1.6), 0.25)
	tween.tween_property(_body, "modulate", Color.WHITE, 0.6)
	for k in 4:
		get_tree().create_timer(k * 0.25).timeout.connect(func() -> void:
			effects.sparkles(head_global() + Vector2(randf_range(-50, 50), randf_range(-40, 30)), Color("bfe8ff"), 8, 30.0))
	await _jelly(0.0)
	await _wait(0.5)


func _falling_star() -> void:
	for k in STAR_FRUITS.size():
		get_tree().create_timer(k * 0.12).timeout.connect(func() -> void:
			effects.sparkles(global_position + to_local_canvas(STAR_FRUITS[k]), Color("ffe27a"), 4, 12.0))
	var star := Sprite2D.new()
	star.texture = load(G + "yildiz.svg")
	star.scale = Vector2.ONE * 34.0 / star.texture.get_width()
	var from: Vector2 = global_position + to_local_canvas(STAR_FRUITS[randi() % STAR_FRUITS.size()])
	var ground := global_position + Vector2(randf_range(-60, 60), -8)
	star.global_position = from
	effects.add_child(star)
	var tween := star.create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(star, "global_position", ground, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "rotation", TAU, 0.6)
	tween.tween_property(star, "global_position:y", ground.y - 50.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "global_position:y", ground.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: effects.sparkles(ground, Color("ffe27a"), 12, 30.0))
	tween.tween_property(star, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.tween_callback(star.queue_free)
	await _jelly(0.0)
	await _wait(1.2)


func _candy() -> void:
	effects.sparkles(head_global(), Color("ff9fcc"), 18, 70.0)
	effects.hearts(head_global() + Vector2(0, -30), 3)
	var tween := create_tween()
	for k in 3:
		tween.tween_property(_body, "rotation", 0.07, 0.12).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_body, "rotation", -0.07, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_body, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
