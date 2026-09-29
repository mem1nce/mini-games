extends SceneTree
# Zıpla Zıpla oynanış testi (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://oyunlar/zipla_zipla/testler/oyun_testi.gd -- <klasör> [GENxYÜK]
# Ana menüden karta dokunup oyunu açar (boyut verilirse oyunu doğrudan o boyutta açar), bir bot uygun anda
# dokunarak tırmanır ve şunları denetler: uygun anda dokununca hep konma, ödül sayacı = toplanan puan,
# basamağın kaybolma süresi, düşme -> oyun bitti, rekor kaydı, geri düğmesinin zıplatmaması, tekrar oyna.
# Ekran görüntülerini <klasör> içine kaydeder. Dokunmalar root.push_input(olay, true) ile gönderilir.

const SAVE := "user://zipla_zipla.cfg"
const GAME_SCENE := "res://oyunlar/zipla_zipla/zipla_zipla.tscn"

var out := ""
var prefix := ""
var game: Node
var _fails := 0
var _collected_points := 0
var _crumbled_step := -1
var _crumbled_frame := -1
var _frame := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fails += 1
		printerr("HATA: " + message)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if args.size() > 1:
		# Farklı ekran oranı: oyunu doğrudan aç
		var parts := args[1].split("x")
		var size := Vector2i(int(parts[0]), int(parts[1]))
		prefix = args[1] + "_"
		root.content_scale_size = Vector2i(1280, 720)
		root.size = size
		root.get_node("SahneGecis").visible = false
		game = load(GAME_SCENE).instantiate()
		root.add_child(game)
		await _frames(40)
		await _shot("01_basla")
		_tap(root.get_visible_rect().size / 2.0)
		await _climb(12)
		await _frames(30)
		await _shot("02_tirmanis")
		await _wait_state(3, 1200)
		await _frames(50)
		await _shot("03_bitti")
		_finish()
		return
	await _from_menu()
	await _play()
	_finish()


func _finish() -> void:
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if _fails == 0:
		print("oyun_testi: TAMAM")
	else:
		printerr("oyun_testi: %d hata" % _fails)
	quit(1 if _fails > 0 else 0)


# --- Ana menüden aç ---

