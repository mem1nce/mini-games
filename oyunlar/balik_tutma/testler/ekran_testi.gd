extends SceneTree
# Balık Tutma ekran görüntüsü testi (pencereli). Proje kökünden (dikey oyun; pencere 450x800 = 720x1280 oranı):
#   godot --path . --fixed-fps 60 --resolution 450x800 -s res://oyunlar/balik_tutma/testler/ekran_testi.gd -- <klasör>
# Göl bölümü, ağın inişi, yakalama, yeni tür tanıtımı, kova, kutlama, çöp bölümü (bulanık → temizlenen),
# mercan ve derin deniz temaları, akvaryum ve duraklatma görüntülerini <klasör> içine kaydeder.
# user://balik_tutma.cfg başta yedeklenir, sonda geri yazılır.

const Kayit := preload("res://oyunlar/balik_tutma/kayit.gd")
const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const Balik := preload("res://oyunlar/balik_tutma/balik.gd")

var out := ""
var game: Node
var _yedek: PackedByteArray
var _yedek_var := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_yedek_var = FileAccess.file_exists(Kayit.PATH)
	if _yedek_var:
		_yedek = FileAccess.get_file_as_bytes(Kayit.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	root.get_node("SahneGecis").visible = false
	game = load("res://oyunlar/balik_tutma/balik_tutma.tscn").instantiate()
	root.add_child(game)
	await frames(90)
	await shot("f01_gol")
	# Ağı suya indir
	var hedef := Vector2(420, 900)
	touch(hedef, true)
	for i in 30:
		drag(hedef + Vector2(sin(i * 0.2) * 40.0, 0))
		await process_frame
	await shot("f02_ag_iniyor")
	touch(hedef, false)
	await frames(60)
	# Bir mavi balığı yakala (yeni tür + görev)
	var mavi := await balik_bul(func(b: Node2D) -> bool: return b.tur == "mavi_minik")
	if mavi:
		touch(mavi.global_position, true)
		for i in 300:
			await process_frame
			if game.olta.icerik == mavi or not is_instance_valid(mavi):
				break
			drag(mavi.global_position)
		touch(Vector2(360, 900), false)
		await frames(20)
		await shot("f03_yakaladi")
		await bekle(func() -> bool: return game._kutlama.get_child_count() > 1, 300)
		await frames(40)
		await shot("f04_yeni_tur")
		await bekle(func() -> bool: return not game.olta.kilitli, 600)
		await frames(10)
		await shot("f05_kovada")
	# Görevi tamamla (kutlama)
	while game.durum == game.Durum.OYUN:
		var b := await balik_bul(func(x: Node2D) -> bool: return x.tur == "mavi_minik")
		if b == null:
			break
		await kovala(b)
		await bekle(func() -> bool: return not game.olta.kilitli and game.olta.icerik == null, 600)
	await frames(40)
	await shot("f06_kutlama")
	await bekle(func() -> bool: return game.durum == game.Durum.OYUN, 900)
	# Çöp bölümü: bulanık, sonra iki çöp toplanınca biraz temiz
	game.kayit.bolum = 3
	game._bolumu_kur()
	await frames(60)
	await shot("f07_cop_bulanik")
	for k in 2:
		if game.uretici.copler.is_empty():
			break
		await kovala(game.uretici.copler[0])
		await bekle(func() -> bool: return not game.olta.kilitli and game.olta.icerik == null, 600)
	await frames(80)
	await shot("f08_cop_temizleniyor")
	for i in [8, 12]:
		game.kayit.bolum = i
		game._bolumu_kur()
		await frames(90)
		touch(Vector2(300, 1000), true)
		for k in 40:
			drag(Vector2(300 + k * 2, 1000))
			await process_frame
		await shot("f%02d_tema" % (i + 1))
		touch(Vector2(380, 1000), false)
		await frames(30)
	# Yeni tür tanıtımı
	game._kutlama.yeni_tur("gokkusagi", Vector2(360, 900), game._akvaryum_simge.get_global_rect().get_center(), Vector2(720, 1280))
	await frames(70)
	await shot("f12_yeni_tur_tanitimi")
	await frames(120)
	# Akvaryum (birkaç tür yakalanmış)
	for tur in ["kirmizi_top", "palyaco", "balon", "gokkusagi", "fener", "isikli_mavi", "mor_yassi"]:
		game.kayit.ekle(tur)
	tap(game._akvaryum_simge.get_global_rect().get_center())
	await frames(60)
	await shot("f10_akvaryum")
	tap(game._akvaryum._kapat.get_global_rect().get_center())
	await frames(30)
	tap(game._duraklat.get_global_rect().get_center())
	await frames(30)
	await shot("f11_duraklat")
	tap(game._devam.get_global_rect().get_center())
	await frames(10)
	game.queue_free()
	await process_frame
	if _yedek_var:
		var f := FileAccess.open(Kayit.PATH, FileAccess.WRITE)
		f.store_buffer(_yedek)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	quit()


func balik_bul(kosul: Callable) -> Node2D:
	for i in 1500:
		for b in game.uretici.baliklar:
			if b.durum == Balik.Durum.YUZUYOR and b.position.x > 80.0 and b.position.x < 640.0 and kosul.call(b):
				return b
		await process_frame
	return null


func kovala(hedef: Node2D) -> void:
	touch(hedef.global_position, true)
	for i in 400:
		await process_frame
		if not is_instance_valid(hedef) or game.olta.icerik != null:
			break
		drag(hedef.global_position)
	touch(Vector2(360, 900), false)


func bekle(kosul: Callable, en_fazla: int) -> void:
	for i in en_fazla:
		if kosul.call():
			return
		await process_frame


func touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func drag(pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.position = pos
	root.push_input(ev, true)


func tap(pos: Vector2) -> void:
	touch(pos, true)
	touch(pos, false)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("çekildi: ", name)
