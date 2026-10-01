# Köstebek Vurma

Çukurlardan çıkan köstebeğe (+30) ve meyve/sebzeye (+10) dokunma. Bomba 1 can götürür (3 can), kaçan için ceza yok.

- Kasklı köstebek iki dokunuş ister.
- Skora bağlı seviyeler (her 150 puan); 6 → 9 çukur.
- **Bütün denge ayarları `denge.tres`** (`MoleBalance` + `MoleLevelData` seviye dizisi).
- Durumlar COUNTDOWN / PLAYING / GAME_OVER (`kostebek.gd`), çıkış kuralları `cikis_yoneticisi.gd`.
- Nesneler `cikan_nesne.gd` temelli (`kostebek_nesne` / `meyve_nesne` / `bomba_nesne`).
- Nesne çukurun maske düğümünde (`clip_children`) çizilir, alt kısmı ön toprak dudağının arkasında kalır (`cukur.gd`).
- Çoklu dokunma, basış anında vurma.
- Ayrıntılar `TASARIM.md` içinde.
- Rekor `user://kostebek.cfg`.
