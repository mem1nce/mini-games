# Minik Oyunlar

Küçük çocuklar (4-8 yaş) için basit eğitici mini oyunlar. Oyun fikirlerini kullanıcı verir, birlikte geliştiririz.
Uygulamanın adı "Minik Oyunlar" (`application/config/name`; `user://` klasörü de bu adla: `app_userdata/Minik Oyunlar`).

## Proje durumu

- Motor: Godot 4.7, renderer: Mobile (`project.godot`). Hedef: sadece telefon (ileride Android).
- Ekran: dikey (portrait), temel çözünürlük 720x1280; masaüstünde test penceresi 450x800.
- Ekran ölçekleme: `canvas_items` + `expand` — görünen alan 720x1280'den uzun/geniş olabilir. Boyutu `get_viewport_rect().size` ile al, anchor/container kullan, sabit piksel konumlarına güvenme.
- Giriş sadece dokunma (`InputEventScreenTouch`). Masaüstünde test için "Emulate Touch From Mouse" açık. Önemli öğeleri kenarlardan ve üstteki çentik bölgesinden uzak tut (üstten ~90 px, yanlardan ~40 px).
- Başlangıç sahnesi: ana menü `res://ana_menu/ana_menu.tscn` (bir oyunu tek başına denemek için o oyunun sahnesini F6 ile çalıştır).

## Uygulama yapısı

- `ana_menu/` — Ana menü: 7 oyun kartı (2 sütun, tek kalan ortada; satırlar ekrana sığmazsa kartlar orantılı küçülür; uzun adlarda kart yazısı küçülür), `OYUNLAR` listesinde. Kart çizimleri oyunların SVG'lerinin kopyaları (`ana_menu/gorseller/`, 2x + mipmap). İlerleme rozeti oyunların kendi `user://*.cfg` kayıtlarından okunur (`_ulasilan_bolum`; Köstebek'te rekor skor); kayıt yoksa gösterilmez. **Yeni oyun eklenince** `OYUNLAR`'a bir satır ve `_ciz()` içine çizimini ekle.
- `ortak/sahne_gecis.gd` — autoload `SahneGecis`: `sahne_degistir(yol)`, `ana_menuye_don()`, `sahneyi_yeniden_baslat()`; yumuşak kararma/açılma, geçişte eski sahne durur. Android geri tuşu (`quit_on_go_back=false`, `NOTIFICATION_WM_GO_BACK_REQUEST`) ve Escape: oyundan ana menüye, ana menüden çıkış.
- `ortak/tema.tres` — proje geneli tema (`gui/theme/custom`): Nunito (değişken font, ağırlıklar `FontVariation` ile; OpenType etiketi sayı olarak yazılmalı: `2003265652` = `wght`), düğme ve panel stilleri, `Baslik` / `KartYazisi` / `Rozet` tip varyasyonları. Fredoka Türkçe "ş" harfini düzgün göstermediği için kullanılmadı.
- `ortak/basili_geri_dugmesi.gd` — basılı tutunca dolan halkalı geri düğmesi (`press` / `release` / `contains`, `completed` sinyali); dokunmayı oyun sahnesi yönetir. Gölge Eşleştirme ve Köstebek kullanır.
- `ortak/ses_havuzu.gd` — küçük `AudioStreamPlayer` havuzu (`play(ad, pitch)`; boş oynatıcı yoksa en eski ses susar). Oyunun `sesler.gd`'si bunu `extends` edip `_init`'te `streams` / `volumes` verir. `ortak/ses/sentez.py`: seslerin Python sentez yardımcıları (oyunların `sesler/ses_uret.py` betikleri içe aktarır).
- `ortak/gorseller/geri.svg` ortak geri simgesi. `ortak/simge/`: simgenin ön/arka plan SVG'leri ve Android PNG'leri; `icon.svg` bunlardan oluşur.
- **Geri düğmesi kuralı**: her oyunun ilk ekranında sol üstte geri düğmesi → `SahneGecis.ana_menuye_don()`. Oyun içindeki geri önce oyunun kendi önceki ekranına (bölüm seçme / başlangıç ekranı), oradan ana menüye.

## Oyunlar

