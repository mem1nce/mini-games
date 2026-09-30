extends Node2D
# Tek apartman katı. Katmanlar: pencere içleri (arkada) → hayvan ailesi (pencerelerde) → delikli duvar ve çerçeveler
# (önde). Düğümün kökü katın ortası. Oturunca esner-zıplar; hayvanlar taşınıp el sallar; kutlamada pencereler yanar.
# Apartman görünümünde pencereye dokununca hayvan küçük bir iş yapar (uyur, yemek yapar, dans eder, kitap okur,
# çiçek sular).

const G := "res://oyunlar/kule_yapma/gorseller/"
const TASARIMLAR := ["tugla", "ahsap", "pembe", "mavi", "balkon", "yuvarlak", "tente", "tas", "sarmasik", "cizgili", "yildizli"]
const HAYVANLAR := ["aslan", "baykus", "fil", "kaplumbaga", "panda", "penguen", "tavsan", "zurafa"]
const ISLER := ["uyu", "yemek", "dans", "kitap", "cicek"]
const YUVARLAK_PENCERE := ["yuvarlak", "cizgili"]

var tasarim := "tugla"
var hayvan := "panda"

var _govde: Node2D
var _hayvanlar: Array[Sprite2D] = []
var _pencereler: Array[Vector2] = []
var _isiklar: Array[Sprite2D] = []
var _zaman := 0.0
var _salla := 0.0
var _mesgul: Array[bool] = []


static func boyut(p_tasarim: String) -> Vector2:
	match p_tasarim:
		"zemin": return Vector2(260, 150)
		"cati": return Vector2(270, 150)
	return Vector2(240, 120)


func kur(p_tasarim: String, p_hayvan: String) -> void:
	tasarim = p_tasarim
	hayvan = p_hayvan
	_zaman = randf() * TAU
	_govde = Node2D.new()
	add_child(_govde)
	var ic_adi := "ic_zemin" if tasarim == "zemin" else ("ic_cati" if tasarim == "cati" else
		("ic_yuvarlak" if tasarim in YUVARLAK_PENCERE else "ic_kare"))
	var b := boyut(tasarim)
	_sprite("katlar/%s.svg" % ic_adi, b.x)
	match tasarim:
		"zemin": _pencereler = [Vector2(-76, -15), Vector2(76, -15)]
		"cati": _pencereler = [Vector2(0, 21)]
		_: _pencereler = [Vector2(-56, -4), Vector2(56, -4)]
	for i in _pencereler.size():
		var boy := 92.0 if i == 0 else 72.0
		if tasarim == "cati":
			boy = 70.0
		var s := Sprite2D.new()
		s.texture = load(G + "hayvanlar/%s.svg" % hayvan)
		s.scale = Vector2.ONE * boy / s.texture.get_width()
		# Kafanın ortası (tuvalde ~y=104) pencerenin ortasına gelsin; gövde duvarın arkasında kalır
		s.position = _pencereler[i] + Vector2(0, (128.0 - 104.0) * boy / 256.0 + 4.0)
		s.set_meta("yer", s.position)
		s.set_meta("olcek", s.scale)
		s.visible = false
		_govde.add_child(s)
		_hayvanlar.append(s)
		_mesgul.append(false)
	_sprite("katlar/kat_%s.svg" % tasarim, b.x)


