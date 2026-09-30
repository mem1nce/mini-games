class_name FeedLevelGenerator
extends RefCounted
# Hayvanları Besle bölüm üretici (sahneden bağımsız, saf mantık). Aşamaya göre hayvanları, isteklerini,
# çeldiricileri ve masadaki tabakların sırasını seçer. Kurallar (problems() denetler):
#   - Bölümdeki hayvanların yediği yiyecekler çakışmaz: her yiyeceğin bölümde tek sahibi var.
#   - Çeldirici, bölümdeki hiçbir hayvanın yemediği bir yiyecektir.
#   - Her yiyecek türü masada bir tabaktır (aynı yiyecekten istenen adet kadar üst üste).
#   - Hiçbir tabak kendi hayvanının tam altında başlamaz (hayvanlar ve tabaklar aynı genişliğe eşit
#     aralıklı dizilir; is_under() buna göre bakar).
#   - Aynı hayvan kümesi art arda iki bölümde gelmez.


class Plan:
	var level: int = 0
	var stage: FeedStage
	var animals: Array[FeedAnimalData] = []
	## Her hayvanın istediği yiyecek (animals ile aynı sıra)
	var wants: Array[FeedFoodData] = []
	## Her hayvanın kaç tane istediği
	var counts: Array[int] = []
	var distractors: Array[FeedFoodData] = []
	## Masadaki tabaklar soldan sağa: her biri bir yiyecek türü
	var plates: Array[FeedFoodData] = []
	var bubble_always: bool = true

	# Tabaktaki yiyecek adedi (istenen adet; çeldirici 1)
	func plate_count(food: FeedFoodData) -> int:
		var k := wants.find(food)
		return counts[k] if k >= 0 else 1

	func animal_key() -> String:
		var ids: Array = animals.map(func(a: FeedAnimalData) -> String: return str(a.id))
		ids.sort()
		return ",".join(ids)


var settings: FeedSettings
var rng := RandomNumberGenerator.new()
var _last_key: String = ""


func _init(feed_settings: FeedSettings, seed_value: int = -1) -> void:
	settings = feed_settings
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func generate(level_index: int) -> Plan:
	var stage := settings.stage_for_level(level_index)
	var plan: Plan = null
	for attempt in 300:
		plan = _try(level_index, stage)
		if plan != null and (plan.animal_key() != _last_key or attempt >= 299):
			break
	if plan == null:
		push_error("Hayvanları Besle: %d. bölüm üretilemedi (ayarları kontrol et)" % (level_index + 1))
		return Plan.new()
	_last_key = plan.animal_key()
	return plan


func _try(level_index: int, stage: FeedStage) -> Plan:
	var plan := Plan.new()
	plan.level = level_index
	plan.stage = stage
	plan.bubble_always = stage.bubble_always
	# Hayvanlar: yedikleri birbirine karışmayanlardan rastgele
	var taken := {}
	for animal in _shuffled(settings.animals):
		if plan.animals.size() >= stage.animal_count:
			break
		if animal == null or animal.accepts.is_empty() or animal.accepts.any(func(f: FeedFoodData) -> bool: return taken.has(f)):
			continue
		plan.animals.append(animal)
		for food in animal.accepts:
			taken[food] = true
	if plan.animals.size() < stage.animal_count:
		return null
	for animal in plan.animals:
		plan.wants.append(animal.accepts[rng.randi_range(0, animal.accepts.size() - 1)])
		plan.counts.append(rng.randi_range(stage.want_min, stage.want_max))
	# Çeldiriciler: diğer hayvanların yiyeceklerinden, bu bölümde kimsenin yemediği
	var others: Array[FeedFoodData] = []
	for animal in settings.animals:
		for food in animal.accepts:
			if not taken.has(food) and not others.has(food):
				others.append(food)
	if others.size() < stage.distractor_count:
		return null
	plan.distractors.assign(_shuffled(others).slice(0, stage.distractor_count))
	# Tabak sırası: karışık, hiçbiri sahibinin altında değil
	var foods: Array = plan.wants + plan.distractors
	for attempt in 200:
		var order := _shuffled(foods)
		if not _any_under(plan, order):
			plan.plates.assign(order)
			return plan
	return null


func _any_under(plan: Plan, order: Array) -> bool:
	for p in order.size():
		var owner := plan.wants.find(order[p])
		if owner >= 0 and is_under(p, order.size(), owner, plan.animals.size()):
			return true
	return false


# Tabak (plate_index / plate_count) hayvanın (animal_index / animal_count) sütununun tam altında mı?
# İkisi de aynı genişliğe eşit aralıklı dizilir; tabak merkezi hayvan sütununun ortasındaki yarısına düşerse "altında".
static func is_under(plate_index: int, plate_count: int, animal_index: int, animal_count: int) -> bool:
	var plate_x := (plate_index + 0.5) / plate_count
	var animal_x := (animal_index + 0.5) / animal_count
	return absf(plate_x - animal_x) < 0.5 / animal_count - 0.001


func _shuffled(list: Array) -> Array:
	var result := list.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


# Planın kurallara uyup uymadığını denetler (test ve hata ayıklama için); boşsa sorun yok
static func problems(plan: Plan) -> PackedStringArray:
	var result := PackedStringArray()
	var stage := plan.stage
	var n := plan.animals.size()
	if n != stage.animal_count:
		result.append("hayvan sayısı %d, olması gereken %d" % [n, stage.animal_count])
	if plan.wants.size() != n or plan.counts.size() != n:
		result.append("istek listesi hayvan sayısıyla uyuşmuyor")
		return result
	var seen := {}
	for animal in plan.animals:
		if seen.has(animal):
			result.append("%s iki kez var" % animal.id)
		seen[animal] = true
	for k in n:
		var food := plan.wants[k]
		if not plan.animals[k].accepts.has(food):
			result.append("%s, istediği %s'i yemiyor" % [plan.animals[k].id, food.id])
		for j in n:
			if j != k and plan.animals[j].accepts.has(food):
				result.append("%s iki hayvana ait (%s, %s)" % [food.id, plan.animals[k].id, plan.animals[j].id])
		if plan.counts[k] < stage.want_min or plan.counts[k] > stage.want_max:
			result.append("%s %d tane istiyor (aralık %d-%d)" % [plan.animals[k].id, plan.counts[k], stage.want_min, stage.want_max])
	if plan.distractors.size() != stage.distractor_count:
		result.append("çeldirici sayısı %d, olması gereken %d" % [plan.distractors.size(), stage.distractor_count])
	for food in plan.distractors:
		for animal in plan.animals:
			if animal.accepts.has(food):
				result.append("çeldirici %s, %s tarafından yeniyor" % [food.id, animal.id])
	var expected: Array = plan.wants + plan.distractors
	if plan.plates.size() != expected.size():
		result.append("tabak sayısı %d, olması gereken %d" % [plan.plates.size(), expected.size()])
	for food in expected:
		if plan.plates.count(food) != 1:
			result.append("%s masada %d tabakta" % [food.id, plan.plates.count(food)])
	for p in plan.plates.size():
		var owner := plan.wants.find(plan.plates[p])
		if owner >= 0 and is_under(p, plan.plates.size(), owner, n):
			result.append("%s kendi hayvanının (%s) altında" % [plan.plates[p].id, plan.animals[owner].id])
	if plan.bubble_always != stage.bubble_always:
		result.append("balon ayarı aşamayla uyuşmuyor")
	return result
