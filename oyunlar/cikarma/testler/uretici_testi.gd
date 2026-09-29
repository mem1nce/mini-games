extends SceneTree
# SubtractionGenerator ve ayar testleri. Çalıştırma (proje klasöründe):
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://oyunlar/cikarma/testler/uretici_testi.gd
# Hata varsa listeler ve 1 koduyla çıkar.

const ObjectBox := preload("res://oyunlar/cikarma/nesne_kutusu.gd")
const RUNS := 2000

var errors: PackedStringArray = []


func _init() -> void:
	var settings: SubtractionSettings = load("res://oyunlar/cikarma/ayarlar.tres")
	_check(settings.problems().is_empty(), "ayarlar.tres sorunlu: %s" % ", ".join(settings.problems()))
	_check(settings.level_count() == 20, "bölüm sayısı 20 olmalı, %d" % settings.level_count())
	_check(settings.stage_for_level(0) == settings.stages[0] and settings.stage_for_level(3) == settings.stages[0], "1-4. bölüm 1. aşama olmalı")
	_check(settings.stage_for_level(4) == settings.stages[1] and settings.stage_for_level(19) == settings.stages[4], "aşama sırası yanlış")

	_test_stages(settings, false)
	var with_zero: SubtractionSettings = settings.duplicate()
	with_zero.allow_zero = true
	with_zero.zero_chance = 0.3
	_test_stages(with_zero, true)
	_test_layout()

	if errors.is_empty():
		print("ÇIKARMA TESTİ: tamam (%d aşama x %d işlem x 2 ayar)" % [settings.stages.size(), RUNS])
		quit(0)
	else:
		for e in errors.slice(0, 30):
			printerr("HATA: " + e)
		printerr("ÇIKARMA TESTİ: %d hata" % errors.size())
		quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)


func _test_stages(settings: SubtractionSettings, zero_allowed: bool) -> void:
	var generator := SubtractionGenerator.new(settings, 12345 if zero_allowed else 777)
	var lowest := 0 if zero_allowed else 1
	for s in settings.stages.size():
		var stage := settings.stages[s]
		var tag := "aşama %d%s" % [s + 1, " (0 açık)" if zero_allowed else ""]
		var previous: SubtractionGenerator.Problem = null
		var recent: Array[Vector2i] = []
		var answer_slots := {}
		var zero_seen := false
		var operand_distractor_seen := false
		for i in RUNS:
			var p := generator.generate(stage)
			var what := "%s: %d - %d" % [tag, p.a, p.b]
			_check(p.answer == p.a - p.b, what + " cevap yanlış")
			_check(p.a <= stage.max_minuend, what + " eksilen sınırı aşıldı")
			_check(p.a <= 20, what + " eksilen ilk kutuya sığmaz")
			_check(p.answer >= 0, what + " cevap 0'dan küçük")
			for n in [p.b, p.answer]:
				if n == 0:
					zero_seen = true
					_check(zero_allowed, what + " 0 kullanıldı")
				else:
					_check(n >= maxi(stage.part_min, 1) and n <= stage.part_max, what + " aralık dışında")
			if previous:
				_check(not (p.a == previous.a and p.b == previous.b), what + " art arda aynı işlem")
			# Bütün aşamalarda en az 8 çift var: son 3 işlem tekrar gelmemeli
			if not zero_allowed:
				_check(not recent.has(Vector2i(p.a, p.b)), what + " son 3 işlemden biri tekrarlandı")
			recent.append(Vector2i(p.a, p.b))
			if recent.size() > SubtractionGenerator.HISTORY_SIZE:
				recent.pop_front()
			_check(p.choices.size() == stage.choice_count, what + " seçenek sayısı %d" % p.choices.size())
			_check(p.choices.count(p.answer) == 1, what + " doğru cevap seçeneklerde bir kez olmalı")
			var unique := {}
			for c in p.choices:
				_check(c >= lowest, what + " seçenek %d'den küçük: %d" % [lowest, c])
				unique[c] = true
				if c != p.answer:
					var near := absi(c - p.answer) <= settings.near_distance
					var operand := c == p.a or c == p.b
					if operand and not near:
						operand_distractor_seen = true
					_check(near or operand or c > p.answer, what + " çeldirici %d cevaptan uzak" % c)
			_check(unique.size() == p.choices.size(), what + " seçenekler farklı değil %s" % str(p.choices))
			answer_slots[p.choices.find(p.answer)] = true
			previous = p
		_check(answer_slots.size() == stage.choice_count, tag + ": doğru cevap her sıraya düşmüyor")
		if zero_allowed:
			_check(zero_seen, tag + ": 0 açıkken hiç 0 çıkmadı")
		if stage.max_minuend >= 10:
			_check(operand_distractor_seen, tag + ": işlemdeki sayı çeldirici olarak hiç kullanılmadı")


func _test_layout() -> void:
	for count in range(0, 21):
		var cells := ObjectBox.layout(count)
		var g := ObjectBox.grid(count)
		_check(cells.size() == count, "dizilim %d: %d konum" % [count, cells.size()])
		for i in cells.size():
			var c := cells[i]
			_check(absf(c.x) <= (g.x - 1) / 2.0 + 0.001 and absf(c.y) <= (g.y - 1) / 2.0 + 0.001, "dizilim %d: konum ızgara dışında %s" % [count, c])
			for j in range(i + 1, cells.size()):
				_check(c.distance_to(cells[j]) >= 0.99, "dizilim %d: nesneler çakışıyor" % count)
		if count > 5:
			_check(cells[0].y < cells[count - 1].y or count <= 5, "dizilim %d: beşli sıralar yukarıdan aşağı değil" % count)
			var first_row := 0
			for c in cells:
				if is_equal_approx(c.y, cells[0].y):
					first_row += 1
			_check(first_row == 5, "dizilim %d: ilk sırada 5 nesne olmalı" % count)
