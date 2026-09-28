class_name ShadowLevelData
extends Resource
# Gölge Eşleştirme'de bir bölüm (bolumler/bolum_XX.tres). Yeni bölüm için yeni bir .tres oluşturup
# golge_eslestirme.tscn kök düğümündeki "Levels" dizisine eklemek yeterli.

## Bölümdeki eşyalar (genelde 4). Siluetleri birbirinden açıkça farklı olmalı.
@export var items: Array[ShadowItemData] = []
## Arka plan gökyüzü renkleri (üst ve alt).
@export var sky_top: Color = Color("bfe3ff")
@export var sky_bottom: Color = Color("fff1d9")
