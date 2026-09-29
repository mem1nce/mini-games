extends Node2D
# Pist yükleyici: pistler.gd'deki parça listesinden yolu üretir, çizer ve arabalara sorgu sağlar.
# - Yol bir Curve2D'dir; noktalar x'te STEP aralıklı, x hep artar. Eğri yolun yakın (ön) kenarıdır.
#   Yol yukarıdan hafifçe görünür: uzak kenar DEPTH px yukarıda, şeritler ikisinin arasında.
# - Rampalar düz zemine oturur; rampadan sonra inişe yetecek düz alan kendiliğinden eklenir.
# - Havadaki yıldızlar, rampaya gaza basarak gelen arabanın yayı üzerine konur.
# Çizim sırası: süsler (yolun arkasında) → yol parçaları → rampa/su/kasis/çizgiler → [arabalar] → yıldızlar.

const Pistler := preload("res://oyunlar/araba_yarisi/pistler.gd")
const Araba := preload("res://oyunlar/araba_yarisi/araba.gd")
const G := "res://oyunlar/araba_yarisi/gorseller/"

const STEP := 24.0
const DEPTH := 108.0            # yolun derinliği (uzak kenar yakın kenardan bu kadar yukarıda)
const CURB := 20.0              # yolun ön yüzü
const VERGE := 46.0             # yolun arkasındaki çimen/kum/kar şeridi
const LEAD_IN := 1100.0         # başlangıç çizgisinden önceki yol dahil ilk düzlük
const START_X := 760.0
const RUN_OUT := 3400.0         # bitişten sonra yol devam eder (arabalar yavaşlayıp durur)
const CHUNK_POINTS := 80        # bir çizim parçasındaki nokta sayısı
const PUDDLE_LEN := 560.0
const BUMP_LEN := 440.0
const RAMP_APPROACH := 320.0
const RAMP_SIZE := [Vector2(250, 62), Vector2(300, 92)]   # küçük / büyük: (uzunluk, yükseklik)
const STAR_REF_SPEED := 0.92    # havadaki yıldızlar bu hızla gelen arabanın yayında
const STAR_SIZE := 66.0

const DECOR := {
	"agac": {"tex": "agac.svg", "h": 250.0},
	"cali": {"tex": "cali.svg", "h": 86.0},
	"kaktus": {"tex": "kaktus.svg", "h": 200.0},
	"kaya": {"tex": "kaya.svg", "h": 64.0},
	"cam_agaci": {"tex": "cam_agaci.svg", "h": 250.0},
	"cam_kucuk": {"tex": "cam_agaci.svg", "h": 160.0},
	"kardan_yigin": {"tex": "kar_yigini.svg", "h": 60.0},
	"lamba": {"tex": "lamba.svg", "h": 300.0},
	"cali_gece": {"tex": "cali.svg", "h": 80.0, "tint": Color("6070b8")},
	"kaya_gece": {"tex": "kaya.svg", "h": 56.0, "tint": Color("8a8fc8")},
}