func _sprite(dosya: String, genislik: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(G + dosya)
	s.scale = Vector2.ONE * genislik / s.texture.get_width()
	_govde.add_child(s)
	return s


func genislik() -> float:
	return boyut(tasarim).x


func yukseklik() -> float:
	return boyut(tasarim).y


# Hayvan ailesi taşınır: pencerede zıplayarak belirir ve el sallar
func tasin(gecikme: float = 0.15) -> void:
	for i in _hayvanlar.size():
		var s := _hayvanlar[i]
		var olcek: Vector2 = s.get_meta("olcek")
		s.visible = true
		s.scale = Vector2.ZERO
		var tween := s.create_tween()
		tween.tween_interval(gecikme + i * 0.12)
		tween.tween_property(s, "scale", olcek, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	el_salla(1.8)


func hemen_goster() -> void:
	for s in _hayvanlar:
		s.visible = true
		s.scale = s.get_meta("olcek")


func el_salla(sure: float) -> void:
	_salla = maxf(_salla, sure)


# Oturunca kısa esneme-zıplama
func esne() -> void:
	var tween := _govde.create_tween()
	tween.tween_property(_govde, "scale", Vector2(1.1, 0.84), 0.07).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_govde, "position:y", yukseklik() * 0.08, 0.07)
	tween.tween_property(_govde, "scale", Vector2(0.95, 1.07), 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_govde, "position:y", -yukseklik() * 0.04, 0.12)
	tween.tween_property(_govde, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_govde, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_SINE)


# Kutlama: pencereler ılık ışıkla yanar
func isik_yak(gecikme: float) -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for p in _pencereler:
		var isik := Sprite2D.new()
		isik.texture = load(G + "isik.svg")
		isik.material = mat
		isik.scale = Vector2.ONE * 130.0 / isik.texture.get_width()
		isik.position = p
		isik.modulate = Color(1.0, 0.85, 0.4, 0.0)
		_govde.add_child(isik)
		_govde.move_child(isik, 1)      # pencere içinin önünde, hayvanların arkasında
		_isiklar.append(isik)
		var tween := isik.create_tween()
		tween.tween_interval(gecikme)
		tween.tween_property(isik, "modulate:a", 0.55, 0.35).set_trans(Tween.TRANS_SINE)


func isiklari_sondur() -> void:
	for isik in _isiklar:
		isik.queue_free()
	_isiklar.clear()


# Dokunulan pencere (yerel nokta), yoksa -1
func pencere_bul(yerel: Vector2) -> int:
	for i in _pencereler.size():
		if yerel.distance_to(_pencereler[i]) < 48.0:
			return i
	return -1


# Apartman görünümü: pencerede hayvan küçük bir iş yapar
func is_yap(pencere: int, is_adi: String) -> void:
	if pencere < 0 or pencere >= _hayvanlar.size() or _mesgul[pencere]:
		return
	_mesgul[pencere] = true
	var s := _hayvanlar[pencere]
	var yer: Vector2 = s.get_meta("yer")
	var olcek: Vector2 = s.get_meta("olcek")
	var p := _pencereler[pencere]
	var tween := s.create_tween()
	match is_adi:
		"uyu":
			_esya("isler/zzz.svg", p + Vector2(22, -34), 44.0, Vector2(20, -60), 2.2)
			tween.tween_property(s, "rotation", 0.35, 0.5).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "scale", olcek * Vector2(1.04, 0.94), 0.6).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "scale", olcek, 0.6).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		"yemek":
			_esya("isler/tencere.svg", p + Vector2(0, 26), 52.0, Vector2(0, -6), 2.0)
			for i in 4:
				tween.tween_property(s, "position:y", yer.y - 6.0, 0.15).set_trans(Tween.TRANS_SINE)
				tween.tween_property(s, "position:y", yer.y, 0.15).set_trans(Tween.TRANS_SINE)
		"dans":
			_esya("isler/nota.svg", p + Vector2(-26, -26), 30.0, Vector2(-18, -50), 1.8)
			_esya("isler/nota.svg", p + Vector2(26, -20), 26.0, Vector2(20, -46), 1.8)
			for i in 3:
				tween.tween_property(s, "position:y", yer.y - 14.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(s, "rotation", 0.25 if i % 2 == 0 else -0.25, 0.14)
				tween.tween_property(s, "position:y", yer.y, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(s, "rotation", 0.0, 0.12)
		"kitap":
			_esya("isler/kitap.svg", p + Vector2(0, 24), 50.0, Vector2(0, -2), 2.2)
			tween.tween_property(s, "rotation", 0.12, 0.5).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "rotation", -0.12, 0.8).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		"cicek":
			_esya("isler/sulama.svg", p + Vector2(-30, 12), 42.0, Vector2(-4, -6), 1.8, 0.5)
			_esya("isler/cicek.svg", p + Vector2(24, 36), 30.0, Vector2(0, -16), 2.4)
			tween.tween_property(s, "rotation", -0.15, 0.4).set_trans(Tween.TRANS_SINE)
			tween.tween_property(s, "rotation", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _mesgul[pencere] = false)


# Küçük eşya: pencerede belirir, kayar, söner
func _esya(dosya: String, yer: Vector2, boy: float, kayma: Vector2, sure: float, egim: float = 0.0) -> void:
	var s := Sprite2D.new()
	s.texture = load(G + dosya)
	var olcek := Vector2.ONE * boy / s.texture.get_width()
	s.scale = Vector2.ZERO
	s.position = yer
	_govde.add_child(s)
	var tween := s.create_tween()
	tween.tween_property(s, "scale", olcek, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(s, "rotation", egim, 0.3)
	tween.tween_property(s, "position", yer + kayma, sure).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(s, "modulate:a", 0.0, sure).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(s.queue_free)


func _process(delta: float) -> void:
	_zaman += delta
	if _salla > 0.0:
		_salla -= delta
	for i in _hayvanlar.size():
		if _mesgul[i]:
			continue
		var s := _hayvanlar[i]
		if _salla > 0.0:
			s.rotation = sin(_zaman * 9.0 + i) * 0.22
		else:
			s.rotation = sin(_zaman * 1.5 + i * 2.0) * 0.04
