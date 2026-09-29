class_name SubtractionStage
extends Resource
# Çıkarma Öğreniyorum: art arda gelen birkaç bölümün ortak zorluk aralığı.
# Aşamalar ayarlar.tres içindeki Stages dizisinde sırayla oynanır.
# İşlem A - B = C; B (çıkan) ve C (sonuç) "parça", A (eksilen) "bütün"dür. Böylece aşamalar
# Toplama'dakilerin tersi olur (Toplama'da 2 + 3 = 5, burada 5 - 2 = 3).

## Bu aşamada kaç bölüm var.
@export_range(1, 20) var level_count: int = 4
## Çıkan sayının ve sonucun en küçüğü ...
@export_range(0, 20) var part_min: int = 1
## ... ve en büyüğü.
@export_range(1, 20) var part_max: int = 3
## Eksilen (ilk kutudaki nesne sayısı) en fazla bu kadar olur.
@export_range(2, 40) var max_minuend: int = 5
## Alttaki cevap düğmesi sayısı.
@export_range(2, 4) var choice_count: int = 3
