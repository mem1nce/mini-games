extends SceneTree
# Sihirli Bahçe ekran görüntüsü testi (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://oyunlar/sihirli_bahce/testler/ekran_testi.gd -- <klasör>
# Boş bahçe (ipucu eli), keseyi parmakla parsele sürükleyip ekme, karışık bahçe, yağmur, güneş, tavşanlı kabak,
# rüzgar, gece, albüm ve ilk keşif kutlamasının görüntülerini <klasör> içine PNG olarak kaydeder.

var out := ""
var game: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sihirli_bahce.cfg"))
	game = load("res://oyunlar/sihirli_bahce/sihirli_bahce.tscn").instantiate()
	root.add_child(game)
	await frames(90)
	shot("s1_bos")
	# Pembe keseyi parmakla ortadaki parsele sürükle
	var pack: Vector2 = game._packs[0].get_global_rect().get_center()
	var plot_pos: Vector2 = game.plots[2].global_position + Vector2(0, -40)
	touch(0, pack, true)
	for k in 24:
		drag(0, pack.lerp(plot_pos, k / 23.0))
		await process_frame
	shot("s1b_surukle")
	touch(0, plot_pos, false)
	await frames(60)
	print("ekildi: ", game.plots[2].plant_id)
	shot("s1c_ekildi")
	var setups := [
		{"bitki": "lale", "asama": 4, "ihtiyac": ""},
		{"bitki": "aycicegi", "asama": 2, "ihtiyac": "water"},
		{"bitki": "kabak", "asama": 4, "ihtiyac": "", "birikinti": true},
		{"bitki": "mantar", "asama": 4, "ihtiyac": ""},
		{"bitki": "yildiz_agaci", "asama": 3, "ihtiyac": "sun"},
	]
	for i in 5:
		game.plots[i].from_dict(setups[i], false)
	game._critters.spawn("kelebek")
	game._critters.spawn("ugur")
	await frames(120)
	shot("s2_bahce")
	# Yağmur: bulutu ayçiçeğinin üstüne sürükle
	var cloud: Vector2 = game._weather.center("cloud")
	touch(0, cloud, true)
	var target: Vector2 = game.plots[1].global_position + Vector2(0, -360)
	for k in 30:
		drag(0, cloud.lerp(target, k / 29.0))
		await process_frame
	await frames(40)
	shot("s3_yagmur")
	touch(0, target, false)
	await frames(40)
	# Güneş
	touch(1, game._weather.center("sun"), true)
	touch(1, game._weather.center("sun"), false)
	await frames(30)
	shot("s4_gunes")
	await frames(90)
	# Kabağa dokun (tavşan)
	game.plots[2].tap_plant(game._weather.center("sun"))
	await frames(40)
	shot("s5_tavsan")
	# Rüzgar
	touch(2, game._weather.center("wind"), true)
	touch(2, game._weather.center("wind"), false)
	await frames(50)
	shot("s6_ruzgar")
	await frames(120)
	# Gece
	touch(3, game._weather.center("moon"), true)
	touch(3, game._weather.center("moon"), false)
	await frames(150)
	shot("s7_gece")
	# Albüm
	game.album_data = {"lale": 2, "kabak": 1, "kristal": 1}
	touch(4, game._album_icon.get_global_rect().get_center(), true)
	touch(4, game._album_icon.get_global_rect().get_center(), false)
	await frames(40)
	shot("s8_album")
	game._album.close_album()
	await frames(30)
	# İlk keşif kutlaması: lale toplanır (albümde 2 var) → sıradan; mantarı topla → yeni
	game.plots[3].harvest()
	await frames(55)
	shot("s9_kesif")
	await frames(200)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sihirli_bahce.cfg"))
	quit()


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("cekildi ", name)


func touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func drag(index: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	root.push_input(ev, true)
