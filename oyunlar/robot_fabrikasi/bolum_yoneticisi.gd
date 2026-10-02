extends RefCounted
# Bölüm yöneticisi: şu anki bölüm, banda gönderilecek parçaların sırası (her kutuya kalan ihtiyacı kadar parça
# dolaşımda olur), robotun görünümü (o bölümde ayrılan parçalardan) ve kayıt (user://robot_fabrikasi.cfg).

const Bolumler := preload("res://oyunlar/robot_fabrikasi/bolumler.gd")
const Robot := preload("res://oyunlar/robot_fabrikasi/robot.gd")
const PATH := "user://robot_fabrikasi.cfg"

var index := 0                        # şu anki bölüm (0'dan)
var level: Dictionary = {}
var boxes: Array = []                 # kutu.gd düğümleri
var gallery := {}                     # robot şablonu → görünüm (yapılan robotlar)
var rng := RandomNumberGenerator.new()
var _circulating: Array[int] = []     # kutu başına bantta/boruda/elde dolaşan parça sayısı


func _init() -> void:
	rng.randomize()


func start(p_index: int, p_level: Dictionary, p_boxes: Array) -> void:
	index = p_index
	level = p_level
	boxes = p_boxes
	_circulating.clear()
	for b in boxes.size():
		_circulating.append(0)


func robot_id() -> String:
	if index < Bolumler.LEVELS.size():
		return level["robot"]
	return Robot.ORDER[rng.randi() % Robot.ORDER.size()]


# Banda gelecek bir sonraki parça: {"data": parça, "box": kutu} ya da boş
func next_part() -> Dictionary:
	var candidates: Array[int] = []
	for b in boxes.size():
		var remaining: int = boxes[b].capacity - boxes[b].stored.size()
		if _circulating[b] < remaining:
			candidates.append(b)
	if candidates.is_empty():
		return {}
	# En az parçası dolaşan kutu öncelikli (bant karışık gelsin)
	candidates.shuffle()
	candidates.sort_custom(func(a: int, b: int) -> bool: return _circulating[a] < _circulating[b])
	var box := candidates[0]
	_circulating[box] += 1
	return {"data": Bolumler.make_part(level, box, rng), "box": box}


func accepted(box: int) -> void:
	_circulating[box] = maxi(0, _circulating[box] - 1)


# Borudan dönen parça kutusu dolduysa artık gerekmez
func discarded(box: int) -> void:
	accepted(box)


func box_for(part: Dictionary) -> int:
	for b in boxes.size():
		if Bolumler.matches(boxes[b].rule, part) and not boxes[b].is_full():
			return b
	for b in boxes.size():
		if Bolumler.matches(boxes[b].rule, part):
			return b
	return -1


func is_complete() -> bool:
	for box in boxes:
		if not box.is_full():
			return false
	return not boxes.is_empty()


# Robotun görünümü: ayrılan parçaların renk ve şekillerinden
func robot_look() -> Dictionary:
	var parts: Array = []
	for box in boxes:
		parts.append_array(box.stored)
	if parts.is_empty():
		return Robot.DEFAULT_LOOK
	var shaped := parts.filter(func(p: Dictionary) -> bool: return p.get("shape", "") != "")
	var first: Dictionary = shaped[0] if not shaped.is_empty() else parts[0]
	var second: Dictionary = shaped[mini(1, shaped.size() - 1)] if shaped.size() > 1 else parts[mini(1, parts.size() - 1)]
	# Başka kutudan bir parça: kafa gövdeden farklı olsun
	for p in shaped:
		if p["color"] != first["color"] or p["shape"] != first["shape"]:
			second = p
			break
	return {
		"body": {"color": first["color"], "shape": first.get("shape", "") if first.get("shape", "") != "" else "kare"},
		"head": {"color": second["color"], "shape": second.get("shape", "") if second.get("shape", "") != "" else "daire"},
		"arm": parts[parts.size() / 2]["color"],
		"antenna": parts.back()["color"],
		"wheel": parts[mini(2, parts.size() - 1)]["color"],
	}


# --- Kayıt ---

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	index = maxi(0, int(config.get_value("ilerleme", "bolum", 0)))
	if config.has_section("galeri"):
		for id in config.get_section_keys("galeri"):
			var value = config.get_value("galeri", id, {})
			if value is Dictionary and Robot.ROBOTS.has(id):
				gallery[id] = value


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("ilerleme", "bolum", index)
	for id in gallery:
		config.set_value("galeri", id, gallery[id])
	config.save(PATH)
