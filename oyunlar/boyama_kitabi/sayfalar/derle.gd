extends SceneTree
# Boyama Kitabı sayfa derleyicisi. Proje kökünden:
#   godot --headless --path . -s res://oyunlar/boyama_kitabi/sayfalar/derle.gd            (bütün sayfalar)
#   godot --headless --path . -s res://oyunlar/boyama_kitabi/sayfalar/derle.gd -- kedi    (sadece bu sayfalar)
# Sonra Godot'u bir kez açmak (ya da --headless --import) yeni PNG'leri içe aktarır.
#
# sayfalar/kaynak/<kategori>/<sayfa>.svg dosyalarını okur (yapısı için bkz. kaynak/sayfa_uret.py) ve
# sayfalar/png/ içine her sayfa için üç görsel yazar:
#   <sayfa>_cizgi.png  sadece çizgiler, saydam, tuval boyutunda (ayarlar.gd CANVAS_LONG_SIDE)
#   <sayfa>_bolge.png  bölge haritası (8 bit gri, kenar yumuşatması yok): piksel değeri = bölge numarası,
#                      0 = kağıt. Bölgeler SVG'deki ressam sırasıyla üst üste konur; her bölge çizgilerin
#                      altına kadar uzandığı için boya ile çizgi arasında boşluk kalmaz.
#   <sayfa>_kucuk.png  sayfa seçimi için küçük resim
# ve sayfalar/sayfa_listesi.gd dosyasını (sayfa listesi, bölge sayıları) yeniden yazar.
#
# Denetimler (hata varsa çıkış kodu 1): çizgiler duvar sayılıp çizgisiz alanlar taranır;
#   - iki bölge arasında çizgi yoksa (birbirine karışıyor) hata,
#   - bir bölge birden çok parçaya bölünmüşse (ya da kapalı bir boşluk kağıda ait kalmışsa) hata,
#   - görünür alanı çok küçük bölge (ayarlar.gd MIN_REGION_AREA) hata.

const Settings := preload("res://oyunlar/boyama_kitabi/ayarlar.gd")
const SOURCE := "res://oyunlar/boyama_kitabi/sayfalar/kaynak/"
const OUTPUT := "res://oyunlar/boyama_kitabi/sayfalar/png/"
const LIST := "res://oyunlar/boyama_kitabi/sayfalar/sayfa_listesi.gd"
const CHECK_SCALE := 0.5          # denetim bu ölçekte yapılır (hız için)
const CRUMB := 24                 # denetim pikselinde bundan küçük parçalar (kenar kırıntısı) sayılmaz
const PAPER_NAME := "kağıt"

var _errors := 0


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var pages: Array[Dictionary] = []
	for category in Settings.CATEGORIES:
		var folder: String = SOURCE + category["id"] + "/"
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".svg"):
				continue
			var id := file.get_basename()
			if only.size() > 0 and not id in only:
				pages.append(_old_entry(id, category["id"]))
				continue
			var count := _build(folder + file, id)
			if count > 0:
				pages.append({"id": id, "category": category["id"], "regions": count})
	for folder in DirAccess.get_directories_at(SOURCE):
		if not Settings.CATEGORIES.any(func(c: Dictionary) -> bool: return c["id"] == folder):
			_fail("kaynak/%s: bilinmeyen kategori klasörü (ayarlar.gd CATEGORIES)" % folder)
	_write_list(pages)
	print("\n%d sayfa, %s" % [pages.size(), "hepsi tamam" if _errors == 0 else "%d HATA" % _errors])
	quit(1 if _errors > 0 else 0)


