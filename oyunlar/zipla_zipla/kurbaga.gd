extends Node2D
# Player: kurbağa. Düğümün konumu ayaklarının bastığı noktadır.
# Konma kararını oyun verir (zıplama anında, deterministik); kurbağa sadece hareketi ve görünüşü yapar:
# - IDLE: basamağın üstünde, basamakla birlikte kayar; nefes alır, ara sıra göz kırpar.
# - JUMP: parabol (tepe süresi ve yüksekliğinden g ve ilk hız hesaplanır). Konacaksa x hedef basamağı
#   izler ve iniş anında `landed`; ıskalayacaksa kendi basamağıyla birlikte yükselip ona geri konar
#   (`returned`). Kendi basamağı bu arada ufalandıysa düşmeye geçer (`missed`).
# - FALL: sarmal gözler, dışarıda dil, havada bacaklar, yavaşça takla atarak aşağı düşer.

signal landed(platform: Node2D)
signal returned(platform: Node2D)
signal missed

enum Mode { IDLE, JUMP, FALL }

const G := "res://oyunlar/zipla_zipla/gorseller/"
const TEX_BODY: Texture2D = preload(G + "kurbaga_govde.svg")
const TEX_LEG: Texture2D = preload(G + "kurbaga_bacak.svg")
const TEX_LEG_LONG: Texture2D = preload(G + "kurbaga_bacak_uzun.svg")
const FACES := {
	"normal": preload(G + "kurbaga_yuz_normal.svg"),
	"kirp": preload(G + "kurbaga_yuz_kirp.svg"),
	"zipla": preload(G + "kurbaga_yuz_zipla.svg"),
	"sersem": preload(G + "kurbaga_yuz_sersem.svg"),
}
const UNIT := 0.58            # SVG tuvalinin bir birimi kaç piksel (kurbağa ~110 px genişlik, ~102 px boy)
const FEET := 238.0           # tuvalde ayakların alt kenarı
const CENTER_UP := 64.0       # takla dönüşünün merkezi: ayakların bu kadar üstü

var mode: Mode = Mode.IDLE
var platform: Node2D = null
var offset: float = 0.0       # basamağın merkezine göre yatay konum

var _target: Node2D = null
var _target_offset: float = 0.0
var _returning: bool = false  # ıskalama: kendi basamağına geri konacak
var _t: float = 0.0
var _g: float = 0.0
var _v0: float = 0.0
var _rise: float = 0.0
var _land_time: float = 0.0
var _x0: float = 0.0
var _y0: float = 0.0
var _vy: float = 0.0
var _vx: float = 0.0

var _tumble: Node2D           # takla için gövde merkezinde döner
var _body: Node2D             # ezilip esneme için ayaklardan ölçeklenir
var _legs: Array[Sprite2D] = []
var _face: Sprite2D
var _time: float = 0.0
var _blink_in: float = 2.0
var _blink_left: float = 0.0
var _squash: Tween
var _slide: Tween


func _ready() -> void:
	z_index = 10
	_tumble = Node2D.new()
	_tumble.position = Vector2(0, -CENTER_UP)
	add_child(_tumble)
	_body = Node2D.new()
	_body.position = Vector2(0, CENTER_UP)
	_tumble.add_child(_body)
	for k in 2:
		var leg := _part(TEX_LEG)
		leg.flip_h = k == 1
		_legs.append(leg)
	_part(TEX_BODY)
	_face = _part(FACES["normal"])


