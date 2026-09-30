extends RefCounted
# Ray bağlantı mantığı (sahneden bağımsız, saf hesap).
# Yönler: 0 = kuzey (yukarı), 1 = doğu, 2 = güney, 3 = batı. Döndürme r: her adım saat yönünde 90°.
#
# Izgara durumu bir sözlük: Vector2i hücre → {"tip": "duz"/"kose"/"t"/"capraz", "yon": 0..3}
# (engel, yolcu ve boş hücreler sözlükte yoktur). Tren başlangıçta batıdan (giris hücresine yön 3'ten) girer,
# istasyon "cikis" hücresinin "cikis_yonu" kenarındadır.

const ADIM := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
# Döndürülmemiş parçaların açık kenarları
const TABAN := {
	"duz": [1, 3],
	"kose": [1, 2],
	"t": [1, 2, 3],
	"capraz": [0, 1, 2, 3],
}


static func ters(yon: int) -> int:
	return (yon + 2) % 4


static func acikliklar(tip: String, donus: int) -> Array:
	var out: Array = []
	for yon in TABAN[tip]:
		out.append((yon + donus) % 4)
	out.sort()
	return out


# Harita karakterinin açık kenarları (kutu çizgisi karakterleri)
const KARAKTERLER := {
	"─": [1, 3], "│": [0, 2],
	"┌": [1, 2], "┐": [2, 3], "┘": [0, 3], "└": [0, 1],
	"┬": [1, 2, 3], "┤": [0, 2, 3], "┴": [0, 1, 3], "├": [0, 1, 2],
	"┼": [0, 1, 2, 3],
}


# Açık kenarlardan (tip, dönüş) bulur; bulunamazsa boş sözlük
static func parca_bul(kenarlar: Array) -> Dictionary:
	var hedef := kenarlar.duplicate()
	hedef.sort()
	for tip in TABAN:
		if TABAN[tip].size() != hedef.size():
			continue
		for donus in 4:
			if acikliklar(tip, donus) == hedef:
				return {"tip": tip, "yon": donus}
	return {}


# Trenin bu parçaya "giris" kenarından girince çıkabileceği kenarlar
static func cikislar(parca: Dictionary, giris: int) -> Array:
	var acik := acikliklar(parca["tip"], parca["yon"])
	if not giris in acik:
		return []
	if parca["tip"] == "capraz":
		return [ters(giris)]
	var out: Array = []
	for yon in acik:
		if yon != giris:
			out.append(yon)
	return out


# Başlangıçtan girilebilen bütün parçalar (canlı parlama için). Döner: Vector2i hücre → true
static func bagli_hucreler(durum: Dictionary, giris: Vector2i) -> Dictionary:
	var bagli := {}
	var gorulen := {}
	var sira: Array = [[giris, 3]]
	while not sira.is_empty():
		var adim: Array = sira.pop_back()
		var hucre: Vector2i = adim[0]
		var kenar: int = adim[1]
		var anahtar := [hucre, kenar]
		if gorulen.has(anahtar) or not durum.has(hucre):
			continue
		gorulen[anahtar] = true
		var cik := cikislar(durum[hucre], kenar)
		if cik.is_empty():
			continue
		bagli[hucre] = true
		for yon in cik:
			sira.append([hucre + ADIM[yon], ters(yon)])
	return bagli


# Trenin rotası. Kavşaklarda istasyona varan ve en çok yolcuya uğrayan kol seçilir (eşitlikte kısa olan);
# istasyona varılamıyorsa en uzun yol. Döner:
#   {"tamam": bool, "adimlar": [{"hucre", "giris", "cikis"}...], "yolcular": [yolcu hücreleri, alınma sırasıyla]}
static func rota(durum: Dictionary, giris: Vector2i, cikis: Vector2i, cikis_yonu: int, yolcular: Array) -> Dictionary:
	var en_iyi := {"tamam": false, "adimlar": [], "yolcular": []}
	var yol: Array = []
	_ara(durum, giris, 3, cikis, cikis_yonu, yolcular, yol, {}, en_iyi)
	return en_iyi


static func _ara(durum: Dictionary, hucre: Vector2i, kenar: int, cikis: Vector2i, cikis_yonu: int,
		yolcular: Array, yol: Array, kullanilan: Dictionary, en_iyi: Dictionary) -> void:
	var devam := false
	if durum.has(hucre):
		var parca: Dictionary = durum[hucre]
		# Çapraz geçiş iki kez kullanılabilir (bir kez her eksende), diğerleri bir kez
		var anahtar = [hucre, kenar % 2] if parca["tip"] == "capraz" else hucre
		if not kullanilan.has(anahtar):
			for yon in cikislar(parca, kenar):
				devam = true
				kullanilan[anahtar] = true
				yol.append({"hucre": hucre, "giris": kenar, "cikis": yon})
				if hucre == cikis and yon == cikis_yonu:
					_aday(yol, true, yolcular, en_iyi)
				else:
					_ara(durum, hucre + ADIM[yon], ters(yon), cikis, cikis_yonu, yolcular, yol, kullanilan, en_iyi)
				yol.pop_back()
				kullanilan.erase(anahtar)
	if not devam:
		_aday(yol, false, yolcular, en_iyi)


static func _aday(yol: Array, tamam: bool, yolcular: Array, en_iyi: Dictionary) -> void:
	var alinan := alinan_yolcular(yol, yolcular)
	var daha_iyi := false
	if tamam != en_iyi["tamam"]:
		daha_iyi = tamam
	elif tamam:
		daha_iyi = alinan.size() > en_iyi["yolcular"].size() \
			or (alinan.size() == en_iyi["yolcular"].size() and yol.size() < en_iyi["adimlar"].size())
	else:
		daha_iyi = yol.size() > en_iyi["adimlar"].size()
	if daha_iyi:
		en_iyi["tamam"] = tamam
		en_iyi["adimlar"] = yol.duplicate(true)
		en_iyi["yolcular"] = alinan


# Rotanın yanından geçtiği yolcular (yan hücre = 4 komşu), geçilme sırasıyla
static func alinan_yolcular(yol: Array, yolcular: Array) -> Array:
	var out: Array = []
	for adim in yol:
		for y in yolcular:
			if not y in out and (y - adim["hucre"]).length_squared() == 1:
				out.append(y)
	return out
