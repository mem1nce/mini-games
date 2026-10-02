extends RefCounted
# Uçan Kuş engel desenleri: direkler tek tek rastgele değil, 3-6 direklik desenler halinde gelir.
# Bu dosya saf hesaptır (sahne yok): uret() bir sonraki desenin engel listesini döner, oyun sırayla ekrana koyar.
#
# DESEN LİSTESİ (kolayca düzenlenir; yeni desen = listeye bir satır):
#   ad       desenin adı (testlerde ve hata ayıklamada görünür)
#   kolay    true ise ilk kolay puanlarda da gelir; false olanlar ancak easy_until_score'dan sonra
#   adimlar  her direğin boşluk merkezi, "basamak" biriminde (- yukarı, + aşağı). Bir basamak, kuşun iki direk
#            arasında rahatça çıkabildiği yüksekliğin BASAMAK_ORANI kadarıdır; desen ekrana sığmazsa küçülür.
#   bosluk   boşluk çarpanı (1 = normal; düz koridorda biraz dar)
#   ara      her direkten ÖNCEKİ mesafe çarpanı (1 = normal aralık). Büyük sıçramadan önce daha uzun mesafe.
#   aynala   true ise rastgele baş aşağı çevrilebilir (yukarı ↔ aşağı)
#   sade     true ise desene kalın ya da hareketli direk gelmez (desenin kendisi zaten bir zorluk taşıyor)
const DESENLER := [
	{"ad": "merdiven_yukari", "kolay": true, "adimlar": [1.5, 0.5, -0.5, -1.5]},
	{"ad": "merdiven_asagi", "kolay": true, "adimlar": [-1.5, -0.5, 0.5, 1.5]},
	{"ad": "dalga", "kolay": true, "adimlar": [0.0, -0.8, -1.2, -0.8, 0.0, 0.8], "aynala": true},
	{"ad": "koridor", "kolay": true, "adimlar": [0.0, 0.0, 0.0], "bosluk": 0.88, "sade": true},
	{"ad": "zikzak", "kolay": false, "adimlar": [0.85, -0.85, 0.85, -0.85, 0.85], "aynala": true, "sade": true},
	{"ad": "surpriz", "kolay": false, "adimlar": [1.4, 1.4, 1.4, -1.5], "ara": [1.0, 1.0, 1.0, 1.75], "sade": true},
]

const BASAMAK_ORANI := 0.55        # bir basamak = en büyük rahat yükseklik farkının bu kadarı
# Desenle birlikte gelebilen engel çeşitleri (listede çok geçen daha sık gelir). Bir desene tek çeşit gelir.
const KATKILAR := ["yok", "yok", "ince", "kalin", "hareketli", "hareketli"]
const SADE_KATKILAR := ["yok", "yok", "ince"]      # "sade" desenlere ikinci bir zorluk binmez
const BULUT_YARI_BOY := 50.0       # bulut engelin yarı yüksekliği (ucan_kus.gd CLOUD_RADII.y ile uyumlu)
const BULUT_YOL_ORANI := 0.4       # bulutun üstünden / altından geçen yolun merkezi: yarı boy + boşluk x bu oran
const ERISIM_PAYI := 0.9           # yükseklik farkları, yetişilebilen en büyük farkın bu kadarını geçmez


