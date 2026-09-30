extends RefCounted
# Balık türleri ve görev eşleşmesi. Yeni tür: gorseller/svg_uret.py TURLER'e ekle (görsel), sonra buraya satır.
#   renk:     kirmizi / mavi / sari / yesil / turuncu / mor / pembe (görevlerde istenebilen renkler);
#             nadirlerde altin / gokkusagi / lacivert / gece
#   desen:    duz / cizgili / benekli / yildiz / gokkusagi / isikli
#   boyut:    kucuk / orta / buyuk (ekrandaki boy: BOYLAR)
#   derinlik: [en sığ, en derin], 0 = yüzey, 1 = dip
#   hiz:      px/sn (bölümün hız çarpanıyla çarpılır)
#   nadir:    havuzda olmasa da kendi temasında ara sıra gelir (NADIR_TEMA)
#   isik:     ışıklı balığın ışık rengi (derin deniz)

const G := "res://oyunlar/balik_tutma/gorseller/"
const BOYLAR := {"kucuk": 92.0, "orta": 124.0, "buyuk": 168.0}

const TURLER := {
	"mavi_minik": {"renk": "mavi", "desen": "duz", "boyut": "kucuk", "derinlik": [0.05, 0.45], "hiz": 115.0},
	"kirmizi_top": {"renk": "kirmizi", "desen": "duz", "boyut": "orta", "derinlik": [0.1, 0.55], "hiz": 85.0},
	"sari_minik": {"renk": "sari", "desen": "duz", "boyut": "kucuk", "derinlik": [0.05, 0.4], "hiz": 110.0},
	"yesil_uzun": {"renk": "yesil", "desen": "duz", "boyut": "orta", "derinlik": [0.2, 0.7], "hiz": 95.0},
	"mavi_cizgili": {"renk": "mavi", "desen": "cizgili", "boyut": "orta", "derinlik": [0.15, 0.6], "hiz": 90.0},
	"kirmizi_benekli": {"renk": "kirmizi", "desen": "benekli", "boyut": "orta", "derinlik": [0.2, 0.65], "hiz": 85.0},
	"sari_cizgili": {"renk": "sari", "desen": "cizgili", "boyut": "orta", "derinlik": [0.1, 0.55], "hiz": 95.0},
	"yesil_benekli": {"renk": "yesil", "desen": "benekli", "boyut": "kucuk", "derinlik": [0.1, 0.5], "hiz": 105.0},
	"palyaco": {"renk": "turuncu", "desen": "cizgili", "boyut": "kucuk", "derinlik": [0.3, 0.8], "hiz": 100.0},
	"mor_yassi": {"renk": "mor", "desen": "duz", "boyut": "orta", "derinlik": [0.25, 0.75], "hiz": 70.0},
	"pembe_benekli": {"renk": "pembe", "desen": "benekli", "boyut": "kucuk", "derinlik": [0.1, 0.6], "hiz": 105.0},
	"mavi_dev": {"renk": "mavi", "desen": "duz", "boyut": "buyuk", "derinlik": [0.4, 0.9], "hiz": 60.0},
	"kirmizi_dev": {"renk": "kirmizi", "desen": "cizgili", "boyut": "buyuk", "derinlik": [0.4, 0.9], "hiz": 60.0},
	"balon": {"renk": "sari", "desen": "benekli", "boyut": "buyuk", "derinlik": [0.3, 0.85], "hiz": 50.0},
	"yesil_dev": {"renk": "yesil", "desen": "cizgili", "boyut": "buyuk", "derinlik": [0.45, 0.95], "hiz": 58.0},
	"mor_benekli": {"renk": "mor", "desen": "benekli", "boyut": "kucuk", "derinlik": [0.3, 0.8], "hiz": 100.0},
	"turuncu_dev": {"renk": "turuncu", "desen": "benekli", "boyut": "buyuk", "derinlik": [0.4, 0.9], "hiz": 58.0},
	"pembe_cizgili": {"renk": "pembe", "desen": "cizgili", "boyut": "orta", "derinlik": [0.2, 0.7], "hiz": 80.0},
	"altin": {"renk": "altin", "desen": "duz", "boyut": "orta", "derinlik": [0.3, 0.8], "hiz": 70.0, "nadir": true},
	"gokkusagi": {"renk": "gokkusagi", "desen": "gokkusagi", "boyut": "orta", "derinlik": [0.4, 0.85], "hiz": 75.0, "nadir": true},
	"yildizli": {"renk": "lacivert", "desen": "yildiz", "boyut": "orta", "derinlik": [0.5, 0.9], "hiz": 65.0, "nadir": true},
	"fener": {"renk": "gece", "desen": "isikli", "boyut": "buyuk", "derinlik": [0.7, 1.0], "hiz": 38.0, "nadir": true, "isik": Color("ffe066")},
	"isikli_mavi": {"renk": "gece", "desen": "isikli", "boyut": "kucuk", "derinlik": [0.35, 0.95], "hiz": 70.0, "isik": Color("7ff0ff")},
	"isikli_pembe": {"renk": "gece", "desen": "isikli", "boyut": "kucuk", "derinlik": [0.35, 0.95], "hiz": 65.0, "isik": Color("ff9ce0")},
	"isikli_yesil": {"renk": "gece", "desen": "isikli", "boyut": "orta", "derinlik": [0.5, 1.0], "hiz": 55.0, "isik": Color("a8ff8a")},
}

