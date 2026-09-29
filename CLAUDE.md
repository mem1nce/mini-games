# Minik Oyunlar

Küçük çocuklar (4-8 yaş) için basit eğitici mini oyunlar. Oyun fikirlerini kullanıcı verir, birlikte geliştiririz.
Uygulamanın adı "Minik Oyunlar" (`application/config/name`; `user://` klasörü de bu adla: `app_userdata/Minik Oyunlar`).

## Takım çalışması

Bu repoyu iki kişi kullanıyor (git kullanıcı adları): **mem1nce** ve **emirsalihgmrk**. İkisinin Claude'u da bu dosyayı okur.

### Dallarla çalışma

- `main` dalı her zaman çalışan sürümdür. `main`'e doğrudan commit veya push yapma (GitHub'da `main` korumalı: PR olmadan push, force push ve dal silme engelli).
- Her yeni iş için `main`'in güncel halinden yeni bir dal aç: `git checkout main`, `git pull`, sonra `git checkout -b <isim>/<kısa-açıklama>` (ör. `mehmet/meyve-topla-ses`).
- Bir iş = bir dal. Dallar kısa ömürlü olsun.
- İş bitince izin istemeden: dalı push'la, `gh pr create` ile PR aç, `gh pr merge --merge --delete-branch` ile hemen main'e birleştir, sonra main'e dön ve pull yap. (PR açıklamasına neyi değiştirdiğini ve Godot'ta nasıl test edileceğini yaz; yerel dal kaldıysa `git branch -d <dal>` ile sil.)
- PR'da çakışma (conflict) varsa birleştirme; dur ve kullanıcıya açıkla. (İstisna: çakışma sadece `CLAUDE.md` dosyalarındaysa aşağıdaki `CLAUDE.md` kuralına uy.)
- Uzun süren bir işte `main`'deki yenilikleri almak için `main`'i dalına merge et (`git fetch`, sonra `git merge origin/main`). Paylaşılan dallarda rebase yapma.
- Başkasının açık dalında, sahibi istemedikçe commit yapma.
- `gh` kurulu değilse veya giriş yapılmamışsa (`gh auth status`), kullanıcıya kurulum ve giriş adımlarını hatırlat: `winget install GitHub.cli`, terminali yeniden aç, `gh auth login` (GitHub.com → HTTPS → tarayıcı ile giriş).

### Sahiplik ve genel kurallar

- Oyun sahipleri:
  - **mem1nce**: `ucan_kus`, `dondurmaci`, `yol_yap`, `hafiza`, `meyve_topla`
  - **emirsalihgmrk**: `golge_eslestirme`, `kostebek`, `toplama`
- Herkes sadece kendi oyun klasöründe çalışır. Başkasına ait oyunun dosyalarını açıkça istenmedikçe değiştirme.
- Ortak dosyalar: `project.godot`, `res://ana_menu/`, `res://ortak/`, `CLAUDE.md`. Bunlarda değişiklikleri küçük tut.
- Yeni oyun eklerken yönünü (dikey/yatay) belirt ve ana menüye kartını ekle; bunu ayrı bir commit olarak yap.
- Küçük ve sık commit at, açık Türkçe commit mesajları yaz.
- Çakışma (conflict) çıkarsa kendi başına çözme ve başkasının değişikliğini asla silme. Dur ve kullanıcıya hangi dosyada ne olduğunu açıkla.
- CLAUDE.md'de çakışma çıkarsa iki tarafı da koru ve devam et. (`.gitattributes` içindeki `CLAUDE.md merge=union` sayesinde yerel `git merge` bunu kendiliğinden yapar. GitHub PR ekranı bu ayarı dikkate almayabilir; PR'da çakışma görünürse dalında `git merge origin/main` yap, iki tarafın satırlarını da bırak (aynı satır iki kez geldiyse birini sil), commit'le, push'la ve PR'ı birleştir.)
- `git push --force`, `git reset --hard` veya geçmişi değiştiren komutları asla kullanma.
- `.godot/` klasörü commit'lenmez. İki geliştirici de Godot 4.7.2 kullanır.

## Proje durumu

