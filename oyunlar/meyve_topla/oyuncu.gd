extends Node2D
# Kirpi: parmağı yumuşakça takip eder, yürürken sallanır ve gittiği yöne bakar,
# başındaki hasır sepette yakaladığı meyveleri biriktirir.
# Düğüm konumu ayak tabanının ortasıdır.

const G := "res://oyunlar/meyve_topla/gorseller/"
const TEX_FACES := {
	"hazir": preload("res://oyunlar/meyve_topla/gorseller/kirpi_hazir.svg"),
	"mutlu": preload("res://oyunlar/meyve_topla/gorseller/kirpi_mutlu.svg"),
	"sersem": preload("res://oyunlar/meyve_topla/gorseller/kirpi_sersem.svg"),
}
const TEX_FOOT: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/kirpi_ayak.svg")
const TEX_BASKET_BACK: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/sepet_arka.svg")
const TEX_BASKET_FRONT: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/sepet_on.svg")
const TEX_SHADOW: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/golge.svg")
const TEX_STAR: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/yildiz.svg")
const TEX_DUST: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/toz.svg")
const TEX_SPARKLE: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/isilti.svg")

const BODY_WIDTH := 190.0
const BODY_Y := -90.0          # gövde merkezinin ayak tabanına göre yüksekliği
const BASKET_WIDTH := 200.0
const BASKET_Y := -200.0       # sepet merkezinin yüksekliği (dikenlerin üstünde durur)
const RIM_Y := -25.0           # sepet merkezine göre ağız çizgisi
const CATCH_HALF_WIDTH := 92.0
const FRUIT_SIZE := 54.0
const STACK_MAX := 10
# Sepetteki meyvelerin yerleri (alttan üste); fazlası gelince en alttaki kaybolur
const SLOTS := [
	Vector2(-54, -2), Vector2(-18, -2), Vector2(18, -2), Vector2(54, -2),
	Vector2(-36, -28), Vector2(0, -28), Vector2(36, -28),
	Vector2(-18, -52), Vector2(18, -52), Vector2(0, -74),
]

var follow_sharpness: float = 9.0
var max_speed: float = 1300.0
var target_x: float = 360.0
var min_x: float = 100.0
var max_x: float = 620.0
var velocity_x: float = 0.0
var width_scale: float = 1.0    # büyük sepet güçlendirmesinde büyür

var _facing := 1
var _walk := 0.0                # yürüme döngüsü
var _walk_amount := 0.0         # 0 = duruyor, 1 = hızlı yürüyor
var _hop := 0.0                 # dans sırasında zıplama yüksekliği
var _face_left := 0.0
var _dizzy_left := 0.0
var _time := 0.0
var _stack: Array[Sprite2D] = []
var _dizzy_stars: Array[Sprite2D] = []

var _shadow: Sprite2D
var _shadow_scale := Vector2.ONE
var _body_pivot: Node2D
var _body: Sprite2D
var _body_scale := Vector2.ONE
var _foot_back: Sprite2D
var _foot_front: Sprite2D
var _basket: Node2D
var _basket_back: Sprite2D
var _basket_front: Sprite2D
var _basket_scale := Vector2.ONE
var _stack_node: Node2D
var _power_icon: Sprite2D
var _dust: CPUParticles2D
var _magnet: CPUParticles2D
var _turn_tween: Tween
var _big_tween: Tween


