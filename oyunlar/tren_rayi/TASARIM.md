# Tren Rayı — Tasarım

Kuşbakışı ızgarada ray parçalarını **yerinde döndürerek** trene istasyona giden yolu kurma. 4-8 yaş, **yatay**
ekran (1280x720, `expand`), yazı yok (sadece kutlamada tek kelime). Ceza, süre, skor yok.
Yol Yap'tan farkı: parça sürükleme yok; her parça kendi hücresinde durur, dokununca 90° döner.

## Ekranlar

- **Giriş ekranı:** yukarıdan görülen yeşil bir tepe; tepenin üstünde oval bir ray. Çocuğun treni, kazandığı
  bütün vagonlarla bu rayda döner durur. Trene dokununca düdük sesi çıkar, bacadan büyük duman yükselir.
  Ortada büyük yeşil "oynat" düğmesi, sol üstte geri (ana menüye).
- **Oyun ekranı:**

```
┌──────────────────────────────────────────────────────────────┐
│ [←]                                                     [↻]  │
│                ┌────┬────┬────┬────┬────┐                    │
│                │ ═╗ │ 🌳 │    │ ╔═ │    │                    │
│ ▭▭▭[lokomotif]═│═╝  │    │ ║  │ ╚══│════│═ [istasyon]        │
│                │    │ 🐼 │    │    │    │                    │
│  (●🚂) hareket └────┴────┴────┴────┴────┘                    │
└──────────────────────────────────────────────────────────────┘
```

  Solda rayın ucunda bekleyen tren (arkasında vagonlar ekranın dışına uzanır). Yanında büyük yeşil, tren simgeli
  "hareket" düğmesi. İstasyon sağda (bazı bölümlerde üstte ya da altta). Sol üstte geri (giriş ekranına),
  sağ üstte bölümü baştan başlatma.

## Oynanış

- Parçalar: **düz**, **köşe**, **T-kavşak** (ileride), **çapraz geçiş** (ileride). Dokununca "klik" sesiyle
  90° döner (hafif zıplama + yumuşak dönme). Sabit parçaların köşesinde küçük bir cıvata var; dokununca sadece
  hafifçe sallanır.
- Engeller (her temada 3 çeşit): ağaç türü, su türü, kaya türü. Boş hücreler temanın zemini.
- **Canlı ipucu:** başlangıçtan itibaren birbirine doğru bağlanan raylar yumuşakça parlar (kavşakların bütün
  kolları dahil). Yol istasyona ulaşınca istasyon ışığı yanar ve hareket düğmesi nabız gibi atar.
- **Hareket:** tren rayda akıcı ilerler, virajlarda yumuşakça döner; vagonlar aynı yolu izler (yol üzerindeki
  mesafeye göre). Kavşakta tren istasyona giden (varsa yolcuları da alan) kolu seçer.
  - Yol tamamsa istasyona varır → kutlama.
  - Yol eksikse eksik noktada nazikçe yavaşlayıp durur, "?" balonu çıkar, sonra yavaşça başlangıca geri döner.
- Uzun süre hamle yoksa (`hint_delay`) yanlış yönde duran bir parça hafifçe sallanır.

## Yolcular

- Bazı hücrelerde küçük bir bekleme platformunda hayvan yolcu (hafıza oyunundaki hayvanların kopyası,
  `gorseller/hayvanlar/`). Tren yanındaki hücreden geçerse durur, yolcu zıplayıp vagona biner ve pencereden
  (vagonun tavan penceresinden) el sallar.
- Yolcusu alınmadan istasyona varılırsa ceza yok; ama bütün yolcular alınırsa kutlama daha büyük ve ek yıldız.

## Ödül: büyüyen tren

- Her bölüm bitince trene yeni bir vagon eklenir. Vagon çeşitleri (kuşbakışı): yolcu vagonu (tavan pencereli),
  açık vagon (içinde yük), kargo vagonu, yuvarlak tanker, odun vagonu, kömür vagonu; her biri birkaç renkte.
- Oyunda en son kazanılan birkaç vagon gösterilir (`MAX_WAGONS`); giriş ekranında hepsi.

## Bölümler (`bolumler.gd`)

Her bölüm bir sözlük; **harita** kutu çizgisi karakterleriyle çözüm yolunu gösterir (kolay düzenlenir):

```
"harita": [
    "─┐A.",
    ".└──",
    "..Y.",
]
```

`─ │ ┌ ┐ └ ┘` düz/köşe, `├ ┤ ┬ ┴` T-kavşak, `┼` çapraz geçiş, `A` ağaç türü, `G` su türü, `K` kaya türü,
`Y` yolcu (sırayla `yolcular` listesinden), `?` rastgele süs parça (yanıltıcı), `.` boş zemin.
Başlangıç: batı kenarında dışarı açılan hücre; istasyon: başka bir kenarda dışarı açılan hücre.
Diğer alanlar: `tema`, `sabit` (dönmeyen parçaların hücreleri), `karistir` (kaç parça yanlış döndürülür;
`-1` = hepsi rastgele), `yolcular`.

Kurulum: haritadan çözüm parçaları çıkarılır → sabit olmayanlar karıştırılır → çözülebilir olduğu (çözüm
yönleri) ve başta çözülmüş olmadığı denetlenir (değilse yeniden karıştırılır). `validate()` bütün bölümleri
denetler (oyun açılırken de çalışır).

| Bölüm | Tema | Yeni öğe |
|---|---|---|
| 1-3 | Çiftlik | 4x3; sadece 2-3 parça yanlış (1-2 düz, 3 köşe) |
| 4 | Çiftlik | köşeler, hepsi karışık |
| 5-8 | Orman | engeller, sabit parçalar, yanıltıcı parçalar; 5x4 → 6x4 |
| 9-12 | Karlı dağlar | yolcular (1 → 2), istasyon üstte/altta |
| 13-16 | Sahil | T-kavşak, sonra çapraz geçiş; 6x5 → 7x5 |
| 17-20 | Gece şehri | kavşak + çapraz + yolcular, 7x5 |

20. bölümden sonra baştan (vagonlar birikmeye devam eder).

## Kutlama

İstasyondaki hayvanlar zıplar, bacadan renkli duman halkaları çıkar, konfeti, zıplayan harflerle
"Harika!" / "Süper!" / "Tebrikler!". Sonra yeni vagon parıltıyla trenin sonuna eklenir, sonraki bölüm başlar.

## Dosyalar

```
tren_rayi/
  tren_rayi.tscn / .gd   ana sahne: ekranlar (giriş/oyun), düğmeler, akış, dokunma
  bolumler.gd            bölüm verileri, haritadan çözüm, karıştırma, validate()
  baglanti.gd            parça açıklıkları, bağlı rayların bulunması, trenin rotası (saf mantık)
  izgara.gd              ızgara: zemin, parçalar, engeller, yolcular, istasyon, parlama, ipucu, trenin yolu
  ray_parcasi.gd         tek ray parçası: görünüm, dönme, sabit cıvata, parlama, sallanma
  tren.gd                lokomotif + vagonlar: yol üzerinde ilerleme, duman, yolcular
  bolum_yoneticisi.gd    bölüm sırası, vagonlar, kayıt
  kutlama.gd             varış kutlaması
  giris_ekrani.gd        tepe manzarasında dönen tren
  efektler.gd / sesler.gd
  gorseller/ (svg_uret.py)  sesler/ (ses_uret.py)  testler/
```

Kayıt `user://tren_rayi.cfg`: `[ilerleme] bolum` (0'dan, toplam bitirilen), `vagon` (kazanılan vagon sayısı).
