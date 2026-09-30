extends "res://ortak/ses_havuzu.gd"
# Büyükten Küçüğe sesleri (ortak ses havuzu). Hepsi sesler/ses_uret.py ile sentezlendi.
# note(sıra): doğru yerleşme notası; 0 = en büyük nesne (en pes), büyüdükçe tizleşir.

const NOTE_COUNT := 6
const STREAMS := {
	"pop": preload("res://oyunlar/buyukten_kucuge/sesler/pop.wav"),
	"nota_0": preload("res://oyunlar/buyukten_kucuge/sesler/nota_0.wav"),
	"nota_1": preload("res://oyunlar/buyukten_kucuge/sesler/nota_1.wav"),
	"nota_2": preload("res://oyunlar/buyukten_kucuge/sesler/nota_2.wav"),
	"nota_3": preload("res://oyunlar/buyukten_kucuge/sesler/nota_3.wav"),
	"nota_4": preload("res://oyunlar/buyukten_kucuge/sesler/nota_4.wav"),
	"nota_5": preload("res://oyunlar/buyukten_kucuge/sesler/nota_5.wav"),
	"kayma": preload("res://oyunlar/buyukten_kucuge/sesler/kayma.wav"),
	"tok": preload("res://oyunlar/buyukten_kucuge/sesler/tok.wav"),
	"firla": preload("res://oyunlar/buyukten_kucuge/sesler/firla.wav"),
	"geri": preload("res://oyunlar/buyukten_kucuge/sesler/geri.wav"),
	"yildiz": preload("res://oyunlar/buyukten_kucuge/sesler/yildiz.wav"),
	"bolum_sonu": preload("res://oyunlar/buyukten_kucuge/sesler/bolum_sonu.wav"),
	"final": preload("res://oyunlar/buyukten_kucuge/sesler/final.wav"),
}
const VOLUMES := {"pop": -10.0, "kayma": -8.0, "tok": -7.0, "firla": -9.0, "geri": -12.0, "yildiz": -8.0,
	"bolum_sonu": -6.0, "final": -5.0}
const NOTE_VOLUME := -6.0


func _init() -> void:
	streams = STREAMS.duplicate()
	volumes = VOLUMES.duplicate()
	for k in NOTE_COUNT:
		volumes["nota_%d" % k] = NOTE_VOLUME
	player_count = 10


# Sıraya göre nota (6'dan fazla nesne olursa bir oktav yukarıdan devam eder)
func note(rank: int) -> void:
	play("nota_%d" % (rank % NOTE_COUNT), 2.0 if rank >= NOTE_COUNT else 1.0)
