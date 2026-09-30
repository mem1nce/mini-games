# Boyama Kitabı sesleri: sadece Python standart kütüphanesiyle üretilir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav yazar, sonunda hepsini denetler)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Bütün sesler save_loudness() ile aynı algılanan yüksekliğe
# eşitlenir (tepe en fazla -6 dBFS); oyunda ayrıca dB ile ayarlanır (sesler.gd). Yumuşak ve kısa.
#
# - kova: boya dolarken yumuşak "fışş-blup" (kabaran süzülmüş hışırtı + yukarı kayan yumuşak ton)
# - renk: renk seçince kısa marimba notası (oyunda perdesi renge göre değişir)
# - firca, silgi: DÖNGÜ sesleri (baştan sona dikişsiz); parmak hareket ettikçe çalar, durunca susar
# - damga: "pıt"; geri_al: aşağı süzülen "vuup"; temizle: süpürge "fşuu" ve ışıltı
# - kaydet: kutlama arpeji; tik: araç seçme; sil: galeriden silme "puf"; sayfa: sayfa açılırken "pop"

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import (RATE, bandpass, bell, check_all, envelope, lowpass, mix, noise, note,  # noqa: E402
                    save_loudness, silence, soft_tone, sweep)

TARGET = 0.1


def save(name: str, samples: list, target: float = TARGET) -> None:
    save_loudness(HERE, name, samples, target)


def bucket() -> list:
    s = 0.42
    hiss = bandpass(noise(s, 21), 900, 4200)
    hiss = [v * math.sin(math.pi * min(1.0, i / (RATE * s))) ** 1.5 for i, v in enumerate(hiss)]
    out = [v * 0.5 for v in hiss]
    mix(out, sweep(260, 620, 0.3, 0.03, 7.0, 0.7), 0.06, 0.8)
    mix(out, sweep(520, 1240, 0.2, 0.02, 12.0, 0.7), 0.1, 0.18)
    return lowpass(out, 5000)


def color_note() -> list:
    return soft_tone(note("C5"), 0.32)


def seamless(samples: list, fade: float = 0.12) -> list:
    # Sonun son 'fade' saniyesini başa karıştırır: döngü dikişsiz olur
    n = int(RATE * fade)
    body = samples[:-n]
    tail = samples[-n:]
    for i in range(n):
        k = i / n
        body[i] = body[i] * k + tail[i] * (1 - k)
    return body


def brush_loop() -> list:
    # Kağıt üstünde yumuşak fırça hışırtısı: süzülmüş gürültü, yavaş dalgalanan genlik
    s = 1.2
    out = bandpass(noise(s, 31), 500, 2600)
    out = [v * (0.75 + 0.25 * math.sin(2 * math.pi * 3.0 * i / RATE)) for i, v in enumerate(out)]
    return seamless(lowpass(out, 3000))


def eraser_loop() -> list:
    # Silgi: daha pes, pürüzlü sürtünme (hızlı küçük dalgalanmalar)
    s = 1.2
    out = bandpass(noise(s, 33), 250, 1500)
    out = [v * (0.6 + 0.4 * abs(math.sin(2 * math.pi * 11.0 * i / RATE))) for i, v in enumerate(out)]
    return seamless(lowpass(out, 1800))


def stamp() -> list:
    out = sweep(700, 260, 0.12, 0.002, 30.0, 0.5)
    mix(out, envelope(bandpass(noise(0.03, 41), 1500, 6000), 0.001, 90.0), 0.0, 0.25)
    mix(out, bell(note("E6"), 0.25, 14.0), 0.02, 0.15)
    return out


def undo() -> list:
    out = sweep(820, 330, 0.26, 0.01, 8.0, 0.8)
    mix(out, sweep(1640, 660, 0.2, 0.01, 12.0, 0.8), 0.0, 0.12)
    return lowpass(out, 4000)


def clear() -> list:
    s = 0.7
    swish = bandpass(noise(s, 51), 700, 5000)
    swish = [v * math.sin(math.pi * i / (RATE * s)) ** 2 for i, v in enumerate(swish)]
    out = [v * 0.6 for v in swish]
    for k, n in enumerate(("C6", "E6", "G6", "C7")):
        mix(out, bell(note(n), 0.35, 9.0), 0.25 + k * 0.07, 0.18)
    return out


def celebrate() -> list:
    out = silence(1.0)
    for k, n in enumerate(("C5", "E5", "G5", "C6")):
        mix(out, soft_tone(note(n), 0.5), k * 0.09, 0.8)
    mix(out, bell(note("E6"), 0.6, 5.0), 0.36, 0.35)
    mix(out, bell(note("G6"), 0.5, 6.0), 0.45, 0.25)
    return out


def tick() -> list:
    out = sweep(1500, 1100, 0.05, 0.001, 70.0)
    mix(out, envelope(bandpass(noise(0.02, 61), 2000, 7000), 0.0005, 150.0), 0.0, 0.2)
    return out


def delete() -> list:
    out = [v * 0.7 for v in envelope(bandpass(noise(0.35, 71), 400, 3000), 0.01, 9.0)]
    mix(out, sweep(520, 180, 0.25, 0.005, 10.0), 0.0, 0.8)
    return lowpass(out, 3500)


def page() -> list:
    out = sweep(380, 1100, 0.12, 0.003, 30.0, 0.6)
    mix(out, bell(note("G5"), 0.4, 8.0), 0.05, 0.4)
    return out


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    save("kova.wav", bucket())
    save("renk.wav", color_note())
    save("firca.wav", brush_loop())
    save("silgi.wav", eraser_loop())
    save("damga.wav", stamp())
    save("geri_al.wav", undo())
    save("temizle.wav", clear())
    save("kaydet.wav", celebrate())
    save("tik.wav", tick())
    save("sil.wav", delete())
    save("sayfa.wav", page())
    sys.exit(0 if check_all(HERE) else 1)
