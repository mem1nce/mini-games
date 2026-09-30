class_name FeedStage
extends Resource
# Hayvanları Besle: art arda gelen birkaç bölümün ortak zorluğu. Aşamalar ayarlar.tres içindeki
# Stages dizisinde sırayla oynanır.

## Bu aşamada kaç bölüm var
@export_range(1, 20) var level_count: int = 3
## Ekrandaki hayvan sayısı
@export_range(1, 4) var animal_count: int = 2
## Her hayvanın istediği yiyecek adedi en az ...
@export_range(1, 3) var want_min: int = 1
## ... ve en fazla (düşünce balonunda o kadar nokta olur)
@export_range(1, 3) var want_max: int = 1
## Düşünce balonu her zaman görünür mü? Kapalıysa sadece ipucu olarak (boşta kalınca / dokununca) belirir.
@export var bubble_always: bool = true
## Hiçbir hayvanın yemediği fazladan (çeldirici) yiyecek sayısı
@export_range(0, 2) var distractor_count: int = 0
