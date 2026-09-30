# Kule Yapma sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Yumuşak, oyuncak gibi sesler; ani ya da sert ses yok.

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, envelope, highpass, lowpass, melody, mix, noise, note, save_loudness, silence, sweep  # noqa: E402


def save(name: str, samples: list, target: float = 0.1) -> None:
    save_loudness(HERE, name + ".wav", samples, target)


def birak() -> list:
    # Kat bırakıldı: kısa aşağı "vıınn"
    out = silence(0.4)
    mix(out, sweep(700, 380, 0.3, attack=0.01, decay=6.0, curve=0.8), 0.0, 0.6)
    mix(out, envelope(lowpass(highpass(noise(0.2, 3), 800), 3000), 0.02, 12.0), 0.0, 0.3)
    return out


def otur() -> list:
    # Kat oturdu: yumuşak tahta "tok" + esneme "boing"
    out = silence(0.5)
    mix(out, envelope(lowpass(noise(0.08, 5), 700), 0.002, 40.0), 0.0, 0.9)
    mix(out, sweep(160, 90, 0.12, attack=0.002, decay=24.0), 0.0, 0.8)
    mix(out, sweep(300, 520, 0.18, attack=0.01, decay=14.0, curve=0.6), 0.06, 0.35)
    return out


def mukemmel() -> list:
    out = silence(0.8)
    for k, n in enumerate(["E6", "G6", "C7"]):
        mix(out, bell(note(n), 0.6, decay=6.0), k * 0.06, 0.5)
    return out


def kombo() -> list:
    out = silence(1.0)
    for k, n in enumerate(["C6", "E6", "G6", "C7", "E7"]):
        mix(out, bell(note(n), 0.6, decay=5.5), k * 0.05, 0.45)
    return out


def iska() -> list:
    # Iska: komik "boyoing"
    out = []
    phase = 0.0
    n = int(RATE * 0.5)
    for i in range(n):
        t = i / RATE
        freq = 220 + 80 * math.sin(2 * math.pi * 12 * t) * math.exp(-4 * t) + 120 * math.exp(-8 * t)
        phase += 2 * math.pi * freq / RATE
        out.append(math.sin(phase) * min(1.0, t / 0.004) * math.exp(-5 * t))
    return out


def puf() -> list:
    return envelope(lowpass(highpass(noise(0.35, 7), 300), 2000), 0.01, 10.0)


def tasin() -> list:
    # Hayvanlar taşındı: neşeli iki "pıt"
    out = silence(0.5)
    mix(out, sweep(500, 900, 0.08, attack=0.002, decay=26.0, curve=0.6), 0.0, 0.8)
    mix(out, sweep(600, 1100, 0.08, attack=0.002, decay=26.0, curve=0.6), 0.1, 0.7)
    return out


def kutlama() -> list:
    return melody(["C5", "E5", "G5", "C6", None, "G5", "C6", "E6"], 0.11, 0.6)


def dokun() -> list:
    return sweep(500, 760, 0.08, attack=0.002, decay=30.0, curve=0.6)


def rekor() -> list:
    return melody(["G5", "C6", "E6", "G6"], 0.09, 0.5)


def kuslar() -> list:
    # Kuş cıvıltısı
    out = silence(1.2)
    for k in range(5):
        mix(out, sweep(2200, 3200, 0.06, attack=0.003, decay=20.0), k * 0.18, 0.5)
        mix(out, sweep(3000, 2400, 0.05, attack=0.003, decay=24.0), k * 0.18 + 0.07, 0.4)
    return out


def isler() -> list:
    # Apartmanda pencereye dokununca: küçük sihirli "tın"
    out = silence(0.6)
    mix(out, bell(note("A5"), 0.5, decay=8.0), 0.0, 0.6)
    mix(out, bell(note("E6"), 0.5, decay=8.0), 0.07, 0.4)
    return out


if __name__ == "__main__":
    save("birak", birak(), 0.07)
    save("otur", otur())
    save("mukemmel", mukemmel())
    save("kombo", kombo())
    save("iska", iska())
    save("puf", puf(), 0.07)
    save("tasin", tasin())
    save("kutlama", kutlama())
    save("dokun", dokun())
    save("rekor", rekor())
    save("kuslar", kuslar(), 0.06)
    save("isler", isler())
