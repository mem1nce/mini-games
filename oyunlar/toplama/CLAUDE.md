# Toplama Öğreniyorum

4-6 yaş, **yatay** ekran, rakamlar dışında yazı yok. Ekranda `[A] + [B] = [?]`; çocuk alttaki sayı düğmelerinden toplamı seçer. Skor, can, süre yok. 20 bölüm, son bölümden sonra büyük kutlama ve 1. bölüme dönüş.

- **Bütün zorluk ayarları `ayarlar.tres`** (`AdditionSettings`): aşama dizisi (`AdditionStage`: bölüm sayısı, toplanan aralığı, toplam sınırı, seçenek sayısı), `allow_zero` (0 kullanımı, varsayılan kapalı), çeldirici ayarları, nesne görselleri listesi. Bölüm sayısı = aşamaların `level_count` toplamı. Açılışta `problems()` denetler.
- `islem_uretici.gd` (`ProblemGenerator`): sahneden bağımsız saf mantık; işlem + seçenekler üretir, son 3 işlemi tekrarlamaz. Çeldiriciler cevaba ±`near_distance` yakın ya da toplananlardan biri.
- `toplama.gd` (`AdditionGame`): durumlar SHOWING / WAITING / WRONG / CORRECT / LEVEL_DONE / FINALE. Cevap sadece WAITING'de seçilir. Animasyon süreleri script başında `@export`.
- `nesne_kutusu.gd` (`ObjectBox`): 1-5 zar yüzü, 6+ beşli sıralar (`layout()` statik, test edilir). A/B nesneleri aynı boyda; sonuç kutusu daha geniş, nesneler uçarken onun boyuna küçülür. Kutular NinePatchRect ile esner; geniş/uzun ekranda büyür.
- `cevap_dugmesi.gd` (`AnswerButton`), `ilerleme_cubugu.gd`, `hoparlor_dugmesi.gd`, `kutlama.gd` (Gölge Eşleştirme'den uyarlama).
- `sesli_sayma.gd`: `DisplayServer.tts_*` ile Türkçe sesli sayma; `tr` dilinde ses yoksa hoparlör düğmesi gizlenir ve her şey sessizce kapalı kalır. Proje ayarı `audio/general/text_to_speech` açık olmalı.
- Rakam yazı tipi `rakam_yazisi.tres` (Nunito 900).
- Görseller `gorseller/` ve `nesneler/` (2x + mipmap). Yeni nesne: `nesneler/` altına SVG (aynı içe aktarma ayarları), `ayarlar.tres`'teki `object_textures`'a ekle.
- Sesler `sesler/ses_uret.py` ile sentezlenmiş `.wav` (`sesler.gd` ortak ses havuzunu kullanır).
- Testler: `testler/uretici_testi.gd` (headless, üretici kuralları ve dizilim), `testler/oynanis_testi.gd` (pencereli, `--fixed-fps 60`; menüden açıp 20 bölümü oynar, `-- --ekran=<klasör>` ile ekran görüntüsü alır).
- Kayıt `user://toplama.cfg`: `[ilerleme] bolum`, `[ayarlar] sesli_sayma`.
