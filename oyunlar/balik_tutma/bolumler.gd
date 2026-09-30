extends RefCounted
# Balık Tutma bölümleri. Her bölüm bir sözlük:
#   "tema":        gol / deniz / mercan / derin (gökyüzü, su renkleri, dip süsleri; derinde ağda fener)
#   "gorev":       gereksinimler listesi (baloncukta sırayla). Gereksinim: {"adet": N, ...} ve şunlardan istenenler:
#                  "renk", "desen", "boyut", "tur", "isikli": true — ya da çöp için "cop": true.
#                  Bir balık listedeki ilk uyan ve dolmamış gereksinime sayılır (özel olanı öne yaz).
#   "havuz":       bu bölümde yüzen türler (balik_turleri.gd)
#   "balik_sayisi": aynı anda sudaki balık sayısı (çöp bölümünde su temizlendikçe artar)
#   "cop":         sudaki çöp sayısı (şişe, poşet, teneke)
#   "denizanasi":  denizanası sayısı
#   "hiz":         balık hız çarpanı
# Yeni bölüm: LEVELS'e sözlük ekle. validate() her gereksinime havuzda uyan bir tür olduğunu denetler.

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const TEMALAR := ["gol", "deniz", "mercan", "derin"]

const GOL := ["mavi_minik", "kirmizi_top", "sari_minik", "yesil_uzun", "yesil_benekli"]
const DENIZ := ["mavi_cizgili", "kirmizi_benekli", "sari_cizgili", "mavi_minik", "pembe_benekli", "mavi_dev", "kirmizi_dev"]
const MERCAN := ["palyaco", "mor_yassi", "pembe_benekli", "balon", "mor_benekli", "pembe_cizgili", "turuncu_dev"]
const DERIN := ["isikli_mavi", "isikli_pembe", "isikli_yesil", "mavi_dev", "yesil_dev"]

