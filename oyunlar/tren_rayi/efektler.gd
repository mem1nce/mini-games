extends Node2D
# Efektler: bacadan çıkan duman pufları (tek tek sprite, yavaşça büyüyüp söner), kutlamadaki renkli duman
# halkaları, konfeti, parıltı ve yıldızlar (CPUParticles2D). Tek seferlik parçacıklar bitince kendini siler.

const G := "res://oyunlar/tren_rayi/gorseller/"
const CONFETTI := [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var _duman: Texture2D = preload(G + "duman.svg")
var _halka: Texture2D = preload(G + "halka.svg")
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


# Tek duman pufu: küçük başlar, büyüyüp süzülür ve söner
func duman(konum: Vector2, boy: float, renk: Color = Color.WHITE) -> void:
	var puf := Sprite2D.new()
	puf.texture = _duman
	puf.position = konum
	var olcek := boy / _duman.get_width()
	puf.scale = Vector2.ONE * olcek * 0.5
	puf.modulate = Color(renk, 0.9)
	puf.rotation = randf() * TAU
	add_child(puf)
	var suzul := Vector2(randf_range(-0.3, 0.3), -1.0) * boy * randf_range(1.2, 1.8)
	var sure := randf_range(1.2, 1.6)
	var tween := puf.create_tween().set_parallel()
	tween.tween_property(puf, "position", konum + suzul, sure).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(puf, "scale", Vector2.ONE * olcek * 1.6, sure).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(puf, "modulate:a", 0.0, sure).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(puf, "rotation", puf.rotation + randf_range(-0.8, 0.8), sure)
	tween.chain().tween_callback(puf.queue_free)


# Düdük: bacadan arka arkaya büyük puflar
func dudum(konum: Vector2, boy: float) -> void:
	for i in 6:
		get_tree().create_timer(i * 0.07).timeout.connect(func() -> void: duman(konum, boy * randf_range(0.9, 1.3)))


# Kutlama: bacadan yükselen renkli duman halkaları
func halkalar(konum: Vector2, boy: float, sayi: int = 8) -> void:
	for i in sayi:
		get_tree().create_timer(i * 0.22).timeout.connect(func() -> void:
			var halka := Sprite2D.new()
			halka.texture = _halka
			halka.position = konum
			var olcek := boy / _halka.get_width()
			halka.scale = Vector2.ONE * olcek * 0.4
			halka.modulate = CONFETTI[i % CONFETTI.size()]
			add_child(halka)
			var hedef := konum + Vector2(randf_range(-0.4, 0.4) * boy, -boy * randf_range(2.2, 3.0))
			var tween := halka.create_tween().set_parallel()
			tween.tween_property(halka, "position", hedef, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(halka, "scale", Vector2.ONE * olcek * 1.4, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(halka, "modulate:a", 0.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.chain().tween_callback(halka.queue_free))


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
	p.initial_velocity_min = 420.0
	p.initial_velocity_max = 780.0
	p.gravity = Vector2(0, 700)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_initial_ramp = renk_rampasi()


func isik(renk: Color, boy: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _isik
	sprite.material = _add
	sprite.scale = Vector2.ONE * boy / _isik.get_width()
	sprite.modulate = renk
	return sprite
