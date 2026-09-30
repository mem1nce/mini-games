extends "res://ortak/ses_havuzu.gd"
# Boyama Kitabı sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile üretildi.
# Fırça ve silgi sesi döngüdür: set_loop(ad, seviye, delta) her karede çağrılır; parmak durunca seviye
# düşer, ses yumuşakça kısılıp durur.

const S := "res://oyunlar/boyama_kitabi/sesler/"
const STREAMS := {
	"kova": preload(S + "kova.wav"),
	"renk": preload(S + "renk.wav"),
	"damga": preload(S + "damga.wav"),
	"geri_al": preload(S + "geri_al.wav"),
	"temizle": preload(S + "temizle.wav"),
	"kaydet": preload(S + "kaydet.wav"),
	"tik": preload(S + "tik.wav"),
	"sil": preload(S + "sil.wav"),
	"sayfa": preload(S + "sayfa.wav"),
}
const VOLUMES := {"kova": -8.0, "renk": -10.0, "damga": -8.0, "geri_al": -10.0, "temizle": -8.0, "kaydet": -6.0,
	"tik": -12.0, "sil": -9.0, "sayfa": -9.0}
const LOOPS := {"firca": preload(S + "firca.wav"), "silgi": preload(S + "silgi.wav")}
const LOOP_VOLUME := -17.0            # fırça sesi kısık: yorucu olmasın

## Renk seçme notası: her renk kendi perdesinde (pentatonik; do re mi sol la ...)
const COLOR_PITCHES := [1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 2.245, 2.52, 2.997, 3.364, 0.749, 0.841, 0.891, 0.667, 0.561, 4.0]

var _loop: AudioStreamPlayer
var _loop_name: String = ""
var _loop_gain: float = 0.0


func _init() -> void:
	streams = STREAMS.duplicate()
	volumes = VOLUMES.duplicate()
	player_count = 8


func _ready() -> void:
	super._ready()
	for stream: AudioStreamWAV in LOOPS.values():
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
	_loop = AudioStreamPlayer.new()
	add_child(_loop)


func play_color(index: int) -> void:
	play("renk", COLOR_PITCHES[index % COLOR_PITCHES.size()] * 0.5)


## name: "firca" / "silgi" / "" (yok); level 0..1 (parmağın hızı)
func set_loop(name: String, level: float, delta: float) -> void:
	var target := level if name != "" else 0.0
	_loop_gain = move_toward(_loop_gain, target, delta * (8.0 if target > _loop_gain else 4.0))
	if name != "" and name != _loop_name and level > 0.0:
		_loop_name = name
		_loop.stream = LOOPS[name]
		_loop.play(randf() * 0.8)
	if _loop_gain <= 0.001:
		if _loop.playing:
			_loop.stop()
		_loop_name = ""
		return
	if not _loop.playing and _loop_name != "":
		_loop.play(randf() * 0.8)
	_loop.volume_db = LOOP_VOLUME + linear_to_db(maxf(_loop_gain, 0.001))
