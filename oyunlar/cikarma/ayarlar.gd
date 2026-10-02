class_name SubtractionSettings
extends Resource
# Çıkarma Öğreniyorum'un bütün zorluk ayarları (tek yer: ayarlar.tres).
# Bölüm sayısı = aşamaların level_count toplamı. Yeni aşama için Stages dizisine bir SubtractionStage ekle.

## Sırayla oynanan aşamalar (her biri birkaç bölüm).
@export var stages: Array[SubtractionStage] = []

@export_group("Sayılar")
## Açıksa bazen 0 kullanılır: çıkan 0 (5 - 0) ya da sonuç 0 (5 - 5). Küçük çocuklar için kapalı önerilir.
@export var allow_zero: bool = false
## allow_zero açıkken bir işlemde 0 çıkma olasılığı.
@export_range(0.0, 0.5, 0.01) var zero_chance: float = 0.15

@export_group("Yanlış seçenekler")
## Yanlış seçenekler doğru cevaba en fazla bu kadar uzak olur (±1, ±2 ...).
@export_range(1, 5) var near_distance: int = 2
## İşlemdeki sayılardan birinin (ör. 5 - 2 için "5" ya da "2") yanlış seçenek olma olasılığı.
@export_range(0.0, 1.0, 0.01) var operand_distractor_chance: float = 0.4

@export_group("Nesneler")
## Kutulardaki nesne türleri; her bölümde biri seçilir (bütün kutularda aynı nesne).
@export var object_textures: Array[Texture2D] = []


func level_count() -> int:
	var total := 0
	for stage in stages:
		if stage:
			total += stage.level_count
	return total


# index: 0'dan başlayan bölüm sırası. Son bölümden sonrası son aşama sayılır.
func stage_for_level(index: int) -> SubtractionStage:
	var start := 0
	for stage in stages:
		if stage == null:
			continue
		start += stage.level_count
		if index < start:
			return stage
	return stages[stages.size() - 1] if not stages.is_empty() else null


# Değerleri denetler; sorunları döndürür (boşsa her şey yolunda)
func problems() -> PackedStringArray:
	var result := PackedStringArray()
	if stages.is_empty():
		result.append("hiç aşama yok")
	if object_textures.is_empty():
		result.append("hiç nesne görseli yok")
	for i in stages.size():
		var stage := stages[i]
		if stage == null:
			result.append("%d. aşama boş" % (i + 1))
			continue
		var low := maxi(stage.part_min, 1)
		if stage.part_min > stage.part_max:
			result.append("%d. aşamada part_min > part_max" % (i + 1))
		if low * 2 > stage.max_minuend:
			result.append("%d. aşamada max_minuend çok küçük: hiçbir işlem sığmıyor" % (i + 1))
		if stage.part_max > 10:
			result.append("%d. aşamada part_max 10'dan büyük: kutuya sığmaz" % (i + 1))
		if stage.max_minuend > 20:
			result.append("%d. aşamada max_minuend 20'den büyük: ilk kutuya sığmaz" % (i + 1))
	return result
