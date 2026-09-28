extends Node2D
# Kutlama efektleri: doğru yerleşimde yıldız/ışıltı patlaması, bölüm sonunda konfeti,
# 10. bölüm sonunda büyük final. Hepsi tek seferlik CPUParticles2D; bitince kendini siler.

const TEX_STAR: Texture2D = preload("res://oyunlar/golge_eslestirme/gorseller/yildiz.svg")
const TEX_SPARKLE: Texture2D = preload("res://oyunlar/golge_eslestirme/gorseller/isilti.svg")
const RAINBOW := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _rainbow := Gradient.new()
var _shrink := Curve.new()
var _confetti_texture: Texture2D


func _ready() -> void:
	# Konfeti için keskin geçişli gökkuşağı renkleri (her parça rastgele birini alır)
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in RAINBOW.size():
		offsets.append(float(i) / RAINBOW.size())
		colors.append(RAINBOW[i])
	_rainbow.offsets = offsets
	_rainbow.colors = colors
	_rainbow.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_shrink.add_point(Vector2(0.0, 1.0))
	_shrink.add_point(Vector2(1.0, 0.2))
	# Konfeti parçası: küçük yuvarlak köşeli beyaz dikdörtgen (renk parçacık başına verilir)
	var image := Image.create(14, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	for corner in [Vector2i(0, 0), Vector2i(13, 0), Vector2i(0, 21), Vector2i(13, 21)]:
		image.set_pixelv(corner, Color(1, 1, 1, 0))
	_confetti_texture = ImageTexture.create_from_image(image)


func _emitter(texture: Texture2D, amount: int, lifetime: float, pos: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = texture
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.position = pos
	particles.finished.connect(particles.queue_free)
	add_child(particles)
	return particles


func _fade(color: Color = Color.WHITE) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	gradient.colors = PackedColorArray([color, color, Color(color, 0.0)])
	return gradient


# Eşya gölgesine oturunca: etrafa saçılan yıldızlar ve ışıltılar
func sparkle(pos: Vector2, item_size: float) -> void:
	var stars := _emitter(TEX_STAR, 12, 0.8, pos)
	stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	stars.emission_sphere_radius = item_size * 0.2
	stars.spread = 180.0
	stars.gravity = Vector2(0, 250)
	stars.initial_velocity_min = item_size * 1.4
	stars.initial_velocity_max = item_size * 2.4
	stars.damping_min = item_size * 1.5
	stars.damping_max = item_size * 2.5
	stars.angular_velocity_min = -300.0
	stars.angular_velocity_max = 300.0
	stars.scale_amount_min = item_size * 0.16 / TEX_STAR.get_width()
	stars.scale_amount_max = item_size * 0.28 / TEX_STAR.get_width()
	stars.scale_amount_curve = _shrink
	stars.color_ramp = _fade()
	stars.emitting = true

	var glints := _emitter(TEX_SPARKLE, 10, 0.6, pos)
	glints.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	glints.emission_sphere_radius = item_size * 0.45
	glints.spread = 180.0
	glints.gravity = Vector2.ZERO
	glints.initial_velocity_min = 20.0
	glints.initial_velocity_max = 80.0
	glints.scale_amount_min = item_size * 0.14 / TEX_SPARKLE.get_width()
	glints.scale_amount_max = item_size * 0.3 / TEX_SPARKLE.get_width()
	glints.scale_amount_curve = _shrink
	glints.color_ramp = _fade()
	glints.emitting = true


# Bölüm sonu: ekranın üstünden yağan konfeti
func confetti(amount: int) -> void:
	var screen := get_viewport_rect().size
	var rain := _emitter(_confetti_texture, amount, 3.2, Vector2(screen.x / 2.0, -40.0))
	rain.explosiveness = 0.75
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(screen.x / 2.0, 20.0)
	rain.direction = Vector2(0, 1)
	rain.spread = 25.0
	rain.gravity = Vector2(0, 260)
	rain.initial_velocity_min = 120.0
	rain.initial_velocity_max = 300.0
	rain.angular_velocity_min = -360.0
	rain.angular_velocity_max = 360.0
	rain.angle_min = 0.0
	rain.angle_max = 360.0
	rain.scale_amount_min = 0.8
	rain.scale_amount_max = 1.3
	rain.color_initial_ramp = _rainbow
	rain.emitting = true


# Alt köşelerden yukarı fırlayan konfeti topları
func confetti_cannons(amount: int) -> void:
	var screen := get_viewport_rect().size
	for left in [true, false]:
		var cannon := _emitter(_confetti_texture, amount, 3.0, Vector2(0.0 if left else screen.x, screen.y + 20.0))
		cannon.direction = Vector2(0.45 if left else -0.45, -1.0)
		cannon.spread = 18.0
		cannon.gravity = Vector2(0, 700)
		cannon.initial_velocity_min = screen.y * 0.9
		cannon.initial_velocity_max = screen.y * 1.35
		cannon.damping_min = 40.0
		cannon.damping_max = 90.0
		cannon.angular_velocity_min = -540.0
		cannon.angular_velocity_max = 540.0
		cannon.angle_max = 360.0
		cannon.scale_amount_min = 0.8
		cannon.scale_amount_max = 1.4
		cannon.color_initial_ramp = _rainbow
		cannon.emitting = true


# 10. bölüm sonu: konfeti yağmuru, konfeti topları ve ekranın farklı yerlerinde sırayla yıldız patlamaları
func finale(item_size: float) -> void:
	confetti(160)
	confetti_cannons(70)
	var screen := get_viewport_rect().size
	var tween := create_tween()
	for k in 7:
		var point := Vector2(randf_range(0.2, 0.8) * screen.x, randf_range(0.25, 0.75) * screen.y)
		tween.tween_callback(sparkle.bind(point, item_size * 1.3))
		tween.tween_interval(0.35)
	# Ortada büyüyüp dönerek kaybolan kocaman bir yıldız
	var big := Sprite2D.new()
	big.texture = TEX_STAR
	big.position = screen / 2.0
	big.scale = Vector2.ZERO
	big.z_index = 5
	add_child(big)
	var target := Vector2.ONE * minf(screen.x, screen.y) * 0.55 / TEX_STAR.get_width()
	var grow := big.create_tween()
	grow.tween_property(big, "scale", target, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	grow.parallel().tween_property(big, "rotation", TAU, 1.6).set_trans(Tween.TRANS_SINE)
	grow.tween_interval(1.0)
	grow.tween_property(big, "modulate:a", 0.0, 0.6)
	grow.parallel().tween_property(big, "scale", target * 1.4, 0.6)
	grow.tween_callback(big.queue_free)


func clear() -> void:
	for child in get_children():
		child.queue_free()
