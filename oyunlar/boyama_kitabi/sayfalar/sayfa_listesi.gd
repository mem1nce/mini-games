extends RefCounted
# Bu dosyayı sayfalar/derle.gd üretir; elle değiştirme.
# Her sayfa: id (png/<id>_*.png), kategori, bölge sayısı (kağıt dahil). Basit sayfalar önce.

const PAGES := [
	{"id": "kedi", "category": "hayvanlar", "regions": 11},
	{"id": "balik", "category": "hayvanlar", "regions": 12},
	{"id": "kaplumbaga", "category": "hayvanlar", "regions": 16},
	{"id": "tavsan", "category": "hayvanlar", "regions": 18},
	{"id": "araba", "category": "araclar", "regions": 11},
	{"id": "tekne", "category": "araclar", "regions": 11},
	{"id": "ucak", "category": "araclar", "regions": 16},
	{"id": "tren", "category": "araclar", "regions": 28},
	{"id": "top", "category": "oyuncaklar", "regions": 9},
	{"id": "ucurtma", "category": "oyuncaklar", "regions": 11},
	{"id": "oyuncak_ayi", "category": "oyuncaklar", "regions": 18},
	{"id": "robot", "category": "oyuncaklar", "regions": 22},
	{"id": "gunes", "category": "doga", "regions": 10},
	{"id": "cicek", "category": "doga", "regions": 11},
	{"id": "agac", "category": "doga", "regions": 14},
	{"id": "gokkusagi", "category": "doga", "regions": 21},
	{"id": "sekiller", "category": "sekiller", "regions": 7},
	{"id": "yildiz", "category": "sekiller", "regions": 11},
	{"id": "kalp", "category": "sekiller", "regions": 12},
	{"id": "mandala", "category": "sekiller", "regions": 27},
]
