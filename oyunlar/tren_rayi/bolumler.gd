extends RefCounted
# Tren Rayı bölümleri. Her bölüm bir sözlük:
#   "tema":      ciftlik / orman / kar / sahil / gece (zemin, engeller, arka plan)
#   "harita":    çözüm yolu, satır satır. Karakterler:
#                ─ │ ┌ ┐ └ ┘ düz/köşe ray, ├ ┤ ┬ ┴ T-kavşak, ┼ çapraz geçiş (her zaman sabit),
#                A ağaç türü, G su türü, K kaya/yapı türü engel, Y yolcu (sırayla "yolcular"dan),
#                ? rastgele yanıltıcı parça (düz ya da köşe), . boş zemin.
#                Başlangıç: batı kenarında dışarı açılan hücre. İstasyon: başka bir kenarda dışarı açılan hücre.
#   "karistir":  kaç parça yanlış döndürülür (1-3. bölümler gibi kolaylar için); -1 = sabit olmayanların hepsi rastgele
#   "sabit":     dönmeyen parçaların hücreleri (üstlerinde cıvata)
#   "yolcular":  yolcu hayvanları (gorseller/hayvanlar/<ad>.svg), haritadaki Y'lerin okuma sırasıyla
# Yeni bölüm: LEVELS'e sözlük ekle. validate() haritayı, yolun istasyona vardığını, yolcuların yol kenarında
# olduğunu ve karıştırınca başta çözülmüş olmadığını denetler (oyun açılırken de çalışır).

const Baglanti := preload("res://oyunlar/tren_rayi/baglanti.gd")

const HAYVANLAR := ["aslan", "baykus", "fil", "kaplumbaga", "panda", "penguen", "tavsan", "zurafa"]

const LEVELS := [
	# --- Çiftlik: az parça, sonra köşeler ---
	{"tema": "ciftlik", "karistir": 2, "harita": [
		"A...",
		"────",
		"..G.",
	]},
	{"tema": "ciftlik", "karistir": 2, "harita": [
		"─┐.A",
		".└──",
		"G...",
	]},
	{"tema": "ciftlik", "karistir": 3, "harita": [
		"..A.",
		"─┐┌─",
		".└┘K",
	]},
	{"tema": "ciftlik", "karistir": -1, "harita": [
		"┌─┐.A",
		"┘.└┐.",
		"G..└─",
	]},
	# --- Orman: engeller, sabit parçalar, yanıltıcı parçalar ---
	{"tema": "orman", "karistir": -1, "harita": [
		"A┌──┐",
		"─┘K.│",
		".G..└",
		"..A..",
	]},
	{"tema": "orman", "karistir": -1, "sabit": [Vector2i(2, 2)], "harita": [
		"..K┌─",
		"─┐A│.",
		".└─┘G",
		"A....",
	]},
	{"tema": "orman", "karistir": -1, "sabit": [Vector2i(3, 0)], "harita": [
		"?.┌─┐A",
		"─┐│K└─",
		".└┘.?G",
		"A..?..",
	]},
	{"tema": "orman", "karistir": -1, "sabit": [Vector2i(2, 3)], "harita": [
		"A?K.│?",
		"..A┌┘.",
		"─┐G│.A",
		"?└─┘.?",
	]},
	# --- Karlı dağlar: yolcular ---
	{"tema": "kar", "karistir": -1, "yolcular": ["tavsan"], "harita": [
		"──┐.A",
		"AY│K.",
		".?└──",
		"G..?.",
	]},
	{"tema": "kar", "karistir": -1, "sabit": [Vector2i(5, 2)], "yolcular": ["penguen"], "harita": [
		"A.K┌─┐",
		"─┐Y│G│",
		"?└─┘.│",
		"A.?..│",
	]},
	{"tema": "kar", "karistir": -1, "sabit": [Vector2i(3, 1)], "yolcular": ["penguen", "tavsan"], "harita": [
		"──┐.A.",
		"?Y└─┐K",
		"A.GY│.",
		".?..│A",
	]},
	{"tema": "kar", "karistir": -1, "sabit": [Vector2i(1, 1)], "yolcular": ["panda", "fil"], "harita": [
		"─┐.A.G",
		"?│K..?",
		"Y└─┐Y.",
		"A.?└──",
		".G..A.",
	]},
	# --- Sahil: T-kavşak, çapraz geçiş ---
	{"tema": "sahil", "karistir": -1, "harita": [
		"A..K.?",
		"──┬┐.A",
		"?.G└──",
		".A..?.",
	]},
	{"tema": "sahil", "karistir": -1, "yolcular": ["kaplumbaga"], "harita": [
		"A.K.?G",
		"─┬──┬─",
		".│A.│?",
		"?└──┘.",
		"A.Y.K.",
	]},
	{"tema": "sahil", "karistir": -1, "harita": [
		"A.?.K.",
		".G┌┐.A",
		"──┼┘.?",
		"?.│.A.",
		".K└───",
	]},
	{"tema": "sahil", "karistir": -1, "yolcular": ["zurafa", "aslan"], "harita": [
		"A.K.?.G",
		".Y┌┐.Y?",
		"──┼┘┌─┐",
		"?.│.│A│",
		"G.└─┴─┴",
	]},
	# --- Gece şehri: kavşaklar, çapraz geçişler, yolcular ---
	{"tema": "gece", "karistir": -1, "yolcular": ["baykus", "tavsan"], "harita": [
		"A.K.?Y.",
		"?G.A┌─┐",
		"─┬─┬┴─┴",
		".└─┘?.G",
		"K.Y.A.?",
	]},
	{"tema": "gece", "karistir": -1, "sabit": [Vector2i(4, 4)], "yolcular": ["panda", "penguen"], "harita": [
		"A.?.K.G",
		".Y┌┐.?.",
		"──┼┘AY.",
		"?.│┌──┐",
		"K.└┴──┴",
	]},
	{"tema": "gece", "karistir": -1, "sabit": [Vector2i(2, 2)], "yolcular": ["aslan", "fil", "kaplumbaga"], "harita": [
		"?.AY┌─┐",
		"Y.K.│G│",
		"─┬─┬┴─┴",
		".│A│.?.",
		"Y└─┘.K.",
	]},
	{"tema": "gece", "karistir": -1, "sabit": [Vector2i(2, 2)], "yolcular": ["baykus", "zurafa", "panda"], "harita": [
		"AY┌┐.?G",
		"──┼┘KY.",
		".A│.┌─┐",
		"?Y└─┴─┴",
		"K.?.A..",
	]},
]


