extends Node2D
# Katmanlı arka plan: gökyüzü, yıldızlar, güneş ve ay, bulutlar, uzak ve yakın tepeler, çimen,
# çiçekler, ateşböcekleri. Her zaman dilimi bir renk paleti; bölüm değişince palet yumuşakça karışır.

const TEX_SUN: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/gunes.svg")
const TEX_MOON: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/ay.svg")
const TEX_CLOUD: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/bulut.svg")
const TEX_STAR: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/isilti.svg")
const TEX_FAR: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/tepe_uzak.svg")
const TEX_NEAR: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/tepe_yakin.svg")
const TEX_GRASS: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/cimen.svg")
const TEX_FLOWERS: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/cicekler.svg")
const TEX_FIREFLY: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/ates_bocegi.svg")

# sun_pos / moon_pos ekran boyutuna oranladır
const PALETTES := {
	"sabah": {
		"sky_top": Color("5fb8f2"), "sky_mid": Color("a8dcfa"), "sky_bottom": Color("eaf8ff"),
		"far": Color(1, 1, 1), "ambient": Color(1, 1, 1), "cloud": Color(1, 1, 1, 0.95),
		"sun": 1.0, "sun_pos": Vector2(0.82, 0.41), "sun_tint": Color(1, 1, 1), "sun_size": 1.0,
		"moon": 0.0, "moon_pos": Vector2(0.2, 0.42), "stars": 0.0, "fireflies": 0.0, "flowers": 0.45,
	},
	"ogle": {
		"sky_top": Color("3aa8f0"), "sky_mid": Color("86cff8"), "sky_bottom": Color("d6f3ff"),
		"far": Color(1, 1, 0.96), "ambient": Color(1, 1, 1), "cloud": Color(1, 1, 1, 0.9),
		"sun": 1.0, "sun_pos": Vector2(0.2, 0.39), "sun_tint": Color(1, 1, 0.92), "sun_size": 0.9,
		"moon": 0.0, "moon_pos": Vector2(0.2, 0.42), "stars": 0.0, "fireflies": 0.0, "flowers": 1.0,
	},
	"aksam": {
		"sky_top": Color("6a5acd"), "sky_mid": Color("ff8fa3"), "sky_bottom": Color("ffc27a"),
		"far": Color(1, 0.74, 0.72), "ambient": Color(1, 0.87, 0.82), "cloud": Color(1, 0.78, 0.82, 0.95),
		"sun": 1.0, "sun_pos": Vector2(0.76, 0.62), "sun_tint": Color(1, 0.62, 0.42), "sun_size": 1.35,
		"moon": 0.0, "moon_pos": Vector2(0.2, 0.42), "stars": 0.25, "fireflies": 0.2, "flowers": 0.55,
	},
	"gece": {
		"sky_top": Color("0b1638"), "sky_mid": Color("1c2c62"), "sky_bottom": Color("3a4a8c"),
		"far": Color(0.38, 0.46, 0.74), "ambient": Color(0.6, 0.66, 0.92), "cloud": Color(0.5, 0.56, 0.8, 0.55),
		"sun": 0.0, "sun_pos": Vector2(0.76, 0.66), "sun_tint": Color(1, 0.6, 0.4), "sun_size": 1.2,
		"moon": 1.0, "moon_pos": Vector2(0.2, 0.42), "stars": 1.0, "fireflies": 1.0, "flowers": 0.4,
	},
}

var tinted: Array = []               # ortam ışığıyla renklenen dış düğümler (ağaç)
var soft_tinted: Array = []          # yarı yarıya renklenenler (kirpi okunaklı kalsın)
var phase_name: String = ""
var _current: Dictionary = {}
var _phase_tween: Tween
var _screen := Vector2(720, 1280)
var _ground_y := 1170.0
var _time := 0.0

var _sky_gradient := Gradient.new()
var _sky: Sprite2D
var _sun: Sprite2D
var _sun_scale := Vector2.ONE
var _moon: Sprite2D
var _far: Sprite2D
var _near: Sprite2D
var _grass: Sprite2D
var _flowers: Sprite2D
var _stars: Array[Sprite2D] = []
var _clouds: Array[Sprite2D] = []
var _fireflies: Array[Sprite2D] = []


func build(screen: Vector2, ground_y: float, front_layer: Node2D) -> void:
	_screen = screen
	_ground_y = ground_y

	# Gökyüzü: üç renkli dikey geçiş
	_sky_gradient.offsets = PackedFloat32Array([0.0, 0.42, 0.75])
	_sky_gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE])
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = _sky_gradient
	sky_texture.fill_from = Vector2(0, 0)
	sky_texture.fill_to = Vector2(0, 1)
	sky_texture.width = 8
	sky_texture.height = 256
	_sky = Sprite2D.new()
	_sky.texture = sky_texture
	_sky.centered = false
	_sky.scale = Vector2(screen.x / 8.0 + 1.0, screen.y / 256.0 + 0.1)
	add_child(_sky)

	# Yıldızlar (gece)
	for i in 30:
		var star := _sprite(TEX_STAR, randf_range(10.0, 22.0))
		star.position = Vector2(randf_range(10.0, screen.x - 10.0), randf_range(380.0, ground_y - 380.0))
		star.set_meta("phase", randf() * TAU)
		add_child(star)
		_stars.append(star)

	_sun = _sprite(TEX_SUN, 190.0)
	_sun_scale = _sun.scale
	add_child(_sun)
	_moon = _sprite(TEX_MOON, 170.0)
	add_child(_moon)

	# Bulutlar
	for i in 5:
		var cloud := _sprite(TEX_CLOUD, randf_range(150.0, 260.0))
		cloud.position = Vector2(randf_range(0.0, screen.x), randf_range(420.0, 700.0))
		cloud.set_meta("speed", randf_range(8.0, 18.0))
		add_child(cloud)
		_clouds.append(cloud)

	# Tepeler, çimen ve çiçekler (alt kenarları zemine göre yerleşir)
	var wide := maxf(1.0, screen.x * 1.2 / TEX_FAR.get_width())
	_far = _layer(TEX_FAR, wide, ground_y - 20.0)
	_near = _layer(TEX_NEAR, wide, ground_y + 40.0)
	_flowers = _layer(TEX_FLOWERS, wide, ground_y - 50.0)
	_grass = _layer(TEX_GRASS, wide, ground_y + 200.0)
	move_child(_flowers, -1)

	# Ateşböcekleri: tepelerin ve ağacın önünde uçuşsun diye ön katmanda
	for i in 14:
		var firefly := _sprite(TEX_FIREFLY, randf_range(26.0, 40.0))
		firefly.set_meta("home", Vector2(randf_range(30.0, screen.x - 30.0), randf_range(ground_y - 720.0, ground_y - 60.0)))
		firefly.set_meta("phase", randf() * TAU)
		firefly.set_meta("speed", randf_range(0.5, 1.1))
		front_layer.add_child(firefly)
		_fireflies.append(firefly)

	set_phase("sabah", 0.0)


