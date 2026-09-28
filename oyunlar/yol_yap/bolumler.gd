extends RefCounted
# Yol Yap bölümleri. Yeni bölüm eklemek için LIST'e bir sözlük ekle.
#
# map: her satır bir dize, satır 0 en üstte. Bütün satırlar aynı uzunlukta olmalı.
#   .  boş (gökyüzü ya da çukur)
#   #  toprak zemin (üstü boşsa çimli çizilir)
#   W  yüksek duvar
#   ~  su birikintisi
#   B  bilyenin başlangıç yeri
#   G  hediye kutusu (hedef)
# dir: bilyenin yuvarlanma yönü (1 = sağa, -1 = sola)
# hints: parçaların gideceği yerler kesikli çizgiyle gösterilsin mi
# pieces: tepsideki parçalar ve doğru yerleri Vector2i(sütun, satır).
#   Türler: "blok", "rampa_sag" (sağa yükselen), "rampa_sol" (sola yükselen),
#           "kopru" (2 hücre, yeri sol hücresi), "yay" (bir üst seviyeye zıplatır)
#
# Oyun açılırken her bölüm yol_mantigi.gd ile kontrol edilir; sorun varsa
# Godot'nun Hata panelinde "Yol Yap bölüm N: ..." diye yazar.

const LIST := [
	# 1: çukura blok
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			".......",
			"B.....G",
			"###.###",
			"###.###",
		],
		"dir": 1,
		"hints": true,
		"pieces": [
			{"type": "blok", "cell": Vector2i(3, 6)},
		],
	},
	# 2: suyun üstüne köprü
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			".......",
			"B.....G",
			"##~~###",
			"#######",
		],
		"dir": 1,
		"hints": true,
		"pieces": [
			{"type": "kopru", "cell": Vector2i(2, 6)},
		],
	},
	# 3: rampayla yukarı çık
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"......G",
			"B..####",
			"#######",
			"#######",
		],
		"dir": 1,
		"hints": true,
		"pieces": [
			{"type": "rampa_sag", "cell": Vector2i(2, 5)},
		],
	},
	# 4: çukur ve basamak
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"......G",
			"B....##",
			"##.####",
			"##.####",
		],
		"dir": 1,
		"hints": true,
		"pieces": [
			{"type": "blok", "cell": Vector2i(2, 6)},
			{"type": "rampa_sag", "cell": Vector2i(4, 5)},
		],
	},
	# 5: yayla duvarın üstünden, sonra su
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			".......",
			"B..W..G",
			"##.#~~#",
			"##.####",
		],
		"dir": 1,
		"hints": true,
		"pieces": [
			{"type": "yay", "cell": Vector2i(2, 6)},
			{"type": "kopru", "cell": Vector2i(4, 6)},
		],
	},
	# 6: sola doğru; su, çukur ve rampa
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"G......",
			"##....B",
			"###.~~#",
			"#######",
		],
		"dir": -1,
		"hints": false,
		"pieces": [
			{"type": "kopru", "cell": Vector2i(4, 6)},
			{"type": "blok", "cell": Vector2i(3, 6)},
			{"type": "rampa_sol", "cell": Vector2i(2, 5)},
		],
	},
	# 7: aşağı in, çukuru kapat, yayla hedefe zıpla
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"B.....G",
			"##....#",
			"###.#.#",
			"#######",
		],
		"dir": 1,
		"hints": false,
		"pieces": [
			{"type": "rampa_sol", "cell": Vector2i(2, 5)},
			{"type": "blok", "cell": Vector2i(3, 6)},
			{"type": "yay", "cell": Vector2i(5, 6)},
		],
	},
	# 8: köprü, rampa, blok ve yay
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"......G",
			"B.....#",
			"#~~##.#",
			"#######",
		],
		"dir": 1,
		"hints": false,
		"pieces": [
			{"type": "kopru", "cell": Vector2i(1, 6)},
			{"type": "rampa_sag", "cell": Vector2i(3, 5)},
			{"type": "blok", "cell": Vector2i(4, 5)},
			{"type": "yay", "cell": Vector2i(5, 6)},
		],
	},
	# 9: sola doğru; aşağı in, suyu ve çukuru geç, yukarı çık
	{
		"map": [
			".......",
			".......",
			".......",
			".......",
			"G.....B",
			"#.....#",
			"##.~~##",
			"#######",
		],
		"dir": -1,
		"hints": false,
		"pieces": [
			{"type": "rampa_sag", "cell": Vector2i(5, 5)},
			{"type": "kopru", "cell": Vector2i(3, 6)},
			{"type": "blok", "cell": Vector2i(2, 6)},
			{"type": "rampa_sol", "cell": Vector2i(1, 5)},
		],
	},
	# 10: beş parça, yüksek duvarın üstündeki hediye
	{
		"map": [
			".......",
			".......",
			".......",
			"......G",
			"......W",
			"B.....W",
			"#.~~.##",
			"#######",
		],
		"dir": 1,
		"hints": false,
		"pieces": [
			{"type": "blok", "cell": Vector2i(1, 6)},
			{"type": "kopru", "cell": Vector2i(2, 6)},
			{"type": "blok", "cell": Vector2i(4, 6)},
			{"type": "rampa_sag", "cell": Vector2i(4, 5)},
			{"type": "yay", "cell": Vector2i(5, 5)},
		],
	},
]
