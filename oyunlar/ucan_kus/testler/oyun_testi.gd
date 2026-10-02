extends SceneTree
# Uçan Kuş oynanış testi. Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://oyunlar/ucan_kus/testler/oyun_testi.gd [-- GENxYUK]
# İsteğe bağlı GENxYUK (ör. 1600x720, 1280x960) farklı telefon oranını dener.
#
# 1) Desen üreticisi (saf hesap, yüzlerce desen): ilk kolay puanlarda yalnızca kolay desenler; hareketli, kalın
#    ve bulut engeller başlama puanlarından önce gelmez; boşluk hep ekranın içinde; art arda iki boşluk arasındaki
#    fark kuşun yetişebileceği kadar; zor desene ikinci bir zorluk binmez; desenler karışık gelir.
# 2) Oyun: bir otomatik pilot gerçek dokunmalarla oynar. Kuş solda (%25-30), ekranda aynı anda 2-3 engel,
#    boşluk yükseklikleri ekranı kullanır, her 5 puanda hızlanma ve üst sınır, her 10 puanda bölge ve sütun stili
#    değişir, yıldızlar toplanır ve ayrı sayılır, kaçan yıldız ceza değildir, bulut engel geçilir.
# 3) Can kaybı: hız bir kademe düşer; kalp gelir ve eksik canı geri verir. Oyun sonu ve tekrar: her şey baştan.
# Oyun kayıt yazmaz; yine de user:// .cfg dosyaları yedeklenip sonunda aynen geri yazılır. Hata varsa çıkış kodu 1.

const SAHNE := "res://oyunlar/ucan_kus/ucan_kus.tscn"
const Desenler := preload("res://oyunlar/ucan_kus/desenler.gd")
const Bolgeler := preload("res://oyunlar/ucan_kus/bolgeler.gd")
const DOKUNMA := Vector2(700, 420)

var failures := 0
var gecis: Node
var ses: Node
var oyun: Node
var _yedek := {}
var istenen: Array[String] = []


func _initialize() -> void:
	gecis = root.get_node("SahneGecis")
	ses = root.get_node("SesYoneticisi")
	ses.ses_istendi.connect(func(ad: String) -> void: istenen.append(ad))
	_kayitlari_yedekle()
	change_scene_to_file(SAHNE)
	_expect(await _sahne_bekle(), "oyun açıldı")
	# Headless'ta pencere boyutu belirsizdir: ekranı açıkça ver (varsayılan 16:9)
	var boyut := Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and "x" in args[0]:
		var p := args[0].split("x")
		boyut = Vector2i(int(p[0]), int(p[1]))
	root.content_scale_size = Vector2i(1280, 720)
	root.size = boyut
	await _frames(10)
	oyun = current_scene
	# Test hep aynı engel dizisiyle oynasın (KUS_TEST_TOHUM ortam değişkeniyle başka diziler denenebilir)
	oyun.rng.seed = int(OS.get_environment("KUS_TEST_TOHUM")) if OS.has_environment("KUS_TEST_TOHUM") else 20261002
	print("ekran: ", oyun._screen_size())
	_uretici_denetle()
	await _oyun_denetle()
	await _can_ve_kalp_denetle()
	await _yeni_oyun_denetle()
	_kayitlari_geri_yaz()
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


# --- 1) Desen üreticisi ---

