extends "res://ortak/ses_havuzu.gd"
# Çıkarma Öğreniyorum sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile üretildi.

const STREAMS := {
	"sayma": preload("res://oyunlar/cikarma/sesler/sayma.wav"),
	"dokunma": preload("res://oyunlar/cikarma/sesler/dokunma.wav"),
	"dogru": preload("res://oyunlar/cikarma/sesler/dogru.wav"),
	"yanlis": preload("res://oyunlar/cikarma/sesler/yanlis.wav"),
	"cikarma": preload("res://oyunlar/cikarma/sesler/cikarma.wav"),
	"ucus": preload("res://oyunlar/cikarma/sesler/ucus.wav"),
	"bolum": preload("res://oyunlar/cikarma/sesler/bolum.wav"),
	"final": preload("res://oyunlar/cikarma/sesler/final.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak, ani yüksek ses olmasın
const VOLUMES := {"sayma": -9.0, "dokunma": -11.0, "dogru": -7.0, "yanlis": -10.0, "cikarma": -10.0, "ucus": -12.0, "bolum": -7.0, "final": -6.0}


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 8
