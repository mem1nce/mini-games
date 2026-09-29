extends CanvasLayer
# Arka plan (ekran koordinatında): gökyüzü, güneş/ay, bulutlar ve 3 paralaks katman (uzak, orta, yakın).
# Kamera ilerledikçe her katman kendi oranında kayar ve yatayda döşenir; yol yükselip alçaldıkça
# katmanlar da biraz kayar. Ayrıca hafif tema efektleri ayrı bir katmanda, yolun önünde:
# orman uçuşan yapraklar, çöl sıcak ışık ve toz zerreleri, kar yağan kar, gece şehri parlayan yıldızlar.

const Pistler := preload("res://oyunlar/araba_yarisi/pistler.gd")
const G := "res://oyunlar/araba_yarisi/gorseller/"
const TILE := 1600.0
const SUN_Y := 168.0
const LAYERS := ["uzak", "orta", "yakin"]
const FACTOR_X := [0.07, 0.18, 0.38]
const FACTOR_Y := [0.05, 0.12, 0.22]
const BASE_Y := [40.0, 132.0, 190.0]     # katmanın üst kenarı (yol başlangıç yüksekliğindeyken)

var _sky: TextureRect
var _sky_gradient := Gradient.new()
var _sun: Sprite2D
var _sun_glow: Sprite2D
var _clouds: Array[Sprite2D] = []
var _layers: Array[Node2D] = []
var _night_stars: Array[Sprite2D] = []
var _weather_layer: CanvasLayer
var _weather: Array[Dictionary] = []     # sprite, vel, depth, spin, phase
var _weather_kind := ""
var _ref_y := 0.0
var _last_x := 0.0
var _time := 0.0
var _screen := Vector2(1280, 720)


func _ready() -> void:
	layer = -10
	var root := Node2D.new()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(root)
	_sky = TextureRect.new()
	var tex := GradientTexture2D.new()
	tex.gradient = _sky_gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	_sky.texture = tex
	_sky.stretch_mode = TextureRect.STRETCH_SCALE
	_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sky)
	_sun = Sprite2D.new()
	root.add_child(_sun)
	for i in 4:
		var cloud := Sprite2D.new()
		cloud.texture = load(G + "bulut.svg")
		root.add_child(cloud)
		_clouds.append(cloud)
	for i in 36:
		var star := Sprite2D.new()
		star.texture = load(G + "kar_tanesi.svg")
		root.add_child(star)
		_night_stars.append(star)
	for i in LAYERS.size():
		var node := Node2D.new()
		root.add_child(node)
		_layers.append(node)
	# Çölün sıcak ışığı katmanların önünde: her şeyi hafifçe ısıtır
	_sun_glow = Sprite2D.new()
	_sun_glow.texture = load(G + "isik.svg")
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sun_glow.material = add
	root.add_child(_sun_glow)
	_weather_layer = CanvasLayer.new()
	_weather_layer.layer = 1
	add_child(_weather_layer)


func set_theme(theme_name: String) -> void:
	var theme: Dictionary = Pistler.THEMES[theme_name]
	_screen = get_viewport().get_visible_rect().size
	_sky.size = _screen
	var sky: Array = theme["sky"]
	_sky_gradient.offsets = PackedFloat32Array([0.0, 0.75])
	_sky_gradient.colors = PackedColorArray([sky[0], sky[1]])
	# Paralaks katmanları: her biri 3 döşeme + altında katmanın alt rengiyle dolgu
	for i in LAYERS.size():
		var node := _layers[i]
		for child in node.get_children():
			child.queue_free()
		var tex: Texture2D = load(G + "arka_%s_%s.svg" % [theme_name, LAYERS[i]])
		var bottom := tex.get_image().get_pixel(4, tex.get_height() - 3)
		var fill := ColorRect.new()
		fill.color = bottom
		fill.position = Vector2(0, tex.get_height() - 4)
		fill.size = Vector2(TILE * 3.0, 1200)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(fill)
		for k in 3:
			var tile := Sprite2D.new()
			tile.texture = tex
			tile.centered = false
			tile.position = Vector2(k * TILE, 0)
			node.add_child(tile)
	# Güneş / ay
	var sun: String = theme["sun"]
	_sun.visible = sun != ""
	_sun_glow.visible = sun == "sicak_gunes"
	if sun != "":
		_sun.texture = load(G + ("ay.svg" if sun == "ay" else "gunes.svg"))
		var size := 200.0 if sun == "sicak_gunes" else 150.0
		_sun.scale = Vector2.ONE * size / _sun.texture.get_width()
		_sun.position = Vector2(_screen.x * 0.8, SUN_Y)
		_sun_glow.scale = Vector2.ONE * 1100.0 / _sun_glow.texture.get_width()
		_sun_glow.position = _sun.position
		_sun_glow.modulate = Color(1, 0.68, 0.35, 0.4)
	# Bulutlar (gece yok, karda gri)
	for i in _clouds.size():
		var cloud := _clouds[i]
		cloud.visible = theme_name != "sehir"
		cloud.scale = Vector2.ONE * randf_range(0.55, 0.95) * 240.0 / cloud.texture.get_width()
		cloud.position = Vector2(randf_range(0, _screen.x), randf_range(50, 190))
		cloud.modulate = Color(0.93, 0.95, 1.0, 0.9) if theme_name == "kar" else Color(1, 1, 1, 0.9)
		cloud.set_meta("drift", randf_range(6.0, 14.0))
	for star in _night_stars:
		star.visible = theme_name == "sehir"
		star.position = Vector2(randf_range(0, _screen.x), randf_range(10, 260))
		star.scale = Vector2.ONE * randf_range(0.16, 0.32)
		star.set_meta("phase", randf() * TAU)
	_make_weather(theme["effect"])


