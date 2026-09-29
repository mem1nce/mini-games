extends Node2D
# Efektler (ışık katmanında: gece de kararmadan parlar). Parçacıklar CPUParticles2D, tek seferlikler
# bitince kendini siler. Güneş huzmesi ve uçan tohum gibi kısa animasyonlar da burada.

const G := "res://oyunlar/sihirli_bahce/gorseller/"

var _sparkle: Texture2D = preload(G + "parilti.svg")
var _star: Texture2D = preload(G + "yildiz.svg")
var _soil: Texture2D = preload(G + "toprak_parca.svg")
var _leaf: Texture2D = preload(G + "yaprak.svg")
var _glow: Texture2D = preload(G + "isik.svg")
var _heart: Texture2D = preload(G + "kalp.svg")
var _fluff: Texture2D = preload(G + "tohum_tuy.svg")
var _add := CanvasItemMaterial.new()


func _init() -> void:
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


static func fade_ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, 1.0), Color(color, 0.0)])
	return ramp


static func curve(from: float, to: float) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, from))
	c.add_point(Vector2(1, to))
	return c


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


func sparkles(pos: Vector2, color: Color = Color("fff6b0"), amount: int = 14, spread_px: float = 40.0) -> void:
	var p := _burst(_sparkle, pos, amount, 0.9)
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
	p.scale_amount_max = 0.55
	p.scale_amount_curve = curve(1.0, 0.1)
	p.color_ramp = fade_ramp(color.lerp(Color.WHITE, 0.5))
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
	p.scale_amount_min = 0.18
	p.scale_amount_max = 0.32
	p.color_ramp = fade_ramp(Color.WHITE)


func soil_bits(pos: Vector2, amount: int = 10) -> void:
	var p := _burst(_soil, pos, amount, 0.7)
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 280.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.55
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40, 4)
	p.color_ramp = fade_ramp(Color.WHITE)


func hearts(pos: Vector2, amount: int = 3) -> void:
	var p := _burst(_heart, pos, amount, 1.1)
	p.explosiveness = 0.6
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 120.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.55
	p.color_ramp = fade_ramp(Color.WHITE)


# Mantar ve ay çiçeği: yavaşça yükselen parlak zerreler
func glow_dust(pos: Vector2, color: Color, amount: int = 18) -> void:
	var p := _burst(_glow, pos, amount, 2.2)
	p.explosiveness = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 50.0
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2(0, -25)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.12
	p.color_ramp = fade_ramp(color)
	p.material = _add


# Rüzgar: ekranın solundan sağına savrulan yapraklar
func leaf_gust(size: Vector2) -> void:
	var p := _burst(_leaf, Vector2(-40, size.y * 0.45), 16, 2.6)
	p.explosiveness = 0.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10, size.y * 0.3)
	p.direction = Vector2(1, -0.1)
	p.spread = 18.0
	p.gravity = Vector2(0, 40)
	p.initial_velocity_min = 520.0
	p.initial_velocity_max = 760.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.8
	p.color_ramp = fade_ramp(Color.WHITE)


# Güneşten bitkiye inen sıcak ışık huzmesi (ve dibinde parıltı)
func sun_beam(from: Vector2, to: Vector2) -> void:
	var beam := Polygon2D.new()
	var dir := (to - from).normalized()
	var side := Vector2(-dir.y, dir.x)
	beam.polygon = PackedVector2Array([from + side * 8.0, from - side * 8.0, to - side * 46.0, to + side * 46.0])
	beam.vertex_colors = PackedColorArray([Color(1, 0.92, 0.55, 0.32), Color(1, 0.92, 0.55, 0.32), Color(1, 0.8, 0.35, 0.06), Color(1, 0.8, 0.35, 0.06)])
	beam.material = _add
	beam.modulate.a = 0.0
	add_child(beam)
	var glow := Sprite2D.new()
	glow.texture = _glow
	glow.material = _add
	glow.position = to
	glow.scale = Vector2.ONE * 0.1
	glow.modulate = Color(1, 0.9, 0.5, 0.0)
	add_child(glow)
	var tween := create_tween().set_parallel()
	tween.tween_property(beam, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.45, 0.4)
	tween.tween_property(glow, "scale", Vector2.ONE * 0.9, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(0.5)
	tween.chain().tween_property(beam, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(beam.queue_free)
	tween.chain().tween_callback(glow.queue_free)
	get_tree().create_timer(0.35).timeout.connect(sparkles.bind(to, Color("ffe27a"), 10, 50.0))


# Rüzgarda uçan tohum: yay çizerek boş parsele süzülür, varınca done çağrılır
func fly_seed(from: Vector2, to: Vector2, done: Callable) -> void:
	var fluff := Sprite2D.new()
	fluff.texture = _fluff
	fluff.scale = Vector2.ONE * 0.9
	fluff.position = from
	add_child(fluff)
	var mid := (from + to) * 0.5 + Vector2(0, -220.0)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var a := from.lerp(mid, t)
		var b := mid.lerp(to, t)
		fluff.position = a.lerp(b, t) + Vector2(sin(t * TAU * 2.0) * 16.0, 0)
		fluff.rotation = sin(t * TAU * 1.5) * 0.4, 0.0, 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fluff, "modulate:a", 0.0, 0.2)
	tween.tween_callback(done)
	tween.tween_callback(fluff.queue_free)


func glow_sprite(color: Color, size: float) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.texture = _glow
	glow.material = _add
	glow.scale = Vector2.ONE * size / _glow.get_width()
	glow.modulate = color
	return glow
