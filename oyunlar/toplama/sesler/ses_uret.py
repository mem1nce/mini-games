# Toplama Öğreniyorum sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Sesler yumuşak ve kısa; ortak yardımcılar ortak/ses/sentez.py içinde (tepe -6 dBFS, kısa fade).

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, lowpass, melody, mix, noise, note, save as _save, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def count() -> list:
    # Sayma: kısa, tatlı bir "tın". Oyunda her sayışta perdesi biraz yükseltilir.
    out = bell(note("C6"), 0.35, 9.0)
    mix(out, soft_tone(note("C5"), 0.3), 0.0, 0.35)
    return out


def tap() -> list:
    # Nesneye dokunma: minik, yukarı süzülen "pıt"
    return sweep(500, 1100, 0.07, attack=0.002, decay=45.0, curve=0.6)


def correct() -> list:
    # Doğru cevap: iki notalı neşeli "ta-da"
    out = melody(["G5", "C6"], 0.1, 0.5)
    mix(out, bell(note("E6"), 0.5, 6.0), 0.1, 0.4)
    return out


def wrong() -> list:
    # Yanlış cevap: yumuşak, hafif aşağı süzülen "bup" (üzücü ya da korkutucu değil)
    out = []
    phase = 0.0
    seconds = 0.32
    for i in range(int(RATE * seconds)):
        t = i / RATE
        x = t / seconds
        freq = 420 - 120 * x
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.015) * math.exp(-7.0 * t)
        out.append((math.sin(phase) + 0.2 * math.sin(2 * phase)) * env)
    return out


def fly() -> list:
    # Düğme uçarken hafif "vuuş": süzülmüş gürültü + yükselen sinüs
    air = lowpass(noise(0.35, seed=7), 1800)
    air = [v * math.sin(math.pi * i / len(air)) ** 2 for i, v in enumerate(air)]
    out = [v * 0.6 for v in air]
    mix(out, sweep(300, 900, 0.3, attack=0.05, decay=4.0), 0.0, 0.35)
    return out


def level_end() -> list:
    out = melody(["C5", "E5", "G5", "C6"], 0.12, 0.8)
    mix(out, bell(note("C7"), 0.6, 6.0), 0.48, 0.25)
    return out


def finale() -> list:
    lead = ["C5", "E5", "G5", "C6", "G5", "C6", "E6", "", "D6", "C6", "G5", "E5", "G5", "C6", "", ""]
    out = melody(lead, 0.15, 0.9)
    for start, chord in [(0.0, ["C4", "E4", "G4"]), (0.6, ["F4", "A4", "C5"]), (1.2, ["G4", "B4", "D5"]), (1.8, ["C4", "E4", "G4", "C5"])]:
        for name in chord:
            mix(out, soft_tone(note(name), 1.2), start, 0.3)
    for k, name in enumerate(["C7", "E7", "G7", "C8"]):
        mix(out, bell(note(name), 0.5, 7.0), 1.95 + k * 0.07, 0.15)
    return out


if __name__ == "__main__":
    save("sayma.wav", count())
    save("dokunma.wav", tap())
    save("dogru.wav", correct())
    save("yanlis.wav", wrong())
    save("ucus.wav", fly())
    save("bolum.wav", level_end())
    save("final.wav", finale())