func start(camera_pos: Vector2) -> void:
	_ref_y = camera_pos.y
	_last_x = camera_pos.x
	scroll(camera_pos, 0.0)


func scroll(camera_pos: Vector2, delta: float) -> void:
	_time += delta
	var dx := camera_pos.x - _last_x
	_last_x = camera_pos.x
	var dy := _ref_y - camera_pos.y
	for i in _layers.size():
		_layers[i].position = Vector2(-fposmod(camera_pos.x * FACTOR_X[i], TILE), BASE_Y[i] + dy * FACTOR_Y[i])
	for cloud in _clouds:
		cloud.position.x -= dx * 0.03 + float(cloud.get_meta("drift")) * delta
		var half := cloud.texture.get_width() * cloud.scale.x * 0.5
		if cloud.position.x < -half:
			cloud.position = Vector2(_screen.x + half, randf_range(50, 190))
	for star in _night_stars:
		if star.visible:
			star.modulate.a = 0.55 + 0.45 * sin(_time * 1.7 + float(star.get_meta("phase")))
	if _sun.visible:
		_sun.position.y = SUN_Y + dy * 0.02
		_sun_glow.position = _sun.position
		_sun_glow.modulate.a = 0.38 + sin(_time * 0.8) * 0.04
	_move_weather(dx, delta)


# --- Tema efektleri: az sayıda sprite, ekranda dolaşır; kamera ilerledikçe derinliğine göre sola kayar ---

func _make_weather(kind: String) -> void:
	for item in _weather:
		item["sprite"].queue_free()
	_weather.clear()
	_weather_kind = kind
	var settings := {
		"yaprak": {"tex": "yaprak.svg", "count": 7, "size": [26.0, 38.0], "alpha": 0.85},
		"kar": {"tex": "kar_tanesi.svg", "count": 46, "size": [10.0, 22.0], "alpha": 0.9},
		"toz": {"tex": "kar_tanesi.svg", "count": 16, "size": [6.0, 12.0], "alpha": 0.45},
	}
	if not settings.has(kind):
		return
	var info: Dictionary = settings[kind]
	for i in info["count"]:
		var sprite := Sprite2D.new()
		sprite.texture = load(G + info["tex"])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var depth := randf_range(0.45, 1.0)
		var size: float = lerpf(info["size"][0], info["size"][1], depth)
		sprite.scale = Vector2.ONE * size / sprite.texture.get_width()
		sprite.modulate = Color(1, 0.93, 0.78, info["alpha"] * depth) if kind == "toz" else Color(1, 1, 1, info["alpha"] * lerpf(0.6, 1.0, depth))
		sprite.position = Vector2(randf_range(0, _screen.x), randf_range(0, _screen.y))
		sprite.rotation = randf() * TAU
		_weather_layer.add_child(sprite)
		var vel := Vector2.ZERO
		match kind:
			"yaprak":
				vel = Vector2(randf_range(-70, -30), randf_range(30, 60))
			"kar":
				vel = Vector2(randf_range(-20, -6), randf_range(40, 85) * depth)
			"toz":
				vel = Vector2(randf_range(-30, -10), randf_range(-6, 6))
		_weather.append({"sprite": sprite, "vel": vel, "depth": depth, "spin": randf_range(-1.5, 1.5), "phase": randf() * TAU})


func _move_weather(dx: float, delta: float) -> void:
	for item in _weather:
		var sprite: Sprite2D = item["sprite"]
		var vel: Vector2 = item["vel"]
		var depth: float = item["depth"]
		var sway := sin(_time * 1.3 + float(item["phase"])) * (22.0 if _weather_kind == "yaprak" else 8.0)
		sprite.position += Vector2(vel.x + sway, vel.y) * delta - Vector2(dx * depth * 0.9, 0)
		sprite.rotation += float(item["spin"]) * delta
		if sprite.position.x < -40.0:
			sprite.position = Vector2(_screen.x + 40.0, randf_range(-20, _screen.y * 0.8))
		elif sprite.position.x > _screen.x + 60.0:
			sprite.position.x = -30.0
		if sprite.position.y > _screen.y + 30.0:
			sprite.position = Vector2(randf_range(0, _screen.x + 200), -30.0)
		elif sprite.position.y < -40.0:
			sprite.position.y = _screen.y + 20.0


func set_weather_visible(value: bool) -> void:
	_weather_layer.visible = value
