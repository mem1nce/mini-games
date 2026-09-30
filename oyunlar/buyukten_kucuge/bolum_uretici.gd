class_name SizeLevelGenerator
extends RefCounted
# Bölüm üretici (sahneden bağımsız, saf mantık): bölüm ayarına (SizeLevel) ve ekran boyutuna göre
# nesne türünü, renkleri, boyutları, başlangıç yerlerini ve hedefleri (kule yeri / yuvalar / sıra) üretir.
# Kurallar (testler/uretici_testi.gd denetler; problems()):
#   - ardışık iki nesnenin boyut farkı bölümün step değeri (en az settings.min_step),
#   - dokunma alanı en az ekranın kısa kenarı x touch_ratio (görsel küçük olsa da),
#   - nesneler başlangıçta üst üste binmez, yuvaların / direğin üstünde başlamaz, ekrandan taşmaz,
#   - soldan sağa başlangıç sırası hiçbir zaman doğru (ya da tam ters) değildir, ikisine de çok yakın olmaz (is_mixed).
# Boyutlar ekrana göre ölçeklenir: sığmazsa hepsi birlikte küçültülür (fark oranı değişmez).
# Yeni etkinlik türü: Plan'a gerekeni ekle, generate() içindeki match'e bir _layout_<tür>() yaz.

const TOP_BAR := 112.0          # üstte geri düğmesi ve ilerleme yıldızları
const SIDE := 40.0              # kenar boşluğu (çentik ve kenarlar)
const BOTTOM := 14.0
const GAP := 14.0               # başlangıçta dokunma alanları arasında en az boşluk
const FLOOR := 420.0 / 720.0    # zemin çizgisi (arka_plan.svg ile aynı oran)
const RING_OVERLAP := 0.2       # kuledeki halka alttakinin üstüne bu oranda biner
const SLOT_PAD := 22.0          # yuvanın içindeki boşluk
const SLOT_GAP := 16.0
const DOT_ROW := 50.0           # yuvaların üstündeki yön ipucu satırı
const LINEUP_GAP := 22.0        # bebek kutlamasında yan yana diziliş aralığı

const PALETTE: Array[Color] = [Color("ff5a6e"), Color("ff9f40"), Color("ffd23f"), Color("5cc95c"), Color("4fa8ff"),
	Color("a66bff"), Color("ff7fc8"), Color("3ccbc0")]
# Nesne türüne özel renkler (yoksa PALETTE; boş dizi: renklenmez)
const KIND_COLORS := {
	"balik": [Color("ff8a3d"), Color("4fa8ff"), Color("ff7fc8"), Color("5cc95c"), Color("a66bff"), Color("ffc93d")],
	"ayi": [Color("c8864b"), Color("e0a85c"), Color("a8744a"), Color("b9a3d9"), Color("e89ab0"), Color("8fb4d9")],
	"agac": [Color("5fbf5f"), Color("8ccf3f"), Color("3fae8a"), Color("f0a040"), Color("e87060"), Color("78c878")],
	"cicek": [Color("ff7fc8"), Color("ff5a6e"), Color("a66bff"), Color("ffb13d"), Color("4fa8ff"), Color("ff9f40")],
	"zurafa": [],
}
# Bebek renk aileleri: [en açık (en küçük), en koyu (en büyük)]
const DOLL_TONES := {
	"tavsan": [[Color("ffd3e4"), Color("e0558f")], [Color("e9dcff"), Color("8a62d6")]],
	"ayi": [[Color("f3cd98"), Color("8e5a34")], [Color("ffe0a8"), Color("c07a30")]],
	"penguen": [[Color("c2dcff"), Color("3458b8")], [Color("b8f0ea"), Color("2a8f9a")]],
}


