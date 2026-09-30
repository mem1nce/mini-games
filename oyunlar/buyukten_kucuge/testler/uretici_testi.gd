extends SceneTree
# SizeLevelGenerator ve ayarlar.tres testi (headless). Proje kökünden:
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://oyunlar/buyukten_kucuge/testler/uretici_testi.gd
# Bölüm tablosunu (15 bölüm) ve her bölümden, birkaç ekran oranında (telefon, geniş telefon, tablet) yüzlerce
# bölüm üretip kuralları denetler (SizeLevelGenerator.problems): boyut farkı bölümün alt sınırının altına inmez,
# en küçük nesnenin dokunma alanı yeterli, başlangıç sırası hiçbir zaman doğru/ters değil, nesneler üst üste
# binmez, yuva/direk üstünde başlamaz, ekrandan taşmaz. Ayrıca tür çeşitliliği, renkler, dizi yuvaları, yön,
# kule/diziliş hedefleri ve boy bölümünde sabit genişlik. Hata varsa listeler ve 1 koduyla çıkar.

const RUNS := 300
const SCREENS := [Vector2(1280, 720), Vector2(1600, 720), Vector2(1520, 720), Vector2(1280, 960), Vector2(1280, 800)]
# Görevdeki tablo: tür, sayı, siluet, küçükten büyüğe, boy, boy atlama yok
const TABLE := [
	["halka", 3, false, false, false, false], ["dizi", 3, true, false, false, false], ["bebek", 3, false, false, false, false],
	["halka", 4, false, false, false, false], ["dizi", 4, true, false, true, false], ["bebek", 4, false, false, false, false],
	["dizi", 4, false, false, false, false], ["halka", 5, false, false, false, false], ["dizi", 4, true, true, false, false],
	["bebek", 5, false, false, false, true], ["dizi", 5, false, false, true, false], ["halka", 6, false, false, false, false],
	["dizi", 5, false, true, false, false], ["bebek", 6, false, false, false, true], ["dizi", 6, false, false, false, false],
]

var errors: PackedStringArray = []


func _init() -> void:
	var settings: SizeSettings = load("res://oyunlar/buyukten_kucuge/ayarlar.tres")
	_check(settings.problems().is_empty(), "ayarlar.tres sorunlu: %s" % ", ".join(settings.problems()))
	_check_table(settings)
	var generator := SizeLevelGenerator.new(settings, 7)
	var arts := {}
	var min_touch_seen := INF
	for screen: Vector2 in SCREENS:
		for run in RUNS:
			for index in settings.level_count():
				var plan := generator.generate(index, screen)
				var what := "%s, %d. bölüm (%s, %s)" % [screen, index + 1, plan.level.describe(), plan.art]
				for p in SizeLevelGenerator.problems(plan, settings):
					_check(false, what + ": " + p)
				_check_plan(plan, what)
				arts[plan.art] = true
				min_touch_seen = minf(min_touch_seen, minf(plan.touch_rect(plan.count - 1).size.x, plan.touch_rect(plan.count - 1).size.y))
	for art in ["halka", "balon", "balik", "ayi", "agac", "zurafa", "kalem", "cicek", "kule", "tavsan", "penguen"]:
		_check(arts.has(art), "hiç çıkmayan nesne: " + art)
	if errors.is_empty():
		print("BÜYÜKTEN KÜÇÜĞE ÜRETİCİ TESTİ: tamam (%d ekran x %d tur x %d bölüm; en küçük dokunma alanı %.0f px)"
			% [SCREENS.size(), RUNS, settings.level_count(), min_touch_seen])
		quit(0)
	else:
		for e in errors.slice(0, 40):
			printerr("HATA: " + e)
		printerr("BÜYÜKTEN KÜÇÜĞE ÜRETİCİ TESTİ: %d hata" % errors.size())
		quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)


func _check_table(settings: SizeSettings) -> void:
	_check(settings.level_count() == 15, "15 bölüm olmalı, %d" % settings.level_count())
	var previous_step := {}      # tür -> önceki bölümün farkı (her türde fark azalarak gider)
	for i in mini(settings.level_count(), TABLE.size()):
		var l := settings.level(i)
		var got := [l.kind, l.count, l.silhouettes, l.ascending, l.by_height, l.strict]
		_check(got == TABLE[i], "%d. bölüm %s, beklenen %s" % [i + 1, got, TABLE[i]])
		_check(l.step >= settings.min_step, "%d. bölümde fark alt sınırın altında" % (i + 1))
		_check(l.step <= previous_step.get(l.kind, 1.0) + 0.001, "%d. bölümde fark aynı türün önceki bölümünden büyük" % (i + 1))
		previous_step[l.kind] = l.step
	_check(settings.level(0).step >= 0.24, "ilk bölümlerde fark belirgin (~%25) olmalı")
	_check(absf(settings.level(14).step - settings.min_step) < 0.001, "son bölüm alt sınırda olmalı")
	_check(settings.min_step >= 0.12, "alt sınır %12'nin altında")


func _check_plan(plan: SizeLevelGenerator.Plan, what: String) -> void:
	var n := plan.count
	_check(plan.touch >= 0.12 * minf(plan.screen.x, plan.screen.y) - 0.01, what + ": dokunma alanı ayarı küçük")
	match plan.kind:
		"halka":
			for r in n:
				var t := plan.targets[r]
				_check(absf(t.x - plan.rod.get_center().x) < 0.5, what + ": halka direğin ortasında değil")
				if r > 0:
					_check(t.y < plan.targets[r - 1].y, what + ": kule yukarı doğru dizilmiyor")
			_check(plan.targets[n - 1].y - plan.sizes[n - 1].y / 2.0 > plan.rod.position.y, what + ": direk kuleden kısa")
		"dizi":
			_check(plan.slots.size() == n, what + ": yuva sayısı")
			for s in n:
				var expected := n - 1 - s if plan.level.ascending else s
				_check(plan.slot_rank[s] == expected, what + ": yuva sırası yanlış")
				_check(plan.slots[s].size.is_equal_approx(plan.slots[0].size), what + ": yuvalar eşit değil")
				_check(plan.slots[s].has_point(plan.targets[plan.slot_rank[s]]), what + ": hedef yuvada değil")
				if s > 0:
					_check(plan.slots[s].position.x >= plan.slots[s - 1].end.x, what + ": yuvalar üst üste")
			var tall := SizeArt.is_tall(plan.art)
			_check(tall == plan.level.by_height, what + ": boy bölümünde uzayan nesne olmalı")
		"bebek":
			_check(settings_has_doll(plan.art), what + ": bebek karakteri")
			for r in range(1, n):
				_check(plan.targets[r].x > plan.targets[r - 1].x, what + ": kutlama dizilişi soldan sağa değil")
				var gap := (plan.targets[r].x - plan.sizes[r].x / 2.0) - (plan.targets[r - 1].x + plan.sizes[r - 1].x / 2.0)
				_check(gap > 0.0, what + ": kutlamada bebekler üst üste")
			_check(plan.targets[0].x - plan.sizes[0].x / 2.0 >= 0.0 and plan.targets[n - 1].x + plan.sizes[n - 1].x / 2.0 <= plan.screen.x,
				what + ": kutlama dizilişi ekrana sığmıyor")


func settings_has_doll(art: String) -> bool:
	return ["tavsan", "ayi", "penguen"].has(art)
