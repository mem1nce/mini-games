# Balık Tutma sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Yumuşak, suyla ilgili, oyuncak gibi sesler; ani ya da sert ses yok.

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, envelope, highpass, lowpass, melody, mix, noise, note, save_loudness, silence, sweep  # noqa: E402


def save(name: str, samples: list, target: float = 0.1) -> None:
    save_loudness(HERE, name + ".wav", samples, target)


def bloop(f0: float, f1: float, seconds: float) -> list:
    # Su damlası / kabarcık "blup": hızla yükselen sinüs
    return sweep(f0, f1, seconds, attack=0.004, decay=14.0, curve=0.5)


def dalis() -> list:
    # Ağ suya girer: yumuşak "şlup"
    out = silence(0.45)
    mix(out, envelope(lowpass(highpass(noise(0.3, 3), 400), 2500), 0.005, 12.0), 0.0, 0.7)
    mix(out, bloop(260, 520, 0.2), 0.03, 0.6)
    return out


def yakala() -> list:
    # Balık ağa girdi: iki kabarcık + minik çan
    out = silence(0.6)
    mix(out, bloop(300, 700, 0.14), 0.0, 0.8)
    mix(out, bloop(420, 900, 0.12), 0.09, 0.6)
    mix(out, bell(note("A6"), 0.4, decay=9.0), 0.16, 0.35)
    return out


def kova() -> list:
    # Kovaya "plop" + su şıpırtısı
    out = silence(0.5)
    mix(out, bloop(220, 480, 0.18), 0.0, 0.9)
    mix(out, envelope(lowpass(highpass(noise(0.2, 5), 800), 4000), 0.002, 18.0), 0.02, 0.5)
    return out


def geri() -> list:
    # Balık suya geri atlar: "vıy" + şıpırtı
    out = silence(0.8)
    mix(out, sweep(700, 380, 0.3, attack=0.01, decay=6.0, curve=0.8), 0.0, 0.6)
    mix(out, envelope(lowpass(highpass(noise(0.3, 7), 500), 3000), 0.004, 10.0), 0.35, 0.7)
    return out


def gidik() -> list:
    # Denizanası gıdıklar: titrek, komik "brrr"
    out = []
    n = int(RATE * 0.55)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 520 + 90 * math.sin(2 * math.pi * 22 * t)
        phase += 2 * math.pi * f / RATE
        out.append(math.sin(phase) * min(1.0, t / 0.02) * math.exp(-3.5 * t))
    return out


def cop() -> list:
    # Çöp geri dönüşüm kutusuna: tatlı "tın-tın"
    out = silence(0.7)
    mix(out, bell(660, 0.3, decay=12.0), 0.0, 0.6)
    mix(out, bell(990, 0.4, decay=10.0), 0.1, 0.6)
    return out


def gorev() -> list:
    # Görev simgesi doldu: parlak iki nota
    out = silence(0.6)
    mix(out, bell(note("E6"), 0.5, decay=7.0), 0.0, 0.6)
    mix(out, bell(note("B6"), 0.5, decay=7.0), 0.08, 0.5)
    return out


def yeni() -> list:
    # Yeni tür: yükselen parıltılı arpej
    out = silence(1.3)
    for k, n in enumerate(["C6", "E6", "G6", "C7", "E7"]):
        mix(out, bell(note(n), 0.6, decay=5.0), k * 0.08, 0.4)
    mix(out, bloop(300, 800, 0.2), 0.0, 0.4)
    return out


def kutlama() -> list:
    return melody(["G4", "C5", "E5", "G5", None, "E5", "G5", "C6"], 0.11, 0.6)


def dokun() -> list:
    return sweep(500, 760, 0.08, attack=0.002, decay=30.0, curve=0.6)


def takla() -> list:
    return sweep(400, 1100, 0.35, attack=0.01, decay=5.0, curve=1.4)


def temiz() -> list:
    # Su berraklaştı: yumuşak "şıng"
    out = silence(1.0)
    for k, n in enumerate(["G5", "D6", "G6"]):
        mix(out, bell(note(n), 0.7, decay=4.0), k * 0.05, 0.35)
    return out


if __name__ == "__main__":
    save("dalis", dalis(), 0.07)
    save("yakala", yakala())
    save("kova", kova())
    save("geri", geri())
    save("gidik", gidik())
    save("cop", cop())
    save("gorev", gorev())
    save("yeni", yeni())
    save("kutlama", kutlama())
    save("dokun", dokun())
    save("takla", takla())
    save("temiz", temiz(), 0.07)
