extends RefCounted
# Uçan Kuş bölgeleri: her zone_length puanda sırayla değişir (son bölgeden sonra başa döner).
# Her bölgenin gökyüzü, zemini, kayan arka plan katmanları ve kendi sütunu vardır. Görseller
# gorseller/svg_uret.py ile üretilir: direk_<ad>_<kalinlik>.svg, katman_<ad>_<uzak|orta|yakin>.svg.

const G := "res://oyunlar/ucan_kus/gorseller/"

# gok: [üst, alt] renk · zemin / zemin_kenar: çimen şeridi · bulut: süzülen bulutların rengi
# cisim: "gunes" / "ay", cisim_renk, cisim_yer (ekran genişliği ve oyun alanı yüksekliğinin oranı), cisim_boy
# direk_renkleri: doluysa sütun bu renklerden biriyle boyanır (şehirde binalar renk renk)
const BOLGELER := [
	{
		"ad": "orman",
		"gok": [Color("8fd3ff"), Color("e6f7ff")], "zemin": Color("8cd873"), "zemin_kenar": Color("66b852"),
		"bulut": Color(1, 1, 1, 0.95),
		"cisim": "gunes", "cisim_renk": Color("fff3b0"), "cisim_yer": Vector2(0.84, 0.2), "cisim_boy": 1.0,
		"direk_renkleri": [],
	},
	{
		"ad": "sehir",
		"gok": [Color("b3d6ff"), Color("f6eeff")], "zemin": Color("cdc9dd"), "zemin_kenar": Color("aaa5c0"),
		"bulut": Color(1, 1, 1, 0.9),
		"cisim": "gunes", "cisim_renk": Color("fff6cf"), "cisim_yer": Vector2(0.16, 0.18), "cisim_boy": 0.9,
		"direk_renkleri": [Color("ffd0de"), Color("ffeab0"), Color("c4f1de"), Color("dcd0ff"), Color("ffd8b8"), Color("c6e3ff")],
	},
	{
		"ad": "kar",
		"gok": [Color("a9cdf4"), Color("f2f8ff")], "zemin": Color("f1f7ff"), "zemin_kenar": Color("cbdcf3"),
		"bulut": Color(1, 1, 1, 0.85),
		"cisim": "gunes", "cisim_renk": Color(1, 1, 1, 0.8), "cisim_yer": Vector2(0.74, 0.22), "cisim_boy": 0.8,
		"direk_renkleri": [],
	},
	{
		"ad": "sahil",
		"gok": [Color("ee86a6"), Color("ffd59a")], "zemin": Color("f3d9a4"), "zemin_kenar": Color("dfbb79"),
		"bulut": Color(1.0, 0.86, 0.82, 0.85),
		"cisim": "gunes", "cisim_renk": Color("ffe9a8"), "cisim_yer": Vector2(0.52, 0.5), "cisim_boy": 1.45,
		"direk_renkleri": [],
	},
	{
		"ad": "gece",
		"gok": [Color("1b2259"), Color("4b4f9a")], "zemin": Color("2f3b6b"), "zemin_kenar": Color("252e57"),
		"bulut": Color(0.62, 0.65, 0.9, 0.55),
		"cisim": "ay", "cisim_renk": Color.WHITE, "cisim_yer": Vector2(0.66, 0.24), "cisim_boy": 1.0,
		"direk_renkleri": [],
	},
]


static func bolge(sira: int) -> Dictionary:
	return BOLGELER[posmod(sira, BOLGELER.size())]


static func katman_yolu(ad: String, tur: String) -> String:
	return G + "katman_%s_%s.svg" % [ad, tur]


static func direk_yolu(ad: String, kalinlik: String) -> String:
	return G + "direk_%s_%s.svg" % [ad, kalinlik]
