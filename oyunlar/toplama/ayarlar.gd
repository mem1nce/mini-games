class_name AdditionSettings
extends Resource
# Toplama Öğreniyorum'un bütün zorluk ayarları (tek yer: ayarlar.tres).
# Bölüm sayısı = aşamaların level_count toplamı. Yeni aşama için Stages dizisine bir AdditionStage ekle.

## Sırayla oynanan aşamalar (her biri birkaç bölüm).
@export var stages: Array[AdditionStage] = []

@export_group("Sayılar")
## Açıksa kutulardan biri bazen boş (0) gelebilir. Küçük çocuklar için kapalı önerilir.
@export var allow_zero: bool = false
## allow_zero açıkken bir işlemde 0 çıkma olasılığı.
@export_range(0.0, 0.5, 0.01) var zero_chance: float = 0.15

@export_group("Yanlış seçenekler")
## Yanlış seçenekler doğru cevaba en fazla bu kadar uzak olur (±1, ±2 ...).
@export_range(1, 5) var near_distance: int = 2
## Toplananlardan birinin (ör. 3 + 2 için "3") yanlış seçenek olma olasılığı.
@export_range(0.0, 1.0, 0.01) var addend_distractor_chance: float = 0.4

@export_group("Nesneler")
## Kutulardaki nesne türleri; her bölümde biri seçilir (iki kutuda aynı nesne).
@export var object_textures: Array[Texture2D] = []


func level_count() -> int:
	var total := 0
	for stage in stages:
		if stage:
			total += stage.level_count
	return total


# index: 0'dan başlayan bölüm sırası. Son bölümden sonrası son aşama sayılır.
func stage_for_level(index: int) -> AdditionStage:
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
		var low := maxi(stage.addend_min, 1)
		if stage.addend_min > stage.addend_max:
			result.append("%d. aşamada addend_min > addend_max" % (i + 1))
		if low * 2 > stage.max_sum:
			result.append("%d. aşamada max_sum çok küçük: hiçbir işlem sığmıyor" % (i + 1))
		if stage.addend_max > 10:
			result.append("%d. aşamada addend_max 10'dan büyük: kutuya sığmaz" % (i + 1))
		if stage.max_sum > 20:
			result.append("%d. aşamada max_sum 20'den büyük: sonuç kutusuna sığmaz" % (i + 1))
	return result