# Havuzda olmasa da temasında ara sıra gelen nadir türler
const NADIR_TEMA := {"gol": ["altin"], "deniz": ["altin"], "mercan": ["gokkusagi", "yildizli"], "derin": ["fener"]}
const NADIR_SANSI := 0.08

# Akvaryumdaki sıra
const SIRA := ["mavi_minik", "sari_minik", "kirmizi_top", "yesil_uzun", "yesil_benekli",
	"mavi_cizgili", "kirmizi_benekli", "sari_cizgili", "pembe_benekli", "pembe_cizgili",
	"palyaco", "mor_yassi", "mor_benekli", "balon", "turuncu_dev",
	"mavi_dev", "kirmizi_dev", "yesil_dev", "isikli_mavi", "isikli_pembe",
	"isikli_yesil", "altin", "gokkusagi", "yildizli", "fener"]


static func tur(ad: String) -> Dictionary:
	return TURLER[ad]


static func doku(ad: String) -> Texture2D:
	return load(G + "baliklar/%s.svg" % ad)


static func boy(ad: String) -> float:
	return BOYLAR[TURLER[ad]["boyut"]]


# Görev gereksinimi bu nesneye uyuyor mu? Nesne: {"tur": ad} ya da {"cop": true}
static func eslesir(gereksinim: Dictionary, nesne: Dictionary) -> bool:
	if gereksinim.get("cop", false):
		return nesne.get("cop", false)
	if nesne.get("cop", false):
		return false
	var t: Dictionary = TURLER[nesne["tur"]]
	if gereksinim.has("tur") and gereksinim["tur"] != nesne["tur"]:
		return false
	for alan in ["renk", "desen", "boyut"]:
		if gereksinim.has(alan) and gereksinim[alan] != t[alan]:
			return false
	if gereksinim.get("isikli", false) and not t.has("isik"):
		return false
	return true


# Baloncuktaki simge (bir adet için)
static func ikon(gereksinim: Dictionary) -> Texture2D:
	if gereksinim.get("cop", false):
		return load(G + "cop_sise.svg")
	if gereksinim.has("tur"):
		return doku(gereksinim["tur"])
	if gereksinim.get("isikli", false):
		return load(G + "ikonlar/ikon_isikli.svg")
	var renk: String = gereksinim.get("renk", "herhangi")
	var desen: String = gereksinim.get("desen", "duz")
	return load(G + "ikonlar/ikon_%s_%s.svg" % [renk, desen])
