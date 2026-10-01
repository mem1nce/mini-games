extends Node
# Autoload "SesYoneticisi": ortak sesler (res://ortak/sesler/, kaynakları SESLER.md) için efekt, döngü ve müzik çalma.
#   SesYoneticisi.efekt("dugme_tik")              kısa efekt (perde her çalışta ±%5 rastgele; aynı ses 45 ms içinde
#                                                 tekrar gelirse birleştirilir; aynı anda en fazla EFEKT_OYNATICI ses)
#   SesYoneticisi.ezgi("kutlama")                 kutlama ezgisi: çalarken müzik kısa süre kısılır
#   SesYoneticisi.dongu_baslat("bilye_yuvarlanma") / dongu_durdur(...)   döngülü efekt
#   SesYoneticisi.muzik("ucan_kus", self)         oyun müziği (muzik_<ad>.ogg); öncekiyle yumuşak geçiş. Sahip düğüm
#                                                 ağaçtan çıkınca müzik kendiliğinden söner (müziksiz sahneye geçince).
#   SesYoneticisi.muzik_hizi(1.04)                çalan müziği hafifçe hızlandırır (perde de değişir); muzik() 1'e döndürür
#   SesYoneticisi.sonraki_mod()                   hepsi açık → sadece efektler → sessiz (user://ses_ayari.cfg)
# Ses yolları: Master → Muzik, Efekt (default_bus_layout.tres). Sessiz modda Master kapanır (bütün oyunlar susar).
# Uygulama arka plana geçince müzik ve döngüler durur, geri gelince devam eder.

# Her efekt, döngü ve müzik isteğinde (mod ne olursa olsun) yayılır; testler sesleri buradan izler
signal ses_istendi(ad: String)

enum Mod { HEPSI, EFEKT, SESSIZ }

const KLASOR := "res://ortak/sesler/"
const AYAR := "user://ses_ayari.cfg"
const EFEKT_OYNATICI := 10
const BIRLESTIRME_MS := 45
const PERDE_OYNAMA := 0.05
const MUZIK_SEVIYE := -7.0         # Muzik yolunun normal seviyesi (dB)
const EFEKT_SEVIYE := -1.0
const SESSIZ_DB := -40.0

var mod := Mod.HEPSI

var _efektler: Array[AudioStreamPlayer] = []
var _baslama: Array[int] = []
var _son_calma := {}               # ad → ms
var _akislar := {}                 # ad → AudioStream
var _donguler := {}                # ad → AudioStreamPlayer
var _dongu_sonumleri := {}         # ad → Tween (durdururken sönme)
var _muzikler: Array[AudioStreamPlayer] = []
var _muzik_tweenleri: Array = [null, null]
var _aktif := 0
var _muzik_adi := ""
var _muzik_sahibi: WeakRef = null
var _hiz_tween: Tween
var _kisma := 0.0
var _kisma_tween: Tween
var _muzik_yolu := 1
var _efekt_yolu := 2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_yollari_hazirla()
	for i in EFEKT_OYNATICI:
		var p := AudioStreamPlayer.new()
		p.bus = &"Efekt"
		add_child(p)
		_efektler.append(p)
		_baslama.append(0)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Muzik"
		p.volume_db = SESSIZ_DB
		add_child(p)
		_muzikler.append(p)
	_yukle()
	_uygula()


# default_bus_layout.tres yoksa (ya da eksikse) yolları kodla kur
func _yollari_hazirla() -> void:
	for ad in ["Muzik", "Efekt"]:
		if AudioServer.get_bus_index(ad) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, ad)
			AudioServer.set_bus_send(i, &"Master")
	_muzik_yolu = AudioServer.get_bus_index("Muzik")
	_efekt_yolu = AudioServer.get_bus_index("Efekt")
	AudioServer.set_bus_volume_db(_efekt_yolu, EFEKT_SEVIYE)


