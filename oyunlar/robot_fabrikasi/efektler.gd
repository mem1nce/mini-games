extends Node2D
# Efektler (CPUParticles2D): parıltı, yıldızlar, kalpler, konfeti ve yumuşak ışık sprite'ı.
# Tek seferlik parçacıklar bitince kendini siler.

const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const CONFETTI := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _sparkle: Texture2D = preload(G + "parilti.svg")
var _star: Texture2D = preload(G + "yildiz.svg")
var _glow: Texture2D = preload(G + "isik.svg")
var _confetti: Texture2D = preload(G + "konfeti.svg")
var _add := CanvasItemMaterial.new()


func _init() -> void:
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


static func fade_ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, 1.0), Color(color, 0.0)])
	return ramp


static func confetti_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI.size():
		offsets.append(float(i) / CONFETTI.size())
		colors.append(CONFETTI[i])
	ramp.offsets = offsets
	ramp.colors = colors
	return ramp


func _burst(texture: Texture2D, pos: Vector2, amount: int, lifetime: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.95
	p.position = pos
	p.finished.connect(p.queue_free)
	add_child(p)
	p.emitting = true
	return p


func sparkles(pos: Vector2, color: Color = Color("fff6b0"), amount: int = 12, spread_px: float = 40.0) -> void:
	var p := _burst(_sparkle, pos, amount, 0.8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread_px
	p.spread = 180.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 140.0
	p.damping_min = 60.0
	p.damping_max = 90.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.5
	p.color_ramp = fade_ramp(color.lerp(Color.WHITE, 0.45))
	p.material = _add


func stars(pos: Vector2, amount: int = 10) -> void:
	var p := _burst(_star, pos, amount, 1.2)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 480.0
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.34
	p.color_ramp = fade_ramp(Color.WHITE)


func hearts(pos: Vector2, amount: int = 2) -> void:
	sparkles(pos, Color("ff8fb0"), amount * 4, 20.0)


func confetti(pos: Vector2, width: float) -> void:
	var p := _burst(_confetti, pos, 90, 3.0)
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width * 0.5, 10)
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.initial_velocity_min = 420.0
	p.initial_velocity_max = 780.0
	p.gravity = Vector2(0, 700)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_initial_ramp = confetti_ramp()


func glow_sprite(color: Color, size: float) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.texture = _glow
	glow.material = _add
	glow.scale = Vector2.ONE * size / _glow.get_width()
	glow.modulate = color
	return glow
