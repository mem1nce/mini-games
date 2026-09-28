extends RefCounted
# Hafıza oyununun temaları ve bölümleri.
#
# Yeni tema eklemek için:
#   1) temalar/ altına yeni bir klasör aç, içine resimleri (256x256 SVG) ve kart arka yüzünü (arka.svg) koy
#   2) THEMES listesine bir satır ekle. "items" en az en büyük bölümdeki çift sayısı kadar (8) olmalı.
#
# Yeni bölüm eklemek için LEVELS listesine bir satır ekle (sütun x satır çift sayı olmalı).

const THEMES := [
	{
		"id": "hayvanlar",
		"folder": "res://oyunlar/hafiza/temalar/hayvanlar/",
		"items": ["aslan", "fil", "zurafa", "panda", "tavsan", "penguen", "kaplumbaga", "baykus"],
		"icon": "aslan",                               # tema düğmesinde görünen resim
		"sky": [Color("a9dcff"), Color("e8f8d8")],     # arka plan renk geçişi (üst, alt)
		"accent": Color("ff7f6b"),                     # düğme ve vurgu rengi
	},
	{
		"id": "meyveler",
		"folder": "res://oyunlar/hafiza/temalar/meyveler/",
		"items": ["cilek", "elma", "muz", "karpuz", "uzum", "portakal", "kiraz", "ananas"],
		"icon": "cilek",
		"sky": [Color("ffd9c2"), Color("ffeef6")],
		"accent": Color("2fb59a"),
	},
]

# preview: bölüm başında bütün kartlar kısa süre açık gösterilir
const LEVELS := [
	{"cols": 2, "rows": 2, "preview": true},
	{"cols": 2, "rows": 3, "preview": true},
	{"cols": 3, "rows": 4, "preview": false},
	{"cols": 4, "rows": 4, "preview": false},
]