# Tek sayfa: görselleri yazar, denetler; bölge sayısını (kağıt dahil) döndürür, hatada 0
func _build(path: String, id: String) -> int:
	var started := Time.get_ticks_msec()
	var svg := _parse(FileAccess.get_file_as_string(path), id)
	if svg.is_empty():
		return 0
	var scale: float = Settings.CANVAS_LONG_SIDE / maxf(svg["width"], svg["height"])
	# Çizgiler
	var lines := Image.new()
	lines.load_svg_from_string(svg["header"] + svg["defs"] + svg["lines"] + "</svg>", scale)
	var size := lines.get_size()
	lines.save_png(ProjectSettings.globalize_path(OUTPUT + id + "_cizgi.png"))
	# Küçük resim: beyaz kağıt üstünde çizgiler
	var thumb := Image.new()
	var paper := '<rect x="-10" y="-10" width="%d" height="%d" fill="#FFFFFF"/>' % [svg["width"] + 20, svg["height"] + 20]
	thumb.load_svg_from_string(svg["header"] + paper + svg["defs"] + svg["lines"] + "</svg>",
		Settings.PAGE_THUMB_WIDTH / float(svg["width"]))
	thumb.save_png(ProjectSettings.globalize_path(OUTPUT + id + "_kucuk.png"))
	# Bölge haritası: her bölge ayrı çizilir, yarıdan fazla örtülen piksel o bölgenin olur (yumuşatma yok)
	var regions: Array = svg["regions"]
	if regions.size() > Settings.MAX_REGIONS:
		_fail("%s: %d bölge var, en fazla %d" % [id, regions.size(), Settings.MAX_REGIONS])
		return 0
	var ids := PackedByteArray()
	ids.resize(size.x * size.y)
	for i in regions.size():
		var region: Dictionary = regions[i]
		var image := Image.new()
		image.load_svg_from_string(svg["header"] + '<g fill="#FFFFFF" stroke="none">' + region["svg"] + "</g></svg>", scale)
		if image.get_size() != size:
			image.crop(size.x, size.y)
		var used := image.get_used_rect()
		if used.size.x == 0:
			_fail("%s: '%s' bölgesi boş (şekil çizilmedi)" % [id, region["name"]])
			continue
		var data := image.get_region(used).get_data()
		var value := i + 1
		var k := 3
		for y in used.size.y:
			var row := (used.position.y + y) * size.x + used.position.x
			for x in used.size.x:
				if data[k] >= 128:
					ids[row + x] = value
				k += 4
	var map := Image.create_from_data(size.x, size.y, false, Image.FORMAT_L8, ids)
	map.save_png(ProjectSettings.globalize_path(OUTPUT + id + "_bolge.png"))
	for suffix in ["_cizgi", "_bolge", "_kucuk"]:
		_write_import(OUTPUT + id + suffix + ".png", suffix != "_bolge")
	var names := PackedStringArray([PAPER_NAME])
	for region in regions:
		names.append(region["name"])
	var ok := _check(id, map, lines, names, scale)
	print("%-12s %2d bölge  %s  %d ms" % [id, regions.size(), "tamam" if ok else "HATALI", Time.get_ticks_msec() - started])
	return regions.size() + 1 if ok else 0


# --- SVG ayrıştırma: kök boyutu, <defs>, <g id="bolgeler"> içindeki her şekil, <g id="cizgiler"> ---

