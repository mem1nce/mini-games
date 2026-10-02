extends RefCounted
# Kayıt: user://balik_tutma.cfg — [ilerleme] bolum (bitirilen bölüm sayısı = sıradaki bölüm),
# [akvaryum] <tür> = kaç kez yakalandı (akvaryumdaki türler).

const PATH := "user://balik_tutma.cfg"

var bolum := 0
var akvaryum := {}


func yukle() -> void:
	var ayar := ConfigFile.new()
	if ayar.load(PATH) != OK:
		return
	bolum = maxi(0, int(ayar.get_value("ilerleme", "bolum", 0)))
	if ayar.has_section("akvaryum"):
		for tur in ayar.get_section_keys("akvaryum"):
			akvaryum[tur] = int(ayar.get_value("akvaryum", tur, 0))


func kaydet() -> void:
	var ayar := ConfigFile.new()
	ayar.set_value("ilerleme", "bolum", bolum)
	for tur in akvaryum:
		ayar.set_value("akvaryum", tur, akvaryum[tur])
	GuvenliKayit.save_config(ayar, PATH)


func yeni_mi(tur: String) -> bool:
	return not akvaryum.has(tur)


func ekle(tur: String) -> void:
	akvaryum[tur] = int(akvaryum.get(tur, 0)) + 1
