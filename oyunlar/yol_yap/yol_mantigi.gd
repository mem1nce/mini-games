extends RefCounted
# Yol Yap oyununun ızgara mantığı: bilyenin yolunu hücre hücre hesaplar.
# Fizik motoru kullanılmaz; aynı yerleşim her zaman aynı yolu verir.
#
# Koordinatlar: Vector2i(sütun, satır), satır 0 en üstte.
# Bilye bir hücrede durur ve altındaki hücrenin üstünde yuvarlanır.

# Harita işaretleri
const EMPTY := "."
const GROUND := "#"
const WALL := "W"
const WATER := "~"
const START := "B"
const GOAL := "G"
const OUT := "out"

# Parça türleri
const BLOCK := "blok"
const RAMP_RIGHT := "rampa_sag"  # sağa doğru yükselir (sol alçak, sağ yüksek)
const RAMP_LEFT := "rampa_sol"   # sola doğru yükselir (sol yüksek, sağ alçak)
const BRIDGE := "kopru"          # 2 hücre uzunluğunda, yeri sol hücresidir
const SPRING := "yay"            # üstüne gelen bilyeyi bir üst seviyeye zıplatır

const UP := Vector2(0, -1)


static func map_size(level: Dictionary) -> Vector2i:
	var map: Array = level["map"]
	return Vector2i((map[0] as String).length(), map.size())


static func find_char(level: Dictionary, ch: String) -> Vector2i:
	var map: Array = level["map"]
	for r in map.size():
		var c := (map[r] as String).find(ch)
		if c != -1:
			return Vector2i(c, r)
	return Vector2i(-1, -1)