class Plan:
	var index: int
	var level: SizeLevel
	var kind: String
	var count: int
	var step: float
	var art: String                          # şablon adı (bebekte karakter: "tavsan")
	var screen: Vector2
	var area: Rect2                          # oyun alanı (üst çubuğun altı, kenar boşlukları içi)
	var floor_y: float
	var touch: float                         # dokunma alanının en küçük kenarı (px)
	var sizes: Array[Vector2] = []           # sıra (rank, 0 = en büyük) -> görünen boyut
	var colors: Array[Color] = []
	var starts: Array[Vector2] = []          # sıra -> başlangıç merkezi
	var targets: Array[Vector2] = []         # halka: kuledeki yeri; dizi: yuvadaki yeri; bebek: kutlamadaki yeri
	var slots: Array[Rect2] = []             # dizi: soldan sağa yuvalar
	var slot_rank: Array[int] = []           # dizi: yuva -> o yuvaya gelecek sıra
	var rod: Rect2                           # halka: direk (topuzdan tabana)
	var rod_color: Color
	var base_top: float                      # halka: direğin tabanının üstü (ilk halka buraya oturur)
	var hint_center: Vector2                 # dizi: yön noktalarının ortası
	var direction_changed: bool              # dizi: yön önceki dizi bölümünden farklı (ya da ilk dizi)

	func doll_art(part: String) -> String:
		return "bebek_%s_%s" % [art, part]

	func touch_size(rank: int) -> Vector2:
		return Vector2(maxf(sizes[rank].x, touch), maxf(sizes[rank].y, touch))

	func touch_rect(rank: int) -> Rect2:
		var size := touch_size(rank)
		return Rect2(starts[rank] - size / 2.0, size)

	# Soldan sağa başlangıç sırası (sıra numaraları)
	func start_order() -> Array[int]:
		var order: Array[int] = []
		for r in count:
			order.append(r)
		order.sort_custom(func(a: int, b: int) -> bool: return starts[a].x < starts[b].x)
		return order

	# Nesnelerin başlangıçta üstünde olmaması gereken yerler
	func blocked() -> Array[Rect2]:
		var out: Array[Rect2] = slots.duplicate()
		if kind == "halka":
			out.append(rod)
		return out


var settings: SizeSettings
var rng := RandomNumberGenerator.new()
var _last_art := {}


func _init(level_settings: SizeSettings, seed_value: int = -1) -> void:
	settings = level_settings
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func generate(index: int, screen: Vector2) -> Plan:
	var level := settings.level(index)
	var plan := Plan.new()
	plan.index = index
	plan.level = level
	plan.kind = level.kind
	plan.count = level.count
	plan.step = maxf(level.step, settings.min_step)
	plan.screen = screen
	plan.area = Rect2(SIDE, TOP_BAR, screen.x - 2.0 * SIDE, screen.y - TOP_BAR - BOTTOM)
	plan.floor_y = screen.y * FLOOR
	plan.touch = settings.touch_ratio * minf(screen.x, screen.y)
	match level.kind:
		"halka":
			_layout_ring(plan)
		"dizi":
			_layout_row(plan)
		"bebek":
			_layout_dolls(plan)
		_:
			push_error("Büyükten Küçüğe: bilinmeyen etkinlik türü " + level.kind)
	return plan


# k. nesnenin en büyüğe oranı
func _factor(plan: Plan, rank: int) -> float:
	return pow(1.0 - plan.step, rank)


# --- Halka Kulesi: sağda direk, solda zeminde dağınık halkalar ---

