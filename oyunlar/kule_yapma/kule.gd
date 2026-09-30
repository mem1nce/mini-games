extends Node2D
# Kule: zemin kat + üst üste oturan katlar (+ bitişte çatı). Düğümün kökü zemin katın tabanı (yer). Kule yükseldikçe
# tabanından hafifçe sallanır (sadece görsel; asla yıkılmaz). Oturma, mıknatıs ve ıska kararı burada hesaplanır.

const Blok := preload("res://oyunlar/kule_yapma/blok.gd")
const MUKEMMEL_PAYI := 12.0

var zemin: Node2D
var katlar: Array[Node2D] = []      # zemin kat hariç, alttan üste (çatı dahil)
var sallanma := true
var _zaman := 0.0


func kur(zemin_hayvan: String) -> void:
	for c in get_children():
		c.queue_free()
	katlar.clear()
	rotation = 0.0
	zemin = Blok.new()
	add_child(zemin)
	zemin.kur("zemin", zemin_hayvan)
	zemin.position = Vector2(0, -zemin.yukseklik() * 0.5)
	zemin.hemen_goster()


func sayi() -> int:
	return katlar.size()


func cati_var() -> bool:
	return not katlar.is_empty() and katlar.back().tasarim == "cati"


# Kulenin tepesi (yerel y) ve dünyadaki yeri
func ust_yerel() -> float:
	var y: float = -zemin.yukseklik()
	for k in katlar:
		y -= k.yukseklik()
	return y


func tepe() -> Vector2:
	return to_global(Vector2(0, ust_yerel()))


# Düşen katın tepeye göre durumu: "mukemmel", "oturur" ya da "iska"
func karar(blok_x: float, tolerans: float, genislik: float) -> String:
	var kayma := absf(blok_x - tepe().x)
	if kayma <= MUKEMMEL_PAYI:
		return "mukemmel"
	if kayma <= tolerans * genislik:
		return "oturur"
	return "iska"


# Kat kuleye oturur: yerine yerleştirilir (çağıran mıknatıs kaymasını önceden yapar)
func yerlestir(blok: Node2D) -> void:
	var y: float = ust_yerel() - blok.yukseklik() * 0.5
	blok.reparent(self)
	blok.position = Vector2(0, y)
	blok.rotation = 0.0
	katlar.append(blok)
	blok.esne()
	# Kule hafifçe çöker ve toparlanır
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 0.985), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_zaman += delta
	if sallanma:
		# Yükseldikçe biraz daha sallanır, ama hep abartısız
		var genlik := minf(0.014, katlar.size() * 0.0009)
		rotation = sin(_zaman * 0.8) * genlik


# Kutlama: aşağıdan yukarı pencereler yanar, herkes el sallar
func kutla() -> void:
	var hepsi: Array = [zemin] + katlar
	for i in hepsi.size():
		hepsi[i].isik_yak(i * 0.12)
		hepsi[i].el_salla(3.5)


# Kayıt için: alttan üste tasarımlar ve hayvanlar
func veri(tema: String) -> Dictionary:
	var hepsi: Array = [zemin] + katlar
	return {"katlar": hepsi.map(func(b: Node2D) -> String: return b.tasarim),
		"hayvanlar": hepsi.map(func(b: Node2D) -> String: return b.hayvan), "tema": tema}