- `oyunlar/ucan_kus/` — Uçan Kuş: dokununca zıplayan kuşla direklerin arasından geçme. Zorluk ayarları `ucan_kus.gd` başında `@export`. Görseller SVG (kuş 3 kare, direk beyaz çizilip `modulate` ile boyanıyor).
- `oyunlar/dondurmaci/` — Dondurmacı: müşterinin baloncukta gösterdiği dondurmayı (külah/kase + sıralı toplar) hazırlama. Sipariş kuralları `dondurmaci.gd` başında `@export`; hayvanlar, tatlar ve kaplar `ANIMALS` / `FLAVORS` / `CONTAINERS` listelerinde. Görseller `gorseller/` alt klasöründe (her hayvanın `hayvan_x.svg` ve `hayvan_x_mutlu.svg` hali var).
- `oyunlar/yol_yap/` — Yol Yap: parçaları (blok, rampa, köprü, yay) ızgaraya sürükleyip bilyeyi hediye kutusuna ulaştırma, 10 bölüm. Bölümler `bolumler.gd` (harita dizeleri + parçaların doğru yerleri), bilyenin yolu fiziksiz olarak `yol_mantigi.gd` içinde hesaplanır; `validate()` her bölümün çözülebildiğini kontrol eder (oyun açılırken de çalışır). Parçalar sadece doğru hücreye oturur. İlerleme `user://yol_yap.cfg`.
- `oyunlar/hafiza/` — Hafıza Kartları: iki tema (hayvanlar, meyveler), 4 bölüm (2x2 → 4x4). Temalar ve bölümler `veriler.gd` içinde (yeni tema = `temalar/` altında yeni klasör + `THEMES`'e bir satır). Kart animasyonları `kart.gd`. İlerleme `user://hafiza.cfg`. Bu oyunun SVG'leri 2x ölçek + mipmap ile içe aktarılır (`.import` içinde `svg/scale=2.0`, `mipmaps/generate=true`) ve kök düğümde `texture_filter = LINEAR_WITH_MIPMAPS` var; yeni SVG eklenince aynı ayarları ver.

- `oyunlar/meyve_topla/` — Meyve Topla: başında sepet taşıyan kirpiyle ağaçtan düşen meyveleri toplama, 12 bölüm + sonsuz mod, güçlendirmeler. Tasarım ve dosya yapısı `TASARIM.md` içinde. Bölüm verileri `bolumler.gd`, akış `meyve_topla.gd`; oyuncu, düşen nesne, bölüm yöneticisi, ağaç, arka plan, efektler ve arayüz ayrı script'lerde. Parçacıklar `CPUParticles2D`. Meyve SVG'leri hafıza oyunundan kopyalandı (zemin gölgesi çıkarılarak). İlerleme `user://meyve_topla.cfg`.
- `oyunlar/golge_eslestirme/` — Gölge Eşleştirme (1-3 yaş, hiç yazı yok): eşyayı sürükleyip kendi gölgesine bırakma, 10 bölüm, sonra büyük kutlama ve 1. bölüme dönüş. Veri odaklı: her eşya `esyalar/<kategori>/<ad>.svg` + `.tres` (`ShadowItemData`: görsel + siluet grubu), her bölüm `bolumler/bolum_XX.tres` (`ShadowLevelData`), bölüm listesi kök düğümün `levels` dizisinde; `_check_data()` aynı siluet grubundan iki eşyanın aynı bölümde olmasını engeller. Gölge ayrı çizilmez, `golge.gdshader` ile eşyanın kendi görselinden üretilir. Ayarlar (bırakma toleransı, ipucu süresi, animasyon süreleri) `golge_eslestirme.gd` başında `@export`. Tek parmak kilidi (`active_touch`), geri düğmesi basılı tutunca çalışır. Sesler `sesler/ses_uret.py` ile sentezlenmiş `.wav` (`sesler.gd` ortak ses havuzunu kullanır). Ayrıntılar ve yeni eşya/bölüm ekleme `TASARIM.md` içinde. İlerleme `user://golge_eslestirme.cfg`.
- `oyunlar/kostebek/` — Köstebek Vurma: çukurlardan çıkan köstebeğe (+30) ve meyve/sebzeye (+10) dokunma, bomba 1 can götürür (3 can), kaçan için ceza yok. Kasklı köstebek iki dokunuş ister. Skora bağlı seviyeler (her 150 puan); 6 → 9 çukur. **Bütün denge ayarları `denge.tres`** (`WhackBalance` + `WhackLevelData` seviye dizisi). Durumlar COUNTDOWN / PLAYING / GAME_OVER (`kostebek.gd`), çıkış kuralları `cikis_yoneticisi.gd`, nesneler `cikan_nesne.gd` temelli (`kostebek_nesne` / `meyve_nesne` / `bomba_nesne`). Nesne çukurun maske düğümünde (`clip_children`) çizilir, alt kısmı ön toprak dudağının arkasında kalır (`cukur.gd`). Çoklu dokunma, basış anında vurma. Ayrıntılar `TASARIM.md` içinde. Rekor `user://kostebek.cfg`.

## Görsel kontrol

SVG çizince Godot'ta bir SubViewport'a koyup PNG olarak kaydederek bak; kalitesiz görünenleri düzelt. Oyun ekranını da `--fixed-fps 60` ile çalışan bir SceneTree script'iyle ekran görüntüsü alarak kontrol et.

Otomatik testte dokunma olaylarını `root.push_input(event, true)` ile gönder (ikinci parametre olmadan headless'ta koordinatlar pencere ölçeğiyle bozulur). Animasyonlu ekranları, animasyon bitince (ör. ölçek ~1 olunca) çek; ilk karede her şey ölçek 0'dadır. Testlerin yazdığı `user://` kayıtlarını sonunda sil.

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