func _akis(ad: String, dongu := false) -> AudioStream:
	if not _akislar.has(ad):
		var yol := KLASOR + ad + ".ogg"
		if not ResourceLoader.exists(yol):
			push_warning("SesYoneticisi: ses yok: " + ad)
			_akislar[ad] = null
		else:
			var akis: AudioStream = load(yol)
			if dongu and akis is AudioStreamOggVorbis:
				akis.loop = true
			_akislar[ad] = akis
	return _akislar[ad]


# --- Efektler ---

func efekt(ad: String, ses_db := 0.0, perde := 1.0) -> void:
	ses_istendi.emit(ad)
	if mod == Mod.SESSIZ:
		return
	var simdi := Time.get_ticks_msec()
	if simdi - int(_son_calma.get(ad, -100000)) < BIRLESTIRME_MS:
		return
	var akis := _akis(ad)
	if akis == null:
		return
	_son_calma[ad] = simdi
	var p := _bos_oynatici()
	p.stream = akis
	p.volume_db = ses_db
	p.pitch_scale = perde * randf_range(1.0 - PERDE_OYNAMA, 1.0 + PERDE_OYNAMA)
	p.play()
	_baslama[_efektler.find(p)] = simdi


func _bos_oynatici() -> AudioStreamPlayer:
	var en_eski := 0
	for i in _efektler.size():
		if not _efektler[i].playing:
			return _efektler[i]
		if _baslama[i] < _baslama[en_eski]:
			en_eski = i
	return _efektler[en_eski]


# Kutlama ezgisi: müzik ezgi boyunca kısılır
func ezgi(ad: String, ses_db := 0.0) -> void:
	var akis := _akis(ad)
	if akis == null:
		return
	efekt(ad, ses_db)
	kis(akis.get_length())


# Müziği kısa süre kısar (ducking)
func kis(sure := 1.5, miktar := -12.0) -> void:
	if _kisma_tween and _kisma_tween.is_valid():
		_kisma_tween.kill()
	_kisma_tween = create_tween()
	_kisma_tween.tween_method(_kisma_ayarla, _kisma, miktar, 0.15)
	_kisma_tween.tween_interval(sure)
	_kisma_tween.tween_method(_kisma_ayarla, miktar, 0.0, 0.8).set_trans(Tween.TRANS_SINE)


func _kisma_ayarla(deger: float) -> void:
	_kisma = deger
	AudioServer.set_bus_volume_db(_muzik_yolu, MUZIK_SEVIYE + _kisma)


# --- Döngülü efektler ---

func dongu_baslat(ad: String, ses_db := 0.0, perde := 1.0) -> void:
	ses_istendi.emit(ad)
	var p: AudioStreamPlayer = _donguler.get(ad)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = &"Efekt"
		p.stream = _akis(ad, true)
		add_child(p)
		_donguler[ad] = p
	var sonum: Tween = _dongu_sonumleri.get(ad)
	if sonum and sonum.is_valid():
		sonum.kill()
	p.volume_db = ses_db
	p.pitch_scale = perde
	if not p.playing:
		p.play()


func dongu_perde(ad: String, perde: float) -> void:
	var p: AudioStreamPlayer = _donguler.get(ad)
	if p:
		p.pitch_scale = clampf(perde, 0.5, 2.0)


func dongu_durdur(ad: String, sure := 0.2) -> void:
	var p: AudioStreamPlayer = _donguler.get(ad)
	if p == null or not p.playing:
		return
	var sonum: Tween = _dongu_sonumleri.get(ad)
	if sonum and sonum.is_valid():
		return  # zaten sönüyor
	var tween := create_tween()
	tween.tween_property(p, "volume_db", SESSIZ_DB, sure)
	tween.tween_callback(p.stop)
	_dongu_sonumleri[ad] = tween


func dongulari_durdur() -> void:
	for ad in _donguler:
		dongu_durdur(ad, 0.1)


# --- Müzik ---