# Yolun bir parçası: arka şerit, yol yüzeyi, ön yüz, zemin ve çizgiler (bir kez çizilir, önbellekte kalır)
class RoadChunk extends Node2D:
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	var theme: Dictionary
	var seed_value := 0

	func _band(top: PackedVector2Array, bottom: PackedVector2Array, top_color: Color, bottom_color: Color) -> void:
		var points := PackedVector2Array(top)
		var colors := PackedColorArray()
		colors.resize(top.size())
		colors.fill(top_color)
		for i in range(bottom.size() - 1, -1, -1):
			points.append(bottom[i])
			colors.append(bottom_color)
		draw_polygon(points, colors)

	func _line(offset: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in xs.size():
			out.append(Vector2(xs[i], ys[i] + offset))
		return out

	func _draw() -> void:
		var verge: Array = theme["verge"]
		var road: Array = theme["road"]
		var ground: Array = theme["ground"]
		# Arka şerit: üst kenarı hafif dalgalı
		var verge_top := PackedVector2Array()
		for i in xs.size():
			var x := xs[i]
			verge_top.append(Vector2(x, ys[i] - DEPTH - VERGE + sin(x * 0.021) * 5.0 + sin(x * 0.053) * 3.0))
		_band(verge_top, _line(-DEPTH + 2.0), verge[0], verge[1])
		# Yol yüzeyi, ön yüz ve zemin
		var far := _line(-DEPTH)
		var near := _line(0.0)
		_band(far, near, road[0], road[1])
		_band(_line(-1.0), _line(CURB), theme["curb"], theme["curb"].darkened(0.15))
		_band(_line(CURB - 1.0), _line(1400.0), ground[0], ground[1])
		# Zeminde birkaç küçük taş/ot
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var dot: Color = theme["ground_dot"]
		for k in xs.size() / 6:
			var i := rng.randi_range(0, xs.size() - 1)
			var depth := rng.randf_range(50.0, 330.0)
			var r := rng.randf_range(4.0, 9.0)
			draw_set_transform(Vector2(xs[i], ys[i] + CURB + depth), 0.0, Vector2(1.6, 1.0))
			draw_circle(Vector2.ZERO, r, Color(dot, 0.55))
		draw_set_transform(Vector2.ZERO)
		# Kenar çizgileri ve kesikli şerit çizgileri
		var edge: Color = theme["road_line"]
		draw_polyline(_line(-DEPTH + 2.0), Color(1, 1, 1, 0.35), 3.0, true)
		draw_polyline(_line(-1.5), Color(1, 1, 1, 0.45), 4.0, true)
		for offset in [-41.0, -70.0]:
			for i in xs.size() - 1:
				if fposmod(xs[i], 150.0) < 75.0:
					draw_line(Vector2(xs[i], ys[i] + offset), Vector2(xs[i + 1], ys[i + 1] + offset), edge, 4.0, true)


# Rampa: yol üstünde kama. Üst yüzü (açık), yan yüzü (koyu) ve üzerinde iki ok
class RampNode extends Node2D:
	var points_near := PackedVector2Array()   # rampanın yakın kenardaki üst çizgisi
	var road_y := PackedFloat32Array()        # altındaki yolun yakın kenarı
	var colors: Array

	func _draw() -> void:
		var n := points_near.size()
		var top := PackedVector2Array()
		for i in n:
			top.append(points_near[i])
		for i in range(n - 1, -1, -1):
			top.append(points_near[i] + Vector2(0, -DEPTH))
		draw_colored_polygon(top, colors[0])
		# Tahtalar
		for i in range(2, n - 1, 3):
			draw_line(points_near[i], points_near[i] + Vector2(0, -DEPTH), Color(colors[1], 0.55), 3.0, true)
		var side := PackedVector2Array()
		for i in n:
			side.append(points_near[i])
		for i in range(n - 1, -1, -1):
			side.append(Vector2(points_near[i].x, road_y[i]))
		draw_colored_polygon(side, colors[1])
		# Yan yüzde iki beyaz ok (">")
		var lip := points_near[n - 1]
		var h := road_y[n - 1] - lip.y
		for k in 2:
			var cx := lip.x - 40.0 - k * 46.0
			var cy := road_y[n - 1] - h * 0.3 * (1.0 - k * 0.35)
			var w := 14.0
			draw_polyline(PackedVector2Array([Vector2(cx - w, cy - w), Vector2(cx, cy), Vector2(cx - w, cy + w)]), Color(1, 1, 1, 0.8), 6.0, true)
		# Dış çizgi
		var outline := PackedVector2Array(side)
		outline.append(side[0])
		draw_polyline(outline, colors[2], 4.0, true)
		draw_polyline(PackedVector2Array([points_near[0] + Vector2(0, -DEPTH), points_near[n - 1] + Vector2(0, -DEPTH), points_near[n - 1]]), colors[2], 4.0, true)


# Başlangıç (beyaz) ve bitiş (damalı) çizgisi
class LineNode extends Node2D:
	var y := 0.0
	var finish := false

	func _draw() -> void:
		if not finish:
			draw_rect(Rect2(-8, y - DEPTH, 16, DEPTH), Color(1, 1, 1, 0.9))
			return
		var rows := 6
		var size := DEPTH / rows
		for r in rows:
			for c in 2:
				var dark := (r + c) % 2 == 0
				draw_rect(Rect2(-size + c * size, y - DEPTH + r * size, size, size), Color("3a3050") if dark else Color.WHITE)
		for c in 2:
			draw_rect(Rect2(-size + c * size, y, size, CURB), Color.WHITE if c == 0 else Color("3a3050"))


var index := 0
var theme: Dictionary = {}
var curve := Curve2D.new()
var start_s := 0.0
var finish_s := 0.0
var length := 0.0
var ramps: Array[Dictionary] = []        # s0, s1, x0, x1, size, height
var obstacles: Array[Dictionary] = []    # type, s, x
var stars: Array[Dictionary] = []        # pos, node, taken, phase

var _ys := PackedFloat32Array()          # yolun yakın kenarının y'si (x = i * STEP)
var _ss := PackedFloat32Array()          # aynı noktalarda yol boyunca uzaklık
var _decor_layer: Node2D
var _road_layer: Node2D
var _items_layer: Node2D
var _stars_layer: Node2D
var _flag: Sprite2D
var _time := 0.0


func _init() -> void:
	_decor_layer = Node2D.new()
	_road_layer = Node2D.new()
	_items_layer = Node2D.new()
	add_child(_decor_layer)
	add_child(_road_layer)
	add_child(_items_layer)


# Arabalar ayrı bir düğümde; yıldızlar arabaların önünde görünsün diye katmanı dışarıdan verilir
func set_stars_layer(layer: Node2D) -> void:
	_stars_layer = layer


# --- Yerleşim (çizimden bağımsız: validate de kullanır) ---

# Pistin yükseklik dizisini ve öğelerini x'e göre çıkarır
static func layout(p_index: int) -> Dictionary:
	var track: Dictionary = Pistler.TRACKS[p_index]
	var heights := PackedFloat32Array([0.0])
	var items: Array[Dictionary] = []
	var base := 0.0
	_extend(heights, LEAD_IN, base, "flat", 0.0)
	for piece in track["pieces"]:
		var x0 := (heights.size() - 1) * STEP
		var kind: String = piece["type"]
		match kind:
			"flat":
				_extend(heights, piece["len"], base, "flat", 0.0)
			"hill":
				_extend(heights, piece["len"], base, "hill", piece["h"])
			"slope":
				_extend(heights, piece["len"], base, "slope", piece["h"])
				base += piece["h"]
			"puddle", "bump":
				var span := PUDDLE_LEN if kind == "puddle" else BUMP_LEN
				_extend(heights, span, base, "flat", 0.0)
				items.append({"kind": kind, "x": x0 + span * 0.5})
			"ramp":
				var size: int = piece.get("size", 1)
				var dims: Vector2 = RAMP_SIZE[size - 1]
				_extend(heights, RAMP_APPROACH + dims.x + landing_length(size), base, "flat", 0.0)
				items.append({"kind": "ramp", "x0": x0 + RAMP_APPROACH, "x1": x0 + RAMP_APPROACH + dims.x,
						"size": size, "height": dims.y, "stars": piece.get("stars", 0)})
		if kind != "ramp" and piece.get("stars", 0) > 0:
			items.append({"kind": "stars", "x0": x0, "x1": (heights.size() - 1) * STEP, "count": piece["stars"]})
	var finish_x := (heights.size() - 1) * STEP + 200.0
	_extend(heights, RUN_OUT, base, "flat", 0.0)
	return {"heights": heights, "items": items, "finish_x": finish_x}


static func _extend(heights: PackedFloat32Array, span: float, base: float, shape: String, h: float) -> void:
	var n := maxi(1, roundi(span / STEP))
	for i in n:
		var u := float(i + 1) / n
		var y := base
		if shape == "hill":
			y += h * (1.0 - cos(TAU * u)) * 0.5
		elif shape == "slope":
			y += h * (1.0 - cos(PI * u)) * 0.5
		heights.append(y)


# Rampadan sonra gereken düz alan: en hızlı araba (yokuş aşağı hızıyla) inip yavaşlayabilsin
static func landing_length(size: int) -> float:
	var height: float = RAMP_SIZE[size - 1].y
	var vy := Araba.jump_vy(size, 1.0)
	var t_up := vy / Araba.JUMP_G_UP
	var apex := vy * vy / (2.0 * Araba.JUMP_G_UP)
	var t_down := sqrt(2.0 * (apex + height) / Araba.JUMP_G_DOWN)
	return Araba.MAX_SPEED * 1.12 * (t_up + t_down) + 420.0


# Pistin ölçümlerini kontrol eder (pistler.gd validate() çağırır)
static func check_track(p_index: int) -> PackedStringArray:
	var errors := PackedStringArray()
	var data := layout(p_index)
	var heights: PackedFloat32Array = data["heights"]
	var road := 0.0
	var low := 0.0
	var high := 0.0
	var steepest := 0.0
	var star_count := 0
	for i in range(1, heights.size()):
		var dy := heights[i] - heights[i - 1]
		if (i - 1) * STEP >= START_X and (i - 1) * STEP < data["finish_x"]:
			road += Vector2(STEP, dy).length()
		low = minf(low, heights[i])
		high = maxf(high, heights[i])
		steepest = maxf(steepest, absf(dy) / STEP)
	for item in data["items"]:
		star_count += item.get("count", item.get("stars", 0))
	var seconds := road / (Araba.MAX_SPEED * 0.9)
	if seconds < 50.0 or seconds > 95.0:
		errors.append("pist %d: süre %.0f sn (50-95 olmalı)" % [p_index + 1, seconds])
	if high - low > 700.0:
		errors.append("pist %d: yükseklik farkı çok (%.0f px)" % [p_index + 1, high - low])
	if steepest > 0.32:
		errors.append("pist %d: çok dik yokuş (%.2f)" % [p_index + 1, steepest])
	if star_count < 10:
		errors.append("pist %d: az yıldız (%d)" % [p_index + 1, star_count])
	return errors


# Pistin tahmini süresi (sn, en hızlı gidişte) ve yıldız sayısı: testler ve ayar için
static func summary(p_index: int) -> Dictionary:
	var data := layout(p_index)
	var heights: PackedFloat32Array = data["heights"]
	var road := 0.0
	for i in range(1, heights.size()):
		if (i - 1) * STEP >= START_X and (i - 1) * STEP < data["finish_x"]:
			road += Vector2(STEP, heights[i] - heights[i - 1]).length()
	var total := 0
	for item in data["items"]:
		total += item.get("count", item.get("stars", 0))
	return {"seconds": road / (Araba.MAX_SPEED * 0.9), "stars": total, "length": road}


# --- Kurulum ---

func build(p_index: int) -> void:
	clear()
	index = p_index
	theme = Pistler.theme_of(index)
	var data := layout(index)
	var heights: PackedFloat32Array = data["heights"]
	var n := heights.size()
	_ys.resize(n)
	_ss.resize(n)
	curve.clear_points()
	for i in n:
		_ys[i] = -heights[i]
		curve.add_point(Vector2(i * STEP, _ys[i]))
		_ss[i] = 0.0 if i == 0 else _ss[i - 1] + Vector2(STEP, _ys[i] - _ys[i - 1]).length()
	length = curve.get_baked_length()
	start_s = s_at_x(START_X)
	finish_s = s_at_x(data["finish_x"])
	for item in data["items"]:
		match item["kind"]:
			"ramp":
				_add_ramp(item)
			"puddle", "bump":
				_add_obstacle(item["kind"], item["x"])
			"stars":
				_add_ground_stars(item["x0"], item["x1"], item["count"])
	_draw_road()
	_add_lines(data["finish_x"])
	_add_decor()


func clear() -> void:
	for layer in [_decor_layer, _road_layer, _items_layer]:
		for child in layer.get_children():
			child.queue_free()
	if _stars_layer:
		for child in _stars_layer.get_children():
			child.queue_free()
	ramps.clear()
	obstacles.clear()
	stars.clear()
	_flag = null


# --- Sorgular ---

# Şeridin (yakın kenardan lane px yukarı) s uzaklığındaki noktası
func lane_point(at: float, lane: float) -> Vector2:
	return curve.sample_baked(clampf(at, 0.0, length)) + Vector2(0, -lane)


func y_at_x(x: float) -> float:
	var f := clampf(x / STEP, 0.0, _ys.size() - 1.001)
	var i := int(f)
	return lerpf(_ys[i], _ys[i + 1], f - i)


func lane_y_at_x(x: float, lane: float) -> float:
	return y_at_x(x) - lane


func s_at_x(x: float) -> float:
	var f := clampf(x / STEP, 0.0, _ss.size() - 1.001)
	var i := int(f)
	return lerpf(_ss[i], _ss[i + 1], f - i)


# Yolun eğimi dy/dx (+ aşağı iniş)
func slope_at(at: float) -> float:
	var a := curve.sample_baked(clampf(at - 14.0, 0.0, length))
	var b := curve.sample_baked(clampf(at + 14.0, 0.0, length))
	return (b.y - a.y) / maxf(b.x - a.x, 0.001)


# Rampanın o noktadaki yüksekliği (rampa dışında 0)
func ramp_height(at: float) -> float:
	for ramp in ramps:
		if at < ramp["s0"]:
			return 0.0
		if at <= ramp["s1"]:
			var u: float = (at - ramp["s0"]) / (ramp["s1"] - ramp["s0"])
			return ramp["height"] * pow(u, 1.5)
	return 0.0


func progress(at: float) -> float:
	return clampf((at - start_s) / (finish_s - start_s), 0.0, 1.0)


# --- Öğeler ---

func _add_ramp(item: Dictionary) -> void:
	var ramp := {"x0": item["x0"], "x1": item["x1"], "s0": s_at_x(item["x0"]), "s1": s_at_x(item["x1"]),
			"size": item["size"], "height": item["height"]}
	ramps.append(ramp)
	var node := RampNode.new()
	node.colors = theme["ramp"]
	var x: float = item["x0"]
	while x <= item["x1"] + 0.1:
		var u: float = (x - item["x0"]) / (item["x1"] - item["x0"])
		var y := y_at_x(x)
		node.points_near.append(Vector2(x, y - item["height"] * pow(u, 1.5)))
		node.road_y.append(y)
		x += 10.0
	_items_layer.add_child(node)
	# Havadaki yıldızlar: rampaya gaza basarak gelen çocuğun arabasının yayı üzerinde
	var count: int = item["stars"]
	if count <= 0:
		return
	var car_scale: float = Araba.SCALES[0]
	var hw := Araba.half_wheel_base(car_scale)
	var s1: float = ramp["s1"]
	var rear_u := clampf((s1 - 2.0 * hw - ramp["s0"]) / (s1 - ramp["s0"]), 0.0, 1.0)
	var lift: float = (item["height"] * pow(rear_u, 1.5) + item["height"]) * 0.5
	var launch_x: float = item["x1"] - hw
	var launch := Vector2(launch_x, lane_y_at_x(launch_x, Araba.LANES[0]) - lift)
	var vy := Araba.jump_vy(item["size"], STAR_REF_SPEED)
	var vx := Araba.MAX_SPEED * STAR_REF_SPEED
	var t_up := vy / Araba.JUMP_G_UP
	for k in count:
		var t := t_up if count == 1 else t_up * lerpf(0.45, 1.6, float(k) / (count - 1))
		var pos := launch + Vector2(vx * t, -Araba.jump_height(t, vy) - Araba.BODY_CENTER * car_scale)
		_add_star(pos)


func _add_obstacle(kind: String, x: float) -> void:
	obstacles.append({"type": kind, "x": x, "s": s_at_x(x)})
	var sprite := Sprite2D.new()
	var y := y_at_x(x)
	if kind == "puddle":
		sprite.texture = load(G + "su.svg")
		sprite.scale = Vector2(270.0, DEPTH * 0.86) / sprite.texture.get_size() * Vector2(1, 1)
		sprite.position = Vector2(x, y - DEPTH * 0.48)
		sprite.modulate = theme["puddle"]
	else:
		sprite.texture = load(G + "kasis.svg")
		var k := (DEPTH + 18.0) / sprite.texture.get_height()
		sprite.scale = Vector2(k, k)
		sprite.position = Vector2(x, y - DEPTH * 0.5 + 4.0)
	_items_layer.add_child(sprite)


func _add_ground_stars(x0: float, x1: float, count: int) -> void:
	var span := x1 - x0
	for k in count:
		var x := lerpf(x0 + span * 0.18, x1 - span * 0.18, 0.5 if count == 1 else float(k) / (count - 1))
		_add_star(Vector2(x, lane_y_at_x(x, Araba.LANES[0]) - Araba.BODY_CENTER * Araba.SCALES[0]))


func _add_star(pos: Vector2) -> void:
	var node := Node2D.new()
	node.position = pos
	var glow := Sprite2D.new()
	glow.texture = load(G + "isik.svg")
	glow.scale = Vector2.ONE * STAR_SIZE * 1.9 / glow.texture.get_width()
	glow.modulate = Color(1, 0.95, 0.6, 0.7)
	node.add_child(glow)
	var star := Sprite2D.new()
	star.texture = load(G + "yildiz.svg")
	star.scale = Vector2.ONE * STAR_SIZE / star.texture.get_width()
	node.add_child(star)
	if _stars_layer:
		_stars_layer.add_child(node)
	stars.append({"pos": pos, "node": node, "taken": false, "phase": randf() * TAU})


func _add_lines(finish_x: float) -> void:
	for data in [[START_X, false], [finish_x, true]]:
		var line := LineNode.new()
		line.position = Vector2(data[0], 0)
		line.y = y_at_x(data[0])
		line.finish = data[1]
		_items_layer.add_child(line)
	_flag = Sprite2D.new()
	_flag.texture = load(G + "bayrak.svg")
	var k := 250.0 / _flag.texture.get_height()
	_flag.scale = Vector2(k, k)
	_flag.offset = Vector2(_flag.texture.get_width() * 0.5 - 19.0 / 160.0 * _flag.texture.get_width(), -_flag.texture.get_height() * 0.5)
	_flag.position = Vector2(finish_x, y_at_x(finish_x) - DEPTH - 6.0)
	_decor_layer.add_child(_flag)


func finish_position() -> Vector2:
	return lane_point(finish_s, DEPTH * 0.5)


# --- Çizim ---

func _draw_road() -> void:
	var n := _ys.size()
	var a := 0
	while a < n - 1:
		var b := mini(a + CHUNK_POINTS, n - 1)
		var chunk := RoadChunk.new()
		chunk.theme = theme
		chunk.seed_value = index * 1000 + a
		for i in range(a, b + 1):
			chunk.xs.append(i * STEP)
			chunk.ys.append(_ys[i])
		_road_layer.add_child(chunk)
		a = b


func _add_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 97 * index + 13
	var names: Array = theme["decor"]
	var gap: Array = theme["decor_gap"]
	var x := rng.randf_range(80.0, 300.0)
	var end := (_ys.size() - 1) * STEP
	while x < end:
		var info: Dictionary = DECOR[names[rng.randi() % names.size()]]
		var sprite := Sprite2D.new()
		sprite.texture = load(G + info["tex"])
		var k: float = info["h"] / sprite.texture.get_height() * rng.randf_range(0.85, 1.1)
		sprite.scale = Vector2(k, k)
		sprite.flip_h = info["tex"] != "lamba.svg" and rng.randf() < 0.5
		var ground := y_at_x(x) - DEPTH - VERGE * 0.4
		sprite.position = Vector2(x, ground - sprite.texture.get_height() * k * 0.5)
		sprite.modulate = info.get("tint", Color.WHITE)
		_decor_layer.add_child(sprite)
		x += rng.randf_range(gap[0], gap[1])
	# Gece şehrinde sokak lambaları düzenli aralıkla
	if theme.has("lamp_gap"):
		var lamp_x := 300.0
		while lamp_x < end:
			var lamp := Sprite2D.new()
			lamp.texture = load(G + "lamba.svg")
			var k: float = DECOR["lamba"]["h"] / lamp.texture.get_height()
			lamp.scale = Vector2(k, k)
			lamp.position = Vector2(lamp_x, y_at_x(lamp_x) - DEPTH - VERGE * 0.4 - lamp.texture.get_height() * k * 0.5)
			_decor_layer.add_child(lamp)
			_add_lamp_light(lamp, k)
			lamp_x += theme["lamp_gap"]


# Sokak lambası: fenerin etrafında ve yolda yumuşak ışık (toplamalı karışım)
func _add_lamp_light(lamp: Sprite2D, k: float) -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var tex: Texture2D = load(G + "isik.svg")
	var tex_size := lamp.texture.get_size()
	var head := lamp.position + (Vector2(81, 54) / Vector2(120, 300) * tex_size - tex_size * 0.5) * k
	var glow := Sprite2D.new()
	glow.texture = tex
	glow.material = add
	glow.scale = Vector2.ONE * 170.0 / tex.get_width()
	glow.position = head
	glow.modulate = Color(1, 0.85, 0.5, 0.8)
	_decor_layer.add_child(glow)
	var pool := Sprite2D.new()
	pool.texture = tex
	pool.material = add
	pool.scale = Vector2(340.0, DEPTH * 1.1) / tex.get_size()
	pool.position = Vector2(head.x, y_at_x(head.x) - DEPTH * 0.5)
	pool.modulate = Color(1, 0.85, 0.5, 0.45)
	_items_layer.add_child(pool)


func _process(delta: float) -> void:
	_time += delta
	# Yıldızlar hafifçe süzülüp sallanır, bayrak dalgalanır
	for star in stars:
		if star["taken"]:
			continue
		var node: Node2D = star["node"]
		var phase: float = star["phase"]
		node.position = star["pos"] + Vector2(0, sin(_time * 3.0 + phase) * 5.0)
		node.get_child(1).rotation = sin(_time * 2.0 + phase) * 0.12
	if _flag:
		_flag.skew = sin(_time * 4.0) * 0.08
