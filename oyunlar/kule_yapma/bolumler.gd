extends RefCounted
# Kule Yapma bölümleri. Her bölüm bir sözlük:
#   "hedef":    kat sayısı (son kat çatı katıdır; zemin kat sayılmaz)
#   "hiz":      sallanma hızı (radyan/sn); çok yavaş artar
#   "aci":      sallanma açısı (radyan); halat 170 px, yani kat ±sin(aci)*170 px gider
#   "dikey":    sallanırken yukarı aşağı oynama (px); 0 = yok
#   "tolerans": mıknatıs: |kayma| <= tolerans * kat genişliği ise kat oturur (1 = neredeyse her dokunuş)
#   "tema":     zemin (cayir / sahil / kar / sehir)
# Yeni bölüm: LEVELS'e sözlük ekle. LEVELS bitince SONSUZ ayarlarıyla "Ne kadar yükseğe?" modu (hedef yok).

const TEMALAR := ["cayir", "sahil", "kar", "sehir"]

const LEVELS := [
	{"hedef": 5, "hiz": 1.5, "aci": 0.42, "dikey": 0.0, "tolerans": 0.92, "tema": "cayir"},
	{"hedef": 6, "hiz": 1.55, "aci": 0.45, "dikey": 0.0, "tolerans": 0.88, "tema": "cayir"},
	{"hedef": 7, "hiz": 1.6, "aci": 0.48, "dikey": 0.0, "tolerans": 0.84, "tema": "sahil"},
	{"hedef": 8, "hiz": 1.65, "aci": 0.5, "dikey": 0.0, "tolerans": 0.8, "tema": "sahil"},
	{"hedef": 9, "hiz": 1.7, "aci": 0.53, "dikey": 0.0, "tolerans": 0.76, "tema": "kar"},
	{"hedef": 10, "hiz": 1.75, "aci": 0.56, "dikey": 0.0, "tolerans": 0.72, "tema": "kar"},
	{"hedef": 11, "hiz": 1.8, "aci": 0.58, "dikey": 10.0, "tolerans": 0.7, "tema": "sehir"},
	{"hedef": 12, "hiz": 1.85, "aci": 0.6, "dikey": 14.0, "tolerans": 0.68, "tema": "sehir"},
	{"hedef": 14, "hiz": 1.9, "aci": 0.62, "dikey": 18.0, "tolerans": 0.66, "tema": "cayir"},
	{"hedef": 16, "hiz": 1.95, "aci": 0.64, "dikey": 22.0, "tolerans": 0.64, "tema": "sahil"},
	{"hedef": 18, "hiz": 2.0, "aci": 0.66, "dikey": 26.0, "tolerans": 0.62, "tema": "kar"},
	{"hedef": 20, "hiz": 2.05, "aci": 0.68, "dikey": 30.0, "tolerans": 0.6, "tema": "sehir"},
]

# 12. bölümden sonra: "Ne kadar yükseğe?" (hedef 0 = sınırsız)
const SONSUZ := {"hedef": 0, "hiz": 2.05, "aci": 0.68, "dikey": 30.0, "tolerans": 0.6, "tema": "cayir"}


static func level(index: int) -> Dictionary:
	if index < LEVELS.size():
		return LEVELS[index]
	return SONSUZ


static func sonsuz_mu(index: int) -> bool:
	return index >= LEVELS.size()


static func validate() -> PackedStringArray:
	var hatalar := PackedStringArray()
	for i in LEVELS.size():
		var d: Dictionary = LEVELS[i]
		if int(d["hedef"]) < 2 or int(d["hedef"]) > 20:
			hatalar.append("bölüm %d: hedef 2-20 olmalı" % (i + 1))
		if not d["tema"] in TEMALAR:
			hatalar.append("bölüm %d: bilinmeyen tema" % (i + 1))
		if float(d["tolerans"]) <= 0.0 or float(d["tolerans"]) > 1.0:
			hatalar.append("bölüm %d: tolerans 0-1 arası olmalı" % (i + 1))
	return hatalar
