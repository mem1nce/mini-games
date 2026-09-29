extends Node2D
# Platform: sağa-sola kayan basamak. Düğümün konumu basamağın üst yüzeyinin ortasıdır (kurbağa burada durur).
# Görsel, basamak SVG'sinin parçalarından kurulur: sol köşe + n orta parça + sağ köşe (`region_rect`).
# Orta parça 60 birim periyotlu çizildiği için genişlik 160 + 60k olunca süsleme hiç bozulmaz.
# Üzerinde durulunca süre başlar: son `warn` saniyede titrer ve solar, süre bitince parçalar
# ayrı ayrı dönerek düşer (ufalanma). Basamak havuzda tekrar kullanılır (setup her şeyi sıfırlar).

signal warning_started(platform: Node2D)
signal crumbled(platform: Node2D)

const G := "res://oyunlar/zipla_zipla/gorseller/"
const TEXTURES := {
	"cim": preload(G + "basamak_cim.svg"),
	"kek": preload(G + "basamak_kek.svg"),
	"seker": preload(G + "basamak_seker.svg"),
	"buz": preload(G + "basamak_buz.svg"),
}
const KINDS := ["cim", "kek", "seker", "buz"]
const CAP := 50.0             # köşe parçasının genişliği (birim = px)
const TILE := 60.0            # döşenen orta parçanın genişliği
const MIN_WIDTH := CAP * 2.0 + TILE
const SURFACE := 20.0         # tuvalde görünen üst kenar
const HEIGHT := 100.0
const TEX_SCALE := 2.0        # SVG'ler 2x içe aktarıldı
const FADED := Color(0.78, 0.8, 0.9, 0.55)

var index: int = 0
var kind: String = "cim"
var width: float = MIN_WIDTH
var fixed: bool = false       # başlangıç basamağı: hareket etmez, kaybolmaz
var frozen: bool = false      # oyun başlamadan önce ilk basamak kurbağanın üstünde bekler
var solid: bool = true        # ufalanınca false
var speed: float = 0.0        # işaretli yatay hız (px/sn)
var center_x: float = 0.0
var travel: float = 0.0       # merkezden en fazla kayma
var reward: Node2D            # Collectible

var _visual: Node2D
var _segments: Array[Sprite2D] = []
var _timer: float = -1.0      # < 0: süre işlemiyor
var _warn: float = 0.0
var _warned: bool = false
var _shake_time: float = 0.0
var _tweens: Array[Tween] = []


func _init() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	reward = preload("res://oyunlar/zipla_zipla/odul.gd").new()
	add_child(reward)


# Genişliği görselin bozulmadan çizilebildiği en yakın değere yuvarlar (160, 220, 280...)
static func snap_width(value: float) -> float:
	return MIN_WIDTH + TILE * maxf(0.0, roundf((value - MIN_WIDTH) / TILE))


func setup(step: int, platform_kind: String, platform_width: float, platform_speed: float,
		column_x: float, max_travel: float, start_x: float, is_fixed: bool) -> void:
	for tween in _tweens:
		tween.kill()
	_tweens.clear()
	index = step
	kind = platform_kind
	width = snap_width(platform_width)
	speed = platform_speed
	center_x = column_x
	travel = maxf(0.0, max_travel)
	fixed = is_fixed
	solid = true
	frozen = false
	_timer = -1.0
	_warned = false
	_shake_time = 0.0
	position.x = clampf(start_x, center_x - travel, center_x + travel)
	_visual.position = Vector2.ZERO
	_visual.rotation = 0.0
	_visual.modulate = Color.WHITE
	_build_segments()
	reward.setup(null)
	show()


