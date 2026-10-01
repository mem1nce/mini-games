class_name MoleBalance
extends Resource
# Köstebek Vurma'nın bütün denge ayarları (tek yer: denge.tres).
# Seviye skordan hesaplanır: seviye = 1 + skor / points_per_level. Son seviyeden sonrası son seviyedir.

@export_group("Puan ve can")
## Köstebeğe vurunca kazanılan puan.
@export var mole_points: int = 30
## Meyve/sebzeye dokununca kazanılan puan.
@export var fruit_points: int = 10
## Başlangıçtaki can (kalp) sayısı.
@export_range(1, 6) var lives: int = 3
## Her kaç puanda bir seviye atlanır.
@export var points_per_level: int = 150

@export_group("Nesneler")
## Kask kırılınca köstebeğin görünür kalma süresine eklenen süre (sn).
@export_range(0.0, 3.0, 0.05) var helmet_extra_time: float = 0.8
## Nesnenin çukurdan çıkma süresi (sn).
@export_range(0.05, 1.0, 0.01) var rise_time: float = 0.22
## Nesnenin içeri girme süresi (sn).
@export_range(0.05, 1.0, 0.01) var hide_time: float = 0.2
## Görünür kalma süresinin alt sınırı: seviye ne olursa olsun bundan kısa olmaz.
@export_range(0.3, 2.0, 0.05) var min_stay_time: float = 0.85

@export_group("Rastgelelik")
## Bir çukurdan nesne indikten sonra o çukur bu kadar süre boş kalır (sn).
@export_range(0.0, 3.0, 0.05) var hole_cooldown: float = 0.6
## En fazla kaç bomba art arda çıkabilir.
@export_range(1, 5) var max_bombs_in_row: int = 2
## Ekranda aynı anda en fazla kaç bomba olabilir.
@export_range(1, 3) var max_bombs_on_screen: int = 1

@export_group("Dokunma")
## Dokunma alanı görselin bu kadar katı (görselden biraz büyük).
@export_range(1.0, 1.8, 0.05) var touch_padding: float = 1.25
## Dokunma alanının en küçük kenarı (piksel).
@export var min_touch_size: float = 130.0

@export_group("Seviyeler")
## Sırayla seviye 1, 2, 3... Yeni seviye için diziye bir MoleLevelData ekle.
@export var levels: Array[MoleLevelData] = []


func level_data(level: int) -> MoleLevelData:
	return levels[clampi(level - 1, 0, levels.size() - 1)]


func level_for_score(score: int) -> int:
	return 1 + score / maxi(points_per_level, 1)


# Değerleri denetler; sorunları döndürür (boşsa her şey yolunda)
func problems() -> PackedStringArray:
	var result := PackedStringArray()
	if levels.is_empty():
		result.append("hiç seviye yok")
	for i in levels.size():
		var data := levels[i]
		if data == null:
			result.append("%d. seviye boş" % (i + 1))
			continue
		if data.bomb_chance + data.fruit_chance > 1.0:
			result.append("%d. seviyede bomba + meyve olasılığı 1'den büyük" % (i + 1))
		if data.spawn_interval_min > data.spawn_interval_max:
			result.append("%d. seviyede spawn_interval_min > spawn_interval_max" % (i + 1))
		if data.hole_count != 6 and data.hole_count != 9:
			result.append("%d. seviyede çukur sayısı 6 ya da 9 olmalı" % (i + 1))
		if data.max_active > data.hole_count:
			result.append("%d. seviyede max_active çukur sayısından büyük" % (i + 1))
	return result