func _from_menu() -> void:
	var menu: Node = load("res://ana_menu/ana_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(90)
	var index := -1
	for k in menu.OYUNLAR.size():
		if menu.OYUNLAR[k]["sahne"] == GAME_SCENE:
			index = k
	_check(index >= 0, "ana menüde Zıpla Zıpla kartı yok")
	if index < 0:
		game = load(GAME_SCENE).instantiate()
		root.add_child(game)
		return
	_tap(menu._kartlar[index].get_global_rect().get_center())
	for k in 300:
		await process_frame
		if current_scene and current_scene.scene_file_path == GAME_SCENE and not root.get_node("SahneGecis").gecis_suruyor:
			break
	_check(current_scene != null and current_scene.scene_file_path == GAME_SCENE, "karta dokununca oyun açılmadı")
	game = current_scene
	await _frames(20)


# --- Oynanış ---

func _play() -> void:
	game.reward_collected.connect(func(reward: JumpRewardType) -> void: _collected_points += reward.points)
	for platform in game.spawner.pool:
		platform.crumbled.connect(func(p: Node2D) -> void:
			_crumbled_step = p.index
			_crumbled_frame = _frame)
	_check(game.state == 0, "oyun READY durumunda başlamalı")
	await _shot("01_basla")

	# Geri düğmesine kısa dokunuş zıplatmamalı, oyunu da başlatmamalı
	var back: Control = game.hud.back_button
	var back_pos := back.get_global_rect().get_center()
	_touch(back_pos, true)
	await _frames(5)
	_touch(back_pos, false)
	await _frames(10)
	_check(game.state == 0 and not game.player.is_airborne(), "geri düğmesine dokunmak zıplatmamalı")

	# İlk dokunuş: 1. basamak kurbağanın üstünde bekler, zıplama hep başarılı
	_check(game.spawner.platform(1).frozen, "1. basamak başlangıçta beklemeli")
	_tap(Vector2(640, 400))
	await _frames(12)
	await _shot("02_zipla")
	await _frames(30)
	_check(game.steps == 1 and game.state == 1, "ilk zıplama 1. basamağa konmalı")
	# Tırman: bot uygun anda dokunur; hiç ıskalamamalı
	await _climb(13)
	_check(game.state == 1, "uygun anda dokununca hep konmalı (durum %d)" % game.state)
	_check(game.steps >= 14, "14 basamak tırmanılamadı (%d)" % game.steps)
	await _frames(45)
	_check(game.rewards == _collected_points, "sayaç (%d) toplanan puana (%d) eşit değil" % [game.rewards, _collected_points])
	_check(game.hud._counter_label.text == str(game.rewards), "sayaç yazısı yanlış")

	# Bekle: basamak zamanında kaybolmalı (titreme görüntüsü, sonra ufalanma ve düşme)
	var step: int = game.steps
	var platform: Node2D = game.player.platform
	var expected: float = game.balance.vanish_for(step)
	var started: int = _frame - 45
	for k in 600:
		await process_frame
		_frame += 1
		if platform.time_left() >= 0.0 and platform.time_left() < game.balance.warn_for(step) * 0.5:
			break
	await _shot("04_titreme")
	for k in 600:
		await process_frame
		_frame += 1
		if _crumbled_step == step:
			break
	var measured: float = (_crumbled_frame - started) / 60.0
	_check(absf(measured - expected) < 0.1, "basamak %.2f sn yerine %.2f sn'de kayboldu" % [expected, measured])
	await _frames(20)
	_check(game.state == 2, "basamak kaybolunca kurbağa düşmeli")
	await _shot("05_dusme")
	await _wait_state(3, 600)
	_check(game.state == 3, "düşünce oyun bitmeli")
	await _frames(50)
	await _shot("06_bitti")
	var config := ConfigFile.new()
	config.load(SAVE)
	_check(int(config.get_value("rekor", "basamak", 0)) == step, "rekor kaydedilmedi")
	_check(game.hud._over_steps.text == str(step) and game.hud._over_best.text == str(step), "panel sayıları yanlış")

	# Tekrar oyna: her şey sıfırlanır
	_tap(game.hud._replay.get_global_rect().get_center())
	await _frames(40)
	_check(game.state == 0 and game.steps == 0 and game.rewards == 0, "tekrar oyna sıfırlamadı")
	_check(game.hud._counter_label.text == "0", "sayaç sıfırlanmadı")
	_check(game.spawner.platform(0).fixed and game.player.platform == game.spawner.platform(0), "kurbağa başlangıç basamağında değil")

	# Iskalama: üstteki basamak uzaktayken dokununca kendi basamağına geri konmalı (basamak testte
	# bilerek uzağa konur); geri konuş yeni basamak sayılmaz ve kaybolma süresini sıfırlamaz
	_tap(Vector2(640, 400))
	await _climb(2)
	await _frames(30)
	_check(game.state == 1, "ıskalama denemesinden önce oyun sürmeli")
	var home: Node2D = game.player.platform
	var steps_before: int = game.steps
	var next: Node2D = game.spawner.platform(game.steps + 1)
	next.frozen = true
	next.position.x = game.player.position.x + next.width / 2.0 + game.balance.player_width * 0.4
	_check(not next.can_land(game.player.position.x, game.balance.player_width, game.balance.land_overlap_ratio), "basamak uzaktayken konulamamalı")
	var left_before: float = home.time_left()
	_tap(Vector2(640, 400))
	await _frames(14)
	await _shot("07_iskalama")
	await _frames(30)
	_check(game.state == 1 and not game.player.is_airborne(), "ıskalayınca kendi basamağına geri konmalı")
	_check(game.player.platform == home and game.steps == steps_before, "geri konuş yeni basamak sayılmamalı")
	_check(home.time_left() < left_before - 0.5, "geri konuş kaybolma süresini sıfırlamamalı")
	_check(absf(game.player.position.x - (home.position.x + game.player.offset)) < 0.5, "kurbağa basamağıyla birlikte kaymalı")
	# Basamak kaybolmak üzereyken ıskalarsa: havadayken basamak ufalanır, kurbağa düşer, oyun biter
	for k in 900:
		await process_frame
		if home.time_left() >= 0.0 and home.time_left() < 0.2:
			break
	next.position.x = game.player.position.x + next.width / 2.0 + game.balance.player_width * 0.4
	_tap(Vector2(640, 400))
	await _wait_state(2, 120)
	_check(game.state == 2, "havadayken basamağı ufalanınca düşmeli")
	await _frames(20)
	await _shot("08_dusme_havada")
	await _wait_state(3, 600)
	_check(game.state == 3, "düşünce oyun bitmeli")
	await _frames(50)
	await _shot("09_bitti_rekorsuz")


# Uygun anda (çakışma geniş) dokunarak `count` basamak daha tırman
func _climb(count: int) -> void:
	var goal: int = game.steps + count
	for k in 6000:
		await process_frame
		_frame += 1
		if game.steps >= goal or game.state >= 2:
			return
		if game.player.is_airborne():
			continue
		var next: Node2D = game.spawner.platform(game.steps + 1)
		var pw: float = game.balance.player_width
		if next and next.overlap(game.player.position.x, pw) >= pw * 0.6:
			_tap(Vector2(640, 400))


func _wait_state(state: int, limit: int) -> void:
	for k in limit:
		if game.state == state:
			return
		await process_frame
		_frame += 1


# --- Yardımcılar ---

func _touch(pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = pos
	event.pressed = pressed
	root.push_input(event, true)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	_touch(pos, false)


func _frames(count: int) -> void:
	for k in count:
		await process_frame
		_frame += 1


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s%s.png" % [out, prefix, name])
