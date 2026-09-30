extends SceneTree
# FeedLevelGenerator ve ayarlar.tres testi. Çalıştırma (proje klasöründe):
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://oyunlar/hayvan_besle/testler/uretici_testi.gd
# Her aşama türünde binlerce bölüm üretir ve kuralları denetler: hayvan sayısı ve tekliği, istek aralığı,
# her yiyeceğin bölümde tek sahibi olması, çeldiricinin hiçbir hayvana ait olmaması, masadaki yiyecek
# sayısının isteklerle tutması, hiçbir tabağın kendi hayvanının altında olmaması, art arda aynı hayvan
# kümesi gelmemesi, balon ayarı. Ayrıca yiyeceği çakışan hayvanlar eklenince de kuralların korunduğuna bakar.
# Hata varsa listeler ve 1 koduyla çıkar.

const RUNS := 3000

var errors: PackedStringArray = []


func _init() -> void:
	var settings: FeedSettings = load("res://oyunlar/hayvan_besle/ayarlar.tres")
	_check(settings.problems().is_empty(), "ayarlar.tres sorunlu: %s" % ", ".join(settings.problems()))
	_check(settings.level_count() == 12, "bölüm sayısı 12 olmalı, %d" % settings.level_count())
	_check(settings.animals.size() == 10, "10 hayvan olmalı, %d" % settings.animals.size())
	_check_table(settings)
	_run(settings, "ayarlar.tres", 1)
	_run(_with_shared_food(settings), "ortak yiyecekli", 2)

	if errors.is_empty():
		print("HAYVANLARI BESLE ÜRETİCİ TESTİ: tamam (%d aşama x %d bölüm x 2 ayar)" % [settings.stages.size(), RUNS])
		quit(0)
	else:
		for e in errors.slice(0, 40):
			printerr("HATA: " + e)
		printerr("HAYVANLARI BESLE ÜRETİCİ TESTİ: %d hata" % errors.size())
		quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)


# İstenen bölüm tablosu: 1-3: 2 hayvan, 4-6: 3, 7-9: 3 (1-3 istek, gizli balon), 10-12: 4 + 1 çeldirici
func _check_table(settings: FeedSettings) -> void:
	var expected := [[2, 1, 1, true, 0], [3, 1, 1, true, 0], [3, 1, 3, false, 0], [4, 1, 3, false, 1]]
	for level in 12:
		var stage := settings.stage_for_level(level)
		var row: Array = expected[level / 3]
		var got := [stage.animal_count, stage.want_min, stage.want_max, stage.bubble_always, stage.distractor_count]
		_check(got == row, "%d. bölüm ayarı %s, olması gereken %s" % [level + 1, got, row])


func _run(settings: FeedSettings, tag: String, seed_value: int) -> void:
	var generator := FeedLevelGenerator.new(settings, seed_value)
	var level_total := settings.level_count()
	var previous_key := ""
	var counts_seen := {}
	var foods_seen := {}
	for i in RUNS * settings.stages.size():
		var level := i % level_total
		var plan := generator.generate(level)
		var what := "%s, %d. bölüm (%s)" % [tag, level + 1, plan.animal_key()]
		for p in FeedLevelGenerator.problems(plan):
			_check(false, what + ": " + p)
		_check(plan.stage == settings.stage_for_level(level), what + ": yanlış aşama")
		# Masadaki yiyecekler: her tabakta istenen adet kadar, çeldirici tek
		var items := 0
		for food in plan.plates:
			items += plan.plate_count(food)
		var wanted := 0
		for c in plan.counts:
			wanted += c
			counts_seen[c] = true
		_check(items == wanted + plan.distractors.size(), what + ": masada %d yiyecek, istekler %d + çeldirici %d" % [items, wanted, plan.distractors.size()])
		# Doğru hayvan: masadaki her yiyeceği bölümde en fazla bir hayvan yer
		for food in plan.plates:
			foods_seen[food] = true
			var owners := plan.animals.filter(func(a: FeedAnimalData) -> bool: return a.accepts.has(food))
			var is_distractor := plan.distractors.has(food)
			_check(owners.size() == (0 if is_distractor else 1), what + ": %s için %d sahip" % [food.id, owners.size()])
		_check(plan.animal_key() != previous_key, what + ": aynı hayvanlar art arda geldi")
		previous_key = plan.animal_key()
	if tag == "ayarlar.tres":
		_check(counts_seen.has(1) and counts_seen.has(2) and counts_seen.has(3), "1, 2 ve 3 adet isteklerin hepsi çıkmadı: %s" % [counts_seen.keys()])
		_check(foods_seen.size() == 10, "bütün yiyecekler masaya gelmedi (%d)" % foods_seen.size())


# Kuralı zorlamak için: iki yeni hayvan, var olan hayvanlarla aynı yiyeceği yesin (maymun gibi muz yiyen,
# tavşan gibi havuç + peynir yiyen). Üretici bunları aynı bölüme koymamalı.
func _with_shared_food(settings: FeedSettings) -> FeedSettings:
	var copy: FeedSettings = settings.duplicate()
	copy.animals = settings.animals.duplicate()
	var by_id := {}
	for animal in settings.animals:
		by_id[animal.id] = animal
	var extra_1: FeedAnimalData = by_id[&"maymun"].duplicate()
	extra_1.id = &"maymun2"
	var extra_2: FeedAnimalData = by_id[&"tavsan"].duplicate()
	extra_2.id = &"tavsan2"
	extra_2.accepts = by_id[&"tavsan"].accepts + by_id[&"fare"].accepts
	copy.animals.append(extra_1)
	copy.animals.append(extra_2)
	_check(copy.problems().is_empty(), "ortak yiyecekli ayar sorunlu: %s" % ", ".join(copy.problems()))
	return copy