## Bir sonraki deseni üretir. Dönen her engel bir sözlük:
##   tip "direk" / "bulut", y (boşluğun ya da bulutun merkezi), bosluk (px), ara (önceki engelden sonraki mesafe
##   çarpanı), kalinlik "ince"/"orta"/"kalin", hareket (px; 0 = sabit), yildiz, kalp, desen (ad), katki, zor
## ortam: ust / alt (boşluğun girebileceği en üst ve en alt y), bosluk (şu anki boşluk, px),
##   en_fazla_kayma (normal aralıkta rahatça aşılan yükseklik farkı, px), nefes (desenler arası mesafe çarpanı),
##   en_fazla_ara (bir sonraki engel ekranda görünsün diye mesafe çarpanının üst sınırı),
##   kolay_puan, kolay_bosluk, en_az_bosluk, kalin_puan, hareketli_puan, hareket_payi, bulut_puan, bulut_sansi,
##   yildiz_sansi, kalp_izni, son_desen, son_bulut,
##   hareketli_sart (uzun süredir hareketli direk gelmediyse true: uygun ilk desen hareketli olur)
static func uret(sira: int, onceki_y: float, ortam: Dictionary, rng: RandomNumberGenerator) -> Array:
	var engeller: Array = []
	var bulutlu := false
	var baslangic_y := onceki_y
	var kayma := float(ortam["en_fazla_kayma"])
	var en_fazla_ara := float(ortam.get("en_fazla_ara", 99.0))
	var nefes := minf(float(ortam["nefes"]), en_fazla_ara)

	# Bulut engel: desenler arasındaki nefes boşluğunda tek başına gelir, ardından kolay ve sade bir desen
	if sira >= int(ortam["bulut_puan"]) and not ortam.get("son_bulut", false) and rng.randf() < float(ortam["bulut_sansi"]):
		var pay := float(ortam["bosluk"]) * 0.72 + BULUT_YARI_BOY      # bulutun üstünde ve altında geçecek yer kalsın
		var ust := float(ortam["ust"]) + pay
		var alt := float(ortam["alt"]) - pay
		var erisim_bulut := kayma * nefes * ERISIM_PAYI
		var bulut_y := clampf(onceki_y + rng.randf_range(-0.5, 0.5) * erisim_bulut, ust, alt)
		# Bulutun üstünden ya da altından geçen yollardan en az biri, önceki boşluktan rahatça yetişilebilir olmalı
		var yol_payi := BULUT_YARI_BOY + float(ortam["bosluk"]) * BULUT_YOL_ORANI
		var en_yakin_yol := minf(absf(bulut_y - yol_payi - onceki_y), absf(bulut_y + yol_payi - onceki_y))
		if alt >= ust and en_yakin_yol <= erisim_bulut:
			engeller.append({"tip": "bulut", "y": bulut_y, "bosluk": 0.0, "ara": nefes, "kalinlik": "orta",
				"hareket": 0.0, "yildiz": false, "kalp": false, "desen": "bulut", "katki": "bulut", "zor": false})
			bulutlu = true
			baslangic_y = bulut_y
			sira += 1

	# Deseni seç: önceki boşluktan rahatça yetişilen ilk aday alınır (hiçbiri yetişmiyorsa sonuncusu, uzun nefesle)
	var sadece_kolay := sira < int(ortam["kolay_puan"]) or bulutlu
	var secim := {}
	var hareketli_sart: bool = ortam.get("hareketli_sart", false) and not bulutlu and sira >= int(ortam["hareketli_puan"])
	for aday: Dictionary in _adaylar(sadece_kolay, str(ortam.get("son_desen", "")), hareketli_sart, rng):
		secim = _yerlestir(aday, sira, baslangic_y, bulutlu, nefes, ortam, rng)
		if secim["sigdi"]:
			break

	var desen: Dictionary = secim["desen"]
	var katki: String = secim["katki"]
	var adimlar: Array = secim["adimlar"]
	var yildizli: bool = katki != "hareketli" and rng.randf() < float(ortam["yildiz_sansi"])
	for i in adimlar.size():
		var kalinlik := "orta"
		if katki == "ince":
			kalinlik = "ince"
		elif katki == "kalin" and i % 2 == 0:
			kalinlik = "kalin"
		engeller.append({
			"tip": "direk", "y": float(secim["yer"]) + float(adimlar[i]) * float(secim["basamak"]),
			"bosluk": secim["bosluk"], "ara": float(secim["aralar"][i]), "kalinlik": kalinlik,
			"hareket": float(secim["hareket"]) if (katki == "hareketli" and i % 2 == 1) else 0.0,
			"yildiz": yildizli, "kalp": false, "desen": desen["ad"], "katki": katki, "zor": not desen["kolay"],
		})
	# Kalp: eksik can varsa, kolay ve sade bir desenin son boşluğunda
	if ortam.get("kalp_izni", false) and desen["kolay"] and katki != "hareketli":
		engeller[-1]["kalp"] = true
	return engeller


