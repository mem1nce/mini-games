# Yol Yap

Parçaları (blok, rampa, köprü, yay) ızgaraya sürükleyip bilyeyi hediye kutusuna ulaştırma, 10 bölüm.

- Bölümler `bolumler.gd` içinde: harita dizeleri + parçaların doğru yerleri.
- Bilyenin yolu fiziksiz olarak `yol_mantigi.gd` içinde hesaplanır. `validate()` her bölümün çözülebildiğini kontrol eder (oyun açılırken de çalışır).
- Parçalar sadece doğru hücreye oturur.
- İlerleme `user://yol_yap.cfg`.