# Parçanın kapladığı hücreler (köprü 2 hücre kaplar)
static func piece_cells(type: String, cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [cell]
	if type == BRIDGE:
		cells.append(cell + Vector2i(1, 0))
	return cells


# placements: [{"type": ..., "cell": Vector2i}] -> {hücre: parça türü}
static func placements_to_cells(placements: Array) -> Dictionary:
	var cells := {}
	for p: Dictionary in placements:
		for cell in piece_cells(p["type"], p["cell"]):
			cells[cell] = p["type"]
	return cells


static func tile_at(level: Dictionary, placed: Dictionary, cell: Vector2i) -> String:
	var size := map_size(level)
	if cell.x < 0 or cell.x >= size.x or cell.y >= size.y:
		return OUT
	if cell.y < 0:
		return EMPTY  # ızgaranın üstü gökyüzü
	if placed.has(cell):
		return placed[cell]
	return (level["map"][cell.y] as String)[cell.x]


static func is_passable(tile: String) -> bool:
	return tile == EMPTY or tile == START or tile == GOAL


static func rises_toward(tile: String, dir: int) -> bool:
	return (tile == RAMP_RIGHT and dir > 0) or (tile == RAMP_LEFT and dir < 0)


static func falls_toward(tile: String, dir: int) -> bool:
	return (tile == RAMP_LEFT and dir > 0) or (tile == RAMP_RIGHT and dir < 0)


# Rampa yüzeyine dik, yukarı bakan yön (bilye yüzeyin bu kadar üstünde durur)
static func ramp_normal(tile: String) -> Vector2:
	if tile == RAMP_RIGHT:
		return Vector2(-1, -1).normalized()
	return Vector2(1, -1).normalized()


# Bilyenin yolunu hesaplar.
# Sonuç: {"ok": hedefe ulaştı mı, "end": "goal" / "fall" / "splash" / "bump" / "stuck",
#         "points": [{"p": değme noktası (hücre biriminde), "n": yüzey normali, "kind": "start" / "roll" / "fall" / "jump"}]}
static func simulate(level: Dictionary, placements: Array) -> Dictionary:
	var placed := placements_to_cells(placements)
	var pos := find_char(level, START)
	var goal := find_char(level, GOAL)
	var dir: int = level.get("dir", 1)
	var points: Array = [_rest_point(pos, "start")]

	for step in 200:
		if pos == goal:
			return {"ok": true, "end": "goal", "points": points}

		# 1) Altında ne var?
		var below := tile_at(level, placed, pos + Vector2i(0, 1))
		if below == OUT:
			points.append({"p": Vector2(pos.x + 0.5, pos.y + 3.0), "n": UP, "kind": "fall"})
			return {"ok": false, "end": "fall", "points": points}
		if below == WATER:
			points.append({"p": Vector2(pos.x + 0.5, pos.y + 1.7), "n": UP, "kind": "fall"})
			return {"ok": false, "end": "splash", "points": points}
		if is_passable(below):
			pos.y += 1
			points.append(_rest_point(pos, "fall"))
			continue
		if below == SPRING:
			var land := pos + Vector2i(dir, -1)
			if is_passable(tile_at(level, placed, pos + Vector2i(0, -1))) and is_passable(tile_at(level, placed, land)):
				pos = land
				points.append(_rest_point(pos, "jump"))
				continue
			return {"ok": false, "end": "bump", "points": points}

		# 2) Önündeki hücreye ilerle
		var next := pos + Vector2i(dir, 0)
		var ahead := tile_at(level, placed, next)

		if rises_toward(ahead, dir):
			# Rampadan yukarı çık
			var top := next + Vector2i(dir, -1)
			if not is_passable(tile_at(level, placed, next + Vector2i(0, -1))) or not is_passable(tile_at(level, placed, top)):
				return {"ok": false, "end": "bump", "points": points}
			var n := ramp_normal(ahead)
			var low_x := next.x + (0 if dir > 0 else 1)
			var high_x := next.x + (1 if dir > 0 else 0)
			points.append({"p": Vector2(low_x, pos.y + 1), "n": n, "kind": "roll"})
			points.append({"p": Vector2(high_x, pos.y), "n": n, "kind": "roll"})
			pos = top
			points.append(_rest_point(pos, "roll"))
			continue

		if ahead == WATER:
			points.append({"p": Vector2(next.x + 0.5, next.y + 1.7), "n": UP, "kind": "fall"})
			return {"ok": false, "end": "splash", "points": points}

		if is_passable(ahead):
			var under := tile_at(level, placed, next + Vector2i(0, 1))
			var after := next + Vector2i(dir, 1)
			if falls_toward(under, dir) and is_passable(tile_at(level, placed, after)):
				# Rampadan aşağı in
				var n := ramp_normal(under)
				var high_x := next.x + (0 if dir > 0 else 1)
				var low_x := next.x + (1 if dir > 0 else 0)
				points.append({"p": Vector2(high_x, pos.y + 1), "n": n, "kind": "roll"})
				points.append({"p": Vector2(low_x, pos.y + 2), "n": n, "kind": "roll"})
				pos = after
				points.append(_rest_point(pos, "roll"))
				continue
			pos = next
			points.append(_rest_point(pos, "roll"))
			continue

		# Duvar, zemin ya da rampanın dik tarafı: ilerleyemez
		return {"ok": false, "end": "bump", "points": points}

	return {"ok": false, "end": "stuck", "points": points}


# Bölümün doğru kurulduğunu ve çözülebildiğini kontrol eder. Sorun yoksa "" döner.
static func validate(level: Dictionary) -> String:
	var size := map_size(level)
	for row in level["map"]:
		if (row as String).length() != size.x:
			return "harita satırlarının uzunluğu farklı"
	if find_char(level, START).x < 0:
		return "haritada B (bilye) yok"
	if find_char(level, GOAL).x < 0:
		return "haritada G (hedef) yok"
	var used := {}
	for p: Dictionary in level["pieces"]:
		for cell in piece_cells(p["type"], p["cell"]):
			var tile := tile_at(level, {}, cell)
			if tile != EMPTY and tile != WATER:
				return "parça dolu bir hücreye konmuş: %s" % cell
			if used.has(cell):
				return "iki parça aynı hücrede: %s" % cell
			used[cell] = true
	if simulate(level, [])["ok"]:
		return "parçasız da çözülüyor"
	var result := simulate(level, level["pieces"])
	if not result["ok"]:
		return "parçalar yerindeyken çözülemiyor (%s)" % result["end"]
	return ""


static func _rest_point(cell: Vector2i, kind: String) -> Dictionary:
	return {"p": Vector2(cell.x + 0.5, cell.y + 1.0), "n": UP, "kind": kind}
