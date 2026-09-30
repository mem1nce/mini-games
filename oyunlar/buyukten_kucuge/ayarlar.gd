class_name SizeSettings
extends Resource
# Büyükten Küçüğe ayarları (tek yer: ayarlar.tres): bölüm tablosu, boyut kuralları, nesne türleri.

## Bölümler sırayla (her biri SizeLevel). Son bölümden sonra 1. bölüme dönülür.
@export var levels: Array[SizeLevel] = []
## Ardışık nesneler arasındaki en küçük boyut farkı (gözle ayırt edilebilsin diye alt sınır)
@export_range(0.05, 0.3, 0.01) var min_step: float = 0.12
## Dokunma alanı en az ekranın kısa kenarının bu oranı (görsel küçük olsa da)
@export_range(0.05, 0.25, 0.01) var touch_ratio: float = 0.12
## Sıralama Dizisi'nde "büyük/küçük" nesneleri (şablon adları, gorseller/sablonlar.json)
@export var size_kinds: PackedStringArray = ["balon", "balik", "ayi", "agac"]
## Sıralama Dizisi'nde "boy" nesneleri (uzayan şablonlar)
@export var height_kinds: PackedStringArray = ["zurafa", "kalem", "cicek", "kule"]
## İç içe bebek karakterleri (bebek_<ad>_ust / _alt şablonları)
@export var doll_kinds: PackedStringArray = ["tavsan", "ayi", "penguen"]


func level_count() -> int:
	return levels.size()


func level(index: int) -> SizeLevel:
	return levels[clampi(index, 0, levels.size() - 1)]


# Ayarlardaki hatalar (oyun açılırken ve testte denetlenir)
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if levels.is_empty():
		out.append("hiç bölüm yok")
	for i in levels.size():
		var l := levels[i]
		if l == null:
			out.append("%d. bölüm boş" % (i + 1))
			continue
		if l.step < min_step - 0.0001:
			out.append("%d. bölümde boyut farkı %.2f, alt sınır %.2f" % [i + 1, l.step, min_step])
		if l.count < 2 or l.count > 6:
			out.append("%d. bölümde nesne sayısı 2-6 olmalı" % (i + 1))
	for list in [size_kinds, height_kinds]:
		for art in list:
			if not SizeArt.has(art):
				out.append("şablon yok: " + art)
	for art in height_kinds:
		if SizeArt.has(art) and not SizeArt.is_tall(art):
			out.append("boy nesnesi uzayan şablon olmalı: " + art)
	for doll in doll_kinds:
		for part in ["_ust", "_alt"]:
			if not SizeArt.has("bebek_" + doll + part):
				out.append("bebek şablonu yok: bebek_" + doll + part)
	return out
