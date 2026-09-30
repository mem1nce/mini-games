extends Node2D
# Arka plan (ekran koordinatında, kameradan ayrı katman). Kameranın yüksekliğine ("kat" cinsinden) göre:
# köy ve tepeler → şehir çatıları → bulutlar ve kuşlar → sıcak hava balonları → gün batımı → yıldızlar, ay ve uzay.
# Gökyüzü rengi yumuşakça değişir; süsler kendi yüksekliklerinde durur ve kameradan yavaş kayar (paralaks).
# Sürprizler: kuş sürüsü geçer (7. kat), balon yanından süzülür (11. kat), ay göz kırpar gibi parlar (21. kat).

const G := "res://oyunlar/kule_yapma/gorseller/manzara/"
const KAT := 90.0                # manzaranın yükseklik ölçüsü (kat başına px; 20 katlık kule uzaya ulaşsın)
# Gökyüzü renkleri (kat, üst renk, alt renk)
const GOK := [
	[0.0, Color("8fd0ff"), Color("e8f7ff")],
	[6.0, Color("7cc4ff"), Color("d6f0ff")],
	[10.0, Color("6ab4ff"), Color("c8ecff")],
	[14.0, Color("8aa8ff"), Color("ffe0c0")],
	[18.0, Color("ff9a8a"), Color("ffd08a")],
	[21.0, Color("6a5a9e"), Color("ff9aa8")],
	[25.0, Color("1a1e4a"), Color("3a3478")],
	[32.0, Color("0a0c24"), Color("1e1a4a")],
]

var ekran := Vector2(720, 1280)
var zemin_y := 1180.0            # dünyada yer seviyesi
var kat := 0.0                   # kameranın bulunduğu yükseklik (kat)

var _susler: Array = []          # {"dugum", "y" (dünya), "p" (paralaks), "x", "hiz"}
var _yildizlar: Array = []
var _zaman := 0.0
var _surprizler := {}
var _ay: Sprite2D


func kur(p_ekran: Vector2, p_zemin_y: float) -> void:
	ekran = p_ekran
	zemin_y = p_zemin_y
	for c in get_children():
		c.queue_free()
	_susler.clear()
	_surprizler.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Şehir (tepelerin arkasında, tabanı yerde), tepeler ve köy
	_sus("sehir.svg", 1500.0, Vector2(ekran.x * 0.5, zemin_y - 310.0), 0.72)
	_sus("tepeler.svg", 1300.0, Vector2(ekran.x * 0.5, zemin_y - 150.0), 0.86)
	# Gökyüzü süsleri: "k" katında ekranın ortasına gelecek yükseklikte, kameradan biraz yavaş kayar (paralaks 0.9);
	# böylece kendi yüksekliklerinden önce görünmezler
	for i in 9:
		var b := _sus("bulut.svg", rng.randf_range(150.0, 260.0), Vector2(rng.randf_range(0.0, ekran.x), _yukseklik(6.0 + i * 1.3) + rng.randf_range(-200.0, 200.0)), 0.9)
		b["hiz"] = rng.randf_range(8.0, 18.0)
	for i in 4:
		var b := _sus("balon.svg", rng.randf_range(90.0, 130.0), Vector2(ekran.x * (0.12 + 0.76 * (i % 2)), _yukseklik(11.0 + i * 1.6)), 0.9)
		b["hiz"] = rng.randf_range(-6.0, 6.0)
	_sus("gunes.svg", 360.0, Vector2(ekran.x * 0.3, _yukseklik(18.0)), 0.9)
	var ay := _sus("ay.svg", 200.0, Vector2(ekran.x * 0.72, _yukseklik(23.0) - 250.0), 0.9)
	_ay = ay["dugum"]
	_sus("gezegen.svg", 220.0, Vector2(ekran.x * 0.28, _yukseklik(29.0)), 0.9)
	_yildizlar.clear()
	for i in 90:
		_yildizlar.append([Vector2(rng.randf_range(0, ekran.x), rng.randf_range(0, ekran.y)), rng.randf_range(1.2, 3.2), rng.randf() * TAU])


# "k" katındayken ekranın ortasına denk gelen dünya y'si
func _yukseklik(k: float) -> float:
	return zemin_y - ekran.y * 0.5 - k * KAT


func _sus(dosya: String, genislik: float, dunya: Vector2, paralaks: float) -> Dictionary:
	var s := Sprite2D.new()
	s.texture = load(G + dosya)
	s.scale = Vector2.ONE * genislik / s.texture.get_width()
	add_child(s)
	var kayit := {"dugum": s, "y": dunya.y, "p": paralaks, "x": dunya.x, "hiz": 0.0}
	_susler.append(kayit)
	return kayit


