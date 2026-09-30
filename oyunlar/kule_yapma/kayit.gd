extends RefCounted
# Kayıt: user://kule_yapma.cfg — [ilerleme] bolum (bitirilen bölüm sayısı), rekor (sonsuz modda en yüksek kat),
# [apartmanlar] liste: her apartman {"katlar": [tasarım...], "hayvanlar": [hayvan...], "tema": zemin}
# (katlar alttan üste; zemin kat ve çatı dahil).

const PATH := "user://kule_yapma.cfg"
const EN_FAZLA_APARTMAN := 40

var bolum := 0
var rekor := 0
var apartmanlar: Array = []


func yukle() -> void:
	var ayar := ConfigFile.new()
	if ayar.load(PATH) != OK:
		return
	bolum = maxi(0, int(ayar.get_value("ilerleme", "bolum", 0)))
	rekor = maxi(0, int(ayar.get_value("ilerleme", "rekor", 0)))
	var liste = ayar.get_value("apartmanlar", "liste", [])
	if liste is Array:
		apartmanlar = liste.filter(func(a) -> bool: return a is Dictionary and a.has("katlar") and a.has("hayvanlar"))


func kaydet() -> void:
	var ayar := ConfigFile.new()
	ayar.set_value("ilerleme", "bolum", bolum)
	ayar.set_value("ilerleme", "rekor", rekor)
	ayar.set_value("apartmanlar", "liste", apartmanlar)
	ayar.save(PATH)


func apartman_ekle(apartman: Dictionary) -> void:
	apartmanlar.append(apartman)
	while apartmanlar.size() > EN_FAZLA_APARTMAN:
		apartmanlar.pop_front()
