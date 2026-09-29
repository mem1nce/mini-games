extends Node2D
# Arabanın görünümü: kabin içi + şoför (cam şekline kırpılı) + direksiyon + gövde + tekerlekler + gölge.
# Hareket bilmez; yarışta araba.gd, ayrıca garaj, harita, podyum ve ilerleme çubuğu kullanır.
# Düğümün (0, 0) noktası iki tekerleğin yere değdiği çizginin ortasıdır. Araba sağa bakar.
# Bütün araba parçaları aynı 360x224 tuvalde çizildi (gorseller/svg_uret.py).

const G := "res://oyunlar/araba_yarisi/gorseller/"
const CANVAS := Vector2(360, 224)
const ORIGIN := Vector2(180, 218)          # tuvalde yere değme çizgisinin ortası
const WHEEL_REAR := Vector2(98, 178)
const WHEEL_FRONT := Vector2(262, 178)
const WHEEL_RADIUS := 40.0
const EXHAUST := Vector2(6, 183)           # egzoz borusunun ucu (tuvalde)
const DRIVER_SEAT := Vector2(182, 76)      # şoförün yüzünün geleceği yer (tuvalde)

# Renk adı -> düğme ve simgelerde kullanılan ana renk (SVG'lerdeki "orta" renk)
const COLORS := {
	"kirmizi": Color("f2545b"),
	"turuncu": Color("ff962e"),
	"sari": Color("ffd23f"),
	"yesil": Color("35c47b"),
	"mavi": Color("3e8eeb"),
	"mor": Color("9b5de5"),
}
const COLOR_NAMES := ["kirmizi", "turuncu", "sari", "yesil", "mavi", "mor"]

# Şoför hayvanlar (hafıza oyunundan kopya, 256x256 tuval).
# face: hayvanın yüz ortası (256'lık tuvalde), size: ölçek, flip: yatay çevir (yüzü öne baksın)
const DRIVERS := [
	{"name": "aslan", "face": Vector2(128, 118), "size": 0.6, "flip": false},
	{"name": "panda", "face": Vector2(128, 124), "size": 0.6, "flip": false},
	{"name": "tavsan", "face": Vector2(128, 132), "size": 0.47, "flip": false},
	{"name": "fil", "face": Vector2(128, 114), "size": 0.56, "flip": false},
	{"name": "penguen", "face": Vector2(128, 120), "size": 0.6, "flip": false},
	{"name": "baykus", "face": Vector2(128, 114), "size": 0.6, "flip": false},
	{"name": "zurafa", "face": Vector2(128, 122), "size": 0.58, "flip": false},
	{"name": "kaplumbaga", "face": Vector2(68, 116), "size": 0.72, "flip": true},
]

# Yaylanma: gövde bir yay-sönümleyiciyle tekerleklere bağlı
const SPRING := 260.0
const DAMPING := 13.0
const TILT_SPRING := 120.0
const TILT_DAMPING := 11.0

var color_name: String = "kirmizi"
var driver_index: int = 0

var _body_root: Node2D
var _interior: Sprite2D
var _driver: Sprite2D
var _body: Sprite2D
var _wheels: Array[Sprite2D] = []
var _shadow: Sprite2D
var _offset := 0.0          # gövdenin dikey yay sapması (px, + aşağı)
var _offset_vel := 0.0
var _tilt := 0.0            # gövdenin ek eğimi (radyan, + burun aşağı)
var _tilt_vel := 0.0
var _tilt_target := 0.0
var _driver_lag := 0.0      # şoförün başı gövdeden biraz geç gelir
var _wheel_drop := 0.0      # havadayken tekerlekler biraz sarkar
var _hop := 0.0             # neşeli zıplamanın yüksekliği (ekran px)
var _hop_tween: Tween


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_shadow = Sprite2D.new()
	_shadow.texture = load(G + "golge.svg")
	_shadow.scale = Vector2.ONE * 300.0 / _shadow.texture.get_width()
	_shadow.position = Vector2(0, -2)
	add_child(_shadow)

	_body_root = Node2D.new()
	add_child(_body_root)
	var center := CANVAS / 2.0 - ORIGIN     # tuval ortasının düğümdeki yeri
	_interior = _canvas_sprite("araba_ic.svg", center)
	_interior.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_body_root.add_child(_interior)
	_driver = Sprite2D.new()
	_interior.add_child(_driver)
	_interior.add_child(_canvas_sprite("direksiyon.svg", Vector2.ZERO))
	_body = _canvas_sprite("araba_kirmizi.svg", center)
	_body_root.add_child(_body)

	for p in [WHEEL_REAR, WHEEL_FRONT]:
		var wheel := Sprite2D.new()
		wheel.texture = load(G + "teker.svg")
		wheel.scale = Vector2.ONE * 88.0 / wheel.texture.get_width()
		wheel.position = p - ORIGIN
		add_child(wheel)
		_wheels.append(wheel)
	set_color(color_name)
	set_driver(driver_index)


# Tuvalle aynı boyda çizilen bir parça (SVG 2x içe aktarıldığı için ölçek dokudan hesaplanır)
func _canvas_sprite(file: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + file)
	sprite.scale = Vector2.ONE * CANVAS.x / sprite.texture.get_width()
	sprite.position = pos
	return sprite


func set_color(color: String) -> void:
	color_name = color if COLORS.has(color) else "kirmizi"
	_body.texture = load(G + "araba_%s.svg" % color_name)


