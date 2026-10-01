extends SceneTree
# Uçan Kuş hızlanma testi (headless). Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://oyunlar/ucan_kus/testler/hizlanma_testi.gd
# Bir otomatik pilot gerçek dokunmalarla oynar. Denetler: her speed_step_points puanda bir kademe ve ~%8 hız;
# üst sınır; direkler arası süre sabit (mesafe hızla açılır); boşluk alt sınırın altına inmez; hareketli direkler
# ancak moving_pipes_start_score'dan sonra, 3-4 direkte bir ve yavaş; can kaybında bir kademe geri; hızlanmada
# "vuus" sesi, rüzgar çizgileri, parıltı, gökyüzü rengi ve müzik hızı; tekrar oynayınca her şey baştan.
# Oyun kayıt yazmaz; yine de user:// .cfg dosyaları yedeklenip sonunda aynen geri yazılır. Hata varsa çıkış kodu 1.

const SAHNE := "res://oyunlar/ucan_kus/ucan_kus.tscn"
const DOKUNMA := Vector2(400, 760)

var failures := 0
var gecis: Node
var ses: Node
var oyun: Node
var _yedek := {}
var istenen: Array[String] = []
var pilot := true


func _initialize() -> void:
	gecis = root.get_node("SahneGecis")
	ses = root.get_node("SesYoneticisi")
	ses.ses_istendi.connect(func(ad: String) -> void: istenen.append(ad))
	_kayitlari_yedekle()
	change_scene_to_file(SAHNE)
	_expect(await _sahne_bekle(), "oyun açıldı")
	oyun = current_scene
	await _hizlanma()
	await _can_kaybi()
	await _yeni_oyun()
	_kayitlari_geri_yaz()
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