func _part(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * 256.0 * UNIT / texture.get_width()
	sprite.position = Vector2(0, (128.0 - FEET) * UNIT)
	_body.add_child(sprite)
	return sprite


# --- Durum geçişleri ---

func place(on: Node2D, at_offset: float) -> void:
	mode = Mode.IDLE
	platform = on
	offset = at_offset
	_target = null
	_tumble.rotation = 0.0
	_body.scale = Vector2.ONE
	_set_pose("sit")
	_follow_platform()


# Zıplamayı başlatır. target null ise ıskalama: kendi basamağıyla birlikte yükselir ve ona geri konar.
# height: iki basamak arası, clearance: tepe noktasının üst basamağın ne kadar üstünde olduğu.
func jump(target: Node2D, target_offset: float, rise_time: float, height: float, clearance: float) -> void:
	if mode != Mode.IDLE:
		return
	mode = Mode.JUMP
	_returning = target == null
	_target = platform if _returning else target
	_target_offset = offset if _returning else target_offset
	var apex := height + clearance
	_rise = rise_time
	_g = 2.0 * apex / (rise_time * rise_time)
	_v0 = _g * rise_time
	# Konarken üst basamağın hizasına, geri dönerken çıkılan yüksekliğe iner
	_land_time = rise_time * 2.0 if _returning else rise_time + sqrt(2.0 * clearance / _g)
	_t = 0.0
	_x0 = position.x
	_y0 = position.y
	platform = null
	if _slide:
		_slide.kill()
	_set_pose("jump")
	_squash_to([Vector2(1.18, 0.8), Vector2(0.82, 1.22), Vector2.ONE], [0.04, 0.1, 0.25])


# Durduğu basamak ufalanınca: olduğu yerden düşer
func drop() -> void:
	if mode != Mode.IDLE:
		return
	platform = null
	_start_fall(0.0)


# Kenara konduysa basamağın içine doğru yumuşakça kay
func slide_to(new_offset: float, seconds: float) -> void:
	if _slide:
		_slide.kill()
	_slide = create_tween()
	_slide.tween_property(self, "offset", new_offset, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func is_airborne() -> bool:
	return mode != Mode.IDLE


# --- Hareket ---

func _process(delta: float) -> void:
	_time += delta
	match mode:
		Mode.IDLE:
			_follow_platform()
			_idle_anim(delta)
		Mode.JUMP:
			_t += delta
			position.y = _y0 - _v0 * _t + 0.5 * _g * _t * _t
			var w := clampf(_t / _land_time, 0.0, 1.0)
			var goal: float = _target.position.x + _target_offset
			position.x = lerpf(_x0, goal, w * w * (3.0 - 2.0 * w))
			if _t >= _land_time:
				if _target.solid:
					_land()
				else:
					# Geri döneceği basamak havadayken ufalandı: aşağı düşmeye devam eder
					_start_fall(-_v0 + _g * _t)
					missed.emit()
		Mode.FALL:
			_vy += _g * 0.55 * delta
			position.y += _vy * delta
			position.x += _vx * delta
			_tumble.rotation += delta * 2.2 * signf(_vx if _vx != 0.0 else 1.0)
			for k in _legs.size():
				_legs[k].rotation = sin(_time * 18.0 + k * PI) * 0.25


func _follow_platform() -> void:
	if platform:
		position = Vector2(platform.position.x + offset, platform.position.y)


func _land() -> void:
	mode = Mode.IDLE
	platform = _target
	offset = _target_offset
	_target = null
	_follow_platform()
	_set_pose("sit")
	_squash_to([Vector2(1.3, 0.72), Vector2(0.9, 1.12), Vector2(1.04, 0.97), Vector2.ONE], [0.07, 0.1, 0.08, 0.08])
	if _returning:
		returned.emit(platform)
	else:
		landed.emit(platform)


func _start_fall(start_vy: float) -> void:
	mode = Mode.FALL
	_vy = start_vy
	if _g <= 0.0:
		_g = 2000.0
	_vx = randf_range(-40.0, 40.0)
	_set_pose("fall")
	_squash_to([Vector2(0.9, 1.1), Vector2.ONE], [0.1, 0.2])


# --- Görünüş ---

func _set_pose(pose: String) -> void:
	match pose:
		"sit":
			_face.texture = FACES["normal"]
			for leg in _legs:
				leg.texture = TEX_LEG
				leg.rotation = 0.0
		"jump":
			_face.texture = FACES["zipla"]
			for leg in _legs:
				leg.texture = TEX_LEG_LONG
				leg.rotation = 0.0
		"fall":
			_face.texture = FACES["sersem"]
			for leg in _legs:
				leg.texture = TEX_LEG_LONG
	_blink_left = 0.0


func _idle_anim(delta: float) -> void:
	# Nefes: gövde çok hafifçe şişip iner (ezilme animasyonu yoksa)
	if _squash == null or not _squash.is_running():
		var breath := sin(_time * 2.6) * 0.025
		_body.scale = Vector2(1.0 - breath * 0.5, 1.0 + breath)
	# Göz kırpma
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_face.texture = FACES["normal"]
		return
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink_in = randf_range(2.0, 4.5)
		_blink_left = 0.13
		_face.texture = FACES["kirp"]


func _squash_to(scales: Array, times: Array) -> void:
	if _squash:
		_squash.kill()
	_squash = create_tween()
	for k in scales.size():
		_squash.tween_property(_body, "scale", scales[k], times[k]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