# Kamera merkezinin dünya y'si
func guncelle(kamera_y: float) -> void:
	kat = maxf(0.0, (zemin_y - ekran.y * 0.5 - kamera_y) / KAT)
	for s in _susler:
		var d: Sprite2D = s["dugum"]
		d.position = Vector2(s["x"], (s["y"] - kamera_y) * s["p"] + ekran.y * 0.5)
	_surpriz_denetle()
	queue_redraw()


func _gok(k: float) -> Array:
	for i in range(GOK.size() - 1):
		var a: Array = GOK[i]
		var b: Array = GOK[i + 1]
		if k <= b[0]:
			var t := clampf((k - a[0]) / (b[0] - a[0]), 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			return [a[1].lerp(b[1], t), a[2].lerp(b[2], t)]
	return [GOK.back()[1], GOK.back()[2]]


func _process(delta: float) -> void:
	_zaman += delta
	for s in _susler:
		if s["hiz"] != 0.0:
			s["x"] = fposmod(s["x"] + s["hiz"] * delta + 150.0, ekran.x + 300.0) - 150.0


func _draw() -> void:
	# Gökyüzü: ekranın üstü daha yüksek kat, altı daha alçak
	var ust: Array = _gok(kat + 4.0)
	var alt: Array = _gok(maxf(0.0, kat - 4.0))
	var bant := 24
	for i in bant:
		var t := float(i) / (bant - 1)
		var renk: Color = ust[0].lerp(alt[1], t)
		draw_rect(Rect2(0, ekran.y * i / bant, ekran.x, ekran.y / bant + 1.0), renk)
	# Yıldızlar: gün batımından sonra belirir, göz kırpar
	var parlaklik := clampf((kat - 19.0) / 5.0, 0.0, 1.0)
	if parlaklik > 0.0:
		for y in _yildizlar:
			var a := parlaklik * (0.55 + 0.45 * sin(_zaman * 2.0 + y[2]))
			draw_circle(y[0], y[1] * 2.4, Color(1, 1, 0.85, a * 0.18))
			draw_circle(y[0], y[1], Color(1, 1, 0.9, a))


# --- Sürprizler (belli yüksekliklerde bir kez) ---

func _surpriz_denetle() -> void:
	if kat >= 6.0 and not _surprizler.has("kuslar"):
		_surprizler["kuslar"] = true
		_kus_surusu()
	if kat >= 10.5 and not _surprizler.has("balon"):
		_surprizler["balon"] = true
		_balon_suzulur()
	if kat >= 20.5 and not _surprizler.has("ay"):
		_surprizler["ay"] = true
		_ay_goz_kirpar()


func _kus_surusu() -> void:
	var y0 := ekran.y * randf_range(0.3, 0.45)
	for i in 6:
		var kus := Sprite2D.new()
		kus.texture = load(G + "kus.svg")
		kus.scale = Vector2.ONE * 64.0 / kus.texture.get_width()
		var ofset := Vector2(-i * 50.0 - (i % 2) * 20.0, (i % 3) * 36.0 - 30.0)
		kus.position = Vector2(-80.0, y0) + ofset
		add_child(kus)
		var tween := kus.create_tween()
		tween.tween_method(func(t: float) -> void:
			kus.position = Vector2(lerpf(-80.0, ekran.x + 380.0, t), y0 + sin(t * 12.0 + i) * 14.0) + ofset
			kus.scale.y = absf(kus.scale.x) * (0.7 + 0.3 * absf(sin(t * 60.0 + i))), 0.0, 1.0, 5.0)
		tween.tween_callback(kus.queue_free)


func _balon_suzulur() -> void:
	var balon := Sprite2D.new()
	balon.texture = load(G + "balon.svg")
	balon.scale = Vector2.ONE * 150.0 / balon.texture.get_width()
	add_child(balon)
	var tween := balon.create_tween()
	tween.tween_method(func(t: float) -> void:
		balon.position = Vector2(lerpf(ekran.x + 100.0, -100.0, t), ekran.y * (0.62 - 0.25 * t) + sin(t * 9.0) * 16.0)
		balon.rotation = sin(t * 7.0) * 0.06, 0.0, 1.0, 9.0)
	tween.tween_callback(balon.queue_free)


func _ay_goz_kirpar() -> void:
	if _ay == null:
		return
	var olcek := _ay.scale
	var tween := _ay.create_tween()
	for i in 2:
		tween.tween_property(_ay, "scale", olcek * 1.2, 0.25).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_ay, "modulate", Color(1.4, 1.4, 1.1), 0.25)
		tween.tween_property(_ay, "scale", olcek, 0.35).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_ay, "modulate", Color.WHITE, 0.35)
