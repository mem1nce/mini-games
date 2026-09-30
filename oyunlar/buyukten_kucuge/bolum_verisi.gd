class_name SizeLevel
extends Resource
# Bir bölümün ayarları (ayarlar.tres içindeki levels listesinde, sırayla).

## Etkinlik türü: halka = Halka Kulesi, dizi = Sıralama Dizisi, bebek = İç İçe Bebekler
@export_enum("halka", "dizi", "bebek") var kind: String = "dizi"
## Nesne sayısı
@export_range(2, 6) var count: int = 3
## Ardışık iki nesne arasındaki boyut farkı (oran): bir küçük nesne = büyük x (1 - step).
## Ayarlar'daki min_step'in altına inemez.
@export_range(0.1, 0.4, 0.01) var step: float = 0.25
## Dizi: yuvalarda gelecek nesnenin kesik çizgili silueti görünür (kolay)
@export var silhouettes: bool = false
## Dizi: soldan sağa küçükten büyüğe (ters yön); yoksa büyükten küçüğe
@export var ascending: bool = false
## Dizi: "boy" bölümü: zürafa, kalem, çiçek, kule; sadece yükseklik değişir (uzundan kısaya)
@export var by_height: bool = false
## Bebek: boy atlama yok (bebek ancak kendinden bir boy büyüğün içine girer); yoksa her büyüğe girebilir
@export var strict: bool = false


func describe() -> String:
	var parts := [kind, str(count), "%d%%" % roundi(step * 100.0)]
	for flag in ["silhouettes", "ascending", "by_height", "strict"]:
		if get(flag):
			parts.append(flag)
	return " ".join(parts)
