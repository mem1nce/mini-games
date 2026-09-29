# Araba Yarışı

4-8 yaş, **yatay** ekran, yazı yok. Yandan görünen oyuncak arabayla inişli çıkışlı yolda iki rakibe karşı yarış. Tek kontrol: ekrana basılı tut = hızlan, bırak = yumuşakça yavaşla. Kaza, devrilme, ceza yok. Tasarım ve dosya listesi `TASARIM.md` içinde.

- Akış (hepsi tek sahnede, `araba_yarisi.gd`): garaj (giriş: renk + şoför) → harita (8 pist) → yarış (3 ışıklı geri sayım) → podyum (sonraki pist / tekrar). Geri düğmeleri ortak `basili_geri_dugmesi.gd` (yarışta çocuk ekrana sürekli bastığı için); her ekranda yeni örneği kurulur, çünkü bir kez dolunca kilitlenir.
- **Fizik motoru yok.** Yol `pist.gd`'de bir `Curve2D` (yakın kenar); araba yol boyunca uzaklık `s` ile ilerler, iki tekerleğin temas noktasından açısını alır (`araba.gd`). Rampa zıplaması süreyle hesaplanan iki parçalı parabol (`Araba.jump_height`); havadaki yıldızlar aynı formülle yerleşir.
- **Pist verileri `pistler.gd`**: tema paletleri (`THEMES`) ve parça listeleri (`TRACKS`: flat, hill, slope, puddle, bump, ramp). Rampadan sonra iniş alanı kendiliğinden eklenir. `validate()` süre, yükseklik ve eğimi kontrol eder (oyun açılırken de çalışır).
- Hız ve zıplama sabitleri `araba.gd` başında; rakip davranışı (rubber band: dalgalanan hedef mesafe, son %15'te geride kalma) `rakip_zekasi.gd`; akış ayarları (geri sayım, ipucu süresi, rakip taban hızları) `araba_yarisi.gd` başında `@export`.
- Şeritler: çocuk öndeki şeritte (`Araba.LANES[0]`), rakipler arkada ve biraz küçük; yıldızları sadece çocuk toplar.
- Görünüm `araba_gorunum.gd`: şoför kabin iç görseline `clip_children` ile kırpılır, yaylanma ve neşeli zıplama burada. Garaj, harita, podyum ve ilerleme çubuğu da bunu kullanır.
- Görseller `gorseller/`: araba gövdeleri ve paralaks katmanları `gorseller/svg_uret.py` ile üretilir (renk eklemek için `CAR_COLORS`); `hayvanlar/` hafıza oyunundan kopya. SVG'ler 2x + mipmap, `arka_*.svg` katmanları 1x ve mipmapsiz içe aktarılır.
- Sesler `sesler/ses_uret.py` (ortak `ortak/ses/sentez.py`); `motor.wav` döngü (`.import` içinde `edit/loop_mode=2`), perdesi hıza göre `sesler.gd`'de değişir.
- Testler: `testler/yaris_testi.gd` (headless, `--fixed-fps 60`; her pisti üç çocuk tipiyle koşturur), `testler/ekran_testi.gd` (pencereli, `-- <klasör> [pist no]` ile ekran görüntüsü).
- Kayıt `user://araba_yarisi.cfg`: `[ilerleme] acik` (açık pist sayısı; ana menü rozeti bunu gösterir), `[yildiz] pist_N`, `[garaj] renk, hayvan`.