func _parse(text: String, id: String) -> Dictionary:
	var bytes := text.to_utf8_buffer()
	var parser := XMLParser.new()
	parser.open_buffer(bytes)
	var nodes: Array[Dictionary] = []
	while parser.read() == OK:
		var node := {"type": parser.get_node_type(), "start": parser.get_node_offset(), "name": "", "empty": false, "attrs": {}}
		if node["type"] == XMLParser.NODE_ELEMENT or node["type"] == XMLParser.NODE_ELEMENT_END:
			node["name"] = parser.get_node_name()
		if node["type"] == XMLParser.NODE_ELEMENT:
			node["empty"] = parser.is_empty()
			for a in parser.get_attribute_count():
				node["attrs"][parser.get_attribute_name(a)] = parser.get_attribute_value(a)
		nodes.append(node)
	for i in nodes.size():
		nodes[i]["end"] = nodes[i + 1]["start"] if i + 1 < nodes.size() else bytes.size()
	var result := {"defs": "", "lines": "", "regions": []}
	var region_group_transform := ""
	var i := 0
	while i < nodes.size():
		var node := nodes[i]
		if node["type"] != XMLParser.NODE_ELEMENT:
			i += 1
			continue
		var attrs: Dictionary = node["attrs"]
		if node["name"] == "svg":
			var box := PackedFloat64Array()
			for v in str(attrs.get("viewBox", "")).replace(",", " ").split(" ", false):
				box.append(float(v))
			result["width"] = float(str(attrs.get("width", box[2] if box.size() == 4 else 0)).trim_suffix("px"))
			result["height"] = float(str(attrs.get("height", box[3] if box.size() == 4 else 0)).trim_suffix("px"))
			var view := ' viewBox="%s"' % attrs["viewBox"] if attrs.has("viewBox") else ""
			result["header"] = '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s"%s>' % [
				result["width"], result["height"], view]
			i += 1
			continue
		var close := _closing(nodes, i)
		var span := bytes.slice(node["start"], nodes[close]["end"]).get_string_from_utf8()
		if node["name"] == "defs":
			result["defs"] += span
		elif node["name"] == "g" and attrs.get("id") == "cizgiler":
			result["lines"] = span
		elif node["name"] == "g" and attrs.get("id") == "bolgeler":
			if attrs.has("transform"):
				region_group_transform = str(attrs["transform"])
			var j := i + 1
			while j < close:
				if nodes[j]["type"] == XMLParser.NODE_ELEMENT:
					var end := _closing(nodes, j)
					var shape := bytes.slice(nodes[j]["start"], nodes[end]["end"]).get_string_from_utf8()
					var name := str(nodes[j]["attrs"].get("id", "bölge %d" % (result["regions"].size() + 1)))
					shape = _plain(shape)
					if region_group_transform != "":
						shape = '<g transform="%s">%s</g>' % [region_group_transform, shape]
					result["regions"].append({"name": name, "svg": shape})
					j = end + 1
				else:
					j += 1
		i = close + 1
	if not result.has("header"):
		_fail("%s: <svg> kökü yok" % id)
		return {}
	if result["regions"].is_empty():
		_fail('%s: <g id="bolgeler"> içinde bölge yok' % id)
		return {}
	if result["lines"] == "":
		_fail('%s: <g id="cizgiler"> yok' % id)
		return {}
	var names := {}
	for region in result["regions"]:
		if names.has(region["name"]):
			_fail("%s: '%s' bölge adı iki kez var" % [id, region["name"]])
		names[region["name"]] = true
	return result


# Açılış düğümünün kapanışının indeksi (boş öğede kendisi)
func _closing(nodes: Array[Dictionary], index: int) -> int:
	if nodes[index]["empty"]:
		return index
	var depth := 0
	for k in range(index, nodes.size()):
		if nodes[k]["type"] == XMLParser.NODE_ELEMENT and not nodes[k]["empty"]:
			depth += 1
		elif nodes[k]["type"] == XMLParser.NODE_ELEMENT_END:
			depth -= 1
			if depth == 0:
				return k
	return nodes.size() - 1


# Bölge şeklinden boya/hat/maske niteliklerini atar: şekil düz beyaz çizilsin
func _plain(shape: String) -> String:
	var strip := RegEx.create_from_string('\\s(fill|stroke|stroke-width|style|mask|clip-path|opacity|fill-opacity|filter)="[^"]*"')
	return strip.sub(shape, "", true)


# --- Denetim ---

