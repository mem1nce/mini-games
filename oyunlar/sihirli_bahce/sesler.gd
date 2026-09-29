extends "res://ortak/ses_havuzu.gd"
# Sihirli Bahçe sesleri (ortak ses havuzu) + bulut sürüklenirken çalan yumuşak yağmur döngüsü.
# Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/sihirli_bahce/sesler/"
const NAMES := ["tohum", "sulandi", "buyume", "acilma", "sihir", "kipir", "kurbaga", "pirilti", "kanat", "vizz",
	"hop", "saklan", "tik", "kese", "gunes", "ruzgar", "gece", "gunduz", "topla", "kesif"]
const VOLUMES := {
	"tohum": -9.0, "sulandi": -11.0, "buyume": -9.0, "acilma": -9.0, "sihir": -10.0, "kipir": -13.0,
	"kurbaga": -8.0, "pirilti": -12.0, "kanat": -12.0, "vizz": -14.0, "hop": -12.0, "saklan": -12.0,
	"tik": -12.0, "kese": -12.0, "gunes": -10.0, "ruzgar": -9.0, "gece": -9.0, "gunduz": -9.0, "topla": -8.0, "kesif": -6.0,
}
const RAIN_DB := -16.0

var _rain: AudioStreamPlayer
var _rain_on := false


func _init() -> void:
	for sound in NAMES:
		streams[sound] = load(S + sound + ".wav")
	volumes = VOLUMES
	player_count = 10


func _ready() -> void:
	super._ready()
	_rain = AudioStreamPlayer.new()
	_rain.stream = load(S + "yagmur.wav")
	_rain.volume_db = -80.0
	add_child(_rain)


func set_rain(value: bool) -> void:
	_rain_on = value
	if value and not _rain.playing:
		_rain.play()


func _process(delta: float) -> void:
	var goal := RAIN_DB if _rain_on else -80.0
	_rain.volume_db = lerpf(_rain.volume_db, goal, 1.0 - exp(-(8.0 if _rain_on else 4.0) * delta))
	if not _rain_on and _rain.playing and _rain.volume_db < -60.0:
		_rain.stop()
