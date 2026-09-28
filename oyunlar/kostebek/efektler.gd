extends Node2D
# Efektler (World içinde, ekran sarsıntısı World'ü sarsar): yıldız/ışıltı patlamaları,
# bombanın yumuşak "puf" duman bulutu, uçan kask parçaları. Tek seferlik parçacıklar bitince silinir.

const G := "res://oyunlar/kostebek/gorseller/"
const TEX_STAR: Texture2D = preload(G + "yildiz.svg")
const TEX_SPARKLE: Texture2D = preload(G + "isilti.svg")
const TEX_SMOKE: Texture2D = preload(G + "duman.svg")
const TEX_SHARDS: Array[Texture2D] = [preload(G + "kask_parca_1.svg"), preload(G + "kask_parca_2.svg"), preload(G + "kask_parca_3.svg")]
# Kask parçalarının tuvaldeki merkezleri, tuval merkezine (128,150) göre
const SHARD_CENTERS: Array[Vector2] = [Vector2(-60, -88), Vector2(0, -100), Vector2(60, -88)]

var world: Node2D
var _shake_left: float = 0.0
var _shake_total: float = 1.0
var _shake_strength: float = 0.0
var _shrink := Curve.new()


func _ready() -> void:
	world = get_parent()
	_shrink.add_point(Vector2(0.0, 1.0))
	_shrink.add_point(Vector2(1.0, 0.2))


func _process(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left -= delta
	if _shake_left <= 0.0:
		world.position = Vector2.ZERO
		return
	var k := _shake_left / _shake_total
	world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * k


# Hafif ekran sarsıntısı
func shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_left = duration
	_shake_total = duration


func stop_shake() -> void:
	_shake_left = 0.0
	world.position = Vector2.ZERO


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


func _fade(color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gradient.colors = PackedColorArray([color, color, Color(color, 0.0)])
	return gradient


# Köstebek vurulunca ya da meyve toplanınca: dışa saçılan yıldızlar ve ışıltılar
func sparkle(pos: Vector2, size: float, color: Color = Color.WHITE, with_stars: bool = true) -> void:
	if with_stars:
		var stars := _emitter(TEX_STAR, 8, 0.6, pos)
		stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		stars.emission_sphere_radius = size * 0.15
		stars.spread = 180.0
		stars.gravity = Vector2(0, 300)
		stars.initial_velocity_min = size * 1.6
		stars.initial_velocity_max = size * 2.6
		stars.damping_min = size * 1.5
		stars.damping_max = size * 2.5
		stars.angular_velocity_min = -300.0
		stars.angular_velocity_max = 300.0
		stars.scale_amount_min = size * 0.14 / TEX_STAR.get_width()
		stars.scale_amount_max = size * 0.24 / TEX_STAR.get_width()
		stars.scale_amount_curve = _shrink
		stars.color_ramp = _fade(Color.WHITE)
		stars.emitting = true
	var glints := _emitter(TEX_SPARKLE, 10, 0.5, pos)
	glints.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	glints.emission_sphere_radius = size * 0.35
	glints.spread = 180.0
	glints.gravity = Vector2.ZERO
	glints.initial_velocity_min = size * 0.3
	glints.initial_velocity_max = size * 0.9
	glints.scale_amount_min = size * 0.16 / TEX_SPARKLE.get_width()
	glints.scale_amount_max = size * 0.32 / TEX_SPARKLE.get_width()
	glints.scale_amount_curve = _shrink
	glints.color_ramp = _fade(color.lightened(0.4))
	glints.emitting = true


# Bomba: büyüyerek beliren ve yavaşça sönen yumuşak duman bulutu + etrafa dağılan küçük bulutçuklar
func smoke(pos: Vector2, size: float) -> void:
	var cloud := Sprite2D.new()
	cloud.texture = TEX_SMOKE
	cloud.position = pos
	var target := Vector2.ONE * size * 1.3 / TEX_SMOKE.get_width()
	cloud.scale = target * 0.3
	add_child(cloud)
	var tween := cloud.create_tween()
	tween.tween_property(cloud, "scale", target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cloud, "position:y", pos.y - size * 0.3, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cloud, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.parallel().tween_property(cloud, "scale", target * 1.2, 0.6).set_delay(0.3)
	tween.tween_callback(cloud.queue_free)

	var puffs := _emitter(TEX_SMOKE, 7, 0.7, pos)
	puffs.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	puffs.emission_sphere_radius = size * 0.2
	puffs.spread = 180.0
	puffs.gravity = Vector2(0, -60)
	puffs.initial_velocity_min = size * 0.8
	puffs.initial_velocity_max = size * 1.4
	puffs.damping_min = size * 1.5
	puffs.damping_max = size * 2.2
	puffs.scale_amount_min = size * 0.25 / TEX_SMOKE.get_width()
	puffs.scale_amount_max = size * 0.4 / TEX_SMOKE.get_width()
	puffs.scale_amount_curve = _shrink
	puffs.color_ramp = _fade(Color(1, 1, 1, 0.9))
	puffs.emitting = true


# Kask kırılınca: üç parça dönerek yana ve yukarı fırlar, sonra düşüp söner.
# xform: kask sprite'ının dünyadaki dönüşümü (parçalar aynı yerden başlar).
func helmet_shards(xform: Transform2D, delay: float = 0.06) -> void:
	var unit := xform.get_scale().x * 2.0   # bir tuval biriminin ekrandaki boyu
	for k in TEX_SHARDS.size():
		var rel := SHARD_CENTERS[k] * Vector2(1.0, 0.86)
		var shard := Sprite2D.new()
		shard.texture = TEX_SHARDS[k]
		shard.offset = -rel * 2.0
		shard.scale = xform.get_scale()
		shard.position = xform * (rel * 2.0)
		shard.visible = false
		add_child(shard)
		var side := signf(rel.x) if absf(rel.x) > 1.0 else randf_range(-0.4, 0.4)
		var start := shard.position
		var peak := start + Vector2(side * 90.0, -130.0 - randf() * 40.0) * unit
		var land := start + Vector2(side * 170.0, 260.0) * unit
		var tween := shard.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(shard.show)
		tween.tween_property(shard, "position", peak, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "position", land, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.3).set_delay(0.2)
		tween.tween_callback(shard.queue_free)
		var spin := shard.create_tween()
		spin.tween_interval(delay)
		spin.tween_property(shard, "rotation", side * 2.5 + randf_range(-1.0, 1.0), 0.78)
	var glints := _emitter(TEX_SPARKLE, 8, 0.4, xform * (Vector2(0, -90) * 2.0))
	glints.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	glints.emission_sphere_radius = 60.0 * unit
	glints.spread = 180.0
	glints.gravity = Vector2.ZERO
	glints.initial_velocity_min = 60.0
	glints.initial_velocity_max = 160.0
	glints.scale_amount_min = 0.2
	glints.scale_amount_max = 0.35
	glints.scale_amount_curve = _shrink
	glints.color_ramp = _fade(Color("fff3a6"))
	glints.emitting = true


func clear() -> void:
	for child in get_children():
		child.queue_free()
	stop_shake()
