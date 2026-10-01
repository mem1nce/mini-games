# Telif ve lisans incelemesi

İnceleme tarihi: 1 Ekim 2026. Kapsam: projedeki bütün görseller, sesler, yazı tipleri, isimler, uygulama simgesi ve
oyun motoru. Dışarıdan alınan varlıkların kısa listesi `CREDITS.md`'de, ortak seslerin dosya dosya dökümü
`ortak/sesler/SESLER.md`'de durur; bu dosya incelemenin sonucunu ve yapılan değişiklikleri anlatır.

**Sonuç:** ticari yayına engel bir lisans sorunu bulunmadı. Dışarıdan alınan her şey CC0 ya da OFL lisanslı,
geri kalan her şey projede üretildi. Bir görsel önlem olarak değiştirildi (Uçan Kuş direği), uygulamaya
Lisanslar ekranı eklendi. Arkadaşımın oyunlarında üç küçük öneri var (aşağıda).

Durum sütunu: **uygun** (sorun yok), **düzeltildi** (bu incelemede değiştirildi), **kontrol edilmeli** (bir insanın
bakması gerekiyor; ayrıntı "Manuel kontrol gerekenler" bölümünde).

## Nasıl incelendi

- **Görseller:** bütün SVG ve PNG dosyaları oyun oyun tabloya dizilip gözle incelendi. Ayrıca SVG'lerin içinde
  dış kaynak izi arandı (çizim programı imzası, gömülü resim, stok site adı, yazı tipi adı); hiçbirinde yok.
- **Sesler:** her ses dosyasının bir üretim betiğinde ya da `SESLER.md`'de karşılığı olduğu denetlendi. İndirilen
  seslerin kaynak sayfaları 1 Ekim 2026'da yeniden açılıp lisansları okundu.
- **İsimler:** kod, dosya adları, sahneler, ekran yazıları ve belgelerde yaklaşık 70 oyun, film ve marka adı arandı.
- **Yazı tipi:** dosyanın içindeki telif ve lisans kayıtları okundu.

## Görseller