func set_driver(index: int) -> void:
	driver_index = clampi(index, 0, DRIVERS.size() - 1)
	var info: Dictionary = DRIVERS[driver_index]
	var tex: Texture2D = load(G + "hayvanlar/%s.svg" % info["name"])
	_driver.texture = tex
	_driver.flip_h = info["flip"]
	var unit := 256.0 / tex.get_width()             # dokunun 1 pikseli, 256'lık tuvalde kaç birim
	# Kabin içi sprite'ı tuval ölçeğinde; şoför onun çocuğu olduğu için tuval birimleriyle çalışırız
	var size: float = info["size"]
	var face: Vector2 = info["face"]
	if info["flip"]:
		face.x = 256.0 - face.x
	var inv := 1.0 / _interior.scale.x
	_driver.scale = Vector2.ONE * size * unit * inv
	# Yüz ortası DRIVER_SEAT'e gelsin: sprite ortası = koltuk - (yüz - 128) * ölçek
	var seat_local := (DRIVER_SEAT - CANVAS / 2.0) * inv
	_driver.position = seat_local - (face - Vector2(128, 128)) * size * inv
	_driver.set_meta("base", _driver.position)
	_driver.set_meta("scale", _driver.scale)


# Yeni şoför koltuğa zıplayarak oturur
func driver_pop() -> void:
	var full: Vector2 = _driver.get_meta("scale")
	_driver.scale = full * 0.3
	var tween := _driver.create_tween()
	tween.tween_property(_driver, "scale", full, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func driver_name(index: int) -> String:
	return DRIVERS[clampi(index, 0, DRIVERS.size() - 1)]["name"]


# --- Hareket geri bildirimi (araba.gd çağırır) ---

# Tekerlekleri gidilen yol kadar döndürür
func spin_wheels(distance: float) -> void:
	for wheel in _wheels:
		wheel.rotation += distance / WHEEL_RADIUS


# Gövdeye ani bir itiş (+ aşağı): iniş, kasis, zıplama
func bump(velocity: float) -> void:
	_offset_vel += velocity


# Hızlanma/yavaşlama eğimi: + burun aşağı (fren), - burun yukarı (gaz)
func set_lean(amount: float) -> void:
	_tilt_target = amount


func kick_tilt(velocity: float) -> void:
	_tilt_vel += velocity


# Havadayken tekerlekler biraz sarkar (0..1)
func set_airborne(amount: float) -> void:
	_wheel_drop = amount


# Havadayken gölge yerde kalır; araba yükseldikçe küçülüp soluklaşır (amount 1 = yerde)
func place_shadow(world_point: Vector2, amount: float) -> void:
	_shadow.global_position = world_point
	_shadow.global_rotation = 0.0
	_shadow.modulate.a = amount
	_shadow.scale = Vector2.ONE * 300.0 / _shadow.texture.get_width() * lerpf(0.5, 1.0, amount)


func reset_shadow() -> void:
	_shadow.position = Vector2(0, -2)
	_shadow.rotation = 0.0
	_shadow.modulate.a = 1.0
	_shadow.scale = Vector2.ONE * 300.0 / _shadow.texture.get_width()


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	# Dikey yay
	var force := -SPRING * _offset - DAMPING * _offset_vel
	_offset_vel += force * dt
	_offset += _offset_vel * dt
	_offset = clampf(_offset, -26.0, 20.0)
	# Eğim yayı
	var tilt_force := -TILT_SPRING * (_tilt - _tilt_target) - TILT_DAMPING * _tilt_vel
	_tilt_vel += tilt_force * dt
	_tilt += _tilt_vel * dt
	_tilt = clampf(_tilt, -0.14, 0.14)
	var hop := _hop / maxf(scale.y, 0.01)
	_body_root.position = Vector2(0, _offset - _wheel_drop * 6.0 - hop)
	# Arka tekerlek etrafında dön: burun eğilir, arka yerinde kalır
	var pivot := WHEEL_REAR - ORIGIN
	_body_root.rotation = _tilt
	_body_root.position += pivot - pivot.rotated(_tilt)
	for wheel in _wheels:
		wheel.position.y = WHEEL_REAR.y - ORIGIN.y + _wheel_drop * 8.0 - hop
	# Şoför gövdeyi biraz geriden izler (başı hafifçe sallanır)
	_driver_lag = lerpf(_driver_lag, -_offset_vel * 0.02, 1.0 - exp(-10.0 * dt))
	var base: Vector2 = _driver.get_meta("base", _driver.position)
	_driver.position = base + Vector2(0, clampf(_driver_lag, -6.0, 6.0) / _interior.scale.x)


# Egzozun düğümdeki yeri (duman parçacıkları için)
func exhaust_position() -> Vector2:
	return _body_root.transform * (EXHAUST - ORIGIN)


# Podyumda ve garajda: neşeli zıplama (gövde ve tekerlekler kalkar, gölge yerde küçülür)
func happy_hop(height: float = 40.0, time: float = 0.42) -> void:
	if _hop_tween and _hop_tween.is_running():
		return
	_hop_tween = create_tween()
	_hop_tween.tween_method(_set_hop, 0.0, height, time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_method(_set_hop, height, 0.0, time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_hop_tween.tween_callback(bump.bind(260.0))


func _set_hop(value: float) -> void:
	_hop = value
	var base := 300.0 / _shadow.texture.get_width()
	_shadow.scale = Vector2.ONE * base * (1.0 - clampf(value / 120.0, 0.0, 0.4))