func _hizlanma() -> void:
	_expect(oyun.speed_level == 0 and is_equal_approx(oyun.speed_factor, 1.0), "oyun yavaş başlar")
	_expect(oyun.sky.color.is_equal_approx(oyun.SKY_COLORS[0]), "gökyüzü sabah renginde başlar")
	_tap(DOKUNMA)
	var en_fazla: int = oyun._max_speed_level()
	var hedef_puan: int = oyun.speed_step_points * (en_fazla + 1)
	var gorulen := {}            # direk çifti → [doğduğu kare, hareketli mi]
	var dogus_kareleri: Array[int] = []
	var hareketli_sira: Array[bool] = []
	var son_kademe := 0
	var son_puan := 0
	var en_hizli_dikey := 0.0
	var kare := 0
	while oyun.score < hedef_puan and oyun.state == oyun.State.PLAYING and kare < 60 * 400:
		var onceki_y := {}
		for pair: Node2D in oyun.pipes.get_children():
			onceki_y[pair] = pair.position.y
		_pilot()
		await process_frame
		kare += 1
		for pair: Node2D in oyun.pipes.get_children():
			if not gorulen.has(pair):
				gorulen[pair] = true
				dogus_kareleri.append(kare)
				hareketli_sira.append(pair.has_meta("travel"))
				_expect(pair.get_meta("gap") >= oyun.gap_size * oyun.min_gap_ratio - 0.01, "boşluk alt sınırın altına inmedi (%.0f)" % pair.get_meta("gap"))
				if pair.has_meta("travel"):
					_expect(oyun.score >= oyun.moving_pipes_start_score, "hareketli direk %d puandan önce gelmedi (puan %d)" % [oyun.moving_pipes_start_score, oyun.score])
			elif onceki_y.has(pair):
				en_hizli_dikey = maxf(en_hizli_dikey, absf(pair.position.y - onceki_y[pair]) * 60.0)
		if oyun.score != son_puan:
			son_puan = oyun.score
			if son_puan % oyun.speed_step_points == 0:
				var beklenen: int = mini(son_kademe + 1, en_fazla)
				_expect(oyun.speed_level == beklenen, "%d puanda kademe %d (%d)" % [son_puan, beklenen, oyun.speed_level])
				if beklenen > son_kademe:
					_expect(oyun.effects.get_child_count() == oyun.WIND_LINE_COUNT, "hızlanmada rüzgar çizgileri çıktı")
					_expect(_parilti_sayisi() == oyun.SPARKLE_COUNT, "hızlanmada kuşun etrafında parıltı çıktı")
				son_kademe = beklenen
		_expect(oyun.speed_factor <= oyun.max_speed_factor + 0.001, "hız üst sınırı aşmadı (%.3f)" % oyun.speed_factor)
	_expect(oyun.score >= hedef_puan, "otomatik pilot %d puana ulaştı (%d, can %d)" % [hedef_puan, oyun.score, oyun.lives])
	_expect(oyun.lives == oyun.start_lives, "en hızlı kademede bile can kaybetmeden oynanabiliyor (can %d)" % oyun.lives)
	_expect(oyun.speed_level == en_fazla, "en üst kademeye ulaşıldı (%d / %d)" % [oyun.speed_level, en_fazla])
	_expect(is_equal_approx(oyun.speed_factor, oyun.max_speed_factor), "hız tam üst sınırda (%.3f)" % oyun.speed_factor)
	_expect(istenen.count("vuus") == en_fazla, "her kademede bir 'vuus' sesi (%d / %d)" % [istenen.count("vuus"), en_fazla])
	# Direkler arası süre hep aynı: mesafe hızla orantılı açılır
	var beklenen_kare: float = oyun.pipe_spacing / oyun.pipe_speed * 60.0
	var en_az := 1e9
	var en_cok := 0.0
	for i in range(1, dogus_kareleri.size()):
		var fark := float(dogus_kareleri[i] - dogus_kareleri[i - 1])
		en_az = minf(en_az, fark)
		en_cok = maxf(en_cok, fark)
	_expect(en_az > beklenen_kare * 0.95 and en_cok < beklenen_kare * 1.05, "direkler sıklaşmadı: aralık %.0f-%.0f kare (beklenen %.0f)" % [en_az, en_cok, beklenen_kare])
	# Hareketli direkler: 3-4 direkte bir, yavaş
	var hareketliler: Array[int] = []
	for i in hareketli_sira.size():
		if hareketli_sira[i]:
			hareketliler.append(i)
	_expect(hareketliler.size() >= 3, "hareketli direkler geldi (%d)" % hareketliler.size())
	for i in range(1, hareketliler.size()):
		var ara: int = hareketliler[i] - hareketliler[i - 1]
		_expect(ara >= oyun.moving_pipe_every_min and ara <= oyun.moving_pipe_every_max, "hareketli direkler %d-%d direkte bir (%d)" % [oyun.moving_pipe_every_min, oyun.moving_pipe_every_max, ara])
	var hiz_siniri: float = TAU * oyun.moving_pipe_range / oyun.moving_pipe_period
	_expect(en_hizli_dikey > 10.0 and en_hizli_dikey <= hiz_siniri + 1.0, "hareketli direk yavaş hareket ediyor (%.0f px/sn, sınır %.0f)" % [en_hizli_dikey, hiz_siniri])
	await _oyna(90)
	_expect(oyun.sky.color.is_equal_approx(oyun.SKY_COLORS[-1]), "en üst kademede gökyüzü gece renginde")
	_expect(is_equal_approx(_muzik_hizi(), 1.0 + oyun.music_speed_per_level * en_fazla), "müzik hafifçe hızlandı (%.3f)" % _muzik_hizi())
	_expect(oyun.effects.get_child_count() == 0 and _parilti_sayisi() == 0, "efektler temizlendi")
	print("tamam: hızlanma (%d direk, %d hareketli, en hızlı dikey %.0f px/sn)" % [dogus_kareleri.size(), hareketliler.size(), en_hizli_dikey])


