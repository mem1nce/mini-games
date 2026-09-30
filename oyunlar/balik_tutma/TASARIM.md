# Balık Tutma — Tasarım

Kayıktaki penguenle ağ kepçeyle balık ve çöp toplama. Renk, sayı, desen ve boyut öğretir; çöp bölümleri çevre
bilinci verir. 4-8 yaş, **dikey** ekran (720x1280, `expand`), yazı yok (sadece kutlamada tek kelime).
Kanca yok, ceza yok: balıklar hep güvende (ya kovaya/akvaryuma ya da suya geri).

## Ekran düzeni

```
┌───────────────────────────┐
│ [←]            [🐠] [⏸]  │  geri, akvaryum, duraklat
│   ┌───────────────────┐   │
│   │ 🐟 🐟 🐟  (görev)  │   │  görev baloncuğu: siluetler, yakalanınca renklenir
│   └───────────────────┘   │
│        🐧╱ olta           │
│  ~~~~[kayık🪣♻]~~~~~~~~~  │  su yüzeyi (y ≈ 400): dalga, ışık yansıması
│        │                  │
│        ╰─(ağ)   🐟   🐠   │  sığ
│   🐟         🪼           │  orta
│         🐡        🧴      │  derin
│ ▓▓ kum, taş, yosun, mercan│  dip
└───────────────────────────┘
```

## Kontrol

- Parmak suya basınca ağ o noktaya yumuşakça iner ve parmağı izler (yatay + derinlik). Kayık parmağın yatay
  konumuna yavaşça kayar. Parmak kalkınca ağ yukarı çıkar. İp kavislidir (gevşekken sarkar).
- Ağ bir balığa değince (cömert çarpışma) balık ağa girer, küçük su sıçraması, ağ kendiliğinden yukarı çıkar:
  - Görevdeki balık: sevinçle kıpırdar, kayıktaki kovaya zıplar; baloncuktaki siluet renklenir ve parlar.
  - İlk kez yakalanan tür: büyüyerek öne gelir, parıltı, sonra akvaryum simgesine yüzer.
  - Görevle ilgisiz, bilinen tür: yüzgecini sallar ve suya geri atlar.
  - Çöp: kayıktaki geri dönüşüm kutusuna gider.
- Denizanası ağa değerse ağ gıdıklanmış gibi titrer, içindeki balık yüzüp gider. Ceza yok.

## Görevler (baloncukta, resimle)

Görev = gereksinim listesi. Gereksinim: `adet` + balık özelliklerinden istenenler (`renk`, `desen`, `boyut`,
`isikli`, `tur`) ya da `cop`. Örnek: `[{"adet": 3, "renk": "mavi"}]`, `[{"adet": 2, "desen": "cizgili"},
{"adet": 2, "desen": "benekli"}]`, `[{"adet": 1, "boyut": "buyuk"}]`, `[{"adet": 5, "cop": true}]`.
Her adet baloncukta bir siluet: istenen renk/desen/boyutta soluk balık simgesi (renk istenmiyorsa açık gri).

## Çöp ve su berraklığı

Çöp bölümlerinde suda şişe, poşet, teneke kutu. Su başta bulanık (yeşil-kahve perde), yosun ve mercanlar soluk,
az balık. Her çöpte su bir adım berraklaşır, bitkiler renklenir, balık sayısı artar.

## Bölümler (`bolumler.gd`) ve balıklar (`balik_turleri.gd`)

Bölüm: `tema`, `gorev`, `havuz` (gelen türler), `balik_sayisi`, `cop` (çöp sayısı), `denizanasi`, `hiz` (çarpan).
Tür: `renk`, `desen` (duz/cizgili/benekli/yildiz/gokkusagi), `boyut` (kucuk/orta/buyuk), `govde` (şekil),
`derinlik` (0 yüzey – 1 dip aralığı), `hiz`, `nadir`, `isikli`. 24 tür; nadirler: altın balık, gökkuşağı balığı,
yıldız desenli balık, fener balığı (ışıklı).

| Bölüm | Tema | Görev |
|---|---|---|
| 1-4 | Göl (sığ, sakin) | tek renk (3 mavi, 3 kırmızı), iki renk, 4 çöp |
| 5-8 | Deniz | desen (çizgili + benekli), boyut, 5 çöp, renk + desen; denizanası başlar |
| 9-12 | Mercan resifi | sayı (4 çizgili), boyut, 6 çöp, karışık |
| 13-16 | Derin deniz (karanlık, ağda fener) | ışıklı balıklar, fener balığı, çöp, final karışık |

Bölümler art arda; 16'dan sonra baştan. Kayıt `user://balik_tutma.cfg`: `[ilerleme] bolum`, `[akvaryum] <tür> = kaç kez`.

## Akvaryum

Köşedeki simgeyle açılır: üstte büyük akvaryum (cam, su, kum, bitki, kabarcık), yakalanan türler içinde yüzer;
altında bütün türlerin ızgarası (yakalanmamışlar gri siluet). Dokunulan balık takla atar.
Bölüm sonunda kovadaki balıklar akvaryum simgesine uçar.

## Kutlama

Penguen kayıkta sevinç dansı yapar, sudan kabarcıklar, konfeti, zıplayan "Harika!" / "Süper!" / "Tebrikler!".

## Dosyalar

```
balik_tutma/
  balik_tutma.tscn / .gd   ana sahne: katmanlar, dokunma, akış, duraklatma, kutlama
  balik_turleri.gd         balık türleri ve eşleşme (görev gereksinimi ↔ balık)
  bolumler.gd              bölüm verileri
  kayik.gd                 kayık, penguen (halleri, dans), kova, geri dönüşüm kutusu
  olta.gd                  olta, kavisli ip, ağ kepçe (fener), yakalama ve yukarı çıkış
  balik.gd                 tek balık: yüzme, ağda kıpırdama, zıplama, kaçma, takla
  denizanasi.gd            denizanası
  cop.gd                   çöp parçası
  balik_uretici.gd         balık, denizanası ve çöpleri üretir, sayıyı korur
  gorev_yoneticisi.gd      görev durumu ve baloncuk
  su.gd                    gökyüzü, su katmanları, dalga, ışık huzmeleri, dip süsleri, berraklık, karanlık
  akvaryum.gd              akvaryum ekranı
  kayit.gd                 ilerleme ve akvaryum kaydı
  efektler.gd / sesler.gd
  gorseller/ (svg_uret.py)  sesler/ (ses_uret.py)  testler/
```
