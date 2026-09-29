class_name AdditionStage
extends Resource
# Toplama Öğreniyorum: art arda gelen birkaç bölümün ortak zorluk aralığı.
# Aşamalar ayarlar.tres içindeki Stages dizisinde sırayla oynanır.

## Bu aşamada kaç bölüm var.
@export_range(1, 20) var level_count: int = 4
## Toplananların (kutulardaki nesne sayılarının) en küçüğü ...
@export_range(0, 20) var addend_min: int = 1
## ... ve en büyüğü.
@export_range(1, 20) var addend_max: int = 3
## İki sayının toplamı en fazla bu kadar olur.
@export_range(2, 40) var max_sum: int = 5
## Alttaki cevap düğmesi sayısı.
@export_range(2, 4) var choice_count: int = 3
