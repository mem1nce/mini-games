# Çıkarma Öğreniyorum

Toplama Öğreniyorum'un (`oyunlar/toplama/`) çıkarma sürümü: görünüm, akış, sesler ve ayar yapısı aynı; sadece işlemler, çıkarma animasyonu ve seslendirme farklı. Toplama'nın dosyaları buraya kopyalandı (oyunlar birbirine bağımlı değil); ortak bir düzeltme gerekirse iki oyunda da yap.

4-6 yaş, **yatay** ekran, rakamlar dışında yazı yok. Ekranda `[A] - [B] = [?]`; A kutusunda A nesne, B kutusunda B **soluk** nesne var. Çocuk alttaki sayı düğmelerinden sonucu seçer. Skor, can, süre yok. 20 bölüm, son bölümden sonra büyük kutlama ve 1. bölüme dönüş.

- Doğru cevapta: rakam "?" kartına uçar → A'nın sondaki B nesnesi tek tek B'deki soluk nesnelerin yerine uçar, soluk nesne canlanır (`cikarma` sesi, perdesi her alışta düşer) → A'da kalanlar tek tek sonuç kutusuna uçup sayılır → "beş eksi iki eder üç".
- **Bütün zorluk ayarları `ayarlar.tres`** (`SubtractionSettings`): aşama dizisi (`SubtractionStage`: bölüm sayısı, `part_min`/`part_max` = çıkan ve sonucun aralığı, `max_minuend` = eksilenin sınırı, seçenek sayısı). Aşamalar Toplama'nınkilerin tersi (Toplama'da 2 + 3 = 5 ise burada 5 - 2 = 3). `allow_zero` (5 - 0 ve 5 - 5; varsayılan kapalı; açıkken 0 düğmesi de çıkabilir), çeldirici ayarları, nesne görselleri.
- `islem_uretici.gd` (`SubtractionGenerator`): saf mantık; son 3 işlemi tekrarlamaz. Çeldiriciler cevaba ±`near_distance` yakın ya da işlemdeki sayılardan biri (A ya da B).
- `cikarma.gd`: durumlar Toplama'daki gibi (SHOWING / WAITING / WRONG / CORRECT / LEVEL_DONE / FINALE). Alma ve sayma süreleri script başında `@export`.
- Kutular: A kutusu geniş olan (en fazla 20 nesne), B ve sonuç kutusu en fazla 10. `nesne_kutusu.gd`'de `fill(..., ghost)`, `release_last()`, `solidify()` çıkarma için eklendi.
- Görseller `gorseller/` (`eksi.svg` yeni) ve `nesneler/` (2x + mipmap). Sesler `sesler/ses_uret.py` (Toplama'nın sesleri + `cikarma.wav`).
- Testler: `testler/uretici_testi.gd` (headless), `testler/oynanis_testi.gd` (pencereli, `--fixed-fps 60`; menüden açıp 20 bölümü oynar, `-- --ekran=<klasör>` ile ekran görüntüsü alır).
- Kayıt `user://cikarma.cfg`: `[ilerleme] bolum`.
