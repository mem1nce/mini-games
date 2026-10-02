extends Node2D
# Balık, denizanası ve çöpleri üretir; sudaki balık sayısını korur (ekrandan çıkanın yerine kenardan yenisi gelir).
# Görevde hâlâ istenen türler daha sık gelir; temanın nadir türleri ara sıra uğrar. Ağla çarpışmaları bulur.

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const Balik := preload("res://oyunlar/balik_tutma/balik.gd")
const Denizanasi := preload("res://oyunlar/balik_tutma/denizanasi.gd")
const Cop := preload("res://oyunlar/balik_tutma/cop.gd")

var level: Dictionary = {}
var gorev: Node                  # gorev_yoneticisi (hangi türler hâlâ isteniyor)
var alan := Rect2()              # yüzme alanı (x ekran dışına taşar)
var ek_balik := 0                # su temizlendikçe artar
var baliklar: Array[Node2D] = []
var denizanalari: Array[Node2D] = []
var copler: Array[Node2D] = []

var _bekleme := 0.0
var _rng := RandomNumberGenerator.new()


func kur(p_level: Dictionary, ekran: Vector2, yuzey_y: float, dip_y: float, p_gorev: Node) -> void:
	level = p_level
	gorev = p_gorev
	_rng.randomize()
	for c in get_children():
		c.queue_free()
	baliklar.clear()
	denizanalari.clear()
	copler.clear()
	ek_balik = 0
	alan = Rect2(-90.0, yuzey_y + 70.0, ekran.x + 180.0, dip_y - yuzey_y - 130.0)
	# Başlangıçta ekranda bir kaç balık hazır olsun
	for i in _hedef_sayi():
		_balik_ekle(true)
	for i in int(level.get("denizanasi", 0)):
		var d: Node2D = Denizanasi.new()
		d.position = Vector2(_rng.randf_range(ekran.x * 0.15, ekran.x * 0.85), alan.get_center().y)
		add_child(d)
		d.kur(Rect2(40.0, alan.position.y, ekran.x - 80.0, alan.size.y), 96.0)
		denizanalari.append(d)
	_copleri_kur(int(level.get("cop", 0)), ekran)


func _hedef_sayi() -> int:
	return int(level["balik_sayisi"]) + ek_balik


func _copleri_kur(sayi: int, ekran: Vector2) -> void:
	var yerler: Array[Vector2] = []
	for i in sayi:
		for deneme in 60:
			var p := Vector2(_rng.randf_range(80.0, ekran.x - 80.0), _rng.randf_range(alan.position.y + 40.0, alan.end.y - 20.0))
			if yerler.all(func(q: Vector2) -> bool: return q.distance_to(p) > 170.0):
				yerler.append(p)
				break
	for i in yerler.size():
		var c: Node2D = Cop.new()
		add_child(c)
		c.kur(Cop.TURLER[i % Cop.TURLER.size()], yerler[i])
		copler.append(c)


func _tur_sec() -> String:
	var tema: String = level["tema"]
	var nadirler: Array = Turler.NADIR_TEMA.get(tema, [])
	if not nadirler.is_empty() and _rng.randf() < Turler.NADIR_SANSI:
		return nadirler[_rng.randi() % nadirler.size()]
	var havuz: Array = level["havuz"]
	var agirliklar: Array[float] = []
	var toplam := 0.0
	for t in havuz:
		var w := 1.0
		if gorev and gorev.gerekli_mi({"tur": t}):
			w = 3.0
		agirliklar.append(w)
		toplam += w
	var r := _rng.randf() * toplam
	for i in havuz.size():
		r -= agirliklar[i]
		if r <= 0.0:
			return havuz[i]
	return havuz.back()


func _balik_ekle(ekranda: bool) -> void:
	var tur := _tur_sec()
	var t := Turler.tur(tur)
	var derinlik: Array = t["derinlik"]
	var y := alan.position.y + _rng.randf_range(derinlik[0], derinlik[1]) * alan.size.y
	var yon := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := alan.position.x if yon > 0.0 else alan.end.x
	if ekranda:
		x = _rng.randf_range(alan.position.x + 160.0, alan.end.x - 160.0)
	var balik: Node2D = Balik.new()
	balik.position = Vector2(x, y)
	add_child(balik)
	balik.kur(tur, yon, y, float(t["hiz"]) * float(level.get("hiz", 1.0)) * _rng.randf_range(0.85, 1.15), alan)
	baliklar.append(balik)


func _process(delta: float) -> void:
	for balik in baliklar.duplicate():
		if balik.get_parent() == self and balik.disarida_mi():
			baliklar.erase(balik)
			balik.queue_free()
	_bekleme -= delta
	if _bekleme <= 0.0 and _yuzen_sayisi() < _hedef_sayi():
		_bekleme = _rng.randf_range(0.6, 1.4)
		_balik_ekle(false)


func _yuzen_sayisi() -> int:
	return baliklar.filter(func(b: Node2D) -> bool: return b.durum == Balik.Durum.YUZUYOR).size()


# Ağa değen balık ya da çöp (en yakını)
func carpisan(nokta: Vector2, yaricap: float) -> Node2D:
	var en_iyi: Node2D = null
	var en_yakin := INF
	for balik in baliklar:
		if balik.durum != Balik.Durum.YUZUYOR:
			continue
		var d := balik.global_position.distance_to(nokta)
		if d < balik.yaricap() + yaricap and d < en_yakin:
			en_iyi = balik
			en_yakin = d
	for cop in copler:
		var d := cop.global_position.distance_to(nokta)
		if d < cop.yaricap() + yaricap and d < en_yakin:
			en_iyi = cop
			en_yakin = d
	return en_iyi


func denizanasi_degiyor(nokta: Vector2, yaricap: float) -> bool:
	for d in denizanalari:
		if d.global_position.distance_to(nokta) < d.yaricap() + yaricap * 0.8:
			return true
	return false


# Ağa giren nesne listeden çıkar (balık suya dönerse geri_al ile eklenir)
func cikar(nesne: Node2D) -> void:
	baliklar.erase(nesne)
	copler.erase(nesne)


func geri_al(balik: Node2D) -> void:
	if not balik in baliklar:
		baliklar.append(balik)


func kalan_cop() -> int:
	return copler.size()
