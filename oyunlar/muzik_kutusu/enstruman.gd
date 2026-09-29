extends Node2D
# Instrument: bütün enstrümanların temel sınıfı. Enstrüman kendi tasarım alanında (design_size) çizilir;
# oyun fit() ile onu ekrandaki alana orantılı sığdırıp ortalar, böylece her ekran oranında düzen korunur.
# Dokunmaları oyun yönlendirir (her parmak index'iyle ayrı): touch_down / touch_move / touch_up.
# Ses dokunuşun basıldığı anda çalar. Her enstrümanın kendi ses havuzu var (ortak ses_havuzu.gd): havuz
# doluysa en eski ses susar, yeni dokunuş asla sessiz kalmaz.
#
# Yeni enstrüman: bu script'i extends eden bir dosya yaz; build() içinde add_pad() ile parçaları ekle,
# sound_streams() ile seslerini ver. Sonra muzik_kutusu.gd INSTRUMENTS listesine bir satır ekle.

signal note_played(pad: Node2D, at: Vector2)

const SoundPool := preload("res://ortak/ses_havuzu.gd")
const Pad := preload("res://oyunlar/muzik_kutusu/ses_alani.gd")

## Tasarım alanı (enstrüman bu boyutta çizilir, sonra ekrana ölçeklenir)
var design_size: Vector2 = Vector2(1040, 470)
## Ses havuzunun yönlendirileceği ses yolu (oyun limiter'lı kendi yolunu verir)
var bus_name: StringName = &"Master"
## Aynı anda çalabilecek ses sayısı
var voices: int = 16
## Bütün seslerin seviyesi (dB). Sesler üretilirken yükseklikleri eşitlendi.
var volume_db: float = -4.0
## Dokunulan yerde halka dalgası çıksın mı (davul)
var ring_effect: bool = false

var pads: Array[Pad] = []
var sounds: SoundPool
var home: Vector2 = Vector2.ZERO      # fit() sonrası yeri (geçiş kaymasında buraya döner)
var _fingers: Dictionary = {}         # parmak index -> dokunduğu parça (yoksa null)


func _ready() -> void:
	sounds = SoundPool.new()
	sounds.streams = sound_streams()
	for sound in sounds.streams:
		sounds.volumes[sound] = volume_db
	sounds.player_count = voices
	add_child(sounds)
	for player in sounds.get_children():
		(player as AudioStreamPlayer).bus = bus_name
	build()


# --- Alt sınıfların yazacağı ---

func build() -> void:
	pass


## Ses adı -> AudioStream (preload ile: dokunuşta yükleme beklemesi olmasın)
func sound_streams() -> Dictionary:
	return {}


# --- Yerleşim ---

func fit(area: Rect2) -> void:
	var s := minf(area.size.x / design_size.x, area.size.y / design_size.y)
	scale = Vector2.ONE * s
	home = area.position + (area.size - design_size * s) / 2.0
	position = home


func add_pad(pad: Pad) -> Pad:
	add_child(pad)
	pads.append(pad)
	return pad


## Dokunulan yerdeki parça (üst üste binenlerde en son eklenen önce)
func pad_at(global_point: Vector2) -> Pad:
	for k in range(pads.size() - 1, -1, -1):
		if pads[k].contains(global_point):
			return pads[k]
	return null


# --- Dokunma ---

func touch_down(index: int, at: Vector2) -> void:
	var pad := pad_at(at)
	_fingers[index] = pad
	if pad:
		play_pad(pad, at)


func touch_move(_index: int, _at: Vector2) -> void:
	pass


func touch_up(index: int) -> void:
	_fingers.erase(index)


## Enstrüman değişince ya da uygulama arka plana gidince bütün parmaklar bırakılır
func release_all() -> void:
	for index in _fingers.keys():
		touch_up(index)
	_fingers.clear()


## Klavye 1-9 (masaüstünde deneme): sıradaki parça çalar
func press_key(number: int) -> void:
	if number >= 0 and number < pads.size():
		play_pad(pads[number], pads[number].touch_center())


func play_pad(pad: Pad, at: Vector2, pitch: float = 1.0) -> void:
	sounds.play(pad.sound, pitch)
	pad.hit(sound_length(pad.sound))
	note_played.emit(pad, at)


func sound_length(sound: String) -> float:
	var stream: AudioStream = sounds.streams.get(sound)
	return stream.get_length() if stream else 0.0


## Uzun süre dokunulmayınca rastgele bir parça davet eder
func invite() -> void:
	if not pads.is_empty():
		pads.pick_random().invite()
