# Mini Games

Küçük çocuklar (4-8 yaş) için basit eğitici mini oyunlar. Oyun fikirlerini kullanıcı verir, birlikte geliştiririz.

## Proje durumu

- Motor: Godot 4.7, renderer: Mobile (`project.godot`). Hedef: sadece telefon (ileride Android).
- Ekran: dikey (portrait), temel çözünürlük 720x1280; masaüstünde test penceresi 450x800.
- Ekran ölçekleme: `canvas_items` + `expand` — görünen alan 720x1280'den uzun/geniş olabilir. Boyutu `get_viewport_rect().size` ile al, anchor/container kullan, sabit piksel konumlarına güvenme.
- Giriş sadece dokunma (`InputEventScreenTouch`). Masaüstünde test için "Emulate Touch From Mouse" açık. Önemli öğeleri kenarlardan ve üstteki çentik bölgesinden uzak tut (üstten ~90 px, yanlardan ~40 px).
- Ana sahne (test için en son yapılan oyun): `res://oyunlar/yol_yap/yol_yap.tscn`

## Oyunlar

- `oyunlar/ucan_kus/` — Uçan Kuş: dokununca zıplayan kuşla direklerin arasından geçme. Zorluk ayarları `ucan_kus.gd` başında `@export`. Görseller SVG (kuş 3 kare, direk beyaz çizilip `modulate` ile boyanıyor).
- `oyunlar/dondurmaci/` — Dondurmacı: müşterinin baloncukta gösterdiği dondurmayı (külah/kase + sıralı toplar) hazırlama. Sipariş kuralları `dondurmaci.gd` başında `@export`; hayvanlar, tatlar ve kaplar `ANIMALS` / `FLAVORS` / `CONTAINERS` listelerinde. Görseller `gorseller/` alt klasöründe (her hayvanın `hayvan_x.svg` ve `hayvan_x_mutlu.svg` hali var).
- `oyunlar/yol_yap/` — Yol Yap: parçaları (blok, rampa, köprü, yay) ızgaraya sürükleyip bilyeyi hediye kutusuna ulaştırma, 10 bölüm. Bölümler `bolumler.gd` (harita dizeleri + parçaların doğru yerleri), bilyenin yolu fiziksiz olarak `yol_mantigi.gd` içinde hesaplanır; `validate()` her bölümün çözülebildiğini kontrol eder (oyun açılırken de çalışır). Parçalar sadece doğru hücreye oturur. İlerleme `user://yol_yap.cfg`.

## Kurallar

- **Godot 4 ve GDScript** kullan. Godot 3 sözdizimi kullanma
  (ör. `yield` yerine `await`, `connect("x", self, "f")` yerine `x.connect(f)`,
  `export var` yerine `@export var`, `onready var` yerine `@onready var`,
  `KinematicBody2D` yerine `CharacterBody2D`, `update()` yerine `queue_redraw()`).
- **Her oyun kendi klasöründe** olsun: `res://oyunlar/oyun_adi/`
  (sahneler, scriptler ve varsa varlıklar o klasörde). Ortak kod gerekirse `res://ortak/` altına konur.
- **Sade kod**: kısa fonksiyonlar, gereksiz soyutlama yok. Değişken/fonksiyon isimleri **İngilizce** (snake_case), yorumlar **Türkçe** olabilir. Mümkünse tip belirt (`var score: int = 0`).
- **Görsel dosya yoksa şekilleri kodla çiz** (`_draw()`, `draw_circle`, `draw_rect`, `draw_polygon`, `Polygon2D`, `ColorRect`, `StyleBoxFlat` vb.).
- **Çocuk dostu arayüz**:
  - Büyük, renkli, kolay tıklanır/dokunulur öğeler (dokunma alanı en az ~120 px).
  - Yazı çok az; mümkünse simge, renk, şekil ve ses ile anlat.
  - Yanlış cevapta ceza yok; nazik geri bildirim, doğru cevapta görsel kutlama.
  - Hem fare hem dokunmatik ile çalışsın.
- **Her değişiklikten sonra** kullanıcıya Godot'ta nasıl test edeceğini kısaca söyle
  (hangi sahneyi açacak, F6 / F5 ile çalıştırma, neye bakacak).