func muzik(ad: String, sahip: Node = null, gecis := 1.2) -> void:
	_muzik_sahibi = weakref(sahip) if sahip else null
	var simdiki := _muzikler[_aktif]
	if ad == _muzik_adi and simdiki.playing:
		_muzik_sesi(_aktif, 0.0, 0.3)
		muzik_hizi(1.0)
		return
	var akis := _akis("muzik_" + ad, true)
	if akis == null:
		return
	ses_istendi.emit("muzik_" + ad)
	_muzik_adi = ad
	_muzik_sesi(_aktif, SESSIZ_DB, gecis, true)
	_aktif = 1 - _aktif
	if _hiz_tween and _hiz_tween.is_valid():
		_hiz_tween.kill()
	var yeni := _muzikler[_aktif]
	yeni.stream = akis
	yeni.pitch_scale = 1.0
	yeni.volume_db = SESSIZ_DB
	yeni.stream_paused = false
	yeni.play()
	_muzik_sesi(_aktif, 0.0, gecis)


# Çalan müziğin hızı: küçük değişiklikler için (perde de aynı oranda değişir)
func muzik_hizi(carpan: float, sure := 0.8) -> void:
	if _hiz_tween and _hiz_tween.is_valid():
		_hiz_tween.kill()
	_hiz_tween = create_tween()
	_hiz_tween.tween_property(_muzikler[_aktif], "pitch_scale", clampf(carpan, 0.5, 2.0), sure)


func muzik_durdur(gecis := 1.0) -> void:
	_muzik_adi = ""
	_muzik_sahibi = null
	_muzik_sesi(_aktif, SESSIZ_DB, gecis, true)


func muzik_caliyor() -> String:
	return _muzik_adi


func _muzik_sesi(i: int, hedef: float, sure: float, sonra_durdur := false) -> void:
	var p := _muzikler[i]
	if _muzik_tweenleri[i] and _muzik_tweenleri[i].is_valid():
		_muzik_tweenleri[i].kill()
	var tween := create_tween()
	# Ses seviyesi dB'de doğrusal değil: yumuşak geçiş için açılışta sinüs, kapanışta üstel eğri
	tween.tween_property(p, "volume_db", hedef, sure).set_trans(Tween.TRANS_SINE if hedef > p.volume_db else Tween.TRANS_EXPO) \
		.set_ease(Tween.EASE_OUT if hedef > p.volume_db else Tween.EASE_IN)
	if sonra_durdur:
		tween.tween_callback(p.stop)
	_muzik_tweenleri[i] = tween


func _process(_delta: float) -> void:
	# Müziğin sahibi sahneden çıktıysa (müziksiz bir sahneye geçildi) müzik söner
	if _muzik_sahibi != null:
		var sahip = _muzik_sahibi.get_ref()
		if sahip == null or not (sahip as Node).is_inside_tree():
			muzik_durdur()


# --- Ses modu ---

func sonraki_mod() -> int:
	mod = (mod + 1) % 3
	_uygula()
	_kaydet()
	return mod


func _uygula() -> void:
	AudioServer.set_bus_mute(0, mod == Mod.SESSIZ)
	AudioServer.set_bus_mute(_muzik_yolu, mod != Mod.HEPSI)
	AudioServer.set_bus_volume_db(_muzik_yolu, MUZIK_SEVIYE + _kisma)


func _yukle() -> void:
	var ayar := ConfigFile.new()
	if ayar.load(AYAR) == OK:
		mod = clampi(int(ayar.get_value("ses", "mod", Mod.HEPSI)), 0, 2)


func _kaydet() -> void:
	var ayar := ConfigFile.new()
	ayar.set_value("ses", "mod", mod)
	ayar.save(AYAR)


# --- Arka plan ---

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_duraklat(true)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_duraklat(false)


func _duraklat(deger: bool) -> void:
	for p in _muzikler:
		p.stream_paused = deger
	for p in _donguler.values():
		p.stream_paused = deger
