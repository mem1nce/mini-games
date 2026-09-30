extends RefCounted
# Bölüm sırası ve kazanılan vagonlar. Kayıt: user://tren_rayi.cfg ([ilerleme] bolum, vagon).
# Bölümler bölüm seçme olmadan art arda gelir; 20. bölümden sonra baştan (vagonlar birikmeye devam eder).

const Bolumler := preload("res://oyunlar/tren_rayi/bolumler.gd")
const Tren := preload("res://oyunlar/tren_rayi/tren.gd")
const PATH := "user://tren_rayi.cfg"
const OYUNDA_VAGON := 5          # oyunda trenin arkasında görünen en son vagonlar
const GIRISTE_VAGON := 26        # giriş ekranındaki halkaya sığan vagon sayısı

var bolum := 0                   # bitirilen bölüm sayısı = sıradaki bölümün indeksi
var vagon := 0                   # kazanılan vagon sayısı


func veri() -> Dictionary:
	return Bolumler.level(bolum)


func vagonlar(en_fazla: int) -> Array:
	var out: Array = []
	for i in range(maxi(0, vagon - en_fazla), vagon):
		out.append(Tren.vagon_adi(i))
	return out


func bitti() -> void:
	bolum += 1
	vagon += 1
	kaydet()


func yukle() -> void:
	var ayar := ConfigFile.new()
	if ayar.load(PATH) != OK:
		return
	bolum = maxi(0, int(ayar.get_value("ilerleme", "bolum", 0)))
	vagon = maxi(0, int(ayar.get_value("ilerleme", "vagon", bolum)))


func kaydet() -> void:
	var ayar := ConfigFile.new()
	ayar.set_value("ilerleme", "bolum", bolum)
	ayar.set_value("ilerleme", "vagon", vagon)
	ayar.save(PATH)
