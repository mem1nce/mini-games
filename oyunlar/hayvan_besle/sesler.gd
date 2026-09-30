extends "res://ortak/ses_havuzu.gd"
# Hayvanları Besle sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile üretildi; kedi, köpek ve inek
# Müzik Kutusu'ndan kopya. Hayvan sesleri FeedAnimalData.voice'tan gelir ve add_voice() ile eklenir.

const STREAMS := {
	"pop": preload("res://oyunlar/hayvan_besle/sesler/pop.wav"),
	"hapur": preload("res://oyunlar/hayvan_besle/sesler/hapur.wav"),
	"yutma": preload("res://oyunlar/hayvan_besle/sesler/yutma.wav"),
	"guruldama": preload("res://oyunlar/hayvan_besle/sesler/guruldama.wav"),
	"ih_ih": preload("res://oyunlar/hayvan_besle/sesler/ih_ih.wav"),
	"nokta": preload("res://oyunlar/hayvan_besle/sesler/nokta.wav"),
	"kikir": preload("res://oyunlar/hayvan_besle/sesler/kikir.wav"),
	"bolum_sonu": preload("res://oyunlar/hayvan_besle/sesler/bolum_sonu.wav"),
	"final": preload("res://oyunlar/hayvan_besle/sesler/final.wav"),
}
# Ses seviyeleri (dB). Sesler aynı yükseklikte üretildi; burada yumuşak olanlar biraz kısık.
const VOLUMES := {"pop": -9.0, "hapur": -8.0, "yutma": -8.0, "guruldama": -10.0, "ih_ih": -7.0, "nokta": -9.0,
	"kikir": -8.0, "bolum_sonu": -6.0, "final": -5.0}
const VOICE_VOLUME := -6.0


func _init() -> void:
	streams = STREAMS.duplicate()
	volumes = VOLUMES.duplicate()
	player_count = 10


# Hayvan sesi (ad: "ses_<hayvan>")
func add_voice(animal: FeedAnimalData) -> void:
	streams[voice_name(animal)] = animal.voice
	volumes[voice_name(animal)] = VOICE_VOLUME


static func voice_name(animal: FeedAnimalData) -> String:
	return "ses_" + str(animal.id)