func _sprite(texture: Texture2D, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * width / texture.get_width()
	return sprite


# Alt kenarı bottom_y'de olan, yatayda ortalı katman
func _layer(texture: Texture2D, layer_scale: float, bottom_y: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * layer_scale
	sprite.position = Vector2(_screen.x / 2.0, bottom_y - texture.get_height() * layer_scale / 2.0)
	add_child(sprite)
	return sprite


# Zaman dilimini değiştir; duration > 0 ise renkler yumuşakça karışır
func set_phase(phase_id: String, duration: float) -> void:
	if not PALETTES.has(phase_id) or phase_id == phase_name:
		return
	phase_name = phase_id
	var target: Dictionary = PALETTES[phase_id]
	if _phase_tween and _phase_tween.is_valid():
		_phase_tween.kill()
	if duration <= 0.0 or _current.is_empty():
		_apply(target)
		return
	var from := _current.duplicate()
	_phase_tween = create_tween()
	_phase_tween.tween_method(_blend.bind(from, target), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Renklenen düğümler sonradan eklendiyse mevcut paleti yeniden uygula
func refresh() -> void:
	if not _current.is_empty():
		_apply(_current)


func _blend(t: float, from: Dictionary, to: Dictionary) -> void:
	var mixed := {}
	for key in to:
		var a = from[key]
		var b = to[key]
		if a is Color or a is Vector2:
			mixed[key] = a.lerp(b, t)
		else:
			mixed[key] = lerpf(a, b, t)
	_apply(mixed)


func _apply(palette: Dictionary) -> void:
	_current = palette.duplicate()
	_sky_gradient.colors = PackedColorArray([palette["sky_top"], palette["sky_mid"], palette["sky_bottom"]])
	_far.modulate = palette["far"]
	var ambient: Color = palette["ambient"]
	_near.modulate = ambient
	_grass.modulate = ambient
	_flowers.modulate = Color(ambient, palette["flowers"])
	for node in tinted:
		(node as CanvasItem).modulate = ambient
	for node in soft_tinted:
		(node as CanvasItem).modulate = ambient.lerp(Color.WHITE, 0.55)
	for cloud in _clouds:
		cloud.modulate = palette["cloud"]
	var sun_pos: Vector2 = palette["sun_pos"]
	_sun.position = Vector2(_screen.x * sun_pos.x, _screen.y * sun_pos.y)
	_sun.modulate = Color(palette["sun_tint"], palette["sun"])
	_sun_scale = Vector2.ONE * 190.0 / TEX_SUN.get_width() * float(palette["sun_size"])
	var moon_pos: Vector2 = palette["moon_pos"]
	_moon.position = Vector2(_screen.x * moon_pos.x, _screen.y * moon_pos.y)
	_moon.modulate.a = palette["moon"]


func _process(delta: float) -> void:
	_time += delta
	if _current.is_empty():
		return
	for cloud in _clouds:
		cloud.position.x -= float(cloud.get_meta("speed")) * delta
		var half := cloud.texture.get_width() * cloud.scale.x / 2.0
		if cloud.position.x < -half:
			cloud.position = Vector2(_screen.x + half, randf_range(420.0, 700.0))
	# Yıldızlar göz kırpar
	var stars_alpha: float = _current["stars"]
	for star in _stars:
		var phase: float = star.get_meta("phase")
		star.modulate.a = stars_alpha * (0.45 + 0.55 * sin(_time * 2.2 + phase))
		star.visible = stars_alpha > 0.01
	# Güneşin ışınları yavaşça döner ve nabız gibi atar
	_sun.rotation += delta * 0.08
	_sun.scale = _sun_scale * (1.0 + sin(_time * 1.5) * 0.03)
	# Ateşböcekleri süzülür ve yanıp söner
	var firefly_alpha: float = _current["fireflies"]
	for firefly in _fireflies:
		firefly.visible = firefly_alpha > 0.01
		if not firefly.visible:
			continue
		var home: Vector2 = firefly.get_meta("home")
		var phase: float = firefly.get_meta("phase")
		var speed: float = firefly.get_meta("speed")
		firefly.position = home + Vector2(sin(_time * speed + phase) * 70.0, cos(_time * speed * 1.3 + phase) * 45.0)
		firefly.modulate.a = firefly_alpha * (0.35 + 0.65 * maxf(0.0, sin(_time * 2.6 * speed + phase)))