func _check(id: String, map: Image, lines: Image, names: PackedStringArray, scale: float) -> bool:
	var size := Vector2i(map.get_size() * CHECK_SCALE)
	var small := map.duplicate() as Image
	small.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var mask := lines.duplicate() as Image
	mask.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	var ids := small.get_data()
	var alpha := mask.get_data()
	var count := size.x * size.y
	var wall := PackedByteArray()
	wall.resize(count)
	for p in count:
		wall[p] = 1 if alpha[p * 4 + 3] >= 128 else 0
	var errors_before := _errors
	var pixel_area := 1.0 / pow(scale * CHECK_SCALE, 2.0)     # bir denetim pikseli kaç tasarım birimi²
	# Her bölgenin görünür parçaları: [piksel sayısı, ...]
	var pieces := {}
	var seen := PackedByteArray()
	seen.resize(count)
	var stack := PackedInt32Array()
	for start in count:
		if wall[start] == 1 or seen[start] == 1:
			continue
		# Çizgisiz komşu pikselleri (bölgesine bakmadan) tara; bir bölgeden fazlası çıkarsa çizgi eksik
		var per_id := {}
		stack.append(start)
		seen[start] = 1
		var total := 0
		while stack.size() > 0:
			var p := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			total += 1
			per_id[ids[p]] = per_id.get(ids[p], 0) + 1
			var x := p % size.x
			for q in [p - 1 if x > 0 else -1, p + 1 if x < size.x - 1 else -1, p - size.x, p + size.x]:
				if q >= 0 and q < count and wall[q] == 0 and seen[q] == 0:
					seen[q] = 1
					stack.append(q)
		if total < CRUMB:
			continue
		var main := -1
		for v in per_id:
			if main == -1 or per_id[v] > per_id[main]:
				main = v
		for v in per_id:
			if v != main and per_id[v] >= CRUMB:
				_fail("%s: '%s' ile '%s' arasında çizgi yok, iki bölge birbirine karışıyor" % [id, names[main], names[v]])
		if not pieces.has(main):
			pieces[main] = []
		pieces[main].append(per_id[main])
	for v in names.size():
		var parts: Array = pieces.get(v, [])
		if parts.is_empty():
			_fail("%s: '%s' görünmüyor (başka bölgelerin ya da çizgilerin altında kalmış)" % [id, names[v]])
			continue
		parts.sort()
		if parts.size() > 1:
			_fail("%s: '%s' %d parçaya bölünmüş (en küçüğü ~%d birim²); her kapalı alan ayrı bölge olmalı" % [
				id, names[v], parts.size(), parts[0] * pixel_area])
		var area: float = parts[parts.size() - 1] * pixel_area
		if area < Settings.MIN_REGION_AREA:
			_fail("%s: '%s' çok küçük (~%d birim², en az %d)" % [id, names[v], area, Settings.MIN_REGION_AREA])
	return _errors == errors_before


# --- Çıktılar ---

func _write_import(path: String, mipmaps: bool) -> void:
	var import_path := ProjectSettings.globalize_path(path + ".import")
	if FileAccess.file_exists(import_path):
		return
	var file := FileAccess.open(import_path, FileAccess.WRITE)
	file.store_string('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\ncompress/mode=0\n'
		+ "mipmaps/generate=%s\nprocess/fix_alpha_border=true\ndetect_3d/compress_to=0\n" % ("true" if mipmaps else "false"))
	file.close()


func _old_entry(id: String, category: String) -> Dictionary:
	var old := load(LIST) as GDScript
	if old:
		for page in old.get_script_constant_map().get("PAGES", []):
			if page["id"] == id:
				return page
	return {"id": id, "category": category, "regions": 0}


# Sayfa listesi: kategori sırasıyla, her kategoride basit (az bölgeli) sayfalar önce
func _write_list(pages: Array[Dictionary]) -> void:
	var order := Settings.CATEGORIES.map(func(c: Dictionary) -> String: return c["id"])
	pages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["category"] != b["category"]:
			return order.find(a["category"]) < order.find(b["category"])
		if a["regions"] != b["regions"]:
			return a["regions"] < b["regions"]
		return a["id"] < b["id"])
	var text := "extends RefCounted\n# Bu dosyayı sayfalar/derle.gd üretir; elle değiştirme.\n"
	text += "# Her sayfa: id (png/<id>_*.png), kategori, bölge sayısı (kağıt dahil). Basit sayfalar önce.\n\n"
	text += "const PAGES := [\n"
	for page in pages:
		text += '\t{"id": "%s", "category": "%s", "regions": %d},\n' % [page["id"], page["category"], page["regions"]]
	text += "]\n"
	var file := FileAccess.open(ProjectSettings.globalize_path(LIST), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _fail(message: String) -> void:
	_errors += 1
	printerr("HATA: " + message)
