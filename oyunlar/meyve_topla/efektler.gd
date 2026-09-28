extends Node2D
# Efektler: CPUParticles2D ile parçacıklar (meyve suyu, parıltı, yaprak, konfeti),
# ekran sarsıntısı ve kısa açılır yazılar. Tek seferlik parçacıklar bitince kendini siler.

const TEX_DROP: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/damla.svg")
const TEX_SPARKLE: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/isilti.svg")
const TEX_STAR: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/yildiz.svg")
const TEX_LEAF: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/yaprak.svg")
const TEX_CONFETTI: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/konfeti.svg")
const TEX_DUST: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/toz.svg")
const RAINBOW := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var world: Node2D                # sarsılacak düğüm
var _shake_left := 0.0
var _shake_total := 1.0
var _shake_strength := 0.0
var _rainbow := Gradient.new()
var _shrink := Curve.new()


func _ready() -> void:
	# Konfeti için rastgele seçilen, keskin geçişli gökkuşağı renkleri
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in RAINBOW.size():
		offsets.append(float(i) / RAINBOW.size())
		colors.append(RAINBOW[i])
	_rainbow.offsets = offsets
	_rainbow.colors = colors
	_rainbow.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_shrink.add_point(Vector2(0.0, 1.0))
	_shrink.add_point(Vector2(1.0, 0.25))


func _process(delta: float) -> void:
	if _shake_left <= 0.0 or world == null:
		return
	_shake_left -= delta
	if _shake_left <= 0.0:
		world.position = Vector2.ZERO
		return
	var k := _shake_left / _shake_total
	world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * k


func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength if _shake_left > 0.0 else 0.0, strength)
	_shake_left = duration
	_shake_total = duration


# Tek seferlik parçacık yayıcısı
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


func _fade(color: Color, hold: float = 0.0) -> Gradient:
	var gradient := Gradient.new()
	if hold > 0.0:
		gradient.offsets = PackedFloat32Array([0.0, hold, 1.0])
		gradient.colors = PackedColorArray([color, color, Color(color, 0.0)])
	else:
		gradient.set_color(0, color)
		gradient.set_color(1, Color(color, 0.0))
	return gradient


# Meyve sepete girince: meyve renginde damlalar ve birkaç parıltı
func burst(pos: Vector2, color: Color, amount: int = 16) -> void:
	var drops := _emitter(TEX_DROP, amount, 0.7, pos)
	drops.direction = Vector2(0, -1)
	drops.spread = 75.0
	drops.initial_velocity_min = 160.0
	drops.initial_velocity_max = 380.0
	drops.gravity = Vector2(0, 980)
	drops.scale_amount_min = 0.25
	drops.scale_amount_max = 0.55
	drops.scale_amount_curve = _shrink
	drops.color_ramp = _fade(color.lightened(0.15), 0.5)
	drops.emitting = true

	var sparkles := _emitter(TEX_SPARKLE, 6, 0.5, pos)
	sparkles.direction = Vector2(0, -1)
	sparkles.spread = 180.0
	sparkles.initial_velocity_min = 80.0
	sparkles.initial_velocity_max = 170.0
	sparkles.damping_min = 150.0
	sparkles.damping_max = 250.0
	sparkles.angular_velocity_min = -240.0
	sparkles.angular_velocity_max = 240.0
	sparkles.scale_amount_min = 0.14
	sparkles.scale_amount_max = 0.28
	sparkles.color_ramp = _fade(Color.WHITE, 0.4)
	sparkles.emitting = true


# Hedef olmayan meyve seker ya da meyve yere düşer: küçük toz bulutu
func puff(pos: Vector2) -> void:
	var dust := _emitter(TEX_DUST, 8, 0.5, pos)
	dust.direction = Vector2(0, -1)
	dust.spread = 90.0
	dust.initial_velocity_min = 40.0
	dust.initial_velocity_max = 110.0
	dust.damping_min = 80.0
	dust.damping_max = 140.0
	dust.scale_amount_min = 0.3
	dust.scale_amount_max = 0.6
	dust.color_ramp = _fade(Color(1, 0.98, 0.92, 0.7))
	dust.emitting = true


# Art arda yakalama ödülü: kirpinin etrafında dışa açılan yıldızlar ve parıltılar
func sparkle_ring(pos: Vector2) -> void:
	var sparkles := _emitter(TEX_SPARKLE, 16, 0.9, pos)
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	sparkles.emission_sphere_radius = 70.0
	sparkles.spread = 180.0
	sparkles.initial_velocity_min = 20.0
	sparkles.initial_velocity_max = 60.0
	sparkles.radial_accel_min = 180.0
	sparkles.radial_accel_max = 300.0
	sparkles.angular_velocity_min = -300.0
	sparkles.angular_velocity_max = 300.0
	sparkles.scale_amount_min = 0.2
	sparkles.scale_amount_max = 0.4
	sparkles.color_ramp = _fade(Color("fff3a6"), 0.5)
	sparkles.emitting = true

	var stars := _emitter(TEX_STAR, 8, 0.9, pos)
	stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	stars.emission_sphere_radius = 50.0
	stars.spread = 180.0
	stars.initial_velocity_min = 60.0
	stars.initial_velocity_max = 140.0
	stars.radial_accel_min = 120.0
	stars.radial_accel_max = 200.0
	stars.angular_velocity_min = -200.0
	stars.angular_velocity_max = 200.0
	stars.scale_amount_min = 0.15
	stars.scale_amount_max = 0.25
	stars.color_ramp = _fade(Color.WHITE, 0.6)
	stars.emitting = true


