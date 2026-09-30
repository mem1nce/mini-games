extends Node2D
# Kule: zemin kat + üst üste oturan katlar (+ bitişte çatı). Düğümün kökü zemin katın tabanı (yer). Fizik yok:
# her katın kuledeki yatay yeri (position.x) saklanır; eğim = en üst katın zemin kata göre kayması (kat genişliği
# cinsinden). Kule eğim yönünde yatar ve eğim büyüdükçe daha çok sallanır. Yerleştirme kararı burada verilir.

const Blok := preload("res://oyunlar/kule_yapma/blok.gd")
const MUKEMMEL_PAYI := 12.0      # bu kadar px içinde bırakmak "Mükemmel!"
const DUZELTME := 0.1            # mükemmel bırakış eğimi bu kadar (kat genişliği) düzeltir
const EGIM_ACISI := 0.07         # eğim başına kulenin yatma açısı (radyan)
const KAT_ENI := 240.0

var zemin: Node2D
var katlar: Array[Node2D] = []      # zemin kat hariç, alttan üste (çatı dahil)
var sallanma := true
var _zaman := 0.0
var _gorunen_egim := 0.0


func kur(zemin_hayvan: String) -> void:
	for c in get_children():
		c.queue_free()
	katlar.clear()
	rotation = 0.0
	_gorunen_egim = 0.0
	sallanma = true
	zemin = Blok.new()
	add_child(zemin)
	zemin.kur("zemin", zemin_hayvan)
	zemin.position = Vector2(0, -zemin.yukseklik() * 0.5)
	zemin.hemen_goster()


func sayi() -> int:
	return katlar.size()


func cati_var() -> bool:
	return not katlar.is_empty() and katlar.back().tasarim == "cati"


func ust_kat() -> Node2D:
	return katlar.back() if not katlar.is_empty() else zemin


# Kulenin tepesi (yerel y) ve dünyadaki yeri (en üst katın ortasının üstü)
func ust_yerel() -> float:
	var y: float = -zemin.yukseklik()
	for k in katlar:
		y -= k.yukseklik()
	return y


func tepe() -> Vector2:
	return to_global(Vector2(ust_kat().position.x, ust_yerel()))


# İşaretli eğim (kat genişliği cinsinden); + sağa, - sola
func egim() -> float:
	return ust_kat().position.x / KAT_ENI


# Düşen katın kararı. Döner: {"tur": mukemmel/oturur/kayik/devril, "x": kuledeki yeri (yerel),
#   "yon": devrilme yönü, "kenar": alttaki katın kenarının yerel x'i, "temas": kenara değiyor mu}
func karar(blok_global: Vector2, miknatis: float, genislik: float) -> Dictionary:
	var alt := ust_kat()
	var yerel_x: float = to_local(blok_global).x
	var kayma: float = yerel_x - alt.position.x
	var yon := 1.0 if kayma >= 0.0 else -1.0
	if absf(kayma) <= MUKEMMEL_PAYI:
		# Mükemmel: ortaya oturur ve eğimi biraz düzeltir
		var duzelt: float = minf(absf(alt.position.x), DUZELTME * KAT_ENI) * signf(alt.position.x)
		return {"tur": "mukemmel", "x": alt.position.x - duzelt}
	if absf(kayma) <= miknatis * genislik:
		return {"tur": "oturur", "x": alt.position.x}
	var yarim: float = alt.genislik() * 0.5
	if absf(kayma) <= yarim:
		return {"tur": "kayik", "x": yerel_x}
	# Ağırlık merkezi kenarın dışında: devrilir
	return {"tur": "devril", "x": yerel_x, "yon": yon, "kenar": alt.position.x + yon * yarim,
		"temas": absf(kayma) < yarim + genislik * 0.5}


# Kat kuleye oturur (x: kuledeki yeri)
func yerlestir(blok: Node2D, x: float) -> void:
	var y: float = ust_yerel() - blok.yukseklik() * 0.5
	blok.reparent(self)
	blok.position = Vector2(x, y)
	blok.rotation = 0.0
	katlar.append(blok)
	blok.esne()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 0.985), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# En üstteki katları kuleden ayırır (devrilmeleri için); dünyaya taşınmış olarak döner, üstten alta
func ust_katlari_ayir(adet: int, dunya: Node2D) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for i in mini(adet, katlar.size()):
		var k: Node2D = katlar.pop_back()
		var yer := k.global_position
		var aci := k.global_rotation
		k.reparent(dunya)
		k.global_position = yer
		k.global_rotation = aci
		out.append(k)
	return out


func _process(delta: float) -> void:
	_zaman += delta
	if not sallanma:
		return
	# Eğim yönünde yatar; eğim ve yükseklik büyüdükçe daha çok sallanır
	_gorunen_egim = lerpf(_gorunen_egim, egim(), 1.0 - exp(-delta * 4.0))
	var genlik := minf(0.014, katlar.size() * 0.0009) + absf(_gorunen_egim) * 0.02
	var hiz := 0.8 + absf(_gorunen_egim) * 1.2
	rotation = _gorunen_egim * EGIM_ACISI + sin(_zaman * hiz) * genlik


# Kutlama: aşağıdan yukarı pencereler yanar, herkes el sallar
func kutla() -> void:
	var hepsi: Array = [zemin] + katlar
	for i in hepsi.size():
		hepsi[i].isik_yak(i * 0.12)
		hepsi[i].el_salla(3.5)


# Kayıt için: alttan üste tasarımlar, hayvanlar ve yatay yerler
func veri(tema: String) -> Dictionary:
	var hepsi: Array = [zemin] + katlar
	return {"katlar": hepsi.map(func(b: Node2D) -> String: return b.tasarim),
		"hayvanlar": hepsi.map(func(b: Node2D) -> String: return b.hayvan),
		"x": hepsi.map(func(b: Node2D) -> float: return snappedf(b.position.x, 0.1)), "tema": tema}