func _ready() -> void:
	_shadow = _sprite(TEX_SHADOW, 170.0)
	_shadow_scale = _shadow.scale
	_shadow.modulate.a = 0.7
	add_child(_shadow)

	_dust = _make_dust()
	add_child(_dust)

	_body_pivot = Node2D.new()
	add_child(_body_pivot)
	_foot_back = _sprite(TEX_FOOT, 50.0)
	_foot_back.position = Vector2(-34, -12)
	_body_pivot.add_child(_foot_back)
	_body = _sprite(TEX_FACES["hazir"], BODY_WIDTH)
	_body.position = Vector2(0, BODY_Y)
	_body_scale = _body.scale
	_body_pivot.add_child(_body)
	_foot_front = _sprite(TEX_FOOT, 50.0)
	_foot_front.position = Vector2(24, -10)
	_body_pivot.add_child(_foot_front)

	_basket = Node2D.new()
	_basket.position = Vector2(0, BASKET_Y)
	add_child(_basket)
	_basket_back = _sprite(TEX_BASKET_BACK, BASKET_WIDTH)
	_basket_scale = _basket_back.scale
	_basket.add_child(_basket_back)
	_stack_node = Node2D.new()
	_basket.add_child(_stack_node)
	_basket_front = _sprite(TEX_BASKET_FRONT, BASKET_WIDTH)
	_basket.add_child(_basket_front)

	_magnet = _make_magnet_sparkles()
	_basket.add_child(_magnet)

	_power_icon = Sprite2D.new()
	_power_icon.visible = false
	add_child(_power_icon)


