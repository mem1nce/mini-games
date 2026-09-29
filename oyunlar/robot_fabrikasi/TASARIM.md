# Robot Fabrikası — Tasarım

Taşıma bandından gelen robot parçalarını doğru kutulara ayırma oyunu. Renk, şekil, boyut ve sayma öğretir.
4-8 yaş, **yatay** ekran (1280x720, `expand`), yazı yok (sadece kutlamada "Harika!" gibi tek kelime). Ceza yok.

## Ekran düzeni

```
┌───────────────────────────────────────────────────────────────┐
│ [←]                                         [galeri]   [⏸]    │
│  ═╗ boru   dişli    lamba      atölye duvarı      dişli   ╔═   │
│  ═╩═▶▶ [parça] ▶▶▶ [parça] ▶▶▶ [parça] ▶▶▶ taşıma bandı ▶▶═╩═ │  soldan sağa akar
│                                                                │
│ 🤖      [simge]   [simge]   [simge]   [simge]          ╿ kol   │  kutuların üstünde tabela
│ yardımcı [kutu]   [kutu]    [kutu]    [kutu]           ▣       │  2-3 kutu, ışıklar dolumu gösterir
└───────────────────────────────────────────────────────────────┘
```

## Oynanış

- Parçalar (gövde, kafa, kol, anten, tekerlek, dişli) bantta akar; bant çizgileri kayar, uçtaki dişliler döner.
- Parçayı parmakla tut: parça parmağın biraz üstünde durur. Bir kutunun üstünde bırak:
  - **Doğru:** parça yumuşak bir yayla kutuya zıplar, kutunun bir lambası yanar, parıltı; yardımcı robot başparmak kaldırır.
  - **Yanlış:** kutu "boing" diye esner ve parçayı banda geri fırlatır, doğru kutu kısaca parlar, yardımcı başını
    sallayıp doğru kutuyu gösterir. Ceza yok.
  - Boşa bırakılan parça banda geri süzülür.
- Bandın sonuna varan parça boruya girer, bir süre sonra bandın başındaki borudan yeniden düşer.
- Sağ alttaki büyük kolu çekince bant durur, tekrar çekince devam eder.
- Kutular dolunca bölüm biter → robot montajı → sonraki bölüm (bölüm seçme ekranı yok, kaldığı yerden devam).
- Yardımcı robot uzun süre hamle olmazsa bir parçayı ve doğru kutuyu işaret eder.

## Parçalar ve renk körlüğü

Renkler: kırmızı, mavi, sarı, yeşil. Her rengin ayrıca kendi deseni var (kırmızı: noktalar, mavi: çizgiler,
sarı: zikzak, yeşil: dama); kutu simgelerindeki renk lekeleri de aynı deseni taşır.
Şekiller (gövde ve kafada): daire, kare, üçgen, yıldız. Boyut: büyük / küçük (aynı parça ölçeklenir).

## Bölümler (`bolumler.gd`)

Her bölüm bir sözlük: `boxes` (kutu kuralları: `color`, `shape`, `size`, `count`), `target` (kutu başına parça),
`kinds` (parça havuzu), `speed` (bant hızı px/sn), `robot` (ödül robotunun şablonu). `validate()` bir kutu için
üretilen parçanın başka kutuya uymadığını ve bölümlerin tutarlı olduğunu denetler.

| Bölüm | Kural | Kutular |
|---|---|---|
| 1-3 | renk | 2 → 2 → 3 |
| 4-6 | şekil (daire, kare, üçgen, yıldız) | 2 → 2 → 3 |
| 7-9 | boyut (büyük / küçük) | 2 (hedef 3 → 4 → 5) |
| 10-12 | renk + şekil (tabelada renkli şekil) | 2 → 3 → 3 |
| 13-15 | sayma: tabelada N nokta, kutuya tam N parça (renk ya da şekil ile), dolunca kapak kapanır | 2 → 3 → 3 |

Bant 55 px/sn ile başlar, her bölüm biraz hızlanır (15. bölümde ~95). 15'ten sonra son bölümlerden karışık devam eder.

## Ödül: robot montajı ve galeri

- Kutular açılır, ayrılan parçalardan seçilenler (gövde, kafa, kollar, anten, tekerlek) havaya uçup ortada birleşir;
  robotun renkleri ve şekilleri o bölümde ayrılan parçalardan gelir.
- Robot canlanır: gözleri yanar, göğsündeki ışıklar yanıp söner, dans eder, el sallar, galeri simgesine uçar;
  konfeti ve "Harika!" / "Süper!" / "Tebrikler!".
- 15 farklı robot şablonu: tekerlekli, yaylı bacaklı, pervaneli, uzun boyunlu, paletli, küçük uçan (jet), tek tekerlekli,
  örümcek bacaklı, zıplayan (pogo), roketli, kanatlı, uzun kollu, ahtapot, çift pervaneli, dev robot.
- Galeri (sağ üstteki simge): raflarda yapılan robotlar hafifçe hareket eder, dokununca dans eder; yapılmamışlar siluet.

## Dosyalar

```
robot_fabrikasi/
  robot_fabrikasi.tscn / .gd   ana sahne: katmanlar, dokunma/sürükleme, akış, duraklatma
  bolumler.gd                  bölüm verileri, parça üretimi, kurallar, validate()
  bolum_yoneticisi.gd          bölüm durumu, kutuların dolumu, bant için parça sırası, kayıt
  bant.gd                      taşıma bandı: çizim, kayan çizgiler, dişliler, borular, parçaların akışı
  parca.gd                     tek parça: görünüm, sallanma, tutma/bırakma animasyonları
  kutu.gd                      kutu: tabela simgesi, dolum lambaları, kabul/ret (boing), parlama, kapak
  robot.gd                     robot görünümü (şablon + renkler) ve animasyonları (uyanma, dans, el sallama)
  montaj.gd                    bölüm sonu robot montajı ve kutlama
  galeri.gd                    robot galerisi
  yardimci.gd                  yardımcı robot (başparmak, baş sallama, işaret, ipucu)
  arka_plan.gd                 atölye: duvar, borular, dönen dişliler, yanıp sönen lambalar
  efektler.gd / sesler.gd      parçacıklar (CPUParticles2D) / sentez sesler
  gorseller/ (svg_uret.py)  sesler/ (ses_uret.py)  testler/
```

Kayıt `user://robot_fabrikasi.cfg`: `[ilerleme] bolum`, `[galeri] <robot şablonu> = görünüm` (yapılan robotun renk ve şekilleri).