func _uretici_denetle() -> void:
	var rng := RandomNumberGenerator.new()
	var gorulen := {}
	var katkilar := {}
	var en_ust := 1e9
	var en_alt := -1e9
	for tohum in 40:
		rng.seed = 1000 + tohum
		var ortam: Dictionary = oyun._pattern_context()
		ortam["kalp_izni"] = false
		var sira := 0
		var onceki_y: float = oyun._floor_y() * 0.5
		var son_desen := ""
		var son_bulut := false
		while sira < 80:
			ortam["son_desen"] = son_desen
			ortam["son_bulut"] = son_bulut
			var engeller: Array = Desenler.uret(sira, onceki_y, ortam, rng)
			var bulutlu: bool = engeller[0]["tip"] == "bulut"
			var direkler: Array = engeller.filter(func(e: Dictionary) -> bool: return e["tip"] == "direk")
			var desen: String = direkler[0]["desen"]
			var katki: String = direkler[0]["katki"]
			gorulen[desen] = true
			katkilar[katki] = true
			_expect(desen != son_desen, "aynı desen art arda gelmedi (%s)" % desen)
			_expect(direkler.size() >= 3 and direkler.size() <= 6, "desen 3-6 direk (%s: %d)" % [desen, direkler.size()])
			if sira < oyun.easy_until_score:
				_expect(not direkler[0]["zor"], "ilk %d puanda yalnızca kolay desen (%s, sıra %d)" % [oyun.easy_until_score, desen, sira])
			if direkler[0]["zor"]:
				_expect(katki in ["yok", "ince"], "zor desene ikinci zorluk binmedi (%s + %s)" % [desen, katki])
			if bulutlu:
				_expect(sira >= oyun.cloud_start_score, "bulut %d puandan önce gelmedi (sıra %d)" % [oyun.cloud_start_score, sira])
				_expect(not direkler[0]["zor"] and katki == "yok", "buluttan sonra kolay ve sade desen (%s + %s)" % [desen, katki])
				_expect(not son_bulut, "art arda iki bulut gelmedi")
			for i in engeller.size():
				var e: Dictionary = engeller[i]
				var fark: float = absf(float(e["y"]) - onceki_y)
				if e["tip"] == "bulut":
					# Bulutun üstünden ya da altından geçen yollardan yakın olanı
					var yol: float = Desenler.BULUT_YARI_BOY + float(ortam["bosluk"]) * Desenler.BULUT_YOL_ORANI
					fark = minf(absf(float(e["y"]) - yol - onceki_y), absf(float(e["y"]) + yol - onceki_y))
				var izin: float = float(ortam["en_fazla_kayma"]) * float(e["ara"]) + 1.0
				_expect(fark <= izin, "%s: yükseklik farkı yetişilebilir (%.0f / %.0f px, sıra %d)" % [e["desen"], fark, izin, sira + i])
				if e["tip"] == "direk":
					var pay: float = float(e["bosluk"]) / 2.0 + float(e["hareket"])
					_expect(float(e["y"]) - pay >= float(ortam["ust"]) - 0.5 and float(e["y"]) + pay <= float(ortam["alt"]) + 0.5,
						"%s: boşluk ekranın içinde (y %.0f, boşluk %.0f)" % [e["desen"], e["y"], e["bosluk"]])
					_expect(float(e["bosluk"]) >= oyun.gap_size * 0.8 - 0.5, "boşluk alt sınırın altına inmedi (%.0f)" % e["bosluk"])
					if float(e["hareket"]) > 0.0:
						_expect(sira + i >= oyun.moving_pipes_start_score, "hareketli direk %d puandan önce gelmedi" % oyun.moving_pipes_start_score)
					if e["kalinlik"] == "kalin":
						_expect(sira >= oyun.thick_pipes_start_score, "kalın direk %d puandan önce gelmedi" % oyun.thick_pipes_start_score)
					en_ust = minf(en_ust, e["y"])
					en_alt = maxf(en_alt, e["y"])
				onceki_y = e["y"]
			sira += engeller.size()
			son_desen = desen
			son_bulut = bulutlu
	_expect(gorulen.size() == Desenler.DESENLER.size(), "bütün desenler geldi (%s)" % [gorulen.keys()])
	for katki in ["yok", "ince", "kalin", "hareketli"]:
		_expect(katkilar.has(katki), "'%s' engel çeşidi geldi" % katki)
	var ortam2: Dictionary = oyun._pattern_context()
	var aralik: float = float(ortam2["alt"]) - float(ortam2["ust"]) - oyun.gap_size
	_expect(en_alt - en_ust >= aralik * 0.85, "boşluk yükseklikleri ekranın neredeyse tamamını kullanıyor (%.0f / %.0f px)" % [en_alt - en_ust, aralik])
	print("tamam: desen üreticisi (boşluk merkezi %.0f - %.0f)" % [en_ust, en_alt])


