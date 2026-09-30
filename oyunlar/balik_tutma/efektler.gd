extends Node2D
# Efektler (CPUParticles2D ve kısa tween'ler): kabarcıklar, su sıçraması, parıltı, yıldızlar, konfeti, ışık.
# Tek seferlik parçacıklar bitince kendini siler. Dipten sürekli yükselen kabarcıklar da burada.

const G := "res://oyunlar/balik_tutma/gorseller/"
const CONFETTI := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _kabarcik: Texture2D = preload(G + "kabarcik.svg")
var _damla: Texture2D = preload(G + "damla.svg")
var _parilti: Texture2D = preload(G + "parilti.svg")
var _yildiz: Texture2D = preload(G + "yildiz.svg")
var _konfeti: Texture2D = preload(G + "konfeti.svg")
var _isik: Texture2D = preload(G + "isik.svg")
var _add := CanvasItemMaterial.new()


func _init() -> void:
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


static func fade_ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, 1.0), Color(color, 0.0)])
	return ramp


static func renk_rampasi() -> Gradient:
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


func _patlama(doku: Texture2D, konum: Vector2, sayi: int, omur: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = doku
	p.amount = sayi
	p.lifetime = omur
	p.one_shot = true
	p.explosiveness = 0.95
	p.position = konum
	p.finished.connect(p.queue_free)
	add_child(p)
	p.emitting = true
	return p


# Dipten yavaşça yükselen kabarcıklar (sürekli)
func dip_kabarciklari(genislik: float, dip_y: float, yukseklik: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = _kabarcik
	p.amount = 18
	p.lifetime = yukseklik / 70.0
	p.position = Vector2(genislik * 0.5, dip_y)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(genislik * 0.5, 10)
	p.direction = Vector2(0, -1)
	p.spread = 8.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.3
	p.color_ramp = fade_ramp(Color(1, 1, 1, 0.8))
	add_child(p)


func kabarciklar(konum: Vector2, sayi: int = 10, yayilma: float = 30.0) -> void:
	var p := _patlama(_kabarcik, konum, sayi, 1.4)
	p.explosiveness = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = yayilma
	p.direction = Vector2(0, -1)
	p.spread = 30.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.38
	p.color_ramp = fade_ramp(Color.WHITE)


# Su sıçraması: yüzeyden yukarı fırlayan damlalar
func sicrama(konum: Vector2, sayi: int = 10) -> void:
	var p := _patlama(_damla, konum, sayi, 0.8)
	p.direction = Vector2(0, -1)
	p.spread = 45.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 380.0
	p.scale_amount_min = 0.22
	p.scale_amount_max = 0.4
	p.color_ramp = fade_ramp(Color.WHITE)


func parilti(konum: Vector2, renk: Color = Color("fff6b0"), sayi: int = 12, yayilma: float = 40.0) -> void:
	var p := _patlama(_parilti, konum, sayi, 0.8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = yayilma
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
	p.color_ramp = fade_ramp(renk.lerp(Color.WHITE, 0.45))
	p.material = _add


func yildizlar(konum: Vector2, sayi: int = 10) -> void:
	var p := _patlama(_yildiz, konum, sayi, 1.3)
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


func konfeti(konum: Vector2, genislik: float, sayi: int = 90) -> void:
	var p := _patlama(_konfeti, konum, sayi, 3.0)
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(genislik * 0.5, 10)
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.initial_velocity_min = 520.0
	p.initial_velocity_max = 900.0
	p.gravity = Vector2(0, 700)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_initial_ramp = renk_rampasi()


func isik(renk: Color, boy: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _isik
	s.material = _add
	s.scale = Vector2.ONE * boy / _isik.get_width()
	s.modulate = renk
	return s
