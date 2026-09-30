extends SceneTree
# Tren Rayı ekran görüntüsü testi (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://oyunlar/tren_rayi/testler/ekran_testi.gd -- <klasör>
# Giriş ekranı (vagonlu tren), bölüm 1, eksik yolda "?", çözülmüş yol (parlama), yolculuk, kutlama ve
# her temadan bir bölümün görüntülerini <klasör> içine kaydeder. user://tren_rayi.cfg başta yedeklenir, sonda geri yazılır.

const Baglanti := preload("res://oyunlar/tren_rayi/baglanti.gd")
const Yonetici := preload("res://oyunlar/tren_rayi/bolum_yoneticisi.gd")

var out := ""
var game: Node
var _yedek: PackedByteArray
var _yedek_var := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	_yedekle()
	_kaydet(0, 7)
	game = load("res://oyunlar/tren_rayi/tren_rayi.tscn").instantiate()
	root.add_child(game)
	await frames(200)
	await shot("t01_giris")
	tap(game._giris._oynat.position)
	await frames(60)
	await shot("t02_bolum1")
	# Eksik yol: hareket
	tap(game._hareket.get_global_rect().get_center())
	await frames(150)
	await shot("t03_soru")
	await frames(300)
	# Çöz: parçalara dokunarak doğru yöne çevir
	await coz()
	await frames(40)
	await shot("t04_cozuldu")
	tap(game._hareket.get_global_rect().get_center())
	await frames(90)
	await shot("t05_yolculuk")
	await bekle_durum(game.Durum.KUTLAMA, 900)
	await frames(50)
	await shot("t06_kutlama")
	await frames(180)
	await shot("t07_vagon")
	# Her temadan bir bölüm (yolcularla, kavşaklarla)
	for i in [4, 9, 13, 15, 19]:
		game.yonetici.bolum = i
		game.yonetici.vagon = i + 3
		game._bolumu_kur()
		await frames(40)
		await shot("b%02d" % (i + 1))
		if i == 13 or i == 19:
			await coz()
			await frames(40)
			await shot("b%02d_cozuldu" % (i + 1))
			tap(game._hareket.get_global_rect().get_center())
			await bekle_durum(game.Durum.KUTLAMA, 1500)
			await frames(80)
			await shot("b%02d_varis" % (i + 1))
	game._giris_ekranina()
	await frames(120)
	tap(game._giris.tren.loko_konumu())
	await frames(20)
	await shot("t08_giris_duduk")
	game.queue_free()
	await process_frame
	_geri_yaz()
	quit()


func coz() -> void:
	var izgara: Node2D = game.izgara
	for h in izgara.parcalar:
		var parca: Node2D = izgara.parcalar[h]
		if parca.sabit or not izgara.bolum["cozum"].has(h):
			continue
		var hedef := Baglanti.acikliklar(izgara.bolum["cozum"][h]["tip"], izgara.bolum["cozum"][h]["yon"])
		for k in 4:
			if Baglanti.acikliklar(parca.tip, parca.yon) == hedef:
				break
			tap(izgara.merkez(h))
			await frames(3)


func bekle_durum(durum: int, en_fazla: int) -> void:
	for i in en_fazla:
		if game.durum == durum:
			return
		await process_frame


func _yedekle() -> void:
	_yedek_var = FileAccess.file_exists(Yonetici.PATH)
	if _yedek_var:
		_yedek = FileAccess.get_file_as_bytes(Yonetici.PATH)


func _geri_yaz() -> void:
	if _yedek_var:
		var f := FileAccess.open(Yonetici.PATH, FileAccess.WRITE)
		f.store_buffer(_yedek)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Yonetici.PATH))


func _kaydet(bolum: int, vagon: int) -> void:
	var ayar := ConfigFile.new()
	ayar.set_value("ilerleme", "bolum", bolum)
	ayar.set_value("ilerleme", "vagon", vagon)
	ayar.save(Yonetici.PATH)


func tap(pos: Vector2) -> void:
	for basili in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.position = pos
		ev.pressed = basili
		root.push_input(ev, true)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("çekildi: ", name)