# Bir deseni ekrana yerleştirir: engel çeşidi, boşluk, basamak boyu, desenin yeri ve direkler arası mesafeler.
# "sigdi": ilk direk önceki engelden rahatça yetişilen yükseklikte mi
static func _yerlestir(desen: Dictionary, sira: int, baslangic_y: float, bulutlu: bool, nefes: float,
		ortam: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var kayma := float(ortam["en_fazla_kayma"])
	var en_fazla_ara := float(ortam.get("en_fazla_ara", 99.0))
	var katki := _katki_sec(desen, sira, bulutlu, ortam, rng)

	var adimlar: Array = (desen["adimlar"] as Array).duplicate()
	if desen.get("aynala", false) and rng.randf() < 0.5:
		for i in adimlar.size():
			adimlar[i] = -float(adimlar[i])
	# Her direkten önceki mesafe çarpanı (ilki desenler arası nefes); hiçbiri ekrandan uzun olmaz
	var aralar: Array = []
	var verilen: Array = desen.get("ara", [])
	for i in adimlar.size():
		aralar.append(minf(float(verilen[i]) if i < verilen.size() else 1.0, en_fazla_ara))
	aralar[0] = nefes

	var bosluk := float(ortam["bosluk"]) * float(desen.get("bosluk", 1.0))
	if sira < int(ortam["kolay_puan"]):
		bosluk *= float(ortam["kolay_bosluk"])
	bosluk = maxf(bosluk, float(ortam["en_az_bosluk"]))
	var hareket := float(ortam["hareket_payi"]) if katki == "hareketli" else 0.0

	# Boşluk merkezinin girebileceği aralık ve basamak boyu
	var en_ust := float(ortam["ust"]) + bosluk / 2.0 + hareket
	var en_alt := float(ortam["alt"]) - bosluk / 2.0 - hareket
	if en_alt < en_ust:
		en_ust = (float(ortam["ust"]) + float(ortam["alt"])) / 2.0
		en_alt = en_ust
	var dusuk: float = adimlar.min()
	var yuksek: float = adimlar.max()
	var basamak := kayma * BASAMAK_ORANI
	if yuksek > dusuk:
		basamak = minf(basamak, (en_alt - en_ust) / (yuksek - dusuk))     # desen ekrana sığmıyorsa küçülür
	for i in range(1, adimlar.size()):
		# Art arda iki boşluk arasındaki fark, aradaki mesafede yetişilebilecek kadar olsun
		var adim_farki := absf(float(adimlar[i]) - float(adimlar[i - 1]))
		if adim_farki > 0.0:
			basamak = minf(basamak, kayma * float(aralar[i]) * ERISIM_PAYI / adim_farki)

	# Desenin yeri: ekrana sığsın ve ilk direk bir önceki engelden rahatça yetişilecek yükseklikte olsun
	var yer_ust := en_ust - dusuk * basamak
	var yer_alt := en_alt - yuksek * basamak
	var erisim := kayma * nefes * (0.4 if bulutlu else ERISIM_PAYI)
	var ilk := float(adimlar[0]) * basamak
	var istenen_ust := maxf(yer_ust, baslangic_y - erisim - ilk)
	var istenen_alt := minf(yer_alt, baslangic_y + erisim - ilk)
	var sigdi := istenen_alt >= istenen_ust
	var yer: float
	if sigdi:
		yer = rng.randf_range(istenen_ust, istenen_alt)
	else:
		# Desen önceki boşluktan uzakta başlamak zorunda: nefes mesafesi yetişilecek kadar uzar
		yer = clampf(baslangic_y - ilk, yer_ust, yer_alt)
		aralar[0] = maxf(nefes, absf(yer + ilk - baslangic_y) / (kayma * ERISIM_PAYI))
	return {"desen": desen, "katki": katki, "adimlar": adimlar, "aralar": aralar, "bosluk": bosluk,
		"hareket": hareket, "basamak": basamak, "yer": yer, "sigdi": sigdi}


# Gelebilecek desenler, karışık sırayla (bir önceki desen en sona kalır: ancak başka hiçbiri uymazsa tekrarlanır).
# sade_olmayan_once: hareketli direk gelmesi gerekiyorsa buna uygun desenler öne alınır
static func _adaylar(sadece_kolay: bool, son_desen: String, sade_olmayan_once: bool, rng: RandomNumberGenerator) -> Array:
	var adaylar: Array = []
	var son: Array = []
	for desen: Dictionary in DESENLER:
		if desen["kolay"] or not sadece_kolay:
			if desen["ad"] == son_desen:
				son.append(desen)
			else:
				adaylar.append(desen)
	for i in range(adaylar.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var gecici: Dictionary = adaylar[i]
		adaylar[i] = adaylar[j]
		adaylar[j] = gecici
	if sade_olmayan_once:
		var uygun := adaylar.filter(func(d: Dictionary) -> bool: return not d.get("sade", false))
		var kalan := adaylar.filter(func(d: Dictionary) -> bool: return d.get("sade", false))
		adaylar = uygun + kalan
	return adaylar + son


# Desenle birlikte gelen tek engel çeşidi: aynı anda birden fazla zor şey üst üste binmez
static func _katki_sec(desen: Dictionary, sira: int, bulutlu: bool, ortam: Dictionary, rng: RandomNumberGenerator) -> String:
	if bulutlu:
		return "yok"
	if ortam.get("hareketli_sart", false) and not desen.get("sade", false) and sira >= int(ortam["hareketli_puan"]):
		return "hareketli"
	var adaylar: Array = []
	for katki: String in (SADE_KATKILAR if desen.get("sade", false) else KATKILAR):
		if katki == "kalin" and sira < int(ortam["kalin_puan"]):
			continue
		if katki == "hareketli" and sira < int(ortam["hareketli_puan"]):
			continue
		adaylar.append(katki)
	return adaylar[rng.randi_range(0, adaylar.size() - 1)]
