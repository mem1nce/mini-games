class_name FeedSettings
extends Resource
# Hayvanları Besle'nin bütün bölüm ayarları (tek yer: ayarlar.tres). Bölüm sayısı = aşamaların
# level_count toplamı. Yeni aşama için Stages dizisine bir FeedStage, yeni hayvan için Animals'a ekle.

## Oyundaki hayvanlar (her bölümde aralarından rastgele seçilir)
@export var animals: Array[FeedAnimalData] = []
## Sırayla oynanan aşamalar (her biri birkaç bölüm)
@export var stages: Array[FeedStage] = []


func level_count() -> int:
	var total := 0
	for stage in stages:
		if stage:
			total += stage.level_count
	return total


# index: 0'dan başlayan bölüm sırası. Son bölümden sonrası son aşama sayılır.
func stage_for_level(index: int) -> FeedStage:
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
	var ids := {}
	for animal in animals:
		if animal == null:
			result.append("boş hayvan")
			continue
		if ids.has(animal.id):
			result.append("'%s' iki kez var" % animal.id)
		ids[animal.id] = true
		if animal.body_texture == null or animal.head_texture == null:
			result.append("%s: görseli eksik" % animal.id)
		if animal.voice == null:
			result.append("%s: sesi yok" % animal.id)
		if animal.accepts.is_empty():
			result.append("%s: yediği yiyecek yok" % animal.id)
		for food in animal.accepts:
			if food == null or food.texture == null:
				result.append("%s: görseli olmayan yiyecek" % animal.id)
	for i in stages.size():
		var stage := stages[i]
		if stage == null:
			result.append("%d. aşama boş" % (i + 1))
			continue
		if stage.want_min > stage.want_max:
			result.append("%d. aşama: want_min want_max'tan büyük" % (i + 1))
		if stage.animal_count + stage.distractor_count > animals.size():
			result.append("%d. aşama: yeterli hayvan yok (%d hayvan + %d çeldirici)" % [i + 1, stage.animal_count, stage.distractor_count])
	return result