# --- 2) Oyun ---

func _oyun_denetle() -> void:
	var ekran: Vector2 = oyun._screen_size()
	var oran: float = oyun.bird.position.x / ekran.x
	_expect(oran >= 0.25 and oran <= 0.3, "kuş soldan %%25-30 içeride (%.2f)" % oran)
	_expect(oyun.speed_level == 0 and is_equal_approx(oyun.speed_factor, 1.0), "oyun yavaş başlar")
	_tap(DOKUNMA)
	var en_fazla: int = oyun._max_speed_level()
	var hedef_puan: int = maxi(oyun.speed_step_points * (en_fazla + 1), oyun.zone_length * 5 + 2)
	var son_puan := 0
	var son_kademe := 0
	var gorunen_en_az := 99
	var gorunen_en_cok := 0
	var stiller := {}
	var gorulen_engeller := {}
	var bulut_gecildi := 0
	var hareketli := 0
	var kare := 0
	var carpma := 0
	var son_can: int = oyun.lives
	while oyun.score < hedef_puan and oyun.state == oyun.State.PLAYING and kare < 60 * 420:
		_pilot()
		await process_frame
		kare += 1
		if oyun.lives < son_can:
			# Pilot çarptı: hız bir kademe düşer; hangi engelde olduğunu yaz (desenin adil olup olmadığını görmek için)
			carpma += 1
			son_kademe = maxi(son_kademe - 1, 0)
			print("  pilot çarptı: puan %d, kuş y %.0f, %s" % [oyun.score, oyun.bird.position.y, _yakin_engel()])
		son_can = oyun.lives
		for engel: Node2D in oyun.pipes.get_children():
			# Anahtar düğümün kendisi değil kimliği: silinmiş düğüm anahtarlı sözlük dolaşılamaz
			if engel.get_meta("tip") == "bulut" and engel.get_meta("scored") and not engel.has_meta("sayildi"):
				engel.set_meta("sayildi", true)
				bulut_gecildi += 1
			if gorulen_engeller.has(engel.get_instance_id()):
				continue
			gorulen_engeller[engel.get_instance_id()] = true
			var sira: int = gorulen_engeller.size() - 1
			if engel.get_meta("tip") == "direk":
				var beklenen: String = Bolgeler.bolge(sira / oyun.zone_length)["ad"]
				var doku: String = (engel.get_child(0) as Sprite2D).texture.resource_path
				_expect(("direk_" + beklenen + "_") in doku, "%d. engelin sütunu %s bölgesinin (%s)" % [sira + 1, beklenen, doku.get_file()])
				stiller[beklenen] = true
				if engel.has_meta("travel"):
					hareketli += 1
					_expect(sira >= oyun.moving_pipes_start_score, "hareketli direk %d puandan önce gelmedi (sıra %d)" % [oyun.moving_pipes_start_score, sira])
			else:
				_expect(sira >= oyun.cloud_start_score, "bulut %d puandan önce gelmedi (sıra %d)" % [oyun.cloud_start_score, sira])
		if oyun.score != son_puan:
			son_puan = oyun.score
			if OS.has_environment("KUS_TEST_AYRINTI"):
				print("puan %d kare %d can %d engel %d" % [son_puan, kare, oyun.lives, oyun.pipes.get_child_count()])
			# Bir engel geçildiği anda ekranda görünen engel sayısı (geçilen dahil)
			var gorunen := 0
			for engel: Node2D in oyun.pipes.get_children():
				if engel.position.x > -60.0 and engel.position.x < ekran.x + 60.0:
					gorunen += 1
			gorunen_en_az = mini(gorunen_en_az, gorunen)
			gorunen_en_cok = maxi(gorunen_en_cok, gorunen)
			if son_puan % oyun.speed_step_points == 0:
				var beklenen_kademe: int = mini(son_kademe + 1, en_fazla)
				_expect(oyun.speed_level == beklenen_kademe, "%d puanda kademe %d (%d)" % [son_puan, beklenen_kademe, oyun.speed_level])
				son_kademe = beklenen_kademe
			_expect(oyun.zone == son_puan / oyun.zone_length, "%d puanda bölge %d (%d)" % [son_puan, son_puan / oyun.zone_length, oyun.zone])
			_expect(oyun.backdrop.bolge_sirasi == oyun.zone, "arka plan bölgeyle aynı (%d)" % oyun.backdrop.bolge_sirasi)
		_expect(oyun.speed_factor <= oyun.max_speed_factor + 0.001, "hız üst sınırı aşmadı (%.3f)" % oyun.speed_factor)
	_expect(oyun.score >= hedef_puan, "otomatik pilot %d puana ulaştı (%d, can %d)" % [hedef_puan, oyun.score, oyun.lives])
	_expect(carpma <= 1, "otomatik pilot en fazla bir kez çarptı (%d)" % carpma)
	_expect(oyun.speed_level >= en_fazla - carpma, "en üst hız kademesine ulaşıldı (%d / %d)" % [oyun.speed_level, en_fazla])
	_expect(gorunen_en_az >= 2 and gorunen_en_cok <= 3, "ekranda aynı anda 2-3 engel (en az %d, en çok %d)" % [gorunen_en_az, gorunen_en_cok])
	_expect(stiller.size() == Bolgeler.BOLGELER.size(), "beş bölgenin sütunları da geldi (%s)" % [stiller.keys()])
	_expect(istenen.count("bolum_gecisi") == oyun.score / oyun.zone_length, "her bölge girişinde kutlama sesi (%d)" % istenen.count("bolum_gecisi"))
	_expect(istenen.count("vuus") >= en_fazla - carpma and istenen.count("vuus") <= en_fazla + carpma, "her hızlanmada 'vuus' (%d / %d)" % [istenen.count("vuus"), en_fazla])
	_expect(oyun.stars > 10 and istenen.count("tink") > 10, "yıldızlar toplandı ve ayrı sayıldı (%d yıldız, puan %d)" % [oyun.stars, oyun.score])
	_expect(hareketli > 0, "hareketli direkler geldi (%d)" % hareketli)
	print("tamam: oyun (puan %d, yıldız %d, çarpma %d, görünen engel %d-%d, hareketli %d, geçilen bulut %d, %d engel)"
		% [oyun.score, oyun.stars, carpma, gorunen_en_az, gorunen_en_cok, hareketli, bulut_gecildi, gorulen_engeller.size()])


