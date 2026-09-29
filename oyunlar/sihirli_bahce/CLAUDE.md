# Sihirli Bahçe

4-8 yaş, **yatay** ekran, yazı yok; kaybetmek, süre ve ceza yok. 5 parsellik bahçede keseden tohum ekip yağmur, güneş, rüzgar ve ay ile büyütme, olgun bitkileri toplayıp albümü doldurma. Tasarım ve dosya listesi `TASARIM.md` içinde.

- **Bitki verileri `bitkiler.gd`**: `PLANTS` (kese, nadirlik, gece bitkisi mi, özel animasyon, renk), `ALBUM_ORDER`, `pick()` (nadirlik ağırlıklı; keşfedilmemişler ×2 şanslı). Yeni bitki: `gorseller/svg_uret.py`'de `PLANTS`'e ekle ve `_3`/`_4` çizimini yaz, `python svg_uret.py`, sonra `bitkiler.gd`'ye satır; özel animasyon `bitki.gd` `special()` içinde.
- Büyüme döngüsü `parsel.gd`: her aşama için su (bulut altında `WATER_TIME`) → güneş → büyüme. Fazla yağmur birikinti + kurbağa getirir, güneş kurutur. Gece bitkileri olgunlaşınca gündüz kapalıdır (`_4_kapali.svg`), sepet sadece açıkken çıkar.
- Katmanlar (`sihirli_bahce.gd` kodla kurar): dünya (arka plan, canlılar, parseller) + `CanvasModulate` ile gece kararması; ışık katmanı (efektler, baloncuk, sepet, parlayan bitki ışıkları, ateşböcekleri, kulübe penceresi) gece kararmaz; arayüz (hava düğmeleri, kese tepsisi, albüm simgesi, geri); ekranlar (albüm, keşif kutlaması).
- Dokunma tek yerden (`sihirli_bahce.gd` `_input`): albüm → geri → albüm simgesi → hava düğmeleri → keseler → sepet → kurbağa → canlılar → bitki. Sürüklenen: kese ya da yağmur bulutu.
- Yol gösterme: ilk ekmeye kadar keseden parsele giden el; bir bitki `hint_delay` sn su/güneş/ay beklerse ilgili hava düğmesi nabız gibi atar.
- **SVG notu:** Godot'nun SVG çizicisi, bir eğrinin iki kontrol noktası aynı yükseklikteyse o şeklin degrade dolgusunu çizmiyor (şekil kayboluyor). `svg_uret.py`'de kontrol noktalarını birebir aynı yapma.
- Görseller `gorseller/` (SVG 2x + mipmap, `tepe_*.svg` 1x); `tavsan.svg` hafıza oyunundan, `el.svg` Araba Yarışı'ndan kopya. Sesler `sesler/ses_uret.py` (ortak `sentez.py`), `yagmur.wav` döngü (`edit/loop_mode=2`).
- Testler: `testler/bahce_testi.gd` (headless, `--fixed-fps 60`), `testler/ekran_testi.gd` (pencereli, `-- <klasör>`).
- Kayıt `user://sihirli_bahce.cfg`: `[bahce] parsel_0..4, gece`, `[album] <bitki> = kaç kez toplandı`, `[ipucu] ekme`. Ana menü rozeti keşfedilen bitki sayısını gösterir.
