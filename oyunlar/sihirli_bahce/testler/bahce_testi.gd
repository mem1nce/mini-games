extends SceneTree
# Sihirli Bahçe oynanış testi (headless). Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://oyunlar/sihirli_bahce/testler/bahce_testi.gd
# Denetler: bütün bitki görselleri var; keseler sadece kendi bitkilerini verir ve nadirler daha seyrek çıkar;
# ekilen bitki 4 kez su + güneşle olgunlaşır; fazla suda birikinti olur, güneş kurutur; gece bitkisi gündüz
# kapalı, gece açık; rüzgar tohumu boş parsele taşır; toplanan bitki albüme eklenir; kayıt geri yüklenir.
# Hata varsa çıkış kodu 1. Sonunda user://sihirli_bahce.cfg silinir.

const Bitkiler := preload("res://oyunlar/sihirli_bahce/bitkiler.gd")
const Kayit := preload("res://oyunlar/sihirli_bahce/kayit.gd")

var failures := 0
var game: Node


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	root.content_scale_size = Vector2i(1280, 720)
	_check_data()
	game = load("res://oyunlar/sihirli_bahce/sihirli_bahce.tscn").instantiate()
	root.add_child(game)
	await _frames(10)
	await _check_growth()
	await _check_night()
	await _check_wind_and_harvest()
	await _check_save()
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


func _check_data() -> void:
	_expect(Bitkiler.PLANTS.size() >= 12, "en az 12 bitki")
	for id in Bitkiler.PLANTS:
		for stage in 5:
			_expect(Bitkiler.texture(id, stage) != null, "%s aşama %d görseli" % [id, stage])
		if Bitkiler.is_night(id):
			_expect(Bitkiler.texture(id, 4, false) != null, "%s kapalı görseli" % id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var album := {}
	for id in Bitkiler.PLANTS:
		album[id] = 1          # keşif şansı artışı olmadan saf ağırlıkları dene
	for pack in Bitkiler.PACKS:
		var counts := {}
		for i in 3000:
			var id := Bitkiler.pick(pack, album, rng)
			_expect(Bitkiler.PLANTS[id]["pack"] == pack, "%s kesesi başka keseden bitki verdi: %s" % [pack, id])
			counts[id] = counts.get(id, 0) + 1
		for id in counts:
			if Bitkiler.PLANTS[id]["rarity"] == Bitkiler.RARE:
				_expect(counts[id] < 3000 * 0.15, "%s nadir olmalı (%d/3000)" % [id, counts[id]])
		print("kese %s: %s" % [pack, counts])


func _grow(plot: Node2D) -> void:
	while plot.stage < 4:
		for f in 80:
			plot.rain(1.0 / 60.0)
			await process_frame
		_expect(plot.need == "sun", "sulanınca güneş istemeli (aşama %d)" % plot.stage)
		game._sun()
		await _frames(110)


func _check_growth() -> void:
	var plot: Node2D = game.plots[0]
	plot.plant_seed("lale")
	_expect(plot.need == "water", "yeni tohum su istemeli")
	await _grow(plot)
	_expect(plot.is_mature() and plot.is_open(), "lale olgunlaşmalı")
	for f in 100:
		plot.rain(1.0 / 60.0)
		await process_frame
	_expect(plot.puddle, "fazla suda birikinti olmalı")
	game._sun()
	await _frames(20)
	_expect(not plot.puddle, "güneş birikintiyi kurutmalı")


func _check_night() -> void:
	var plot: Node2D = game.plots[1]
	plot.plant_seed("ay_cicegi")
	await _grow(plot)
	_expect(plot.is_mature() and not plot.is_open(), "gece bitkisi gündüz kapalı olmalı")
	game._set_night(true)
	await _frames(90)
	_expect(plot.is_open(), "gece bitkisi gece açmalı")
	game._set_night(false)
	await _frames(90)


func _check_wind_and_harvest() -> void:
	var empty_before := 0
	for plot in game.plots:
		if plot.is_empty():
			empty_before += 1
	game._wind()
	await _frames(160)
	var empty_after := 0
	for plot in game.plots:
		if plot.is_empty():
			empty_after += 1
	_expect(empty_after < empty_before, "rüzgar olgun bitkinin tohumunu boş parsele taşımalı")
	game.plots[0].harvest()
	await _frames(200)
	_expect(int(game.album_data.get("lale", 0)) == 1, "toplanan lale albüme eklenmeli")
	_expect(game.plots[0].is_empty(), "toplanınca parsel boşalmalı")


func _check_save() -> void:
	game._save_now()
	var state := Kayit.load_state()
	_expect(int(state["album"].get("lale", 0)) == 1, "albüm kaydedilmeli")
	var filled := 0
	for data in state["plots"]:
		if not data.is_empty():
			filled += 1
	_expect(filled >= 2, "dolu parseller kaydedilmeli")


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("HATA: ", message)