# --- 3) Can kaybı, kalp, oyun sonu ---

func _can_ve_kalp_denetle() -> void:
	var kademe: int = oyun.speed_level
	var can: int = oyun.lives
	# Dokunmayınca kuş bir yere çarpar ve bir can gider
	for k in 900:
		await process_frame
		if oyun.lives < can:
			break
	_expect(oyun.lives == can - 1, "çarpınca bir can gitti")
	_expect(oyun.speed_level == kademe - 1, "can kaybında hız bir kademe düştü (%d → %d)" % [kademe, oyun.speed_level])
	# Eksik can varken kalp gelir; toplanınca can geri gelir
	var kalp_goruldu := false
	for k in 60 * 150:
		_pilot()
		await process_frame
		for p: Sprite2D in oyun.pickups.get_children():
			if p.get_meta("tur") == "kalp":
				kalp_goruldu = true
		if oyun.lives == can or oyun.state != oyun.State.PLAYING:
			break
	_expect(kalp_goruldu, "eksik can varken kalp geldi")
	_expect(oyun.lives == can, "kalp eksik canı geri verdi (can %d)" % oyun.lives)
	_expect(istenen.has("basari_parlak"), "kalp sesi çaldı")
	print("tamam: can kaybı ve kalp")


func _yeni_oyun_denetle() -> void:
	oyun.lives = 1
	for k in 60 * 40:
		await process_frame
		if oyun.state == oyun.State.GAME_OVER and oyun.can_restart:
			break
	_expect(oyun.state == oyun.State.GAME_OVER, "canlar bitince oyun biter")
	_expect(oyun.result_star_label.text == str(oyun.stars), "oyun sonunda yıldız sayısı görünür")
	_tap(oyun.restart_button.get_global_rect().get_center())
	for k in 180:
		await process_frame
		if current_scene != null and current_scene != oyun and current_scene.scene_file_path == SAHNE:
			break
	oyun = current_scene
	await _frames(70)
	_expect(oyun.score == 0 and oyun.stars == 0 and oyun.speed_level == 0 and oyun.zone == 0, "yeni oyun baştan başlar")
	_expect(oyun.backdrop.bolge_sirasi == 0 and oyun.lives == oyun.start_lives, "yeni oyunda ilk bölge ve tam can")
	_expect(is_equal_approx(ses._muzikler[ses._aktif].pitch_scale, 1.0), "yeni oyunda müzik normal hızda")
	print("tamam: oyun sonu ve yeni oyun")


