extends "res://ortak/ses_havuzu.gd"
# Gölge Eşleştirme sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile üretildi.

const STREAMS := {
	"pop": preload("res://oyunlar/golge_eslestirme/sesler/pop.wav"),
	"ding": preload("res://oyunlar/golge_eslestirme/sesler/ding.wav"),
	"boing": preload("res://oyunlar/golge_eslestirme/sesler/boing.wav"),
	"bolum_sonu": preload("res://oyunlar/golge_eslestirme/sesler/bolum_sonu.wav"),
	"final": preload("res://oyunlar/golge_eslestirme/sesler/final.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak, ani yüksek ses olmasın
const VOLUMES := {"pop": -10.0, "ding": -8.0, "boing": -9.0, "bolum_sonu": -7.0, "final": -6.0}


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 6
