extends Node2D
# Giriş ekranı: yukarıdan görülen yeşil bir tepe, tepenin üstünde oval ray. Çocuğun treni kazandığı bütün
# vagonlarla bu rayda döner durur; trene dokununca düdük çalar ve bacadan büyük duman yükselir.
# Ortada büyük yeşil oynat düğmesi. Dokunmayı ana sahne yönetir (dokun()).

const Tren := preload("res://oyunlar/tren_rayi/tren.gd")
const Yol := preload("res://oyunlar/tren_rayi/yol.gd")
const RayCizici := preload("res://oyunlar/tren_rayi/ray_cizici.gd")
const Efektler := preload("res://oyunlar/tren_rayi/efektler.gd")
const G := "res://oyunlar/tren_rayi/gorseller/"
const HUCRE := 74.0
const HIZ := 90.0

var sesler: Node
var tren: Node2D

var _ekran := Vector2(1280, 720)
var _merkez := Vector2.ZERO
var _yol: RefCounted
var _oynat: Sprite2D
var _oynat_boyu := 170.0
var _efektler: Node2D
var _tepe := Vector2(600, 280)   # tepenin yarıçapları
var _zaman := 0.0


func kur(ekran: Vector2, vagonlar: Array) -> void:
	_ekran = ekran
	for c in get_children():
		c.queue_free()
	_merkez = Vector2(ekran.x * 0.5, ekran.y * 0.5 + 34.0)
	var a := minf(310.0, ekran.x * 0.5 - 330.0)
	var r := 168.0
	_tepe = Vector2(a + r + 170.0, r + 118.0)
	_yol = Yol.new()
	_yol.kapali = true
	_yol.ekle(_merkez + Vector2(-a, -r))
	_yol.duz_ekle(_merkez + Vector2(a, -r))
	_yol.yay_ekle(_merkez + Vector2(a, 0), r, -PI / 2.0, PI / 2.0)
	_yol.duz_ekle(_merkez + Vector2(-a, r))
	_yol.yay_ekle(_merkez + Vector2(-a, 0), r, PI / 2.0, PI * 1.5)
	_suslari_kur(a, r)
	tren = Tren.new()
	add_child(tren)
	_efektler = Efektler.new()
	add_child(_efektler)
	tren.efektler = _efektler
	tren.yol = _yol
	tren.kur(vagonlar, HUCRE)
	tren.mesafe = tren.uzunluk()
	tren.dongu_hizi = HIZ
	_oynat = Sprite2D.new()
	_oynat.texture = load(G + "oynat.svg")
	_oynat.scale = Vector2.ONE * _oynat_boyu / _oynat.texture.get_width()
	_oynat.position = _merkez
	add_child(_oynat)
	move_child(_oynat, tren.get_index())
	queue_redraw()


# Tepenin üstüne ve çevresine ağaçlar, göl, saman balyası, çiçekler
func _suslari_kur(a: float, r: float) -> void:
	var yerler := [
		["engel_ciftlik_A.svg", Vector2(-a - r - 110, -60), 100.0], ["engel_orman_A.svg", Vector2(-a - r - 70, 120), 90.0],
		["engel_ciftlik_A.svg", Vector2(a + r + 105, 70), 96.0], ["engel_ciftlik_K.svg", Vector2(a + r + 80, -120), 70.0],
		["engel_ciftlik_G.svg", Vector2(-a + 20, 0), 120.0], ["engel_orman_A.svg", Vector2(a - 30, -10), 84.0],
		["engel_ciftlik_A.svg", Vector2(-80, r + 104), 80.0], ["engel_ciftlik_K.svg", Vector2(170, r + 96), 62.0],
		["engel_orman_A.svg", Vector2(-_ekran.x * 0.5 + 70, _ekran.y * 0.5 - 60), 110.0],
		["engel_orman_A.svg", Vector2(_ekran.x * 0.5 - 80, _ekran.y * 0.5 - 70), 120.0],
		["engel_orman_A.svg", Vector2(_ekran.x * 0.5 - 70, -_ekran.y * 0.5 + 170), 96.0],
		["engel_ciftlik_A.svg", Vector2(-_ekran.x * 0.5 + 90, -_ekran.y * 0.5 + 230), 90.0],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in yerler:
		var s := Sprite2D.new()
		s.texture = load(G + y[0])
		s.scale = Vector2.ONE * y[2] / s.texture.get_width()
		s.position = _merkez + y[1] - Vector2(0, 34)
		s.rotation = rng.randf_range(-0.4, 0.4)
		add_child(s)


func dokun(nokta: Vector2) -> String:
	if nokta.distance_to(_oynat.position) < _oynat_boyu * 0.5:
		var tween := _oynat.create_tween()
		tween.tween_property(_oynat, "scale", _oynat.scale * 0.9, 0.08).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_oynat, "scale", _oynat.scale, 0.12).set_trans(Tween.TRANS_SINE)
		return "oyna"
	if tren and tren.iceriyor_mu(nokta):
		duduk()
		return "tren"
	return ""


func duduk() -> void:
	SesYoneticisi.efekt("tren_duduk", -5.0)
	_efektler.dudum(tren.baca_konumu(), HUCRE * 0.7)
	# Düdükle birlikte kısa bir hızlanma
	var tween := create_tween()
	tween.tween_property(tren, "dongu_hizi", HIZ * 2.2, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tren, "dongu_hizi", HIZ, 1.2).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_zaman += delta
	if _oynat:
		var nefes := 1.0 + sin(_zaman * 2.4) * 0.035
		_oynat.rotation = sin(_zaman * 1.3) * 0.03
		_oynat.scale = Vector2.ONE * _oynat_boyu / _oynat.texture.get_width() * nefes


func _elips(merkez: Vector2, yaricap: Vector2, sayi: int = 72) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in sayi:
		var a := TAU * i / sayi
		out.append(merkez + Vector2(cos(a) * yaricap.x, sin(a) * yaricap.y))
	return out


func _draw() -> void:
	# Çayır
	var bant := 20
	for i in bant:
		var t := float(i) / (bant - 1)
		draw_rect(Rect2(0, _ekran.y * i / bant, _ekran.x, _ekran.y / bant + 1.0), Color("b9e89a").lerp(Color("8fcf6a"), t))
	for i in 40:
		var p := Vector2(fmod(i * 173.0, _ekran.x), fmod(i * 97.0 + 40.0, _ekran.y))
		draw_circle(p, 3.0, [Color("ffffff"), Color("ffe066"), Color("ff9cc2")][i % 3])
	# Tepe: gölge, yamaç, düzlük, parlaklık
	draw_colored_polygon(_elips(_merkez + Vector2(10, 26), _tepe * 1.03), Color(0.2, 0.3, 0.1, 0.18))
	draw_colored_polygon(_elips(_merkez + Vector2(0, 10), _tepe), Color("6fb04c"))
	draw_colored_polygon(_elips(_merkez, _tepe * Vector2(0.97, 0.93)), Color("8fd46a"))
	draw_colored_polygon(_elips(_merkez - Vector2(0, 8), _tepe * Vector2(0.9, 0.82)), Color("a2df7c"))
	draw_colored_polygon(_elips(_merkez - Vector2(_tepe.x * 0.35, _tepe.y * 0.45), _tepe * Vector2(0.28, 0.1)), Color(1, 1, 1, 0.16))
	var kapali: PackedVector2Array = _yol.noktalar.duplicate()
	kapali.append(_yol.noktalar[0])
	RayCizici.ciz(self, kapali, HUCRE / 128.0)
