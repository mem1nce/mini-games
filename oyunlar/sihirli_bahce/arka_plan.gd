extends Node2D
# Arka plan: gökyüzü (ayrı katmanda; gündüz/gece geçişli, yıldızlar, süzülen bulutlar), uzak ve yakın tepeler,
# ahşap kulübe, çit, çimenlik ve hafifçe sallanan çimen öbekleri. Gece: dünya katmanı CanvasModulate ile
# mavimsi kararır; kulübenin penceresi ışık katmanında yanar. Öndeki çimenler `front` düğümündedir
# (ana sahne onu parsellerin önüne koyar).

const G := "res://oyunlar/sihirli_bahce/gorseller/"
const DAY_SKY := [Color("8fd0f2"), Color("e8f7f2")]
const NIGHT_SKY := [Color("141a48"), Color("3d4288")]
const NIGHT_TINT := Color(0.46, 0.5, 0.8)
const FENCE_Y := 478.0                 # çitin dibi (ekran)
const TRANSITION := 1.6

var front: Node2D                      # parsellerin önünde kalan çimenler
var night := false

var _sky_layer: CanvasLayer
var _day_sky: TextureRect
var _night_sky: TextureRect
var _stars: Array[Sprite2D] = []
var _clouds: Array[Sprite2D] = []
var _tufts: Array[Sprite2D] = []
var _window: Sprite2D
var _window_glow: Sprite2D
var _modulate: CanvasModulate
var _size := Vector2(1280, 720)
var _time := 0.0
var _night_amount := 0.0


func setup(canvas_modulate: CanvasModulate, light_layer: Node2D, effects: Node2D) -> void:
	_modulate = canvas_modulate
	_size = get_viewport_rect().size
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -10
	add_child(_sky_layer)
	var sky_root := Node2D.new()
	sky_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sky_layer.add_child(sky_root)
	_day_sky = _gradient_rect(DAY_SKY)
	sky_root.add_child(_day_sky)
	_night_sky = _gradient_rect(NIGHT_SKY)
	_night_sky.modulate.a = 0.0
	sky_root.add_child(_night_sky)
	var star_tex: Texture2D = load(G + "parilti.svg")
	for i in 40:
		var star := Sprite2D.new()
		star.texture = star_tex
		star.position = Vector2(randf_range(0, _size.x), randf_range(10, 330))
		star.scale = Vector2.ONE * randf_range(0.12, 0.3)
		star.modulate.a = 0.0
		star.set_meta("phase", randf() * TAU)
		sky_root.add_child(star)
		_stars.append(star)
	var cloud_tex: Texture2D = load(G + "bulut.svg")
	for i in 4:
		var cloud := Sprite2D.new()
		cloud.texture = cloud_tex
		cloud.scale = Vector2.ONE * randf_range(0.6, 1.0) * 220.0 / cloud_tex.get_width()
		cloud.position = Vector2(randf_range(0, _size.x), randf_range(170, 300))
		cloud.modulate.a = 0.85
		cloud.set_meta("speed", randf_range(6.0, 12.0))
		sky_root.add_child(cloud)
		_clouds.append(cloud)

	var far := _sprite("tepe_uzak.svg", 2000.0, Vector2(_size.x * 0.5, 305))
	far.position.y = 150.0 + far.texture.get_height() * far.scale.y * 0.5
	var near := _sprite("tepe_yakin.svg", 2000.0, Vector2(_size.x * 0.5, 0))
	near.position.y = 262.0 + near.texture.get_height() * near.scale.y * 0.5
	var hut := _sprite("kulube.svg", 230.0, Vector2(maxf(120.0, _size.x * 0.5 - 520.0), FENCE_Y - 104.0))
	_window = Sprite2D.new()
	_window.texture = load(G + "kulube_isik.svg")
	_window.scale = hut.scale
	_window.global_position = hut.global_position
	_window.modulate.a = 0.0
	light_layer.add_child(_window)
	_window_glow = effects.glow_sprite(Color(1, 0.85, 0.5, 0.0), 150.0)
	_window_glow.global_position = hut.global_position + (Vector2(88, 170) - Vector2(140, 140)) * hut.scale.x * hut.texture.get_width() / 280.0
	light_layer.add_child(_window_glow)
	# Çit: yan yana döşenir
	var fence_tex: Texture2D = load(G + "cit.svg")
	var fence_w := 200.0 * 0.9
	var x := -fence_w * 0.5
	while x < _size.x + fence_w:
		var fence := _sprite("cit.svg", fence_w, Vector2(x, FENCE_Y - 54.0 * 0.9))
		fence.texture = fence_tex
		x += fence_w
	queue_redraw()
	# Çimen öbekleri: çitin dibinde ve önde
	for i in 12:
		_tufts.append(_sprite("cimen.svg", randf_range(70, 100), Vector2(randf_range(0, _size.x), FENCE_Y + randf_range(4, 20))))
	front = Node2D.new()
	for i in 10:
		var side := -1.0 if i % 2 == 0 else 1.0
		var tx := _size.x * 0.5 + side * randf_range(300, _size.x * 0.5)
		var tuft := Sprite2D.new()
		tuft.texture = load(G + "cimen.svg")
		tuft.scale = Vector2.ONE * randf_range(80, 120) / tuft.texture.get_width()
		tuft.offset = Vector2(0, -tuft.texture.get_height() * 0.5)
		tuft.position = Vector2(tx, randf_range(650, 712))
		front.add_child(tuft)
		_tufts.append(tuft)
	for tuft in _tufts:
		tuft.set_meta("phase", randf() * TAU)
		if tuft.offset == Vector2.ZERO:
			tuft.offset = Vector2(0, -tuft.texture.get_height() * 0.5)
			tuft.position.y += tuft.texture.get_height() * tuft.scale.y * 0.5