func _sprite(texture: Texture2D, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * width / texture.get_width()
	return sprite


func _process(delta: float) -> void:
	_time += delta

	# Parmağı yumuşakça takip et (üstel yumuşatma + azami hız)
	var desired := clampf(target_x, min_x, max_x)
	var smoothed := lerpf(position.x, desired, 1.0 - exp(-follow_sharpness * delta))
	var step := clampf(smoothed - position.x, -max_speed * delta, max_speed * delta)
	position.x += step
	velocity_x = step / maxf(delta, 0.0001)

	# Yürüme: hıza göre sallanma, zıplama ve ayak kaldırma
	var target_amount := clampf(absf(velocity_x) / 450.0, 0.0, 1.0)
	_walk_amount = lerpf(_walk_amount, target_amount, 1.0 - exp(-10.0 * delta))
	_walk += delta * (4.0 + 12.0 * _walk_amount)
	var bob := -absf(sin(_walk)) * 8.0 * _walk_amount
	_body_pivot.position.y = bob + _hop
	_body_pivot.rotation = sin(_walk) * 0.07 * _walk_amount
	_foot_back.position.y = -12.0 - maxf(0.0, sin(_walk)) * 10.0 * _walk_amount
	_foot_front.position.y = -10.0 - maxf(0.0, -sin(_walk)) * 10.0 * _walk_amount
	# Dururken hafifçe nefes alır
	var breath := sin(_time * 2.4) * 0.018 * (1.0 - _walk_amount)
	_body.scale.y = _body_scale.y * (1.0 + breath) if not _squashing() else _body.scale.y

	# Gittiği yöne dönsün
	if velocity_x > 60.0 and _facing != 1:
		_turn(1)
	elif velocity_x < -60.0 and _facing != -1:
		_turn(-1)

	# Sepet başın üstünde; yürürken hareket yönünün tersine hafifçe eğilir
	_basket.position.y = BASKET_Y + bob * 0.9 + _hop
	var tilt := clampf(-velocity_x * 0.00011, -0.12, 0.12) + sin(_walk * 0.5) * 0.03 * _walk_amount
	_basket.rotation = lerpf(_basket.rotation, tilt, 1.0 - exp(-8.0 * delta))
	_basket_back.scale.x = _basket_scale.x * width_scale
	_basket_front.scale.x = _basket_scale.x * width_scale
	_magnet.emission_rect_extents.x = 80.0 * width_scale

	_shadow.scale = _shadow_scale * (1.0 + _hop / 260.0) * Vector2(width_scale * 0.3 + 0.7, 1.0)
	_dust.emitting = _walk_amount > 0.55 and _hop > -5.0

	_update_stack(delta)
	_update_face(delta)
	_update_dizzy_stars(delta)
	if _power_icon.visible:
		_power_icon.position = Vector2(0, BASKET_Y - 150.0 + sin(_time * 4.0) * 6.0 + _hop)


func _squashing() -> bool:
	return _body.has_meta("squash")


func _turn(direction: int) -> void:
	_facing = direction
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	# Ölçek 0'dan geçerken kirpi dönüyormuş gibi görünür
	_turn_tween = create_tween()
	_turn_tween.tween_property(_body_pivot, "scale:x", float(direction), 0.16).set_trans(Tween.TRANS_SINE)


# --- Sepet ---

func catch_line_y() -> float:
	return position.y + _basket.position.y + RIM_Y


func catch_half_width() -> float:
	return CATCH_HALF_WIDTH * width_scale


func basket_position() -> Vector2:
	return position + _basket.position + Vector2(0, RIM_Y)


# Yakalanan meyve bulunduğu yerden sepetteki yerine süzülür; sepet esneyip zıplar
func add_fruit(texture: Texture2D, from_position: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * FRUIT_SIZE / texture.get_width()
	sprite.rotation = randf_range(-0.35, 0.35)
	_stack_node.add_child(sprite)
	sprite.position = _stack_node.to_local(get_parent().to_global(from_position))
	if _stack.size() >= STACK_MAX:
		var oldest: Sprite2D = _stack.pop_front()
		var fade := oldest.create_tween().set_parallel()
		fade.tween_property(oldest, "scale", Vector2.ZERO, 0.25)
		fade.tween_property(oldest, "modulate:a", 0.0, 0.25)
		fade.chain().tween_callback(oldest.queue_free)
	_stack.append(sprite)
	_squash_basket(1.0)
	set_face("mutlu", 0.35)


func clear_stack() -> void:
	for sprite in _stack:
		sprite.queue_free()
	_stack.clear()


func _slot_position(index: int) -> Vector2:
	var slot: Vector2 = SLOTS[index]
	return Vector2(slot.x * width_scale, RIM_Y + slot.y)


func _update_stack(delta: float) -> void:
	var k := 1.0 - exp(-16.0 * delta)
	for i in _stack.size():
		_stack[i].position = _stack[i].position.lerp(_slot_position(i), k)


func _squash_basket(strength: float) -> void:
	var tween := _basket.create_tween()
	tween.tween_property(_basket, "scale", Vector2(1.0 + 0.18 * strength, 1.0 - 0.2 * strength), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_basket, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Gövde de hafifçe ezilir
	_body.set_meta("squash", true)
	var body_tween := _body.create_tween()
	body_tween.tween_property(_body, "scale", _body_scale * Vector2(1.06, 0.93), 0.07)
	body_tween.tween_property(_body, "scale", _body_scale, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	body_tween.tween_callback(_body.remove_meta.bind("squash"))


# Hedef olmayan meyve sepetten sekince küçük bir tepki
func bump() -> void:
	_squash_basket(0.5)


# --- Güçlendirmeler ---

func set_big(on: bool, big_scale: float = 1.6) -> void:
	if _big_tween and _big_tween.is_valid():
		_big_tween.kill()
	_big_tween = create_tween()
	_big_tween.tween_property(self, "width_scale", big_scale if on else 1.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_magnet(on: bool) -> void:
	_magnet.emitting = on


func set_power_icon(texture: Texture2D) -> void:
	if texture == null:
		if _power_icon.visible:
			var tween := _power_icon.create_tween()
			tween.tween_property(_power_icon, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(_power_icon.hide)
		return
	_power_icon.texture = texture
	_power_icon.visible = true
	var size := Vector2.ONE * 64.0 / texture.get_width()
	_power_icon.scale = Vector2.ZERO
	_power_icon.create_tween().tween_property(_power_icon, "scale", size, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Yüz ifadeleri ve tepkiler ---

func set_face(face: String, duration: float = 0.0) -> void:
	if _dizzy_left > 0.0 and face != "sersem":
		return  # sersemken önce kendine gelsin
	_body.texture = TEX_FACES[face]
	_face_left = duration


func _update_face(delta: float) -> void:
	if _face_left > 0.0:
		_face_left -= delta
		if _face_left <= 0.0:
			_body.texture = TEX_FACES["hazir"]


# Kötü nesne yakalanınca: sarmal gözler, başını sallar, başının üstünde yıldızlar döner
func dizzy(duration: float = 1.4) -> void:
	_dizzy_left = duration
	set_face("sersem", duration)
	var tween := _body.create_tween()
	for angle in [0.2, -0.2, 0.15, -0.12, 0.08, 0.0]:
		tween.tween_property(_body, "rotation", angle, 0.09).set_trans(Tween.TRANS_SINE)
	_squash_basket(0.8)
	if _dizzy_stars.is_empty():
		for i in 3:
			var star := _sprite(TEX_STAR, 30.0)
			add_child(star)
			_dizzy_stars.append(star)
	for star in _dizzy_stars:
		star.visible = true
		star.modulate.a = 1.0


func _update_dizzy_stars(delta: float) -> void:
	if _dizzy_stars.is_empty():
		return
	if _dizzy_left > 0.0:
		_dizzy_left -= delta
	var alpha := clampf(_dizzy_left / 0.3, 0.0, 1.0)
	for i in _dizzy_stars.size():
		var star := _dizzy_stars[i]
		var angle := _time * 5.0 + i * TAU / _dizzy_stars.size()
		# Başın üstünde elips çizerek döner (sepetin altında, yüzün hizasında)
		star.position = Vector2(cos(angle) * 70.0, BODY_Y - 40.0 + sin(angle) * 16.0 + _hop)
		star.rotation = _time * 4.0
		star.modulate.a = alpha
		star.visible = alpha > 0.0
		star.z_index = 1 if sin(angle) > 0.0 else 0


# Bölüm sonu sevinç dansı: zıplar, döner, sepeti sallanır
func dance(duration: float = 2.0) -> void:
	_dizzy_left = 0.0
	set_face("mutlu", duration)
	var tween := create_tween()
	var hops := 4
	var hop_time := duration / hops
	for i in hops:
		tween.tween_property(self, "_hop", -70.0, hop_time * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_turn.bind(-_facing if i % 2 == 0 else _facing))
		tween.tween_property(self, "_hop", 0.0, hop_time * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var wiggle := _basket.create_tween()
	for i in hops * 2:
		wiggle.tween_property(_basket, "rotation", 0.15 if i % 2 == 0 else -0.15, hop_time * 0.5).set_trans(Tween.TRANS_SINE)
	wiggle.tween_property(_basket, "rotation", 0.0, 0.2)


# --- Parçacıklar ---

func _make_dust() -> CPUParticles2D:
	var dust := CPUParticles2D.new()
	dust.texture = TEX_DUST
	dust.amount = 10
	dust.lifetime = 0.5
	dust.emitting = false
	dust.position = Vector2(0, -6)
	dust.local_coords = false
	dust.direction = Vector2(0, -1)
	dust.spread = 60.0
	dust.initial_velocity_min = 20.0
	dust.initial_velocity_max = 60.0
	dust.gravity = Vector2(0, -20)
	dust.scale_amount_min = 0.25
	dust.scale_amount_max = 0.45
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.97, 0.9, 0.55))
	fade.set_color(1, Color(1.0, 0.97, 0.9, 0.0))
	dust.color_ramp = fade
	return dust


func _make_magnet_sparkles() -> CPUParticles2D:
	var sparkles := CPUParticles2D.new()
	sparkles.texture = TEX_SPARKLE
	sparkles.amount = 14
	sparkles.lifetime = 0.9
	sparkles.emitting = false
	sparkles.position = Vector2(0, RIM_Y - 10.0)
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkles.emission_rect_extents = Vector2(80, 6)
	sparkles.direction = Vector2(0, -1)
	sparkles.spread = 20.0
	sparkles.initial_velocity_min = 60.0
	sparkles.initial_velocity_max = 140.0
	sparkles.gravity = Vector2.ZERO
	sparkles.angular_velocity_min = -180.0
	sparkles.angular_velocity_max = 180.0
	sparkles.scale_amount_min = 0.12
	sparkles.scale_amount_max = 0.25
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	fade.set_color(1, Color(1.0, 0.8, 0.9, 0.0))
	sparkles.color_ramp = fade
	return sparkles
