class_name SubtractionGenerator
extends RefCounted
# Çıkarma işlemi ve cevap seçenekleri üretir. Sahneden bağımsızdır (testler/uretici_testi.gd sınar).
# Kurallar: çıkan ve sonuç aşamanın parça aralığında, eksilen <= max_minuend, 0 yalnızca allow_zero
# açıksa, aynı işlem art arda gelmez. Yanlış seçenekler cevaba yakın (±near_distance) ya da işlemdeki
# sayılardan biri; hepsi farklı ve >= 1 (allow_zero açıksa >= 0). Doğru cevabın yeri rastgeledir.


class Problem:
	var a: int
	var b: int
	var answer: int
	var choices: Array[int] = []

	func _init(minuend: int, subtrahend: int) -> void:
		a = minuend
		b = subtrahend
		answer = minuend - subtrahend


## Son kaç işlem mümkünse tekrar sorulmasın.
const HISTORY_SIZE := 3

var settings: SubtractionSettings
var rng := RandomNumberGenerator.new()
var _recent: Array[Vector2i] = []   # son sorulan işlemler (eksilen, çıkan), en yenisi sonda


# seed_value verilirse hep aynı sıra üretilir (test için)
func _init(game_settings: SubtractionSettings, seed_value: int = -1) -> void:
	settings = game_settings
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func generate(stage: SubtractionStage) -> Problem:
	var pairs := _pairs(stage)
	# Önce son işlemleri çıkarmayı dene; seçenek kalmazsa daha azını çıkar
	for keep in range(HISTORY_SIZE, 0, -1):
		var fresh := _without(pairs, _recent.slice(-keep))
		if not fresh.is_empty():
			pairs = fresh
			break
	var pair: Vector2i = pairs[rng.randi_range(0, pairs.size() - 1)]
	_recent.append(pair)
	if _recent.size() > HISTORY_SIZE:
		_recent.pop_front()
	var problem := Problem.new(pair.x, pair.y)
	problem.choices = _choices(problem, stage.choice_count)
	return problem


# Aşamada olabilecek bütün (eksilen, çıkan) çiftleri: çıkan ve sonuç parça aralığında.
# allow_zero açıksa bazen çıkanı ya da sonucu 0 olan çiftler (5 - 0, 5 - 5).
func _pairs(stage: SubtractionStage) -> Array[Vector2i]:
	var low := maxi(stage.part_min, 1)
	var high := mini(stage.part_max, stage.max_minuend - low)
	var result: Array[Vector2i] = []
	if settings.allow_zero and rng.randf() < settings.zero_chance:
		for n in range(low, mini(stage.part_max, stage.max_minuend) + 1):
			result.append(Vector2i(n, 0))
			result.append(Vector2i(n, n))
		if not result.is_empty():
			return result
	for b in range(low, high + 1):
		for c in range(low, high + 1):
			if b + c <= stage.max_minuend:
				result.append(Vector2i(b + c, b))
	if result.is_empty():
		# Ayar hatalı (SubtractionSettings.problems() bunu bildirir); oyun yine de çalışsın
		result.append(Vector2i(2, 1))
	return result


func _without(pairs: Array[Vector2i], removed: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pair in pairs:
		if not removed.has(pair):
			result.append(pair)
	return result


func _choices(problem: Problem, count: int) -> Array[int]:
	var lowest := 0 if settings.allow_zero else 1
	var wrong: Array[int] = []
	# Yaygın çocuk hatası: işlemdeki sayılardan birini cevap sanmak (ör. 5 - 2 için 5 ya da 2)
	if count > 1 and rng.randf() < settings.operand_distractor_chance:
		var operand := problem.a if rng.randf() < 0.5 else problem.b
		_try_add(wrong, operand, problem.answer, lowest)
	# Cevaba yakın sayılar: yakın olan daha sık seçilir (ağırlık: uzaklık 1 -> en büyük)
	var pool: Array[int] = []
	var weights: Array[float] = []
	for d in range(1, settings.near_distance + 1):
		for value in [problem.answer - d, problem.answer + d]:
			if value >= lowest and value != problem.answer and not wrong.has(value):
				pool.append(value)
				weights.append(1.0 / d)
	while wrong.size() < count - 1 and not pool.is_empty():
		var k := rng.rand_weighted(PackedFloat32Array(weights))
		wrong.append(pool[k])
		pool.remove_at(k)
		weights.remove_at(k)
	# Hâlâ eksikse (ör. cevap 1 ve near_distance 1) yukarı doğru tamamla
	var extra := settings.near_distance + 1
	while wrong.size() < count - 1:
		_try_add(wrong, problem.answer + extra, problem.answer, lowest)
		extra += 1
	var result: Array[int] = wrong.duplicate()
	result.append(problem.answer)
	_shuffle(result)
	return result


func _try_add(list: Array[int], value: int, answer: int, lowest: int) -> void:
	if value >= lowest and value != answer and not list.has(value):
		list.append(value)


# Array.shuffle() genel rastgeleliği kullanır; tohumlu test için kendi rng'mizle karıştır
func _shuffle(list: Array[int]) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := list[i]
		list[i] = list[j]
		list[j] = tmp