func _gradient_rect(colors: Array) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray(colors)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(_size.x, _size.y * 0.75)
	return rect


func _sprite(file: String, width: float, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + file)
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
	sprite.position = pos
	add_child(sprite)
	return sprite


# Çimenlik: çitin dibinden ekranın altına yumuşak renk geçişi
func _draw() -> void:
	var top := FENCE_Y - 18.0
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for k in 33:
		var x := _size.x * k / 32.0
		points.append(Vector2(x, top + sin(x * 0.013) * 6.0 + sin(x * 0.037) * 3.0))
		colors.append(Color("a8e08a"))
	points.append(Vector2(_size.x, _size.y))
	colors.append(Color("6cbc5a"))
	points.append(Vector2(0, _size.y))
	colors.append(Color("6cbc5a"))
	draw_polygon(points, colors)


func set_night(value: bool, animate: bool) -> void:
	night = value
	var time := TRANSITION if animate else 0.01
	var tween := create_tween().set_parallel()
	tween.tween_method(_set_night_amount, _night_amount, 1.0 if value else 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_night_amount(amount: float) -> void:
	_night_amount = amount
	_night_sky.modulate.a = amount
	_modulate.color = Color.WHITE.lerp(NIGHT_TINT, amount)
	for cloud in _clouds:
		cloud.modulate = Color(1, 1, 1, 0.85).lerp(Color(0.55, 0.6, 0.9, 0.35), amount)
	_window.modulate.a = amount
	_window_glow.modulate.a = amount * 0.7


func _process(delta: float) -> void:
	_time += delta
	for cloud in _clouds:
		cloud.position.x += float(cloud.get_meta("speed")) * delta
		var half := cloud.texture.get_width() * cloud.scale.x * 0.5
		if cloud.position.x > _size.x + half:
			cloud.position = Vector2(-half, randf_range(170, 300))
	for star in _stars:
		star.modulate.a = _night_amount * (0.6 + 0.4 * sin(_time * 1.8 + float(star.get_meta("phase"))))
	for tuft in _tufts:
		tuft.rotation = sin(_time * 1.4 + float(tuft.get_meta("phase"))) * 0.06