static func level(index: int) -> Dictionary:
	return LEVELS[posmod(index, LEVELS.size())]


# Haritayı okur. Döner: boyut, cozum (hücre → {tip, yon}), engeller (hücre → A/G/K), yolcular ([{hucre, hayvan}]),
# rastgele (? hücreleri), giris, cikis, cikis_yonu, sabit; hata varsa "hata" alanı
static func coz(data: Dictionary) -> Dictionary:
	var harita: Array = data["harita"]
	var boyut := Vector2i(harita[0].length(), harita.size())
	var sonuc := {"boyut": boyut, "cozum": {}, "engeller": {}, "yolcular": [], "rastgele": [],
		"sabit": data.get("sabit", []), "giris": Vector2i(-1, -1), "cikis": Vector2i(-1, -1), "cikis_yonu": -1}
	var hayvanlar: Array = data.get("yolcular", [])
	for y in boyut.y:
		var satir: String = harita[y]
		if satir.length() != boyut.x:
			sonuc["hata"] = "satır %d uzunluğu farklı" % y
			return sonuc
		for x in boyut.x:
			var k := satir[x]
			var hucre := Vector2i(x, y)
			if Baglanti.KARAKTERLER.has(k):
				var parca := Baglanti.parca_bul(Baglanti.KARAKTERLER[k])
				sonuc["cozum"][hucre] = parca
				for yon in Baglanti.KARAKTERLER[k]:
					var komsu: Vector2i = hucre + Baglanti.ADIM[yon]
					if komsu.x >= 0 and komsu.y >= 0 and komsu.x < boyut.x and komsu.y < boyut.y:
						continue
					sonuc["disari"] = int(sonuc.get("disari", 0)) + 1
					if yon == 3 and x == 0 and sonuc["giris"] == Vector2i(-1, -1):
						sonuc["giris"] = hucre
					else:
						sonuc["cikis"] = hucre
						sonuc["cikis_yonu"] = yon
			elif k in ["A", "G", "K"]:
				sonuc["engeller"][hucre] = k
			elif k == "Y":
				var sira: int = sonuc["yolcular"].size()
				sonuc["yolcular"].append({"hucre": hucre, "hayvan": hayvanlar[sira] if sira < hayvanlar.size() else "tavsan"})
			elif k == "?":
				sonuc["rastgele"].append(hucre)
			elif k != ".":
				sonuc["hata"] = "bilinmeyen karakter '%s'" % k
	return sonuc