# --- Otomatik pilot: sıradaki boşluğun biraz altına inince kanat çırpar; bulutun üstünden ya da altından geçer ---

func _pilot() -> void:
	if oyun.state != oyun.State.PLAYING:
		return
	var kus: Node2D = oyun.bird
	var siradakiler: Array = []
	for engel: Node2D in oyun.pipes.get_children():
		if engel.position.x + float(engel.get_meta("half_width")) + oyun.bird_hit_radius > kus.position.x:
			siradakiler.append(engel)
	siradakiler.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.x < b.position.x)
	var hedef: float = oyun._floor_y() * 0.5
	if not siradakiler.is_empty():
		var engel: Node2D = siradakiler[0]
		if engel.get_meta("tip") == "direk":
			hedef = engel.position.y + 18.0
		else:
			# Bulut: üstünden ya da altından geçilir
			# Taraf bir kez seçilir (kuş o an hangi taraftaysa), sonra değişmez
			if not engel.has_meta("pilot_ustten"):
				engel.set_meta("pilot_ustten", kus.position.y <= engel.position.y)
			var pay: float = oyun.CLOUD_RADII.y + 100.0
			hedef = engel.position.y - pay if engel.get_meta("pilot_ustten") else engel.position.y + pay + 18.0
	if kus.position.y > hedef + 28.0 and oyun.bird_velocity > 0.0:
		_tap(DOKUNMA)


# Kuşa en yakın engelin özeti (çarpma kaydı için)
func _yakin_engel() -> String:
	var en_yakin: Node2D = null
	for engel: Node2D in oyun.pipes.get_children():
		if en_yakin == null or absf(engel.position.x - oyun.bird.position.x) < absf(en_yakin.position.x - oyun.bird.position.x):
			en_yakin = engel
	if en_yakin == null:
		return "engel yok (yer)"
	return "%s (%s) x farkı %.0f, y %.0f, boşluk %.0f, hareketli %s, yarı genişlik %.0f" % [
		en_yakin.get_meta("desen"), en_yakin.get_meta("tip"), en_yakin.position.x - oyun.bird.position.x,
		en_yakin.position.y, float(en_yakin.get_meta("gap", 0.0)), en_yakin.has_meta("travel"), en_yakin.get_meta("half_width")]


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
	for i in 900:
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
