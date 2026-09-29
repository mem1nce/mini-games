extends RefCounted
# Robot Fabrikası: bölüm verileri, parça üretimi ve kutu kuralları.
#
# Bir bölüm:
#   "boxes":  kutuların kuralları. Kural anahtarları: "color" (kirmizi/mavi/sari/yesil), "shape" (daire/kare/ucgen/yildiz),
#             "size" (buyuk/kucuk), "count" (sayma: tabelada o kadar nokta, kutuya tam o kadar parça)
#   "target": kutu başına parça sayısı ("count" olan kutuda count kullanılır)
#   "kinds":  bantta gelen parça çeşitleri; "colors": kuralı renk olmayan kutular için rastgele renkler
#   "speed":  bant hızı (px/sn); "robot": ödül robotunun şablonu (robot.gd ROBOTS)
# Yeni bölüm: LEVELS'e bir sözlük ekle. validate() kuralların çakışmadığını denetler (oyun açılırken de çalışır).

const COLORS := ["kirmizi", "mavi", "sari", "yesil"]
const SHAPES := ["daire", "kare", "ucgen", "yildiz"]
const SHAPED_KINDS := ["govde", "kafa"]
const ALL_KINDS := ["govde", "kafa", "kol", "tekerlek", "anten", "disli"]

const LEVELS := [
	# 1-3: renk
	{"boxes": [{"color": "kirmizi"}, {"color": "mavi"}], "target": 3, "kinds": ALL_KINDS, "speed": 55.0, "robot": "tekerlekli"},
	{"boxes": [{"color": "sari"}, {"color": "yesil"}], "target": 3, "kinds": ALL_KINDS, "speed": 58.0, "robot": "yayli"},
	{"boxes": [{"color": "kirmizi"}, {"color": "mavi"}, {"color": "sari"}], "target": 3, "kinds": ALL_KINDS, "speed": 60.0, "robot": "pervaneli"},
	# 4-6: şekil
	{"boxes": [{"shape": "daire"}, {"shape": "kare"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 62.0, "robot": "uzun_boyunlu"},
	{"boxes": [{"shape": "ucgen"}, {"shape": "yildiz"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 64.0, "robot": "paletli"},
	{"boxes": [{"shape": "daire"}, {"shape": "kare"}, {"shape": "ucgen"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 66.0, "robot": "ucan"},
	# 7-9: boyut
	{"boxes": [{"size": "buyuk"}, {"size": "kucuk"}], "target": 3, "kinds": ALL_KINDS, "speed": 68.0, "robot": "tek_tekerlekli"},
	{"boxes": [{"size": "buyuk"}, {"size": "kucuk"}], "target": 4, "kinds": ALL_KINDS, "speed": 71.0, "robot": "orumcek"},
	{"boxes": [{"size": "buyuk"}, {"size": "kucuk"}], "target": 5, "kinds": ALL_KINDS, "speed": 74.0, "robot": "ziplayan"},
	# 10-12: renk + şekil
	{"boxes": [{"color": "kirmizi", "shape": "ucgen"}, {"color": "mavi", "shape": "kare"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 77.0, "robot": "roketli"},
	{"boxes": [{"color": "sari", "shape": "daire"}, {"color": "yesil", "shape": "yildiz"}, {"color": "kirmizi", "shape": "kare"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 80.0, "robot": "kanatli"},
	{"boxes": [{"color": "mavi", "shape": "daire"}, {"color": "mavi", "shape": "ucgen"}, {"color": "sari", "shape": "ucgen"}], "target": 3, "kinds": SHAPED_KINDS, "speed": 83.0, "robot": "uzun_kollu"},
	# 13-15: sayma
	{"boxes": [{"color": "kirmizi", "count": 2}, {"color": "mavi", "count": 3}], "target": 0, "kinds": ALL_KINDS, "speed": 86.0, "robot": "ahtapot"},
	{"boxes": [{"color": "sari", "count": 4}, {"color": "yesil", "count": 2}, {"color": "kirmizi", "count": 3}], "target": 0, "kinds": ALL_KINDS, "speed": 90.0, "robot": "cift_pervaneli"},
	{"boxes": [{"shape": "daire", "count": 3}, {"shape": "kare", "count": 4}, {"shape": "yildiz", "count": 5}], "target": 0, "kinds": SHAPED_KINDS, "speed": 95.0, "robot": "dev"},
]

# 15. bölümden sonra: son bölümlerden karışık devam (bant hızı bu kadarı geçmez)
const ENDLESS_FROM := 9
const MAX_SPEED := 95.0


static func level(index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if index < LEVELS.size():
		return LEVELS[index]
	var r := rng if rng else RandomNumberGenerator.new()
	var copy: Dictionary = LEVELS[r.randi_range(ENDLESS_FROM, LEVELS.size() - 1)].duplicate(true)
	copy["speed"] = MAX_SPEED
	return copy


static func capacity(level_data: Dictionary, box: int) -> int:
	var rule: Dictionary = level_data["boxes"][box]
	return int(rule.get("count", level_data["target"]))


static func matches(rule: Dictionary, part: Dictionary) -> bool:
	for key in ["color", "shape", "size"]:
		if rule.has(key) and part.get(key, "") != rule[key]:
			return false
	return true


# Bir kutunun kuralına uyan, diğer kutulara uymayan rastgele parça
static func make_part(level_data: Dictionary, box: int, rng: RandomNumberGenerator) -> Dictionary:
	var rules: Array = level_data["boxes"]
	var rule: Dictionary = rules[box]
	var kinds: Array = level_data["kinds"]
	if rule.has("shape"):
		kinds = SHAPED_KINDS
	var part := {}
	for attempt in 30:
		var kind: String = kinds[rng.randi() % kinds.size()]
		part = {
			"kind": kind,
			"color": rule.get("color", COLORS[rng.randi() % COLORS.size()]),
			"shape": rule.get("shape", SHAPES[rng.randi() % SHAPES.size()]) if kind in SHAPED_KINDS else "",
			"size": rule.get("size", "normal"),
		}
		var unique := true
		for other in rules.size():
			if other != box and matches(rules[other], part):
				unique = false
		if unique:
			return part
	return part


# Kuralların tutarlılığı: her kutu için üretilen parça sadece o kutuya uymalı
static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in LEVELS.size():
		var data: Dictionary = LEVELS[i]
		var boxes: Array = data["boxes"]
		if boxes.size() < 2 or boxes.size() > 4:
			errors.append("bölüm %d: 2-4 kutu olmalı" % (i + 1))
		for b in boxes.size():
			if capacity(data, b) <= 0:
				errors.append("bölüm %d kutu %d: hedef yok" % [i + 1, b + 1])
			for k in 20:
				var part := make_part(data, b, rng)
				for other in boxes.size():
					if matches(boxes[other], part) != (other == b):
						errors.append("bölüm %d: kutu %d için parça kutu %d'e de uyuyor" % [i + 1, b + 1, other + 1])
						break
	return errors
