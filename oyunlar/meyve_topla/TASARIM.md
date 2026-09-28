# Meyve Topla — Tasarım

Başındaki sepetle ağaçtan düşen meyveleri toplayan sevimli bir kirpi. 4-8 yaş, okuma gerektirmez.

## Ekran düzeni (720x1280 dikey, `expand`)

```
┌──────────────────────────────┐
│ [←]   [🍎▓▓▓▓░░░░░░🧺]   [⏸]  │  üst çubuk: geri, ilerleme, duraklat
│          ❤ ❤ ❤               │  kalpler         (güçlendirme göstergesi sağda)
│  ░░ ağaç tacı (üst kısım) ░░ │
│   ╿    ╿    ╿    ╿    ╿    ╿  │  6 sallanabilir dal; meyveler dal uçlarında belirir
│  ☁         gövde        ☀    │  gökyüzü bandı: bulut, güneş/ay, yıldız
│ ~~~ uzak tepeler ~~~~~~~~~~~ │
│ ~~~ yakın tepeler, çiçekler ~ │
│        🧺                     │  sepet kirpinin başında
│      (kirpi)   ·gölge        │  zemin çizgisi: ekran altından ~110 px yukarıda
└──────────────────────────────┘
```

## Oynanış

- Parmak ekranın herhangi bir yerinde (düğmeler hariç) sürüklenince kirpi yatayda parmağın x'ini
  yumuşakça takip eder (üstel yumuşatma + azami hız). Sadece x kullanıldığı için çocuk kirpinin
  yukarısında sürükleyebilir; kirpi parmağın altında kalmaz. Dokunmak da hedefi belirler.
- Meyve bir dalın ucunda küçükten büyüyerek belirir, dal ~0.7 sn sallanır (yapraklar dökülür), sonra düşer.
  Yerde, ineceği noktada yaklaştıkça büyüyen hafif bir gölge vardır.
- Sepetin ağız çizgisini geçerken sepetin genişliği içindeyse yakalanır.
  - İyi meyve: sepete uçar, sepette üst üste birikir (en fazla 10; fazlası en alttan kaybolur),
    sepet esner, meyve renginde parçacık çıkar, ilerleme artar.
  - Hedef meyve bölümlerinde başka iyi meyve sepetten seker ve düşer (ceza yok, sayılmaz).
  - Çürük elma / taş: 1 kalp gider, kirpi sersemler (sarmal gözler, başının üstünde dönen yıldızlar),
    kısa ekran sarsıntısı. Kalpler biterse aynı bölüm nazik bir "tekrar" animasyonuyla baştan başlar.
  - Kaçan iyi meyve yere düşüp sönümlenir, ceza yok (sadece art arda sayacı sıfırlanır).
- Art arda 5, 10, 15... meyvede kirpinin etrafında yıldız parıltısı ve "x2", "x3"... yazısı (görsel ödül).

## Güçlendirmeler (parlayan baloncuk içinde düşer, 6 sn)

| Tür | Etki | Görsel |
|---|---|---|
| `buyuk_sepet` | Sepet 1.6 kat genişler | Sepet esneyerek büyür |
| `miknatis` | Yakındaki iyi meyveler sepete doğru kayar | Sepetin üstünde mıknatıs, parıltılar |
| `yavas` | Düşen her şey ve doğma hızı yarıya iner | Sepetin üstünde salyangoz |

Aktif güçlendirme sağ üstte, süresi azalan dairesel göstergeyle görünür. Aynı anda bir tane olur.

## Akış

`BAŞLANGIÇ` (başlık, "Başlamak için dokun", kaldığı bölüm, küçük "baştan başla" düğmesi: iki kez dokun)
→ `AFİŞ` ("Bölüm N" 1 sn; hedef meyve bölümünde hedef meyve büyük gösterilip ilerleme çubuğuna uçar)
→ `OYUN` → hedef tamam → `KUTLAMA` (konfeti, gökkuşağı yazı, kirpi dansı ~2 sn, ilerleme kaydedilir)
→ `AFİŞ` (sonraki bölüm; gerekirse arka plan yumuşakça değişir) → ...
Kalpler biterse `TEKRAR` (dönen ok, kalpler tek tek dolar) → `AFİŞ` (aynı bölüm).
Duraklat: oyun ağacı durur (`get_tree().paused`), büyük "devam et" düğmesi. Geri: başlangıç ekranı.

## Bölümler (`bolumler.gd`)

Her bölüm bir sözlük: `goal` (hedef sayı), `fall_speed`, `spawn_interval`, `fruits`, `bad` (kötü nesneler),
`bad_chance`, `wind` (rüzgarlı düşen meyve oranı), `target_fruit` (boşsa hepsi sayılır),
`powerup_chance`, `background` (`sabah` / `ogle` / `aksam` / `gece`).

- 1-3 sabah: 2-4 meyve, yavaş, kötü nesne yok (1. bölüm: 6 meyve, çok yavaş, güçlendirme yok)
- 4-6 öğle: çürük elma başlar, yeni meyveler
- 7-9 gün batımı: taş eklenir, bazı meyveler rüzgarla salınır
- 10-12 gece: hedef meyve bölümleri
- 13+: sonsuz mod; hız, hedef ve kötü nesne oranı yavaşça artar (üst sınırlı), arka plan döner,
  bölümlerin yarısı hedef meyveli

## Arka plan (`arka_plan.gd`)

Katmanlar: gökyüzü (3 renkli geçiş), yıldızlar, güneş/ay, bulutlar, uzak tepeler, yakın tepeler,
çimen, çiçekler, ateşböcekleri. Her zaman dilimi bir renk paleti; bölüm değişince palet 2 sn'de
yumuşakça karışır (renkler, güneş/ay konumu, yıldız/ateşböceği/çiçek görünürlüğü).
Ağaç ve çimen "ortam ışığı" ile renklenir; düşen nesneler ve kirpi okunaklı kalsın diye renklenmez.

## Dosyalar

```
meyve_topla/
  meyve_topla.tscn / .gd   ana sahne: durumlar, dokunma, nesne döngüsü, güçlendirmeler, kombo
  bolumler.gd              bölüm verileri + sonsuz mod üretimi
  bolum_yoneticisi.gd      bölüm ilerlemesi, ne zaman ne düşeceği, kayıt (user://meyve_topla.cfg)
  oyuncu.gd                kirpi: takip, yürüme, yüz halleri, sepet ve birikme, dans, sersemleme
  dusen_nesne.gd           düşen nesne: belirme, sallanma, düşüş, rüzgar, gölge, sekme, sinek
  agac.gd                  taç, gövde, sallanan dallar, yaprak dökülmesi
  arka_plan.gd             katmanlı arka plan ve zaman dilimi geçişleri
  efektler.gd              CPUParticles2D parçacıklar, konfeti, ekran sarsıntısı, açılır yazılar
  arayuz.gd                üst çubuk, ilerleme, kalpler, güçlendirme göstergesi, ekranlar
  gorseller/               bütün SVG'ler (meyveler/ hafiza oyunundan kopyalandı)
```

Genel ayarlar (`@export`): takip hızı, güçlendirme süresi, kombo eşiği, kalp sayısı, uyarı süresi,
sepet kapasitesi vb. `meyve_topla.gd` başında.

## Performans

Parçacıklar `CPUParticles2D`, tek seferlik olanlar bitince silinir. Aynı anda en fazla birkaç düşen
nesne. SVG'ler 2x ölçek + mipmap ile içe aktarılır (büyük arka plan parçaları 1x).
