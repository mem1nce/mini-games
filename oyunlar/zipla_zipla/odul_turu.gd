class_name JumpRewardType
extends Resource
# Zıpla Zıpla'da bir ödül türü (lolipop, kurabiye...). Türler denge.tres içindeki `rewards` dizisinde.
# Hepsi aynı sayaçta toplanır; farklı türlere farklı puan vermek için `points` değiştirilir.

## Tür adı (kayıt ve testler için)
@export var id: String = ""
## Ödülün görseli
@export var texture: Texture2D
## Toplanınca sayaca eklenen puan
@export_range(1, 10) var points: int = 1
## Seçilme ağırlığı: diğer türlere göre ne sıklıkta çıkar (0 = hiç çıkmaz)
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Toplanınca çıkan ışıltıların rengi
@export var sparkle_color: Color = Color.WHITE