const LEVELS := [
	# --- Göl: tek renk, az balık ---
	{"tema": "gol", "gorev": [{"adet": 3, "renk": "mavi"}], "havuz": ["mavi_minik", "kirmizi_top", "sari_minik"],
		"balik_sayisi": 5, "cop": 0, "denizanasi": 0, "hiz": 0.7},
	{"tema": "gol", "gorev": [{"adet": 3, "renk": "kirmizi"}], "havuz": ["mavi_minik", "kirmizi_top", "sari_minik", "yesil_uzun"],
		"balik_sayisi": 6, "cop": 0, "denizanasi": 0, "hiz": 0.75},
	{"tema": "gol", "gorev": [{"adet": 2, "renk": "sari"}, {"adet": 2, "renk": "yesil"}], "havuz": GOL,
		"balik_sayisi": 6, "cop": 0, "denizanasi": 0, "hiz": 0.8},
	{"tema": "gol", "gorev": [{"adet": 4, "cop": true}], "havuz": GOL,
		"balik_sayisi": 3, "cop": 4, "denizanasi": 0, "hiz": 0.8},
	# --- Deniz: desen, boyut, çöp; denizanası ---
	{"tema": "deniz", "gorev": [{"adet": 2, "desen": "cizgili"}, {"adet": 2, "desen": "benekli"}],
		"havuz": ["mavi_cizgili", "kirmizi_benekli", "sari_cizgili", "mavi_minik", "pembe_benekli"],
		"balik_sayisi": 6, "cop": 0, "denizanasi": 1, "hiz": 0.85},
	{"tema": "deniz", "gorev": [{"adet": 1, "boyut": "buyuk"}, {"adet": 2, "boyut": "kucuk"}],
		"havuz": ["mavi_dev", "kirmizi_dev", "mavi_minik", "sari_minik", "kirmizi_top", "mavi_cizgili"],
		"balik_sayisi": 7, "cop": 0, "denizanasi": 1, "hiz": 0.85},
	{"tema": "deniz", "gorev": [{"adet": 5, "cop": true}], "havuz": DENIZ,
		"balik_sayisi": 3, "cop": 5, "denizanasi": 1, "hiz": 0.9},
	{"tema": "deniz", "gorev": [{"adet": 2, "renk": "kirmizi", "desen": "benekli"}, {"adet": 2, "renk": "mavi", "desen": "cizgili"}],
		"havuz": ["kirmizi_benekli", "mavi_cizgili", "kirmizi_top", "mavi_minik", "sari_cizgili", "pembe_benekli"],
		"balik_sayisi": 7, "cop": 0, "denizanasi": 2, "hiz": 0.9},
	# --- Mercan resifi: sayı, boyut, çöp, karışık ---
	{"tema": "mercan", "gorev": [{"adet": 4, "desen": "cizgili"}],
		"havuz": ["palyaco", "pembe_cizgili", "sari_cizgili", "mor_yassi", "pembe_benekli"],
		"balik_sayisi": 7, "cop": 0, "denizanasi": 1, "hiz": 0.95},
	{"tema": "mercan", "gorev": [{"adet": 1, "renk": "sari", "boyut": "buyuk"}, {"adet": 3, "boyut": "kucuk"}],
		"havuz": ["balon", "palyaco", "mor_benekli", "pembe_benekli", "mor_yassi", "turuncu_dev"],
		"balik_sayisi": 7, "cop": 0, "denizanasi": 2, "hiz": 0.95},
	{"tema": "mercan", "gorev": [{"adet": 6, "cop": true}], "havuz": MERCAN,
		"balik_sayisi": 3, "cop": 6, "denizanasi": 1, "hiz": 1.0},
	{"tema": "mercan", "gorev": [{"adet": 2, "renk": "mor"}, {"adet": 2, "renk": "turuncu"}, {"adet": 1, "desen": "benekli"}],
		"havuz": ["mor_yassi", "mor_benekli", "palyaco", "turuncu_dev", "pembe_cizgili", "balon", "pembe_benekli"],
		"balik_sayisi": 8, "cop": 0, "denizanasi": 2, "hiz": 1.0},
	# --- Derin deniz: karanlık, ışıklı balıklar, nadir fener balığı ---
	{"tema": "derin", "gorev": [{"adet": 3, "isikli": true}], "havuz": ["isikli_mavi", "isikli_pembe", "isikli_yesil", "mavi_dev"],
		"balik_sayisi": 6, "cop": 0, "denizanasi": 1, "hiz": 0.8},
	{"tema": "derin", "gorev": [{"adet": 1, "tur": "fener"}, {"adet": 2, "isikli": true}],
		"havuz": ["fener", "isikli_mavi", "isikli_pembe", "isikli_yesil"],
		"balik_sayisi": 6, "cop": 0, "denizanasi": 2, "hiz": 0.8},
	{"tema": "derin", "gorev": [{"adet": 5, "cop": true}], "havuz": DERIN,
		"balik_sayisi": 3, "cop": 5, "denizanasi": 2, "hiz": 0.85},
	{"tema": "derin", "gorev": [{"adet": 1, "tur": "fener"}, {"adet": 2, "isikli": true}, {"adet": 2, "boyut": "buyuk"}],
		"havuz": ["fener", "mavi_dev", "yesil_dev", "isikli_mavi", "isikli_pembe", "isikli_yesil"],
		"balik_sayisi": 7, "cop": 0, "denizanasi": 2, "hiz": 0.85},
]


static func level(index: int) -> Dictionary:
	return LEVELS[posmod(index, LEVELS.size())]


static func validate() -> PackedStringArray:
	var hatalar := PackedStringArray()
	for i in LEVELS.size():
		var data: Dictionary = LEVELS[i]
		var ad := "bölüm %d" % (i + 1)
		if not data["tema"] in TEMALAR:
			hatalar.append("%s: bilinmeyen tema" % ad)
		for tur in data["havuz"]:
			if not Turler.TURLER.has(tur):
				hatalar.append("%s: bilinmeyen tür %s" % [ad, tur])
		var toplam := 0
		for g in data["gorev"]:
			toplam += int(g["adet"])
			if g.get("cop", false):
				if int(data["cop"]) < int(g["adet"]):
					hatalar.append("%s: çöp sayısı görevden az" % ad)
				continue
			var uyan: Array = data["havuz"].filter(func(t: String) -> bool: return Turler.eslesir(g, {"tur": t}))
			if uyan.is_empty():
				hatalar.append("%s: %s gereksinimine uyan tür havuzda yok" % [ad, g])
		if toplam > 6:
			hatalar.append("%s: baloncuğa en fazla 6 simge sığar" % ad)
	return hatalar