| Dosya / klasör | Kaynak | Lisans | Durum |
|---|---|---|---|
| `oyunlar/ucan_kus/` (6 SVG) | projede çizildi | bize ait | **düzeltildi** (direk; aşağıda) |
| `oyunlar/dondurmaci/gorseller/` (24 SVG) | projede çizildi | bize ait | uygun |
| `oyunlar/yol_yap/gorseller/` (16 SVG) | projede çizildi | bize ait | uygun |
| `oyunlar/hafiza/` (27 SVG) | projede çizildi | bize ait | uygun |
| `oyunlar/meyve_topla/gorseller/` (46 SVG) | projede çizildi | bize ait | uygun |
| `oyunlar/araba_yarisi/gorseller/` (59 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun: arabalarda yüz ya da göz yok, logo yok |
| `oyunlar/sihirli_bahce/gorseller/` (102 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun |
| `oyunlar/robot_fabrikasi/gorseller/` (102 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun: geometrik parçalar, bilinen bir film robotuna benzemiyor |
| `oyunlar/tren_rayi/gorseller/` (80 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun: lokomotif üstten görünüşlü ve yüzsüz |
| `oyunlar/balik_tutma/gorseller/` (88 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun: çöp nesnelerinde (şişe, kutu, poşet) yazı ya da logo yok |
| `oyunlar/kule_yapma/gorseller/` (65 SVG) | projede çizildi (`svg_uret.py`) | bize ait | uygun |
| Arkadaşımın 9 oyunu (311 SVG, 60 PNG) | projede çizildi; boyama sayfaları kendi SVG'lerinden üretildi | bize ait | uygun; bir isim önerisi var (aşağıda) |
| `ana_menu/kartlar/` (20 SVG) | oyunların kendi SVG'lerinden birleştirildi (`ana_menu/svg_uret.py`) | bize ait | uygun |
| `ana_menu/gorseller/` (11 SVG) | projede çizildi | bize ait | uygun |
| `ortak/gorseller/` (2 SVG) | projede çizildi | bize ait | uygun |
| `icon.svg`, `ortak/simge/` (2 SVG, 4 PNG) | projede çizildi (kirpi, sepet, kuş, bilye) | bize ait | uygun: Godot logosu değil |

Hiçbir görselde gerçek marka logosu, marka yazısı ya da ambalajı yok.

## Sesler

| Dosya / klasör | Kaynak | Lisans | Durum |
|---|---|---|---|
| `ortak/sesler/` (38 ses) | Kenney ve OpenGameArt paketleri; dökümü `SESLER.md` | CC0 | uygun: 16 kaynak sayfası yeniden doğrulandı |
| `ortak/sesler/vuus.ogg` | projede kodla üretildi (`ses_hazirla.py`) | bize ait | uygun |
| Oyunların `sesler/` klasörleri (194 wav) | projede Python ile sentezlendi (`ses_uret.py` betikleri) | bize ait | uygun |
| `muzik_kutusu/sesler/kedi.wav`, `kopek.wav` ve `hayvan_besle`'deki kopyaları | OpenGameArt: "Cat Purr & Meow" (Kerzoven), "Dog Barking Mono" (Brandon Morris) | CC0 | uygun: sayfalar doğrulandı |
| Müzik Kutusu şarkıları (`sarkilar/`, 3 ezgi) | geleneksel ezgiler: Twinkle Twinkle, Mary Had a Little Lamb, Frère Jacques | kamu malı | uygun |

- `SESLER.md`'deki 39 satır ile `ortak/sesler/` içindeki 39 dosya birebir eşleşiyor; listede olmayan ses yok.
- İki kaynak çift lisanslı (CC0 ve OGA-BY 3.0): "Feel Good Island" ve "Dog Barking Mono". İkisinde de CC0 seçildi.
- "Feel Good Island" döngüsü, Brandon Morris'in özgün parçasından başka bir kullanıcının kırptığı sürüm. Özgün
  parçanın sayfası da CC0 / OGA-BY çift lisanslı, yani yeniden lisanslama geçerli.
- Kaynağı ya da lisansı belirsiz ses bulunmadı; bu yüzden hiçbir ses değiştirilmedi.

## Yazı tipleri

| Dosya | Kaynak | Lisans | Durum |
|---|---|---|---|
| `ortak/fontlar/Nunito.ttf` | Google Fonts; Copyright 2014 The Nunito Project Authors | SIL Open Font License 1.1 | uygun: lisans dosyası `ortak/fontlar/OFL.txt` projede |

Projede başka yazı tipi yok. SVG'lerin hiçbirinde yazı ya da yazı tipi adı geçmiyor. Nunito'nun lisansında
"ayrılmış yazı tipi adı" (Reserved Font Name) beyanı yok.

## İsimler

| Yer | Bulgu | Durum |
|---|---|---|
| Benim 11 oyunum, `ana_menu/`, `ortak/`, `project.godot` | başka oyun, film ya da marka adı yok ("flappy" dahil) | uygun |
| Uygulama adı "Minik Oyunlar" | aramada aynı adlı bir uygulama çıkmadı, ama bu kesin kanıt değil | **kontrol edilmeli** |
| Gölge Eşleştirme: `lego.svg`, `lego.tres`, `TASARIM.md` | "LEGO" tescilli marka; yalnızca dosya adında, ekranda görünmüyor | arkadaşıma öneri |
| Köstebek: `WhackBalance`, `WhackLevelData`, `WhackAMoleGame` | "Whac-A-Mole" tescilli marka; yalnızca kod içinde | arkadaşıma öneri |
| `GELISTIRMELER.md` | Google Play adı ve bağlantıları (politika notları) | uygun: uygulamaya girmiyor |

## Uygulama simgesi ve oyun motoru

| Konu | Bulgu | Durum |
|---|---|---|
| `icon.svg` | özgün çizim; Godot logosu değil | uygun |
| Android simgeleri (`ortak/simge/android_*.png`, `simge_*.png`) | özgün çizim; ama repoda `export_presets.cfg` yok, simgelerin dışa aktarım ayarına bağlandığı doğrulanamadı | **kontrol edilmeli** |
| Açılış ekranı | `boot_splash/show_image=false`: Godot logosu gösterilmiyor | uygun |
| Godot Engine (MIT) | lisans metni uygulamada gösterilmiyordu | **düzeltildi**: Lisanslar ekranı eklendi |
| Godot içindeki üçüncü taraf bileşenler (FreeType, mbedTLS vb.) | bildirimleri gösterilmiyordu | **düzeltildi**: Lisanslar ekranında |

## Yapılan değişiklikler

1. **Uçan Kuş direği** (`oyunlar/ucan_kus/direk.svg`). Direk "gövde + daha geniş dudaklı başlık" biçimindeydi.
   Renkleri farklı olsa da bu siluet Flappy Bird ve Mario borularının en tanınan öğesi. Geniş başlık kaldırıldı,
   uç yuvarlatıldı; renkler, bantlar ve noktalar aynı kaldı. Gövde genişliği çarpışma alanıyla aynı (120 px)
   yapıldı, yani oynanış değişmedi. Kuşa dokunulmadı: mavi, tepelikli vektör çizim, Flappy Bird'ün sarı pikselli
   kuşuna benzemiyor.
2. **Lisanslar ekranı** (`ana_menu/lisanslar.gd`, `ana_menu/lisans_metinleri.gd`). Ana menünün sol üstündeki
   küçük "i" düğmesi 3 saniye basılı tutulunca açılır (ebeveyn kapısı); kısa dokunuşta yalnızca "3 saniye
   basılı tutun" yazısı belirir. İçerik: Godot lisans metni, Nunito telifi ve OFL metni, ses kaynakları,
   Godot içindeki bileşenlerin listesi ve isteğe bağlı tam lisans metinleri. Godot bilgileri çalışırken
   motordan okunur (`Engine.get_license_text()`, `get_copyright_info()`, `get_license_info()`).
3. **Geri tuşu** (`ortak/sahne_gecis.gd`). Lisanslar açıkken Escape ya da Android geri tuşu uygulamadan çıkmak
   yerine ekranı kapatsın diye küçük bir kanca eklendi (`geri_yakalayici`).
4. **`CREDITS.md`**. "Sesler projede sentezlendi" cümlesi ortak ses paketleri eklendikten sonra eksik kalmıştı;
   `SESLER.md`'ye ve bu dosyaya gönderme eklendi.
5. **`.gitignore`**. Python önbellek dosyaları (`__pycache__/`, `*.pyc`) eklendi.

Yazı tipi lisans dosyası (`OFL.txt`) zaten `ortak/fontlar/` içindeydi; eklemeye gerek kalmadı.

## Arkadaşımın oyunları

Bu oyunlarda hiçbir dosya değiştirilmedi. Ciddi bir sorun yok; üç küçük öneri:

1. **Gölge Eşleştirme: "lego" adı.** `esyalar/oyuncaklar/lego.svg`, `lego.tres`, `bolumler/bolum_03.tres` ve
   `TASARIM.md`. Ad ekranda görünmüyor, ama "LEGO" tescilli bir marka. Öneri: dosyaları `blok` olarak yeniden
   adlandırmak ve `bolum_03.tres` ile `lego.tres` içindeki yolları güncellemek. Görsel (kırmızı çıkıntılı yapı
   bloğu) genel bir oyuncak blok çizimi; istenirse çıkıntı sayısı ya da oranı değiştirilerek daha da uzaklaştırılabilir.
2. **Köstebek: `Whack...` sınıf adları.** `denge.gd` (`WhackBalance`), `seviye_verisi.gd` (`WhackLevelData`),
   yorumlarda `WhackAMoleGame`, `WhackGameState`. Yalnızca kod içinde, kullanıcı görmez; risk düşük. Öneri:
   bir sonraki dokunuşta `Mole...` gibi nötr adlara çevirmek (`denge.tres` içindeki `script_class` da değişir).
3. **Hayvanları Besle: derlenmiş Python dosyası repoda.** `gorseller/__pycache__/svg_uret.cpython-314.pyc`.
   Lisans sorunu değil, ama repoda durmamalı: `git rm --cached` ile çıkarılabilir (`.gitignore` artık engelliyor).

Sorun olmayanlar: kedi ve köpek sesleri (CC0, sayfalar doğrulandı, kaynak dosyalar `.gdignore`'lu klasörde),
Müzik Kutusu şarkıları (kamu malı geleneksel ezgiler), boyama sayfaları (kendi SVG'lerinden üretilmiş),
Toplama ve Çıkarma'daki sesli sayma (cihazın kendi seslendirmesi, pakete ses dosyası girmiyor). Turuncu-beyaz
çizgili balık gerçek bir tür (palyaço balığı) ve sade çizilmiş; bir film karakterini kopyalamıyor.

## Manuel kontrol gerekenler

1. **Uygulama adı.** "Minik Oyunlar" için Google Play, App Store ve TÜRKPATENT marka sorgusunda aynı ya da çok
   benzer bir ad var mı bakılmalı. Web aramasında birebir eşleşme çıkmadı, ama mağaza içi arama yapılmadı.
2. **Android dışa aktarım ayarları.** `export_presets.cfg` repoda yok. Dışa aktarım kurulurken başlatıcı
   simgelerinin `ortak/simge/` altındaki dosyalara bağlandığı ve varsayılan Godot simgesinin kalmadığı
   kontrol edilmeli.
3. **Sesleri dinlemek.** Lisanslar sayfalardan doğrulandı, ama sesleri dinleyemedim. Tanıdık bir melodiye
   benzeyen bir müzik olursa (özellikle altı müzik döngüsü) haber verilmeli.
4. **Lisans kanıtı.** CC0 geri alınamaz, ama sayfalar ileride silinebilir. Kaynak sayfalarının birer kopyasını
   (PDF ya da ekran görüntüsü) saklamak iyi olur; bağlantılar `SESLER.md` ve `CREDITS.md`'de.
5. **Oyun düzenlerinin benzerliği.** Dondurmacı (konuşma balonunda sipariş, altta kaplar ve tatlar) ve Yol Yap
   (ızgaraya parça yerleştirip bilyeyi hedefe ulaştırma) yaygın oyun türleri; projede sıfırdan tasarlandı ve
   bildiğim bir oyunun birebir kopyası değil. Yine de piyasadaki bütün çocuk oyunlarıyla karşılaştıramadım;
   benzer oyunları bilen birinin ekranlara bir kez bakması iyi olur.
6. **Uçan Kuş'un oynanışı.** "Dokununca kanat çırp, boşluklardan geç" mekaniği Flappy Bird ile aynı türde.
   Oyun mekaniği telifle korunmaz; yine de mağaza açıklamasında ve ekran görüntülerinde "Flappy" adı ya da
   o oyuna gönderme kullanılmamalı.
7. **Araba silueti.** Arabalar yuvarlak hatlı genel bir oyuncak araba; belirli bir modelin kopyası değil ve
   logosu yok. Çok düşük risk, yalnızca bilgi için.

Bu inceleme hukuki görüş değildir; mağazaya göndermeden önce şüpheli görülen noktalar için bir uzmana danışılabilir.