func _can_kaybi() -> void:
	var kademe: int = oyun.speed_level
	var can: int = oyun.lives
	var vuus := istenen.count("vuus")
	# Dokunmayınca kuş yere düşer ve bir can gider
	for k in 600:
		await process_frame
		if oyun.lives < can:
			break
	_expect(oyun.lives == can - 1, "kuş yere çarptı, bir can gitti")
	_expect(oyun.speed_level == kademe - 1, "can kaybında hız bir kademe düştü (%d → %d)" % [kademe, oyun.speed_level])
	_expect(istenen.count("vuus") == vuus, "yavaşlarken 'vuus' çalmadı")
	await _oyna(120)
	var hedef: float = oyun._target_speed_factor()
	_expect(hedef < oyun.max_speed_factor and is_equal_approx(oyun.speed_factor, hedef), "hız yumuşakça yeni kademeye indi (%.3f)" % oyun.speed_factor)
	print("tamam: can kaybı")


func _yeni_oyun() -> void:
	# Kalan canlar da gidince oyun biter; "Tekrar oyna" ile her şey baştan başlar
	for k in 60 * 40:
		await process_frame
		if oyun.state == oyun.State.GAME_OVER and oyun.can_restart:
			break
	_expect(oyun.state == oyun.State.GAME_OVER, "oyun bitti")
	_tap(oyun.restart_button.get_global_rect().get_center())
	for k in 120:
		await process_frame
		if current_scene != null and current_scene != oyun and current_scene.scene_file_path == SAHNE:
			break
	oyun = current_scene
	await _frames(70)
	_expect(oyun.speed_level == 0 and is_equal_approx(oyun.speed_factor, 1.0), "yeni oyun yavaş başlar")
	_expect(oyun.sky.color.is_equal_approx(oyun.SKY_COLORS[0]), "yeni oyunda gökyüzü yine sabah")
	_expect(is_equal_approx(_muzik_hizi(), 1.0), "yeni oyunda müzik normal hızda (%.3f)" % _muzik_hizi())
	_tap(DOKUNMA)
	await _oyna(200)
	_expect(is_equal_approx(oyun.speed_factor, 1.0), "ilk direklerde hız başlangıç hızında")
	print("tamam: yeni oyun")


# --- Otomatik pilot: sıradaki boşluğun biraz altına inince kanat çırpar ---

func _pilot() -> void:
	if oyun.state != oyun.State.PLAYING:
		return
	var hedef_y: float = oyun.last_gap_y
	var en_yakin := 1e9
	for pair: Node2D in oyun.pipes.get_children():
		var sag: float = pair.position.x + oyun.PIPE_HALF_WIDTH + oyun.bird_hit_radius
		if sag > oyun.bird.position.x and pair.position.x < en_yakin:
			en_yakin = pair.position.x
			hedef_y = pair.position.y
	if oyun.bird.position.y > hedef_y + 45.0 and oyun.bird_velocity > 0.0:
		_tap(DOKUNMA)


func _oyna(kare: int) -> void:
	for i in kare:
		_pilot()
		await process_frame


func _parilti_sayisi() -> int:
	var sayi := 0
	for cocuk in oyun.bird.get_children():
		if cocuk is Polygon2D and not cocuk.is_queued_for_deletion():
			sayi += 1
	return sayi


func _muzik_hizi() -> float:
	return ses._muzikler[ses._aktif].pitch_scale


# --- Yardımcılar ---

func _kayitlari_yedekle() -> void:
	var klasor := OS.get_user_data_dir()
	for dosya in DirAccess.get_files_at(klasor):
		if dosya.ends_with(".cfg"):
			_yedek[dosya] = FileAccess.get_file_as_bytes(klasor.path_join(dosya))


func _kayitlari_geri_yaz() -> void:
	var klasor := OS.get_user_data_dir()
	for dosya in DirAccess.get_files_at(klasor):
		if dosya.ends_with(".cfg") and not _yedek.has(dosya):
			DirAccess.remove_absolute(klasor.path_join(dosya))
	for dosya in _yedek:
		var f := FileAccess.open(klasor.path_join(dosya), FileAccess.WRITE)
		f.store_buffer(_yedek[dosya])
		f.close()


func _sahne_bekle() -> bool:
	for i in 600:
		await process_frame
		if current_scene and current_scene.scene_file_path == SAHNE and not gecis.gecis_suruyor:
			return true
	return false


func _tap(pos: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.position = pos
		ev.pressed = pressed
		root.push_input(ev, true)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HATA: " + message)
