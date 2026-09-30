class_name SizeArt
extends RefCounted
# Boyutu değişen nesnelerin çizimi (halka, direk, sıralama nesneleri, bebekler).
# Şablonlar gorseller/sablonlar.json içinde (gorseller/svg_uret.py üretir). Her nesne görüneceği boyutta
# SVG'den ayrı çizilir (bulanıklaşmaz) ve:
#   - çizgi kalınlığı boyuta göre ayarlanır: küçük nesnede çok ince, büyükte çok kalın olmaz
#     (stroke-width değerleri çarpılır; hedef kalınlık stroke_px()),
#   - renk tonları şablondaki {L} {l} {c} {d} {D} yerine yazılır (tones(), svg_uret.py ile aynı formül),
#   - "boy" şablonlarında (top/bottom alanı olanlar) genişlik sabittir, sadece orta parça ({N}) uzar.
# Aynı ad + renk + boyut bir kez çizilir (önbellek).

const TEMPLATES_PATH := "res://oyunlar/buyukten_kucuge/gorseller/sablonlar.json"
const OUTLINE := Color("3b2f6b")
## Çizim çözünürlüğü: nesne görünen boyutunun bu katı pikselle çizilir (yüksek yoğunluklu ekranda net kalsın)
const RASTER := 2.0
## 180 px'lik bir nesnede çizgi kalınlığı (px). Diğer boyutlarda (boyut/180)^0.25 ile çok az değişir.
const STROKE_PX := 5.0

static var _templates: Dictionary = {}
static var _cache: Dictionary = {}
static var _stroke_regex: RegEx


static func templates() -> Dictionary:
	if _templates.is_empty():
		var json: JSON = load(TEMPLATES_PATH)
		_templates = json.data
	return _templates


static func has(art: String) -> bool:
	return templates().has(art)


static func info(art: String) -> Dictionary:
	return templates()[art]


# Uzayan ("boy") şablon mu: genişliği sabit, sadece yüksekliği değişir
static func is_tall(art: String) -> bool:
	return info(art).has("top")


# Sabit oranlı şablonun genişlik / yükseklik oranı
static func aspect(art: String) -> float:
	var t := info(art)
	return float(t["w"]) / float(t["h"])


# Uzayan şablonun en kısa hali için yükseklik / genişlik oranı (orta parça en az min_mid)
static func min_tall_ratio(art: String) -> float:
	var t := info(art)
	return (float(t["top"]) + float(t["bottom"]) + float(t["min_mid"])) / float(t["w"])


# Renk tonları: çok açık, açık, kendisi, koyu, çok koyu (svg_uret.py tones() ile aynı)
static func tones(color: Color) -> Dictionary:
	return {
		"L": _hex(color.lerp(Color.WHITE, 0.6)), "l": _hex(color.lerp(Color.WHITE, 0.3)), "c": _hex(color),
		"d": _hex(color.lerp(OUTLINE, 0.25)), "D": _hex(color.lerp(OUTLINE, 0.55)),
	}


# Görünen boyuttaki çizgi kalınlığı (px)
static func stroke_px(visual: Vector2) -> float:
	return STROKE_PX * pow(maxf(visual.x, visual.y) / 180.0, 0.25)


# Nesnenin dokusu. visual: görünen boyut (px); uzayan şablonda genişlik sabit, yükseklik istenen boy.
# Doku RASTER katı büyüklükte çizilir: Sprite2D ölçeği 1 / RASTER olmalı.
static func texture(art: String, visual: Vector2, color: Color = Color.WHITE) -> Texture2D:
	return _entry(art, visual, color)["texture"]


# Nesnenin dış çizgisi (siluet): Sprite2D merkezine göre, görünen boyutta çokgenler
static func outline(art: String, visual: Vector2, color: Color = Color.WHITE) -> Array[PackedVector2Array]:
	var entry := _entry(art, visual, color)
	if not entry.has("outline"):
		var image: Image = entry["image"]
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image, 0.4)
		var half := Vector2(image.get_size()) / 2.0
		var result: Array[PackedVector2Array] = []
		for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 2.0):
			var points := PackedVector2Array()
			for p in polygon:
				points.append((p - half) / RASTER)
			if absf(_area(points)) > 400.0:      # ipin ucu gibi çok küçük parçalar atlanır
				result.append(points)
		entry["outline"] = result
	return entry["outline"]


static func _entry(art: String, visual: Vector2, color: Color) -> Dictionary:
	var key := "%s|%s|%d|%d" % [art, color.to_html(false), roundi(visual.x), roundi(visual.y)]
	if not _cache.has(key):
		var image := _render(art, visual, color)
		image.generate_mipmaps()
		_cache[key] = {"image": image, "texture": ImageTexture.create_from_image(image)}
	return _cache[key]


static func _render(art: String, visual: Vector2, color: Color) -> Image:
	var t := info(art)
	var svg: String = t["svg"]
	var scale: float
	var stroke: float
	if t.has("top"):
		# Uzayan şablon: genişliğe göre ölçek, orta parça kalan boyu doldurur. Çizgi hep aynı kalınlıkta.
		scale = visual.x / float(t["w"])
		var mid := maxf(float(t["min_mid"]), visual.y / scale - float(t["top"]) - float(t["bottom"]))
		svg = svg.format({"H": _num(float(t["top"]) + mid + float(t["bottom"])), "N": _num(mid), "Y": _num(float(t["top"]) + mid)})
		stroke = STROKE_PX
	else:
		scale = visual.y / float(t["h"])
		stroke = stroke_px(visual)
	if t["tint"]:
		svg = svg.format(tones(color))
	svg = _scale_strokes(svg, stroke / (float(t["sw"]) * scale))
	var image := Image.new()
	image.load_svg_from_string(svg, scale * RASTER)
	image.convert(Image.FORMAT_RGBA8)
	return image


# Bütün stroke-width değerlerini factor ile çarpar
static func _scale_strokes(svg: String, factor: float) -> String:
	if _stroke_regex == null:
		_stroke_regex = RegEx.create_from_string('stroke-width="([0-9.]+)"')
	var out := ""
	var last := 0
	for m in _stroke_regex.search_all(svg):
		out += svg.substr(last, m.get_start() - last)
		out += 'stroke-width="%s"' % _num(float(m.get_string(1)) * factor)
		last = m.get_end()
	return out + svg.substr(last)


static func _num(value: float) -> String:
	return "%.2f" % value


static func _hex(color: Color) -> String:
	return "#" + color.to_html(false)


static func _area(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size():
		total += points[i].cross(points[(i + 1) % points.size()])
	return total / 2.0
