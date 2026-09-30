extends Control
# "Apartmanım" görünümü: kaydedilmiş bir kule, oyundaki manzarayla birlikte. Parmakla yukarı aşağı kaydırılır;
# pencereye dokununca oradaki hayvan küçük bir iş yapar (uyur, yemek yapar, dans eder, kitap okur, çiçek sular).
# Sol üstteki düğme kapatır. Dokunmayı ana sahne yönetir (dokun / surukle / birak).

signal kapandi

const Blok := preload("res://oyunlar/kule_yapma/blok.gd")
const Manzara := preload("res://oyunlar/kule_yapma/manzara.gd")
const G := "res://oyunlar/kule_yapma/gorseller/"
const KAYMA_ESIGI := 14.0

var sesler: Node

var _acik := false
var _ekran := Vector2(720, 1280)
var _zemin_y := 1180.0
var _manzara: Node2D
var _dunya: Node2D
var _bloklar: Array[Node2D] = []
var _kapat: Control
var _kamera_y := 640.0
var _en_ust := 640.0
var _hiz := 0.0
var _bas := Vector2.ZERO
var _son_y := 0.0
var _kayiyor := false
var _basili := false
var _son_is := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func acik_mi() -> bool:
	return _acik


func ac(apartman: Dictionary, ekran: Vector2) -> void:
	_acik = true
	visible = true
	_ekran = ekran
	size = ekran
	_zemin_y = ekran.y - 100.0
	for c in get_children():
		c.queue_free()
	_bloklar.clear()
	_manzara = Manzara.new()
	add_child(_manzara)
	_manzara.kur(ekran, _zemin_y)
	_dunya = Node2D.new()
	add_child(_dunya)
	var zemin := Sprite2D.new()
	zemin.texture = load(G + "manzara/zemin_%s.svg" % apartman.get("tema", "cayir"))
	zemin.scale = Vector2.ONE * 900.0 / zemin.texture.get_width()
	zemin.centered = false
	zemin.position = Vector2(ekran.x * 0.5 - 450.0, _zemin_y - 20.0)
	_dunya.add_child(zemin)
	var y := _zemin_y
	var katlar: Array = apartman["katlar"]
	var hayvanlar: Array = apartman["hayvanlar"]
	for i in katlar.size():
		var b: Node2D = Blok.new()
		_dunya.add_child(b)
		b.kur(katlar[i], hayvanlar[i] if i < hayvanlar.size() else "panda")
		b.position = Vector2(ekran.x * 0.5, y - b.yukseklik() * 0.5)
		b.hemen_goster()
		y -= b.yukseklik()
		_bloklar.append(b)
	# Kaydırma sınırı: en üstte çatı ekranın üst kısmında kalsın
	_en_ust = minf(ekran.y * 0.5, y - 260.0 + ekran.y * 0.5)
	_kamera_y = ekran.y * 0.5
	_hiz = 0.0
	_kapat = _geri_dugmesi()
	add_child(_kapat)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_konumla()
	# Açılışta herkes bir el sallasın
	for i in _bloklar.size():
		_bloklar[i].el_salla(1.5 + i * 0.05)


func _geri_dugmesi() -> Control:
	var d := Control.new()
	d.size = Vector2(104, 104)
	d.position = Vector2(36, 24)
	d.pivot_offset = d.size * 0.5
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var simge: Texture2D = load("res://ortak/gorseller/geri.svg")
	d.draw.connect(func() -> void:
		d.draw_circle(Vector2(52, 58), 46, Color(0.1, 0.1, 0.25, 0.2))
		d.draw_circle(Vector2(52, 52), 46, Color.WHITE)
		d.draw_arc(Vector2(52, 52), 46, 0.0, TAU, 48, Color(0.23, 0.18, 0.42), 5.0, true)
		d.draw_texture_rect(simge, Rect2(Vector2(26, 26), Vector2(52, 52)), false))
	return d


func kapat() -> void:
	if not _acik:
		return
	_acik = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		if not _acik:
			visible = false
			for c in get_children():
				c.queue_free()
		kapandi.emit())


func dokun(p: Vector2) -> void:
	if _kapat.get_global_rect().grow(10.0).has_point(p):
		_ses("dokun")
		kapat()
		return
	_basili = true
	_kayiyor = false
	_bas = p
	_son_y = p.y
	_hiz = 0.0


func surukle(p: Vector2) -> void:
	if not _basili:
		return
	if not _kayiyor and p.distance_to(_bas) > KAYMA_ESIGI:
		_kayiyor = true
	if _kayiyor:
		var fark := p.y - _son_y
		_kamera_y = clampf(_kamera_y - fark, _en_ust - 60.0, _ekran.y * 0.5 + 60.0)
		_hiz = lerpf(_hiz, -fark * 60.0, 0.5)
		_son_y = p.y


func birak(p: Vector2) -> void:
	if not _basili:
		return
	_basili = false
	if _kayiyor:
		return
	# Dokunuş: hangi katın hangi penceresi?
	for b in _bloklar:
		var yerel: Vector2 = b.to_local(p)
		if absf(yerel.x) < b.genislik() * 0.5 and absf(yerel.y) < b.yukseklik() * 0.5:
			var pencere: int = b.pencere_bul(yerel)
			if pencere >= 0:
				var isler := Blok.ISLER.filter(func(x: String) -> bool: return x != _son_is)
				_son_is = isler[randi() % isler.size()]
				b.is_yap(pencere, _son_is)
				_ses("isler")
			return


func _ses(ad: String) -> void:
	if sesler:
		sesler.play(ad)


func _konumla() -> void:
	_dunya.position = Vector2(0, _ekran.y * 0.5 - _kamera_y)
	_manzara.guncelle(_kamera_y)


func _process(delta: float) -> void:
	if not _acik or _manzara == null:
		return
	if not _basili:
		_kamera_y += _hiz * delta
		_hiz *= exp(-delta * 3.0)
		# Uçlardan taşınca yumuşakça geri döner
		var hedef := clampf(_kamera_y, _en_ust, _ekran.y * 0.5)
		_kamera_y = lerpf(_kamera_y, hedef, 1.0 - exp(-delta * 10.0))
	_konumla()
