extends "res://ortak/ses_havuzu.gd"
# Araba Yarışı sesleri (ortak ses havuzu) + çocuğun arabasının motor sesi (döngü; perdesi ve
# yüksekliği hıza göre değişir). Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/araba_yarisi/sesler/"
const STREAMS := {
	"yildiz": preload(S + "yildiz.wav"),
	"su": preload(S + "su.wav"),
	"kasis": preload(S + "kasis.wav"),
	"zipla": preload(S + "zipla.wav"),
	"inis": preload(S + "inis.wav"),
	"bip": preload(S + "bip.wav"),
	"basla": preload(S + "basla.wav"),
	"bitis": preload(S + "bitis.wav"),
	"podyum": preload(S + "podyum.wav"),
	"tik": preload(S + "tik.wav"),
	"boya": preload(S + "boya.wav"),
	"hayvan": preload(S + "hayvan.wav"),
	"kilit": preload(S + "kilit.wav"),
	"say": preload(S + "say.wav"),
}
const VOLUMES := {
	"yildiz": -10.0, "su": -9.0, "kasis": -9.0, "zipla": -12.0, "inis": -10.0, "bip": -10.0, "basla": -8.0,
	"bitis": -7.0, "podyum": -7.0, "tik": -12.0, "boya": -9.0, "hayvan": -9.0, "kilit": -12.0, "say": -12.0,
}
const ENGINE_DB := [-30.0, -17.0]    # boştayken / en hızlıyken

var _engine: AudioStreamPlayer
var _engine_on := false


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 10


func _ready() -> void:
	super._ready()
	_engine = AudioStreamPlayer.new()
	_engine.stream = preload(S + "motor.wav")
	_engine.volume_db = -80.0
	add_child(_engine)


func engine_start() -> void:
	_engine_on = true
	if not _engine.playing:
		_engine.play()


func engine_stop() -> void:
	_engine_on = false


# Motor sesi: hız ve gaz perdesini/yüksekliğini belirler; kapanınca yumuşakça söner
func engine_update(speed_ratio: float, throttle: bool, delta: float) -> void:
	var goal_db := -80.0
	var goal_pitch := 0.8
	if _engine_on:
		goal_db = lerpf(ENGINE_DB[0], ENGINE_DB[1], clampf(speed_ratio, 0.0, 1.0)) + (2.0 if throttle else 0.0)
		goal_pitch = 0.75 + speed_ratio * 0.75 + (0.08 if throttle else 0.0)
	var k := 1.0 - exp(-6.0 * delta)
	_engine.volume_db = lerpf(_engine.volume_db, goal_db, k)
	_engine.pitch_scale = maxf(0.3, lerpf(_engine.pitch_scale, goal_pitch, k))
	if not _engine_on and _engine.volume_db < -60.0 and _engine.playing:
		_engine.stop()
