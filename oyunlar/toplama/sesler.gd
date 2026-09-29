extends "res://ortak/ses_havuzu.gd"
# Toplama Öğreniyorum sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile üretildi.

const STREAMS := {
	"sayma": preload("res://oyunlar/toplama/sesler/sayma.wav"),
	"dokunma": preload("res://oyunlar/toplama/sesler/dokunma.wav"),
	"dogru": preload("res://oyunlar/toplama/sesler/dogru.wav"),
	"yanlis": preload("res://oyunlar/toplama/sesler/yanlis.wav"),
	"ucus": preload("res://oyunlar/toplama/sesler/ucus.wav"),
	"bolum": preload("res://oyunlar/toplama/sesler/bolum.wav"),
	"final": preload("res://oyunlar/toplama/sesler/final.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak, ani yüksek ses olmasın
const VOLUMES := {"sayma": -9.0, "dokunma": -11.0, "dogru": -7.0, "yanlis": -10.0, "ucus": -12.0, "bolum": -7.0, "final": -6.0}


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 8
