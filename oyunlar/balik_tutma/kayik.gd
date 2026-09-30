extends Node2D
# Kayık: içinde oltalı penguen, kova (görev balıkları) ve geri dönüşüm kutusu (çöpler). Dalgada hafifçe
# sallanır, parmağın yatay konumuna doğru yavaşça kayar; parmak kayığın öbür yanına geçerse penguen o yana döner.
# Penguenin halleri: oltalı (normal), mutlu, şaşkın; kutlamada sevinç dansı.

const G := "res://oyunlar/balik_tutma/gorseller/"
const GENISLIK := 300.0
const PENGUEN_BOY := 150.0
const OLTA_BOY := 236.0
const OLTA_ACI := -0.46
const HIZ := 150.0

var yuzey_y := 400.0
var hedef_x := 360.0
var yon := 1.0                   # 1: olta sağa, -1: sola
var sinir := Vector2(150, 570)

var _govde: Node2D              # yön değişince aynalanan kısım
var _penguen: Sprite2D
var _olta: Sprite2D
var _kova: Sprite2D
var _kutu: Sprite2D
var _dokular := {}
var _zaman := 0.0
var _hal_suresi := 0.0
var _dans := false


func kur(ekran: Vector2, p_yuzey: float) -> void:
	yuzey_y = p_yuzey
	sinir = Vector2(150.0, ekran.x - 150.0)
	position = Vector2(ekran.x * 0.4, yuzey_y)
	hedef_x = position.x
	for hal in ["olta", "mutlu", "saskin"]:
		_dokular[hal] = load(G + "penguen_%s.svg" % hal)
	_govde = Node2D.new()
	add_child(_govde)
	var k := GENISLIK / 320.0
	# Kayık tuvali 320x140, su çizgisi tuvalin y=95'inde (düğümün kökü su çizgisi)
	_sprite(_govde, "kayik_arka.svg", GENISLIK, Vector2(0, (70.0 - 95.0) * k))
	_kova = _sprite(_govde, "kova.svg", 70.0, Vector2(-104.0, -52.0))
	_penguen = Sprite2D.new()
	_penguen.texture = _dokular["olta"]
	_penguen.scale = Vector2.ONE * PENGUEN_BOY / _penguen.texture.get_width()
	_penguen.position = Vector2(-20.0, -70.0)
	_govde.add_child(_penguen)
	_olta = Sprite2D.new()
	_olta.texture = load(G + "olta.svg")
	_olta.scale = Vector2.ONE * OLTA_BOY / _olta.texture.get_width()
	_olta.centered = false
	_olta.offset = Vector2(-10.0, -18.0) * _olta.texture.get_width() / 260.0
	_olta.position = _penguen.position + Vector2(98.0, 46.0) * PENGUEN_BOY / 256.0
	_olta.rotation = OLTA_ACI
	_govde.add_child(_olta)
	_kutu = _sprite(_govde, "geri_donusum.svg", 64.0, Vector2(96.0, -50.0))
	_sprite(_govde, "kayik_on.svg", GENISLIK, Vector2(0, (70.0 - 95.0) * k))


func _sprite(ebeveyn: Node2D, dosya: String, genislik: float, yer: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(G + dosya)
	s.scale = Vector2.ONE * genislik / s.texture.get_width()
	s.position = yer
	ebeveyn.add_child(s)
	return s


# Oltanın ucu (ip buradan sarkar)
func olta_ucu() -> Vector2:
	return _olta.to_global(Vector2(256.0, 18.0) * _olta.texture.get_width() / 260.0 + _olta.offset)


func kova_konumu() -> Vector2:
	return _kova.global_position + Vector2(0, -16)


func kutu_konumu() -> Vector2:
	return _kutu.global_position + Vector2(0, -20)


# Parmak x'ine göre kayığın hedefi: oltanın ucu parmağın üstüne gelsin
func parmagi_izle(x: float) -> void:
	if x < position.x - 70.0 and yon > 0.0:
		_don(-1.0)
	elif x > position.x + 70.0 and yon < 0.0:
		_don(1.0)
	var uzanma := olta_ucu().x - position.x
	hedef_x = clampf(x - uzanma, sinir.x, sinir.y)


func _don(yeni: float) -> void:
	yon = yeni
	var tween := _govde.create_tween()
	tween.tween_property(_govde, "scale:x", yon, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hal(ad: String, sure: float = 1.2) -> void:
	_penguen.texture = _dokular[ad]
	_hal_suresi = sure


func kova_zipla() -> void:
	_zipla(_kova)


func kutu_zipla() -> void:
	_zipla(_kutu)


func _zipla(s: Sprite2D) -> void:
	var olcek := s.scale
	var tween := s.create_tween()
	tween.tween_property(s, "scale", olcek * Vector2(1.18, 0.86), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(s, "scale", olcek, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Kutlama: penguen zıplar, döner, kanat çırpar
func dans(sure: float = 2.4) -> void:
	_dans = true
	hal("mutlu", sure)
	var y := _penguen.position.y
	var tween := _penguen.create_tween()
	for i in 3:
		tween.tween_property(_penguen, "position:y", y - 34.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(_penguen, "rotation", 0.25 if i % 2 == 0 else -0.25, 0.2)
		tween.tween_property(_penguen, "position:y", y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_penguen, "rotation", TAU, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_penguen.rotation = 0.0
		_dans = false)


func _process(delta: float) -> void:
	_zaman += delta
	position.x = move_toward(position.x, hedef_x, HIZ * delta)
	position.y = yuzey_y + sin(_zaman * 1.6) * 4.0
	rotation = sin(_zaman * 1.2) * 0.03
	if _hal_suresi > 0.0:
		_hal_suresi -= delta
		if _hal_suresi <= 0.0 and not _dans:
			_penguen.texture = _dokular["olta"]
	if not _dans:
		_penguen.rotation = sin(_zaman * 2.0) * 0.03
