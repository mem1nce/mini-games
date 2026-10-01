class_name MoleLevelData
extends Resource
# Köstebek Vurma: bir seviyenin zorluk değerleri. Seviyeler denge.tres içindeki Levels dizisinde.
# Olasılıklar: bomb_chance + fruit_chance kadarı bomba/meyve, kalanı köstebek.

## Nesnenin çukurdan tamamen çıktıktan sonra görünür kalma süresi (sn).
@export_range(0.3, 4.0, 0.05) var stay_time: float = 1.5
## İki çıkış arasındaki bekleme (sn): bu ikisi arasında rastgele.
@export_range(0.1, 4.0, 0.05) var spawn_interval_min: float = 1.0
@export_range(0.1, 4.0, 0.05) var spawn_interval_max: float = 1.5
## Aynı anda en fazla kaç çukurda nesne olabilir.
@export_range(1, 5) var max_active: int = 1
## Bir çıkışın bomba olma olasılığı.
@export_range(0.0, 0.4, 0.01) var bomb_chance: float = 0.1
## Bir çıkışın meyve/sebze olma olasılığı.
@export_range(0.0, 0.8, 0.01) var fruit_chance: float = 0.4
## Çıkan bir köstebeğin kasklı olma olasılığı.
@export_range(0.0, 1.0, 0.01) var helmet_chance: float = 0.0
## Çukur sayısı: 6 (2 sütun x 3 satır) ya da 9 (3x3).
@export_enum("6:6", "9:9") var hole_count: int = 6
