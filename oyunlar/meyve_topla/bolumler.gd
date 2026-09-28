extends RefCounted
# Meyve Topla bölümleri. Her bölüm bir sözlük; 12. bölümden sonra sonsuz mod üretilir.
#
#   goal            toplanacak meyve sayısı
#   fall_speed      en yüksek düşme hızı (piksel/sn)
#   spawn_interval  iki nesne arasındaki ortalama süre (sn)
#   fruits          düşebilecek iyi meyveler (gorseller/meyveler/ içindeki dosya adları)
#   bad             kötü nesneler: "curuk_elma", "tas"
#   bad_chance      düşen bir nesnenin kötü olma olasılığı (0-1)
#   wind            iyi meyvelerin rüzgarla salınarak düşme olasılığı (0-1)
#   target_fruit    boş değilse sadece bu meyve sayılır, diğer iyi meyveler sepetten seker
#   target_share    hedef meyve bölümünde düşen iyi meyvelerin ne kadarının hedef olacağı
#   powerup_chance  güçlendirme baloncuğu olasılığı
#   background      "sabah", "ogle", "aksam", "gece"

const ALL_FRUITS := ["elma", "cilek", "muz", "portakal", "kiraz", "uzum", "karpuz", "ananas"]

# Meyve yakalanınca çıkan parçacıkların rengi
const FRUIT_COLORS := {
	"elma": Color("a8dc45"), "cilek": Color("f23a55"), "muz": Color("ffd84a"), "portakal": Color("ffa93a"),
	"kiraz": Color("e3203f"), "uzum": Color("9b6bea"), "karpuz": Color("f2465e"), "ananas": Color("ffc53a"),
}

const LIST := [
	# --- Sabah: kolay, kötü nesne yok ---
	{"goal": 6, "fall_speed": 165.0, "spawn_interval": 2.0, "fruits": ["elma", "cilek"],
		"bad": [], "bad_chance": 0.0, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.0, "background": "sabah"},
	{"goal": 8, "fall_speed": 180.0, "spawn_interval": 1.9, "fruits": ["elma", "cilek", "muz"],
		"bad": [], "bad_chance": 0.0, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.07, "background": "sabah"},
	{"goal": 10, "fall_speed": 195.0, "spawn_interval": 1.8, "fruits": ["elma", "cilek", "muz", "portakal"],
		"bad": [], "bad_chance": 0.0, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "sabah"},
	# --- Öğle: çürük elma başlar ---
	{"goal": 10, "fall_speed": 205.0, "spawn_interval": 1.75, "fruits": ["elma", "cilek", "muz", "portakal", "kiraz"],
		"bad": ["curuk_elma"], "bad_chance": 0.12, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "ogle"},
	{"goal": 12, "fall_speed": 215.0, "spawn_interval": 1.7, "fruits": ["elma", "cilek", "muz", "portakal", "kiraz", "uzum"],
		"bad": ["curuk_elma"], "bad_chance": 0.15, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "ogle"},
	{"goal": 12, "fall_speed": 225.0, "spawn_interval": 1.65, "fruits": ["elma", "cilek", "muz", "portakal", "kiraz", "uzum", "karpuz"],
		"bad": ["curuk_elma"], "bad_chance": 0.17, "wind": 0.0, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "ogle"},
	# --- Gün batımı: taşlar ve rüzgar ---
	{"goal": 12, "fall_speed": 235.0, "spawn_interval": 1.6, "fruits": ALL_FRUITS,
		"bad": ["curuk_elma", "tas"], "bad_chance": 0.17, "wind": 0.25, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "aksam"},
	{"goal": 14, "fall_speed": 245.0, "spawn_interval": 1.55, "fruits": ALL_FRUITS,
		"bad": ["curuk_elma", "tas"], "bad_chance": 0.19, "wind": 0.35, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "aksam"},
	{"goal": 14, "fall_speed": 255.0, "spawn_interval": 1.5, "fruits": ALL_FRUITS,
		"bad": ["curuk_elma", "tas"], "bad_chance": 0.2, "wind": 0.45, "target_fruit": "", "target_share": 0.0,
		"powerup_chance": 0.08, "background": "aksam"},
	# --- Gece: hedef meyve bölümleri ---
	{"goal": 8, "fall_speed": 240.0, "spawn_interval": 1.5, "fruits": ["cilek", "elma", "muz", "portakal"],
		"bad": ["curuk_elma"], "bad_chance": 0.12, "wind": 0.2, "target_fruit": "cilek", "target_share": 0.5,
		"powerup_chance": 0.08, "background": "gece"},
	{"goal": 10, "fall_speed": 250.0, "spawn_interval": 1.45, "fruits": ["muz", "elma", "cilek", "portakal", "kiraz", "uzum"],
		"bad": ["curuk_elma", "tas"], "bad_chance": 0.15, "wind": 0.3, "target_fruit": "muz", "target_share": 0.5,
		"powerup_chance": 0.08, "background": "gece"},
	{"goal": 12, "fall_speed": 260.0, "spawn_interval": 1.4, "fruits": ALL_FRUITS,
		"bad": ["curuk_elma", "tas"], "bad_chance": 0.18, "wind": 0.35, "target_fruit": "uzum", "target_share": 0.5,
		"powerup_chance": 0.08, "background": "gece"},
]

const BACKGROUNDS := ["sabah", "ogle", "aksam", "gece"]


# Bölüm ayarlarını verir (index 0'dan başlar). Listenin sonundan sonrası sonsuz moddur:
# her bölümde biraz daha hızlı ve kalabalık olur (üst sınırlı), arka plan iki bölümde bir değişir.
static func get_level(index: int) -> Dictionary:
	if index < LIST.size():
		return LIST[index]
	var n := index - LIST.size() + 1
	var target_level := n % 2 == 0
	return {
		"goal": mini(8 + floori(n / 2.0), 14) if target_level else mini(12 + n, 22),
		"fall_speed": minf(260.0 + 6.0 * n, 360.0),
		"spawn_interval": maxf(1.4 - 0.02 * n, 1.0),
		"fruits": ALL_FRUITS,
		"bad": ["curuk_elma", "tas"],
		"bad_chance": minf(0.2 + 0.01 * n, 0.3),
		"wind": minf(0.4 + 0.02 * n, 0.6),
		"target_fruit": ALL_FRUITS[n % ALL_FRUITS.size()] if target_level else "",
		"target_share": 0.5,
		"powerup_chance": 0.08,
		"background": BACKGROUNDS[floori((n - 1) / 2.0) % BACKGROUNDS.size()],
	}
