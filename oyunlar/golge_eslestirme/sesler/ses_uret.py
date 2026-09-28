# Gölge Eşleştirme sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Sesler yumuşak ve kısa; ortak yardımcılar ortak/ses/sentez.py içinde (tepe -6 dBFS, kısa fade).

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, melody, mix, note, save as _save, soft_tone  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def pop() -> list:
    # Kısa, yukarı süzülen "pop"
    out = []
    phase = 0.0
    n = int(RATE * 0.09)
    for i in range(n):
        t = i / RATE
        freq = 380 + 900 * (t / 0.09) ** 0.6
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.003) * math.exp(-38 * t)
        out.append(math.sin(phase) * env)
    return out


def ding() -> list:
    out = bell(note("E6"), 0.8, 5.5)
    mix(out, bell(note("B6"), 0.7, 7.0), 0.0, 0.35)
    return out


def boing() -> list:
    # Yumuşak "boing": aşağı inip hafif yukarı dönen, titreşimli sinüs
    out = []
    phase = 0.0
    seconds = 0.45
    for i in range(int(RATE * seconds)):
        t = i / RATE
        x = t / seconds
        freq = 330 - 150 * math.sin(math.pi * min(x * 1.4, 1.0)) + 25 * math.sin(2 * math.pi * 14 * t) * (1 - x)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.01) * math.exp(-5.5 * t)
        out.append((math.sin(phase) + 0.15 * math.sin(2 * phase)) * env)
    return out


def level_end() -> list:
    out = melody(["C5", "E5", "G5", "C6"], 0.13, 0.8)
    mix(out, bell(note("C7"), 0.6, 6.0), 0.52, 0.25)
    return out


def finale() -> list:
    lead = ["C5", "E5", "G5", "C6", "G5", "C6", "E6", "", "D6", "C6", "G5", "E5", "G5", "C6", "", ""]
    out = melody(lead, 0.15, 0.9)
    # Alt armoni: uzun, yumuşak akorlar
    for start, chord in [(0.0, ["C4", "E4", "G4"]), (0.6, ["F4", "A4", "C5"]), (1.2, ["G4", "B4", "D5"]), (1.8, ["C4", "E4", "G4", "C5"])]:
        for name in chord:
            mix(out, soft_tone(note(name), 1.2), start, 0.3)
    # Sonda parıltılı çanlar
    for k, name in enumerate(["C7", "E7", "G7", "C8"]):
        mix(out, bell(note(name), 0.5, 7.0), 1.95 + k * 0.07, 0.15)
    return out


if __name__ == "__main__":
    save("pop.wav", pop())
    save("ding.wav", ding())
    save("boing.wav", boing())
    save("bolum_sonu.wav", level_end())
    save("final.wav", finale())