func _layout_ring(plan: Plan) -> void:
	plan.art = "halka"
	plan.colors = _colors("halka", plan.count)
	plan.rod_color = PALETTE[rng.randi() % PALETTE.size()]
	var rod_art := SizeArt.info("direk")
	var ratio := 1.0 / SizeArt.aspect("halka")
	var width := minf(plan.area.size.x * 0.27, 330.0)
	for attempt in 40:
		plan.sizes.clear()
		for r in plan.count:
			plan.sizes.append(Vector2(width, width * ratio) * _factor(plan, r))
		# Direk: tabanı en büyük halkadan biraz geniş, sağ kenarda, zeminin altında durur
		var rod_w := width * 1.06
		var s := rod_w / float(rod_art["w"])
		var rod_x := plan.area.end.x - rod_w / 2.0
		var rod_bottom := plan.area.end.y
		plan.base_top = rod_bottom - (float(rod_art["bottom"]) - 2.0) * s
		plan.targets.clear()
		var bottom := plan.base_top + plan.sizes[0].y * 0.08
		for r in plan.count:
			var h := plan.sizes[r].y
			plan.targets.append(Vector2(rod_x, bottom - h / 2.0))
			bottom = bottom - h + h * RING_OVERLAP
		var last := plan.sizes[plan.count - 1].y
		var stack_top := plan.targets[plan.count - 1].y - last / 2.0
		var rod_top := stack_top - maxf(18.0, last * 0.5) - (float(rod_art["top"]) - 4.0) * s
		plan.rod = Rect2(rod_x - rod_w / 2.0, rod_top, rod_w, rod_bottom - rod_top)
		var zone_top := plan.floor_y - 50.0
		var zone := Rect2(plan.area.position.x, zone_top, plan.rod.position.x - 30.0 - plan.area.position.x, plan.area.end.y - zone_top)
		if rod_top >= plan.area.position.y and _scatter(plan, zone):
			return
		width *= 0.93
	push_error("Büyükten Küçüğe: halka bölümü sığmadı")


# --- Sıralama Dizisi: üstte yön noktaları, ortada yuvalar, altta (zeminde) karışık nesneler ---

func _layout_row(plan: Plan) -> void:
	var level := plan.level
	var kinds := settings.height_kinds if level.by_height else settings.size_kinds
	plan.art = _pick("dizi_boy" if level.by_height else "dizi", kinds)
	plan.colors = _colors(plan.art, plan.count)
	plan.direction_changed = _direction_changed(plan.index)
	var n := plan.count
	var area := plan.area
	plan.hint_center = Vector2(area.get_center().x, area.position.y + DOT_ROW / 2.0)
	var slots_top := area.position.y + DOT_ROW + 6.0
	var avail := area.end.y - slots_top - 24.0
	var max_h := minf(250.0, (avail - SLOT_PAD - GAP - 10.0) / 2.0)
	var max_w := (area.size.x - (n - 1) * SLOT_GAP) / n - SLOT_PAD
	for attempt in 40:
		plan.sizes.clear()
		if level.by_height:
			# Sadece boy değişir: hepsi aynı genişlikte, en kısası bile şablonun en kısa halinden uzun
			var shortest := max_h * _factor(plan, n - 1)
			var w := minf(minf(max_w, shortest / SizeArt.min_tall_ratio(plan.art)), max_h * 0.5)
			for r in n:
				plan.sizes.append(Vector2(w, max_h * _factor(plan, r)))
		else:
			var aspect := SizeArt.aspect(plan.art)
			var h0 := minf(max_h, max_w / aspect)
			for r in n:
				plan.sizes.append(Vector2(aspect * h0, h0) * _factor(plan, r))
		var slot_size := plan.sizes[0] + Vector2(SLOT_PAD, SLOT_PAD)
		var row_w := n * slot_size.x + (n - 1) * SLOT_GAP
		var x0 := area.get_center().x - row_w / 2.0
		plan.slots.clear()
		plan.slot_rank.clear()
		plan.targets.clear()
		plan.targets.resize(n)
		for s in n:
			var rect := Rect2(x0 + s * (slot_size.x + SLOT_GAP), slots_top, slot_size.x, slot_size.y)
			var rank := n - 1 - s if level.ascending else s
			plan.slots.append(rect)
			plan.slot_rank.append(rank)
			# Nesneler yuvanın tabanına oturur (boylar karşılaştırılabilsin)
			plan.targets[rank] = Vector2(rect.get_center().x, rect.end.y - SLOT_PAD / 2.0 - plan.sizes[rank].y / 2.0)
		var zone_top := slots_top + slot_size.y + 24.0
		if _scatter(plan, Rect2(area.position.x, zone_top, area.size.x, area.end.y - zone_top)):
			return
		max_h *= 0.93
		max_w *= 0.93
	push_error("Büyükten Küçüğe: dizi bölümü sığmadı")


# --- İç İçe Bebekler: zeminde dağınık bebekler; kutlamada soldan sağa büyükten küçüğe dizilirler ---

