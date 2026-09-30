extends Node2D
# Efektler (dünya koordinatında): toz bulutu, parıltı, ışık halkası, yıldızlar, konfeti, "puf".
# Tek seferlik parçacıklar bitince kendini siler.

const G := "res://oyunlar/kule_yapma/gorseller/"
const CONFETTI := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _toz: Texture2D = preload(G + "toz.svg")
var _parilti: Texture2D = preload(G + "parilti.svg")
var _yildiz: Texture2D = preload(G + "yildiz.svg")
var _konfeti: Texture2D = preload(G + "konfeti.svg")
var _halka: Texture2D = preload(G + "halka.svg")
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


# Katın iki yanından yayılan küçük toz bulutu
func toz(konum: Vector2, genislik: float) -> void:
	for yon in [-1.0, 1.0]:
		var p := _patlama(_toz, konum + Vector2(yon * genislik * 0.45, 0), 6, 0.7)
		p.direction = Vector2(yon, -0.4)
		p.spread = 30.0
		p.gravity = Vector2(0, -20)
		p.initial_velocity_min = 60.0
		p.initial_velocity_max = 150.0
		p.damping_min = 120.0
		p.damping_max = 160.0
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.45
		p.color_ramp = fade_ramp(Color(1, 1, 1, 0.9))


func puf(konum: Vector2) -> void:
	var p := _patlama(_toz, konum, 12, 0.8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 40.0
	p.spread = 180.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.damping_min = 100.0
	p.damping_max = 140.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	p.color_ramp = fade_ramp(Color.WHITE)


func parilti(konum: Vector2, renk: Color = Color("fff6b0"), sayi: int = 14, yayilma: float = 50.0) -> void:
	var p := _patlama(_parilti, konum, sayi, 0.8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = yayilma
	p.spread = 180.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 160.0
	p.damping_min = 60.0
	p.damping_max = 90.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.5
	p.color_ramp = fade_ramp(renk.lerp(Color.WHITE, 0.45))
	p.material = _add


# Mükemmel: genişleyerek sönen ışık halkası (kombo büyüdükçe daha büyük)
func halka(konum: Vector2, boy: float, renk: Color = Color("fff1a6")) -> void:
	var s := Sprite2D.new()
	s.texture = _halka
	s.material = _add
	s.position = konum
	var olcek := boy / _halka.get_width()
	s.scale = Vector2.ONE * olcek * 0.3
	s.modulate = renk
	add_child(s)
	var tween := s.create_tween().set_parallel()
	tween.tween_property(s, "scale", Vector2.ONE * olcek, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(s, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(s.queue_free)


func yildizlar(konum: Vector2, sayi: int = 8) -> void:
	var p := _patlama(_yildiz, konum, sayi, 1.2)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 520)
	p.initial_velocity_min = 240.0
	p.initial_velocity_max = 440.0
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = 0.18
	p.scale_amount_max = 0.3
	p.color_ramp = fade_ramp(Color.WHITE)


func konfeti(konum: Vector2, genislik: float, sayi: int = 100) -> void:
	var p := _patlama(_konfeti, konum, sayi, 3.2)
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(genislik * 0.5, 10)
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.initial_velocity_min = 620.0
	p.initial_velocity_max = 1000.0
	p.gravity = Vector2(0, 700)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_initial_ramp = renk_rampasi()
