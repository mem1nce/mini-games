extends RefCounted
# Sihirli Bahçe: bitki ve kese verileri.
#
# Yeni bitki eklemek:
#   1) gorseller/svg_uret.py içinde PLANTS'e ekle ve tomurcuk/olgun çizimini yaz (python svg_uret.py → 5 aşama)
#   2) Aşağıdaki PLANTS'e bir satır ekle:
#      "id": {"pack": kese, "rarity": COMMON/UNCOMMON/RARE, "night": sadece gece mi açar,
#             "special": dokununca yapacağı animasyon (bitki.gd), "color": parıltı rengi}
#   Albümdeki sıra ALBUM_ORDER'dır.

const G := "res://oyunlar/sihirli_bahce/gorseller/bitkiler/"
const COMMON := 0
const UNCOMMON := 1
const RARE := 2
const WEIGHTS := [10, 5, 2]           # nadirliğe göre seçilme ağırlığı
const NEW_BONUS := 2.0                # henüz keşfedilmemiş bitkinin ağırlık çarpanı
const STAGES := 5                     # 0 tohum, 1 filiz, 2 fidan, 3 tomurcuk, 4 olgun

const PACKS := ["pembe", "turuncu", "mor"]

const PLANTS := {
	"lale": {"pack": "pembe", "rarity": COMMON, "night": false, "special": "renk_degistir", "color": Color("ff8fbe")},
	"balon": {"pack": "pembe", "rarity": COMMON, "night": false, "special": "balonlar", "color": Color("7cc4ff")},
	"kelebek_cicegi": {"pack": "pembe", "rarity": COMMON, "night": false, "special": "kelebekler", "color": Color("d08cf0")},
	"gokkusagi": {"pack": "pembe", "rarity": UNCOMMON, "night": false, "special": "gokkusagi", "color": Color("ffd93d")},
	"kristal": {"pack": "pembe", "rarity": RARE, "night": false, "special": "parilti", "color": Color("9ed8ff")},
	"aycicegi": {"pack": "turuncu", "rarity": COMMON, "night": false, "special": "gunese_don", "color": Color("ffd23f")},
	"cilek": {"pack": "turuncu", "rarity": COMMON, "night": false, "special": "jole", "color": Color("ff6f7e")},
	"kabak": {"pack": "turuncu", "rarity": COMMON, "night": false, "special": "tavsan", "color": Color("ff9a2e")},
	"seker_agaci": {"pack": "turuncu", "rarity": RARE, "night": false, "special": "sekerler", "color": Color("ff9fcc")},
	"mantar": {"pack": "mor", "rarity": COMMON, "night": true, "special": "isik_sac", "color": Color("7ff0de")},
	"ay_cicegi": {"pack": "mor", "rarity": COMMON, "night": true, "special": "ay_tozu", "color": Color("dde6ff")},
	"yildiz_agaci": {"pack": "mor", "rarity": RARE, "night": false, "special": "yildiz_dus", "color": Color("ffd84a")},
}

const ALBUM_ORDER := ["lale", "balon", "kelebek_cicegi", "gokkusagi", "kristal", "aycicegi",
	"cilek", "kabak", "seker_agaci", "mantar", "ay_cicegi", "yildiz_agaci"]

static var _top_cache := {}


static func texture(id: String, stage: int, open: bool = true) -> Texture2D:
	if stage == STAGES - 1 and not open and PLANTS[id]["night"]:
		return load(G + "%s_4_kapali.svg" % id)
	return load(G + "%s_%d.svg" % [id, stage])


static func is_night(id: String) -> bool:
	return PLANTS.has(id) and PLANTS[id]["night"]


# Keseden rastgele bir bitki: nadirlik ağırlıklı, keşfedilmemişler biraz daha şanslı
static func pick(pack: String, album: Dictionary, rng: RandomNumberGenerator) -> String:
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id in PLANTS:
		if PLANTS[id]["pack"] != pack:
			continue
		var weight: float = WEIGHTS[PLANTS[id]["rarity"]]
		if int(album.get(id, 0)) == 0:
			weight *= NEW_BONUS
		ids.append(id)
		weights.append(weight)
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	for i in ids.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ids[i]
	return ids.back()


# Çizimin en üst noktası (tuvalde, 300 yükseklikte): baloncuk bunun üstünde durur
static func top_y(id: String, stage: int, open: bool = true) -> float:
	var key := "%s_%d_%s" % [id, stage, open]
	if not _top_cache.has(key):
		var tex := texture(id, stage, open)
		var rect := tex.get_image().get_used_rect()
		_top_cache[key] = rect.position.y * 300.0 / tex.get_height()
	return _top_cache[key]


# Çizimin dolu kısmı (240x300 tuval biriminde): kutlamada ortalamak için
static func content_rect(id: String, stage: int) -> Rect2:
	var tex := texture(id, stage)
	var rect := tex.get_image().get_used_rect()
	var k := 240.0 / tex.get_width()
	return Rect2(Vector2(rect.position) * k, Vector2(rect.size) * k)


# Kesenin rengi (parıltı ve efektler için)
static func pack_color(pack: String) -> Color:
	match pack:
		"pembe":
			return Color("ff8fbe")
		"turuncu":
			return Color("ffa84a")
	return Color("b996f2")