func _build_segments() -> void:
	var texture: Texture2D = TEXTURES[kind]
	var middle := int(roundf((width - MIN_WIDTH) / TILE)) + 1
	var count := middle + 2
	while _segments.size() < count:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.region_enabled = true
		sprite.scale = Vector2.ONE / TEX_SCALE
		_visual.add_child(sprite)
		_segments.append(sprite)
	var x := -width / 2.0
	for k in _segments.size():
		var sprite := _segments[k]
		sprite.visible = k < count
		if not sprite.visible:
			continue
		sprite.texture = texture
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE
		var from := 0.0
		var span := CAP
		if k == count - 1:
			from = CAP + TILE
		elif k > 0:
			from = CAP
			span = TILE
		sprite.region_rect = Rect2(from * TEX_SCALE, 0.0, span * TEX_SCALE, HEIGHT * TEX_SCALE)
		sprite.position = Vector2(x, -SURFACE)
		x += span


func left() -> float:
	return position.x - width / 2.0


func right() -> float:
	return position.x + width / 2.0


# Genişliği `player_width` olan, merkezi `x` noktasındaki kurbağa ile yatay çakışma (px)
func overlap(x: float, player_width: float) -> float:
	if not solid:
		return 0.0
	return maxf(0.0, minf(right(), x + player_width / 2.0) - maxf(left(), x - player_width / 2.0))


# Deterministik konma kuralı: çakışma kurbağa genişliğinin `ratio` katından azsa konamaz
func can_land(x: float, player_width: float, ratio: float) -> bool:
	return overlap(x, player_width) >= player_width * ratio - 0.001


# Kurbağa konunca: ofseti basamağın içine doğru kaydırılmış hâli (kenara konduysa)
func settle_offset(offset: float, player_width: float, slide: float) -> float:
	var limit := maxf(0.0, width / 2.0 - player_width / 2.0)
	if absf(offset) <= limit:
		return offset
	return signf(offset) * lerpf(absf(offset), limit, slide)


func velocity() -> float:
	return 0.0 if fixed or frozen or not solid else speed


func start_timer(seconds: float, warn: float) -> void:
	if fixed:
		return
	_timer = seconds
	_warn = warn


func time_left() -> float:
	return _timer


func _process(delta: float) -> void:
	if not solid:
		return
	if not fixed and not frozen and travel > 0.0:
		position.x += speed * delta
		# Kenara varınca yön değiştir (taşan kısmı geri yansıt)
		if position.x > center_x + travel:
			position.x = 2.0 * (center_x + travel) - position.x
			speed = -absf(speed)
		elif position.x < center_x - travel:
			position.x = 2.0 * (center_x - travel) - position.x
			speed = absf(speed)
	if _timer < 0.0:
		return
	_timer -= delta
	if _timer <= _warn:
		if not _warned:
			_warned = true
			warning_started.emit(self)
		# Titreme giderek sertleşir, renk solar
		_shake_time += delta
		var k := 1.0 - clampf(_timer / maxf(_warn, 0.01), 0.0, 1.0)
		_visual.position = Vector2(sin(_shake_time * 55.0) * (2.0 + 4.0 * k), cos(_shake_time * 47.0) * 1.5 * k)
		_visual.rotation = sin(_shake_time * 38.0) * 0.02 * k
		_visual.modulate = Color.WHITE.lerp(FADED, k)
	if _timer <= 0.0:
		crumble()


# Ufalanma: parçalar ayrı ayrı dönerek düşer ve kaybolur; basamak artık konulamaz
func crumble() -> void:
	if not solid:
		return
	solid = false
	_timer = -1.0
	reward.setup(null)
	_visual.position = Vector2.ZERO
	_visual.rotation = 0.0
	for sprite in _segments:
		if not sprite.visible:
			continue
		var center := sprite.position.x + sprite.region_rect.size.x / TEX_SCALE / 2.0
		var drift := signf(center) * randf_range(20.0, 70.0) + randf_range(-20.0, 20.0)
		var tween := sprite.create_tween().set_parallel()
		tween.tween_property(sprite, "position", sprite.position + Vector2(drift, randf_range(260.0, 360.0)), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(randf_range(0.0, 0.08))
		tween.tween_property(sprite, "rotation", randf_range(-1.2, 1.2), 0.75)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3).set_delay(0.45)
		_tweens.append(tween)
	crumbled.emit(self)
