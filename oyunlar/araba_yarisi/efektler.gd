extends Node2D
# Yarış efektleri (CPUParticles2D): egzoz dumanı, yıldız parıltısı + zıplayan "+1", su sıçraması,
# toz ve konfeti. Tek seferlik parçacıklar bitince kendini siler. Hepsi hafif ve kısa.

const G := "res://oyunlar/araba_yarisi/gorseller/"
const CONFETTI_COLORS := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _smoke: Texture2D = preload(G + "duman.svg")
var _sparkle: Texture2D = preload(G + "parilti.svg")
var _drop: Texture2D = preload(G + "damla.svg")
var _confetti: Texture2D = preload(G + "konfeti.svg")


static func fade_ramp(color: Color, peak: float = 0.9) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, peak), Color(color, 0.0)])
	return ramp


static func grow_curve(from: float, to: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0, from))
	curve.add_point(Vector2(1, to))
	return curve


# Her arabanın egzozuna takılan duman (dünya koordinatında kalır, arkada iz bırakır)
func make_exhaust() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _smoke
	p.amount = 7
	p.lifetime = 0.6
	p.local_coords = false
	p.emitting = false
	p.direction = Vector2(-1, -0.25)
	p.spread = 16.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, -50)
	p.damping_min = 40.0
	p.damping_max = 60.0
	p.scale_amount_min = 0.16
	p.scale_amount_max = 0.24
	p.scale_amount_curve = grow_curve(0.5, 1.6)
	p.color_ramp = fade_ramp(Color(1, 1, 1), 0.55)
	return p


func _burst(texture: Texture2D, pos: Vector2, amount: int, lifetime: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.position = pos
	p.finished.connect(p.queue_free)
	add_child(p)
	p.emitting = true
	return p


func star_burst(pos: Vector2) -> void:
	var p := _burst(_sparkle, pos, 12, 0.6)
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2.ZERO
	p.damping_min = 250.0
	p.damping_max = 350.0
	p.angular_velocity_min = -200.0
	p.angular_velocity_max = 200.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.38
	p.scale_amount_curve = grow_curve(1.0, 0.2)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color("fff6b0"), Color(1, 0.85, 0.3, 0.0)])
	p.color_ramp = ramp
	_plus_one(pos)


# Yıldızın yerinden zıplayarak yükselen "+1"
func _plus_one(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "+1"
	var settings := LabelSettings.new()
	settings.font_size = 46
	settings.font_color = Color("ffd84a")
	settings.outline_size = 12
	settings.outline_color = Color("8a4b00")
	settings.shadow_size = 0
	label.label_settings = settings
	label.theme_type_variation = &"Baslik"
	label.size = Vector2(100, 60)
	label.pivot_offset = label.size / 2.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos - label.size / 2.0 + Vector2(0, -30)
	label.scale = Vector2.ZERO
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - 80.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(label.queue_free)


func splash(pos: Vector2, tint: Color) -> void:
	var p := _burst(_drop, pos, 16, 0.75)
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.initial_velocity_min = 240.0
	p.initial_velocity_max = 420.0
	p.gravity = Vector2(0, 980)
	p.scale_amount_min = 0.22
	p.scale_amount_max = 0.4
	p.color = tint
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(80, 10)


func dust(pos: Vector2, tint: Color, amount: int = 8) -> void:
	var p := _burst(_smoke, pos, amount, 0.7)
	p.direction = Vector2(0, -1)
	p.spread = 85.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.gravity = Vector2(0, -20)
	p.damping_min = 120.0
	p.damping_max = 180.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.5
	p.scale_amount_curve = grow_curve(0.6, 1.4)
	p.color_ramp = fade_ramp(tint, 0.8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(70, 6)


func confetti(pos: Vector2) -> void:
	var p := _burst(_confetti, pos, 70, 2.4)
	p.explosiveness = 0.95
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.initial_velocity_min = 520.0
	p.initial_velocity_max = 900.0
	p.gravity = Vector2(0, 760)
	p.damping_min = 20.0
	p.damping_max = 40.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_initial_ramp = confetti_ramp()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40, 10)


# Konfeti renkleri: her parça rastgele bir renk alır
static func confetti_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / CONFETTI_COLORS.size())
		colors.append(CONFETTI_COLORS[i])
	ramp.offsets = offsets
	ramp.colors = colors
	return ramp