# Oynanacak durumu kurar: çözüm parçaları + yanıltıcılar, sabit olmayanlar karıştırılmış, başta çözülmemiş.
# Döner: coz() sonucu + "parcalar" (hücre → {tip, yon, sabit})
static func kur(data: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var bolum := coz(data)
	var yolcu_hucreleri: Array = bolum["yolcular"].map(func(y: Dictionary) -> Vector2i: return y["hucre"])
	for deneme in 200:
		var parcalar := {}
		for hucre in bolum["cozum"]:
			var p: Dictionary = bolum["cozum"][hucre]
			parcalar[hucre] = {"tip": p["tip"], "yon": p["yon"], "sabit": hucre in bolum["sabit"] or p["tip"] == "capraz"}
		for hucre in bolum["rastgele"]:
			parcalar[hucre] = {"tip": "duz" if rng.randf() < 0.4 else "kose", "yon": rng.randi() % 4, "sabit": false}
		var oynar: Array = parcalar.keys().filter(func(h: Vector2i) -> bool: return not parcalar[h]["sabit"])
		var karistir: int = data.get("karistir", -1)
		if karistir < 0:
			for hucre in oynar:
				parcalar[hucre]["yon"] = rng.randi() % 4
		else:
			# Sadece çözüm yolundaki birkaç parça yanlış döner
			var yoldakiler: Array = oynar.filter(func(h: Vector2i) -> bool: return bolum["cozum"].has(h))
			yoldakiler.shuffle()
			for i in mini(karistir, yoldakiler.size()):
				_yanlis_dondur(parcalar[yoldakiler[i]], rng)
		var durum := durum_sozlugu(parcalar)
		if not Baglanti.rota(durum, bolum["giris"], bolum["cikis"], bolum["cikis_yonu"], yolcu_hucreleri)["tamam"]:
			bolum["parcalar"] = parcalar
			return bolum
	bolum["parcalar"] = {}
	bolum["hata"] = "karıştırılamadı"
	return bolum


static func _yanlis_dondur(parca: Dictionary, rng: RandomNumberGenerator) -> void:
	var dogru := Baglanti.acikliklar(parca["tip"], parca["yon"])
	var secenekler: Array = []
	for donus in 4:
		if Baglanti.acikliklar(parca["tip"], donus) != dogru:
			secenekler.append(donus)
	parca["yon"] = secenekler[rng.randi() % secenekler.size()]


# Baglanti fonksiyonlarının beklediği biçim: hücre → {tip, yon}
static func durum_sozlugu(parcalar: Dictionary) -> Dictionary:
	var durum := {}
	for hucre in parcalar:
		durum[hucre] = {"tip": parcalar[hucre]["tip"], "yon": parcalar[hucre]["yon"]}
	return durum


static func validate() -> PackedStringArray:
	var hatalar := PackedStringArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in LEVELS.size():
		var data: Dictionary = LEVELS[i]
		var ad := "bölüm %d" % (i + 1)
		var bolum := coz(data)
		if bolum.has("hata"):
			hatalar.append("%s: %s" % [ad, bolum["hata"]])
			continue
		if bolum["giris"] == Vector2i(-1, -1) or bolum["cikis"] == Vector2i(-1, -1) or bolum.get("disari", 0) != 2:
			hatalar.append("%s: tam bir başlangıç ve bir istasyon olmalı" % ad)
			continue
		for hucre in bolum["sabit"]:
			if not bolum["cozum"].has(hucre):
				hatalar.append("%s: sabit hücre %s rayda değil" % [ad, hucre])
		if data.get("yolcular", []).size() != bolum["yolcular"].size():
			hatalar.append("%s: Y sayısı yolcu listesiyle aynı değil" % ad)
		for y in bolum["yolcular"]:
			if not y["hayvan"] in HAYVANLAR:
				hatalar.append("%s: bilinmeyen hayvan %s" % [ad, y["hayvan"]])
		var yolcu_hucreleri: Array = bolum["yolcular"].map(func(y: Dictionary) -> Vector2i: return y["hucre"])
		var rota := Baglanti.rota(bolum["cozum"], bolum["giris"], bolum["cikis"], bolum["cikis_yonu"], yolcu_hucreleri)
		if not rota["tamam"]:
			hatalar.append("%s: çözüm yolu istasyona varmıyor" % ad)
		elif rota["yolcular"].size() != yolcu_hucreleri.size():
			hatalar.append("%s: çözüm yolu bütün yolculara uğramıyor" % ad)
		# Haritadaki her ray parçası çözümde kullanılabilir olmalı (kopuk parça olmasın)
		var bagli := Baglanti.bagli_hucreler(bolum["cozum"], bolum["giris"])
		for hucre in bolum["cozum"]:
			if not bagli.has(hucre):
				hatalar.append("%s: %s parçası yola bağlı değil" % [ad, hucre])
		for deneme in 5:
			var kurulu := kur(data, rng)
			if kurulu.has("hata"):
				hatalar.append("%s: %s" % [ad, kurulu["hata"]])
				break
	return hatalar
