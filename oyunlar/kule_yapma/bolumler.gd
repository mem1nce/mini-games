extends RefCounted
# Kule Yapma bölümleri. Her bölüm bir sözlük (hepsi kolayca değiştirilebilir):
#   "hedef":       kat sayısı (son kat çatı katıdır; zemin kat sayılmaz)
#   "hiz":         vinç sallanma hızı (radyan/sn)
#   "aci":         sallanma açısı (radyan); halat 140 px, yani kat ±sin(aci)*140 px gider
#   "dikey":       sallanırken yukarı aşağı oynama (px); 0 = yok
#   "miknatis":    mıknatıs payı (kat genişliğinin oranı): alttaki katın ortasına bu kadar yakın bırakılan kat ortaya
#                  kayar; daha uzaktaki kat bırakıldığı yerde kaymış olarak kalır
#   "egim_siniri": kulenin en fazla eğimi (en üst katın zemin kata göre yatay kayması, kat genişliği cinsinden);
#                  aşılırsa en üstteki 1-2 kat devrilir ve 1 kalp gider
#   "kalp":        bölümdeki kalp sayısı (art arda 3 mükemmel 1 kalp geri verir, bu sayıyı geçmez)
#   "tema":        zemin (cayir / sahil / kar / sehir)
# Ağırlık merkezi alttaki katın kenarından dışarıda kalan kat her zaman devrilir (1 kalp).
# Yeni bölüm: LEVELS'e sözlük ekle. LEVELS bitince SONSUZ ayarlarıyla "Ne kadar yükseğe?" modu (hedef yok, rekor).

const TEMALAR := ["cayir", "sahil", "kar", "sehir"]

const LEVELS := [
	# İlk iki bölüm kolay: geniş mıknatıs, yavaş vinç, az kat, çok eğime izin
	{"hedef": 5, "hiz": 1.3, "aci": 0.36, "dikey": 0.0, "miknatis": 0.15, "egim_siniri": 1.0, "kalp": 3, "tema": "cayir"},
	{"hedef": 6, "hiz": 1.35, "aci": 0.38, "dikey": 0.0, "miknatis": 0.15, "egim_siniri": 0.95, "kalp": 3, "tema": "cayir"},
	{"hedef": 7, "hiz": 1.5, "aci": 0.44, "dikey": 0.0, "miknatis": 0.13, "egim_siniri": 0.85, "kalp": 3, "tema": "sahil"},
	{"hedef": 8, "hiz": 1.6, "aci": 0.48, "dikey": 0.0, "miknatis": 0.12, "egim_siniri": 0.8, "kalp": 3, "tema": "sahil"},
	{"hedef": 9, "hiz": 1.7, "aci": 0.52, "dikey": 0.0, "miknatis": 0.11, "egim_siniri": 0.75, "kalp": 3, "tema": "kar"},
	{"hedef": 10, "hiz": 1.75, "aci": 0.55, "dikey": 0.0, "miknatis": 0.1, "egim_siniri": 0.72, "kalp": 3, "tema": "kar"},
	{"hedef": 11, "hiz": 1.8, "aci": 0.58, "dikey": 10.0, "miknatis": 0.09, "egim_siniri": 0.68, "kalp": 3, "tema": "sehir"},
	{"hedef": 12, "hiz": 1.85, "aci": 0.6, "dikey": 14.0, "miknatis": 0.08, "egim_siniri": 0.65, "kalp": 3, "tema": "sehir"},
	{"hedef": 14, "hiz": 1.9, "aci": 0.62, "dikey": 18.0, "miknatis": 0.07, "egim_siniri": 0.62, "kalp": 3, "tema": "cayir"},
	{"hedef": 16, "hiz": 1.95, "aci": 0.64, "dikey": 22.0, "miknatis": 0.06, "egim_siniri": 0.6, "kalp": 3, "tema": "sahil"},
	{"hedef": 18, "hiz": 2.0, "aci": 0.66, "dikey": 26.0, "miknatis": 0.055, "egim_siniri": 0.57, "kalp": 3, "tema": "kar"},
	{"hedef": 20, "hiz": 2.05, "aci": 0.68, "dikey": 30.0, "miknatis": 0.05, "egim_siniri": 0.55, "kalp": 3, "tema": "sehir"},
]

# 12. bölümden sonra: "Ne kadar yükseğe?" (hedef 0 = sınırsız)
const SONSUZ := {"hedef": 0, "hiz": 2.05, "aci": 0.68, "dikey": 30.0, "miknatis": 0.05, "egim_siniri": 0.55, "kalp": 3, "tema": "cayir"}


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
		for alan in ["hedef", "hiz", "aci", "dikey", "miknatis", "egim_siniri", "kalp", "tema"]:
			if not d.has(alan):
				hatalar.append("bölüm %d: '%s' yok" % [i + 1, alan])
		if int(d.get("hedef", 0)) < 2 or int(d.get("hedef", 0)) > 20:
			hatalar.append("bölüm %d: hedef 2-20 olmalı" % (i + 1))
		if not d.get("tema") in TEMALAR:
			hatalar.append("bölüm %d: bilinmeyen tema" % (i + 1))
		if float(d.get("miknatis", 0)) <= 0.0 or float(d.get("miknatis", 0)) > 0.5:
			hatalar.append("bölüm %d: mıknatıs 0-0.5 arası olmalı" % (i + 1))
		if float(d.get("egim_siniri", 0)) <= 0.0:
			hatalar.append("bölüm %d: eğim sınırı pozitif olmalı" % (i + 1))
		if int(d.get("kalp", 0)) < 1:
			hatalar.append("bölüm %d: en az 1 kalp" % (i + 1))
	return hatalar