func _layout_dolls(plan: Plan) -> void:
	plan.art = _pick("bebek", settings.doll_kinds)
	var families: Array = DOLL_TONES.get(plan.art, [[Color("ffd3e4"), Color("e0558f")]])
	var family: Array = families[rng.randi() % families.size()]
	var n := plan.count
	for r in n:
		plan.colors.append((family[1] as Color).lerp(family[0], r / maxf(1.0, n - 1.0)))
	var aspect := SizeArt.aspect(plan.doll_art("alt"))
	var area := plan.area
	var h0 := minf(area.size.y * 0.62, 340.0)
	for attempt in 40:
		plan.sizes.clear()
		var total := (n - 1) * LINEUP_GAP
		for r in n:
			plan.sizes.append(Vector2(aspect * h0, h0) * _factor(plan, r))
			total += plan.sizes[r].x
		var x := area.get_center().x - total / 2.0
		var bottom := area.end.y - 6.0
		plan.targets.clear()
		for r in n:
			plan.targets.append(Vector2(x + plan.sizes[r].x / 2.0, bottom - plan.sizes[r].y / 2.0))
			x += plan.sizes[r].x + LINEUP_GAP
		var zone_top := area.position.y + 20.0
		if total <= area.size.x - 20.0 and _scatter(plan, Rect2(area.position.x, zone_top, area.size.x, area.end.y - zone_top)):
			return
		h0 *= 0.93
	push_error("Büyükten Küçüğe: bebek bölümü sığmadı")


# --- Dağıtma: nesneler zone içinde satırlara (alttan üste) karışık sırayla, aralarında rastgele boşlukla dizilir.
# Her nesnenin dokunma alanı + GAP ayrı bir kutu: üst üste binme olmaz. Başlangıç sırası doğru/ters çıkarsa yeniden.

func _scatter(plan: Plan, zone: Rect2) -> bool:
	var n := plan.count
	for attempt in 60:
		var order: Array[int] = []
		for r in n:
			order.append(r)
		_shuffle(order)
		var placed := false
		for rows in range(1, 4):
			if _place_rows(plan, zone, order, rows):
				placed = true
				break
		if not placed:
			return false
		if is_mixed(plan.start_order()):
			return true
	return false


func _place_rows(plan: Plan, zone: Rect2, order: Array[int], rows: int) -> bool:
	var per_row := ceili(order.size() / float(rows))
	var groups: Array = []
	var heights: Array[float] = []
	var total_h := 0.0
	for r in rows:
		var group := order.slice(r * per_row, (r + 1) * per_row)
		if group.is_empty():
			continue
		var width := 0.0
		var height := 0.0
		for rank in group:
			var fp := plan.touch_size(rank) + Vector2(GAP, GAP)
			width += fp.x
			height = maxf(height, fp.y)
		if width > zone.size.x:
			return false
		groups.append(group)
		heights.append(height)
		total_h += height
	if total_h > zone.size.y:
		return false
	plan.starts.clear()
	plan.starts.resize(plan.count)
	var row_gap := (zone.size.y - total_h) / groups.size()
	var bottom := zone.end.y
	for g in groups.size():
		var group: Array = groups[g]
		var width := 0.0
		for rank in group:
			width += plan.touch_size(rank).x + GAP
		# Boşluk rastgele paylaştırılır (nesneler arasına ve iki kenara)
		var weights: Array[float] = []
		var weight_sum := 0.0
		for k in group.size() + 1:
			weights.append(rng.randf_range(0.3, 1.0))
			weight_sum += weights[k]
		var slack := zone.size.x - width
		var x := zone.position.x + slack * weights[0] / weight_sum
		for k in group.size():
			var rank: int = group[k]
			var fp := plan.touch_size(rank) + Vector2(GAP, GAP)
			var lift := rng.randf() * minf(heights[g] - fp.y, 16.0)
			plan.starts[rank] = Vector2(x + fp.x / 2.0, bottom - fp.y / 2.0 - lift)
			x += fp.x + slack * weights[k + 1] / weight_sum
		bottom -= heights[g] + row_gap
	return true


