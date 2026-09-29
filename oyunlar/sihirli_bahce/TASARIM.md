# Sihirli Bahçe — Tasarım

Sakin, büyülü ve yaratıcı bir bahçe oyunu. 4-8 yaş, **yatay** ekran (1280x720, `expand`), yazı yok.
Kaybetmek yok, süre yok, ceza yok: bitkiler asla ölmez, fazla su bile sevimli bir sürpriz (kurbağa) getirir.

## Ekran düzeni

```
┌──────────────────────────────────────────────────────────────┐
│ [←]        [☁ yağmur] [☀ güneş] [≋ rüzgar] [☾ ay]       [📖] │  hava kontrolleri, albüm
│   gökyüzü, süzülen bulutlar (gece: yıldızlar)                │
│   uzak tepeler ~~~~~ kulübe ~~~~ çit ~~~~~~~~~~~~~~~~        │
│      🌻        🌷        ·         🍄        🌱   (bitkiler)  │  ihtiyaç baloncuğu: 💧 / ☀ / ☾
│   [parsel]  [parsel]  [parsel]  [parsel]  [parsel]  🧺       │  5 toprak parseli, olgunda sepet
│  çimen ~~~~~~~~ [pembe kese] [turuncu kese] [mor kese] ~~~~  │  tohum tepsisi
└──────────────────────────────────────────────────────────────┘
```

## Oynanış

- **Ekme:** Tepsideki keseyi boş bir parsele sürükle → tohum toprağa düşer. Kese kendi havuzundan rastgele
  bir bitki verir (nadirlik ağırlıklı; henüz keşfedilmemiş bitkilerin şansı biraz daha yüksek).
- **Büyüme:** tohum → filiz → fidan → tomurcuk → olgun. Her aşama için önce **su**, sonra **güneş** gerekir.
  Bitkinin üstündeki baloncuk ne istediğini gösterir (damla / güneş; gece bitkisi olgunlaşınca ay).
- **Yağmur bulutu:** sürüklenir; altındaki parsele yağmur yağar, toprak koyulaşır, yeterince yağınca sulanır.
  Su istemeyen bitkiye yağarsa yanında su birikintisi oluşur ve içine bir kurbağa gelir (güneş birikintiyi kurutur).
- **Güneş:** dokununca parlar; güneş isteyen bütün bitkilere sıcak ışık huzmesi iner, bitkiler zıplayarak büyür.
  Gece dokunulursa önce sabah olur.
- **Rüzgar:** esinti, bitkiler sallanır, yapraklar uçar, kelebek ve arılar gelir; olgun bitkilerin tohumları
  boş parsellere uçar ve aynı bitkiden yenisi başlar.
- **Ay:** yumuşak geçişle gece (yıldızlar, ateşböcekleri, kulübenin penceresi yanar); tekrar dokununca gündüz.
  Gece bitkileri (parlayan mantar, ay çiçeği) sadece gece açar.
- **Olgun bitki:** dokununca kendi sihirli animasyonu. Yanındaki sepete dokununca toplanır, albüme eklenir,
  parsel boşalır. İlk kez keşfedilen bitki için kutlama: bitki büyüyerek öne gelir, parıltı ve yıldızlar, albüme uçar.
- **Yol gösterme (yazısız):** ilk açılışta keseyi parsele sürükleyen bir el; bir bitki su/güneş bekliyorsa ilgili
  hava düğmesi hafifçe nabız gibi atar.

## Bitkiler (`bitkiler.gd`)

Her bitki bir sözlük: `id`, `pack` (kese), `rarity` (yaygın / az / nadir), `night` (sadece gece açar),
`kind` (çiçek / çalı / sarmaşık / ağaç / mantar: erken aşamaların çizimi), `special` (dokununca animasyon).
Görseller `gorseller/bitkiler/<id>_0..4.svg` (aşama başına ayrı çizim, `svg_uret.py` üretir).

| Kese | Bitkiler (nadirlik) |
|---|---|
| Pembe (çiçekler) | lale demeti, balon çiçeği, kelebek çiçeği, gökkuşağı çiçeği (az), kristal çiçek (nadir) |
| Turuncu (meyve ve güneş) | dev ayçiçeği, dev çilek, tavşanlı kabak, şeker ağacı (nadir) |
| Mor (gece ve sihir) | parlayan mantar (gece), ay çiçeği (gece), yıldız meyveli ağaç (nadir) |

Özel animasyonlar: ayçiçeği güneşe döner, laleler renk değiştirir, çilek jöle gibi sallanır, kabaktan tavşan
çıkar, balonlar uçar, gökkuşağı belirir, kelebekler çıkar, mantar ışık saçar, ay çiçeği parlar, kristal
parıldar, ağaçtan yıldız düşer, lolipoplar sallanır.

## Canlılar ve ortam

- Kelebek, arı, uğur böceği, salyangoz ara sıra gelir; dokununca küçük tepki (kanat çırpıp kaçma, takla,
  kalp, kabuğa saklanma). Gece kelebek/arı yerine ateşböcekleri.
- Arka plan: gökyüzü (gündüz/gece geçişli), süzülen bulutlar, iki kat yumuşak tepe, ahşap kulübe, çit, çimen.
  Gece: dünya `CanvasModulate` ile mavimsi kararır; yıldızlar, ateşböcekleri, parlayan bitkiler ayrı bir ışık
  katmanında kararmadan parlar.

## Kayıt (`kayit.gd`)

`user://sihirli_bahce.cfg`: parseller (bitki, aşama, ihtiyaç, birikinti), gece/gündüz, albüm (bitki → toplama sayısı),
ilk açılış ipucu gösterildi mi. Her değişiklikten kısa süre sonra ve uygulamadan çıkarken kaydedilir.

## Dosyalar

```
sihirli_bahce/
  sihirli_bahce.tscn / .gd   ana sahne: kurulum, dokunma ve sürükleme, akış, yol gösterme, kayıt tetikleme
  bitkiler.gd                bitki ve kese verileri, rastgele seçim
  parsel.gd                  toprak parseli: ıslaklık, bitki, baloncuk, sepet, birikinti ve kurbağa
  bitki.gd                   bitki görünümü: aşamalar, büyüme, sallanma, gece açma, özel animasyonlar
  hava.gd                    hava düğmeleri: yağmur bulutu, güneş, rüzgar, ay (gündüz/gece durumu)
  arka_plan.gd               gökyüzü, tepeler, kulübe, çit, çimen; gündüz/gece görünümü
  canlilar.gd                kelebek, arı, uğur böceği, salyangoz, ateşböcekleri
  album.gd                   albüm ekranı ve ilk keşif kutlaması
  kayit.gd                   kaydetme / yükleme
  efektler.gd                CPUParticles2D parçacıklar
  sesler.gd                  ses havuzu (ortak/ses_havuzu.gd) + yağmur döngüsü
  gorseller/  sesler/  testler/
```
