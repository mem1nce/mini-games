# Yol Yap

Parçaları (blok, rampa, köprü, yay) ızgaraya sürükleyip bilyeyi hediye kutusuna ulaştırma, 10 bölüm.

- Bölümler `bolumler.gd` içinde: harita dizeleri + parçaların doğru yerleri.
- Bilyenin yolu fiziksiz olarak `yol_mantigi.gd` içinde hesaplanır. `validate()` her bölümün çözülebildiğini kontrol eder (oyun açılırken de çalışır).
- Parçalar sadece doğru hücreye oturur.
- İlerleme `user://yol_yap.cfg`.
- Sesler (`SesYoneticisi`, `yol_yap.gd`): müzik `yol_yap`; parça alma `pop`, oturma `tahta_tok`, tepsiye dönme `hisirti`, bilye yuvarlanırken döngü `bilye_yuvarlanma` (düşüş ve zıplamada susar), yay `boing_kisa`, hediye `hediye_acilis`, bölüm sonu `tamamlandi` / son bölüm `kutlama`.