# Dal sallanırken dökülen yapraklar
func leaves(pos: Vector2, amount: int = 3) -> void:
	var falling := _emitter(TEX_LEAF, amount, 1.8, pos)
	falling.explosiveness = 0.6
	falling.direction = Vector2(0, 1)
	falling.spread = 70.0
	falling.initial_velocity_min = 30.0
	falling.initial_velocity_max = 90.0
	falling.gravity = Vector2(0, 140)
	falling.damping_min = 10.0
	falling.damping_max = 30.0
	falling.angle_min = 0.0
	falling.angle_max = 360.0
	falling.angular_velocity_min = -200.0
	falling.angular_velocity_max = 200.0
	falling.scale_amount_min = 0.35
	falling.scale_amount_max = 0.5
	falling.color_ramp = _fade(Color.WHITE, 0.75)
	falling.emitting = true


# Güçlendirme baloncuğu patlayınca
func pop(pos: Vector2) -> void:
	var drops := _emitter(TEX_DROP, 14, 0.5, pos)
	drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	drops.emission_sphere_radius = 40.0
	drops.spread = 180.0
	drops.radial_accel_min = 400.0
	drops.radial_accel_max = 600.0
	drops.scale_amount_min = 0.2
	drops.scale_amount_max = 0.35
	drops.color_ramp = _fade(Color("c8f0ff"))
	drops.emitting = true
	sparkle_ring(pos)


# Bölüm sonu: yukarıdan konfeti yağmuru ve alt köşelerden fırlayan iki konfeti topu
func confetti(screen: Vector2) -> void:
	var rain := _emitter(TEX_CONFETTI, 140, 3.2, Vector2(screen.x / 2.0, -30.0))
	rain.explosiveness = 0.35
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(screen.x / 2.0, 10.0)
	_confetti_look(rain)
	rain.direction = Vector2(0, 1)
	rain.spread = 25.0
	rain.initial_velocity_min = 140.0
	rain.initial_velocity_max = 280.0
	rain.gravity = Vector2(0, 240)
	rain.emitting = true

	for side in [-1.0, 1.0]:
		var start := Vector2(screen.x / 2.0 + side * (screen.x / 2.0 + 10.0), screen.y + 10.0)
		var cannon := _emitter(TEX_CONFETTI, 60, 2.4, start)
		cannon.explosiveness = 0.9
		_confetti_look(cannon)
		cannon.direction = Vector2(-side * 0.42, -1.0)
		cannon.spread = 16.0
		cannon.initial_velocity_min = 950.0
		cannon.initial_velocity_max = 1350.0
		cannon.gravity = Vector2(0, 1100)
		cannon.damping_min = 30.0
		cannon.damping_max = 80.0
		cannon.emitting = true

	var stars := _emitter(TEX_STAR, 14, 3.0, Vector2(screen.x / 2.0, -40.0))
	stars.explosiveness = 0.4
	stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	stars.emission_rect_extents = Vector2(screen.x / 2.0, 10.0)
	stars.direction = Vector2(0, 1)
	stars.spread = 20.0
	stars.initial_velocity_min = 160.0
	stars.initial_velocity_max = 260.0
	stars.gravity = Vector2(0, 200)
	stars.angular_velocity_min = -180.0
	stars.angular_velocity_max = 180.0
	stars.scale_amount_min = 0.25
	stars.scale_amount_max = 0.4
	stars.color_ramp = _fade(Color.WHITE, 0.8)
	stars.emitting = true


func _confetti_look(particles: CPUParticles2D) -> void:
	particles.color_initial_ramp = _rainbow
	particles.color_ramp = _fade(Color.WHITE, 0.8)
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.scale_amount_min = 0.45
	particles.scale_amount_max = 0.8


# Kısa, gökkuşağı renkli açılır yazı (ör. "x2")
func popup_text(pos: Vector2, text: String) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	for i in text.length():
		var letter := Label.new()
		letter.text = text[i]
		letter.add_theme_font_size_override("font_size", 72)
		letter.add_theme_color_override("font_color", RAINBOW[(i * 2 + 1) % RAINBOW.size()])
		letter.add_theme_color_override("font_outline_color", Color("3b2a5a"))
		letter.add_theme_constant_override("outline_size", 20)
		box.add_child(letter)
	add_child(box)
	box.size = box.get_combined_minimum_size()
	box.position = pos - box.size / 2.0
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2.ZERO
	var tween := box.create_tween()
	tween.tween_property(box, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(box, "position:y", box.position.y - 70.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "modulate:a", 0.0, 0.3)
	tween.tween_callback(box.queue_free)
