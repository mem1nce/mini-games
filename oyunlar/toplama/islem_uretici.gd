class_name ProblemGenerator
extends RefCounted
# Toplama işlemi ve cevap seçenekleri üretir. Sahneden bağımsızdır (testler/uretici_testi.gd sınar).
# Kurallar: toplananlar aşamanın aralığında, toplam <= max_sum, 0 yalnızca allow_zero açıksa,
# aynı işlem art arda gelmez. Yanlış seçenekler cevaba yakın (±near_distance) ya da toplananlardan
# biri; hepsi farklı ve >= 1. Doğru cevabın düğme sırasındaki yeri rastgeledir.


class Problem:
	var a: int
	var b: int
	var answer: int
	var choices: Array[int] = []

	func _init(first: int, second: int) -> void:
		a = first
		b = second
		answer = first + second


## Son kaç işlem (ve yer değiştirmiş halleri) mümkünse tekrar sorulmasın.
const HISTORY_SIZE := 3

var settings: AdditionSettings
var rng := RandomNumberGenerator.new()
var _recent: Array[Vector2i] = []   # son sorulan işlemler, en yenisi sonda


# seed_value verilirse hep aynı sıra üretilir (test için)
func _init(game_settings: AdditionSettings, seed_value: int = -1) -> void:
	settings = game_settings
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func generate(stage: AdditionStage) -> Problem:
	var pairs := _pairs(stage)
	# Önce son işlemleri ve yer değiştirmiş hallerini (3+2 / 2+3) çıkarmayı dene; seçenek kalmazsa
	# daha azını çıkar. Bir önceki işlem her durumda çıkarılır (tek çift yoksa).
	for keep in range(HISTORY_SIZE, 0, -1):
		var removed: Array[Vector2i] = []
		for pair in _recent.slice(-keep):
			removed.append(pair)
			removed.append(Vector2i(pair.y, pair.x))
		var fresh := _without(pairs, removed)
		if fresh.is_empty() and keep == 1:
			fresh = _without(pairs, _recent.slice(-1))
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


# Aşamada olabilecek bütün (a, b) çiftleri. allow_zero açıksa bazen biri 0 olan çiftler.
func _pairs(stage: AdditionStage) -> Array[Vector2i]:
	var low := maxi(stage.addend_min, 1)
	var high := mini(stage.addend_max, stage.max_sum - low)
	var result: Array[Vector2i] = []
	if settings.allow_zero and rng.randf() < settings.zero_chance:
		for n in range(low, mini(stage.addend_max, stage.max_sum) + 1):
			result.append(Vector2i(n, 0))
			result.append(Vector2i(0, n))
		if not result.is_empty():
			return result
	for a in range(low, high + 1):
		for b in range(low, high + 1):
			if a + b <= stage.max_sum:
				result.append(Vector2i(a, b))
	if result.is_empty():
		# Ayar hatalı (AdditionSettings.problems() bunu bildirir); oyun yine de çalışsın
		result.append(Vector2i(1, 1))
	return result


func _without(pairs: Array[Vector2i], removed: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pair in pairs:
		if not removed.has(pair):
			result.append(pair)
	return result


func _choices(problem: Problem, count: int) -> Array[int]:
	var wrong: Array[int] = []
	# Yaygın çocuk hatası: toplananlardan birini cevap sanmak
	if count > 1 and rng.randf() < settings.addend_distractor_chance:
		var addend := problem.a if rng.randf() < 0.5 else problem.b
		_try_add(wrong, addend, problem.answer)
	# Cevaba yakın sayılar: yakın olan daha sık seçilir (ağırlık: uzaklık 1 -> en büyük)
	var pool: Array[int] = []
	var weights: Array[float] = []
	for d in range(1, settings.near_distance + 1):
		for value in [problem.answer - d, problem.answer + d]:
			if value >= 1 and value != problem.answer and not wrong.has(value):
				pool.append(value)
				weights.append(1.0 / d)
	while wrong.size() < count - 1 and not pool.is_empty():
		var k := rng.rand_weighted(PackedFloat32Array(weights))
		wrong.append(pool[k])
		pool.remove_at(k)
		weights.remove_at(k)
	# Hâlâ eksikse (ör. cevap 2 ve near_distance 1) yukarı doğru tamamla
	var extra := settings.near_distance + 1
	while wrong.size() < count - 1:
		_try_add(wrong, problem.answer + extra, problem.answer)
		extra += 1
	var result: Array[int] = wrong.duplicate()
	result.append(problem.answer)
	_shuffle(result)
	return result


func _try_add(list: Array[int], value: int, answer: int) -> void:
	if value >= 1 and value != answer and not list.has(value):
		list.append(value)


# Array.shuffle() genel rastgeleliği kullanır; tohumlu test için kendi rng'mizle karıştır
func _shuffle(list: Array[int]) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := list[i]
		list[i] = list[j]
		list[j] = tmp