# Başlangıç sırası yeterince karışık mı: soldan sağa sıra, doğru sıradan da tam tersinden de en az
# (en fazla ters çevrim sayısının) %25'i kadar uzak olmalı (3 nesnede: doğru ya da tam ters olmasın).
static func is_mixed(order: Array[int]) -> bool:
	var n := order.size()
	var inversions := 0
	for i in n:
		for j in range(i + 1, n):
			if order[i] > order[j]:
				inversions += 1
	var most := n * (n - 1) / 2
	return mini(inversions, most - inversions) >= maxi(1, most / 4)


func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


# Aynı türde art arda aynı nesne gelmesin
func _pick(key: String, kinds: PackedStringArray) -> String:
	var choices := Array(kinds)
	if choices.size() > 1 and _last_art.has(key):
		choices.erase(_last_art[key])
	var art: String = choices[rng.randi() % choices.size()]
	_last_art[key] = art
	return art


func _colors(art: String, count: int) -> Array[Color]:
	var source: Array = KIND_COLORS.get(art, PALETTE)
	var out: Array[Color] = []
	if source.is_empty():
		for k in count:
			out.append(Color.WHITE)
		return out
	var pool := source.duplicate()
	_shuffle(pool)
	for k in count:
		out.append(pool[k % pool.size()])
	return out


# Dizi bölümünün yönü önceki dizi bölümününkinden farklı mı (ilk dizi bölümü de "farklı" sayılır: yön tanıtılır)
func _direction_changed(index: int) -> bool:
	var level := settings.level(index)
	for i in range(index - 1, -1, -1):
		var previous := settings.level(i)
		if previous.kind == "dizi":
			return previous.ascending != level.ascending
	return true


# Planın kurallara uyup uymadığı (test ve hata ayıklama için); boşsa sorun yok
static func problems(plan: Plan, settings_used: SizeSettings) -> PackedStringArray:
	var out := PackedStringArray()
	var n := plan.count
	if plan.sizes.size() != n or plan.starts.size() != n or plan.colors.size() != n:
		out.append("eksik veri")
		return out
	if plan.step < settings_used.min_step - 0.0001:
		out.append("boyut farkı alt sınırın altında")
	for r in range(1, n):
		# Yükseklik her türde değişir (boy bölümünde tek değişen odur)
		var big := plan.sizes[r - 1].y
		var small := plan.sizes[r].y
		if 1.0 - small / big < plan.step - 0.001:
			out.append("%d-%d arası boyut farkı %.3f < %.3f" % [r - 1, r, 1.0 - small / big, plan.step])
		if plan.level.by_height and absf(plan.sizes[r].x - plan.sizes[0].x) > 0.01:
			out.append("boy bölümünde genişlik değişmiş")
	var screen := Rect2(Vector2.ZERO, plan.screen)
	for r in n:
		var rect := plan.touch_rect(r)
		if rect.size.x < plan.touch - 0.01 or rect.size.y < plan.touch - 0.01:
			out.append("%d. nesnenin dokunma alanı küçük" % r)
		if not screen.encloses(rect):
			out.append("%d. nesne ekrandan taşıyor" % r)
		if rect.position.y < TOP_BAR - 1.0:
			out.append("%d. nesne üst çubukta" % r)
		for other in range(r + 1, n):
			if rect.intersects(plan.touch_rect(other)):
				out.append("%d ve %d üst üste" % [r, other])
		for block in plan.blocked():
			if rect.intersects(block):
				out.append("%d. nesne yuva/direk üstünde başlıyor" % r)
	if not is_mixed(plan.start_order()):
		out.append("başlangıç sırası doğruya ya da tam terse çok yakın: %s" % [plan.start_order()])
	for rect in plan.slots:
		if not screen.encloses(rect):
			out.append("yuva ekrandan taşıyor")
	if plan.kind == "halka" and (plan.rod.position.y < TOP_BAR - 1.0 or plan.rod.end.y > plan.screen.y):
		out.append("direk sığmıyor")
	return out