- Motor: Godot 4.7, renderer: Mobile (`project.godot`). Hedef: sadece telefon (ileride Android).
- Ekran yönü: **her oyun dikey ya da yatay olabilir, yönünü SahneGecis sistemine bildirmelidir** — oyunun ana sahnesinin kök düğüm script'ine `@export_enum("dikey", "yatay") var ekran_yonu: String = "yatay"` (bu değişkeni olmayan sahne dikey sayılır). Dikey: çizim boyutu 720x1280 (bilgisayarda test penceresi 450x800); yatay: 1280x720 (800x450). Ana menü her zaman dikeydir.
- Ekran ölçekleme: `canvas_items` + `expand` — görünen alan temel boyuttan uzun/geniş olabilir. Boyutu `get_viewport_rect().size` ile al, anchor/container kullan, sabit piksel konumlarına güvenme.
- Giriş sadece dokunma (`InputEventScreenTouch`). Masaüstünde test için "Emulate Touch From Mouse" açık. Önemli öğeleri kenarlardan ve üstteki çentik bölgesinden uzak tut (üstten ~90 px, yanlardan ~40 px).
- Başlangıç sahnesi: ana menü `res://ana_menu/ana_menu.tscn` (bir oyunu tek başına denemek için o oyunun sahnesini F6 ile çalıştır).

## Uygulama yapısı

- `ana_menu/` — Ana menü: oyun kartları (2 sütun, tek kalan ortada; uzun adlarda kart yazısı küçülür), `OYUNLAR` listesinde. Kart çizimleri oyunların SVG'lerinin kopyaları (`ana_menu/gorseller/`, 2x + mipmap). İlerleme rozeti oyunların kendi `user://*.cfg` kayıtlarından okunur (`_ulasilan_bolum`); kayıt yoksa gösterilmez. **Yeni oyun eklenince** `OYUNLAR`'a bir satır ve `_ciz()` içine çizimini ekle.
- `ortak/sahne_gecis.gd` — autoload `SahneGecis`: `sahne_degistir(yol)`, `ana_menuye_don()`, `sahneyi_yeniden_baslat()`; yumuşak kararma/açılma, geçişte eski sahne durur. Ekran yönü: perde kapalıyken yeni sahnenin `ekran_yonu` değeri okunur, `root.content_scale_size` 720x1280 / 1280x720 yapılır, mobilde `DisplayServer.screen_set_orientation`, bilgisayarda pencere çevrilir; sahne ancak bundan sonra ağaca eklenir (`_ready` doğru boyutla çalışır). F6 ile doğrudan açılan yatay sahne perde kapalıyken döndürülüp yeniden yüklenir. Android geri tuşu (`quit_on_go_back=false`, `NOTIFICATION_WM_GO_BACK_REQUEST`) ve Escape: oyundan ana menüye, ana menüden çıkış.
- `ortak/tema.tres` — proje geneli tema (`gui/theme/custom`): Nunito (değişken font, ağırlıklar `FontVariation` ile; OpenType etiketi sayı olarak yazılmalı: `2003265652` = `wght`), düğme ve panel stilleri, `Baslik` / `KartYazisi` / `Rozet` tip varyasyonları. Fredoka Türkçe "ş" harfini düzgün göstermediği için kullanılmadı.
- `ortak/basili_geri_dugmesi.gd` — basılı tutunca dolan halkalı geri düğmesi (`press` / `release` / `contains`, `completed` sinyali); dokunmayı oyun sahnesi yönetir. Gölge Eşleştirme, Köstebek ve Toplama kullanır.
- `ortak/ses_havuzu.gd` — küçük `AudioStreamPlayer` havuzu (`play(ad, pitch)`; boş oynatıcı yoksa en eski ses susar). Oyunun `sesler.gd`'si bunu `extends` edip `_init`'te `streams` / `volumes` verir. `ortak/ses/sentez.py`: seslerin Python sentez yardımcıları (oyunların `sesler/ses_uret.py` betikleri içe aktarır).
- `ortak/gorseller/geri.svg` ortak geri simgesi. `ortak/simge/`: simgenin ön/arka plan SVG'leri ve Android PNG'leri; `icon.svg` bunlardan oluşur.
- **Geri düğmesi kuralı**: her oyunun ilk ekranında sol üstte geri düğmesi → `SahneGecis.ana_menuye_don()`. Oyun içindeki geri önce oyunun kendi önceki ekranına (bölüm seçme / başlangıç ekranı), oradan ana menüye.

## Oyunlar

- Her oyunun kendine özel notları kendi klasöründeki `CLAUDE.md` içindedir (`oyunlar/<oyun_adi>/CLAUDE.md`). Bir oyunda çalışmadan önce onu oku; oyuna özel yeni notları oraya yaz, bu dosyaya değil.
- Yeni oyun eklerken klasörüne de bir `CLAUDE.md` koy (oyunun kısa tanımı, önemli dosyalar, ayarların yeri, kayıt dosyası).

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
