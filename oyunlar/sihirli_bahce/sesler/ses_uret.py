# Sihirli Bahçe sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Hepsi yumuşak, sakin ve kısa; yağmur kesintisiz döngü.

import math
import os
import random
import struct
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import PEAK, RATE, bell, envelope, lowpass, melody, mix, noise, note, save as _save, silence, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def save_loop(name: str, samples: list) -> None:
    peak = max(abs(v) for v in samples) or 1.0
    frames = bytearray()
    for v in samples:
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v / peak * PEAK)) * 32767))
    with wave.open(os.path.join(HERE, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(name, "(döngü)")


def yagmur() -> list:
    # Yumuşak yağmur hışırtısı: süzülmüş gürültü + ara sıra minik damla "tık"ları; 2 sn döngü
    seconds = 2.0
    base = lowpass(noise(seconds, 21), 2200)
    base = [v * 0.6 for v in base]
    # Döngü noktası yumuşak olsun: baş ve sonu çapraz geçişle birleştir
    n = len(base)
    fade = int(RATE * 0.25)
    for i in range(fade):
        k = i / fade
        base[i] = base[i] * k + base[n - fade + i] * (1 - k)
    base = base[: n - fade]
    rng = random.Random(4)
    for _ in range(26):
        start = rng.uniform(0.0, (len(base) - RATE * 0.05) / RATE)
        drop = sweep(rng.uniform(1400, 2200), rng.uniform(700, 1000), 0.04, attack=0.001, decay=60.0)
        mix(base, drop, start, rng.uniform(0.15, 0.35))
    return base


def tohum() -> list:
    # Tohum toprağa düşer: yumuşak "pıt"
    out = sweep(520, 220, 0.14, attack=0.002, decay=22.0, curve=0.6)
    mix(out, envelope(lowpass(noise(0.08, 3), 900), 0.002, 40.0), 0.0, 0.4)
    return out


def sulandi() -> list:
    out = silence(0.5)
    for k, n in enumerate(["G5", "B5", "D6"]):
        mix(out, bell(note(n), 0.35, decay=9.0), k * 0.07, 0.6)
    return out


def buyume() -> list:
    # Büyüme: yukarı süzülen yumuşak "vuup" + çan
    out = sweep(300, 820, 0.3, attack=0.02, decay=6.0, curve=0.7)
    mix(out, bell(note("E6"), 0.5, decay=6.0), 0.18, 0.5)
    return out


def acilma() -> list:
    return melody(["C6", "E6", "G6"], 0.09, 0.6)


def sihir() -> list:
    # Sihirli ışıltı: hızlı yükselen çan dizisi
    out = silence(1.0)
    for k, n in enumerate(["C6", "E6", "G6", "C7", "E7"]):
        mix(out, bell(note(n), 0.5, decay=7.0), k * 0.06, 0.45)
    return out


def kipir() -> list:
    return sweep(600, 900, 0.1, attack=0.003, decay=30.0, curve=0.7)


def kurbaga() -> list:
    # Sevimli "vrak": iki kısa, perdesi titreyen sesten
    out = silence(0.4)
    for start in (0.0, 0.16):
        seg = []
        phase = 0.0
        for i in range(int(RATE * 0.12)):
            t = i / RATE
            freq = 240 + 60 * math.sin(2 * math.pi * 38 * t)
            phase += 2 * math.pi * freq / RATE
            v = math.sin(phase) + 0.4 * math.sin(phase * 2) + 0.2 * math.sin(phase * 3)
            seg.append(v * min(1.0, t / 0.01) * math.exp(-10 * t))
        mix(out, seg, start, 1.0)
    return lowpass(out, 2400)


def pirilti() -> list:
    out = silence(0.45)
    mix(out, bell(note("A6"), 0.4, decay=9.0), 0.0, 0.6)
    mix(out, bell(note("E7"), 0.3, decay=12.0), 0.05, 0.4)
    return out


def kanat() -> list:
    # Kelebek: hızlı yumuşak çırpıntı
    out = silence(0.35)
    for k in range(5):
        mix(out, envelope(lowpass(noise(0.05, 10 + k), 1600), 0.005, 40.0), k * 0.06, 0.8)
    return out


def vizz() -> list:
    out = []
    for i in range(int(RATE * 0.5)):
        t = i / RATE
        freq = 210 + 40 * math.sin(2 * math.pi * 3 * t)
        v = math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 2 * t)
        out.append(v * (0.6 + 0.4 * math.sin(2 * math.pi * 32 * t)) * min(1.0, t / 0.05) * min(1.0, (0.5 - t) / 0.1))
    return lowpass(out, 1500)


def hop() -> list:
    return sweep(380, 760, 0.12, attack=0.003, decay=20.0, curve=0.6)


def saklan() -> list:
    return sweep(700, 260, 0.2, attack=0.003, decay=14.0, curve=0.5)


def tik() -> list:
    return sweep(420, 880, 0.08, attack=0.002, decay=40.0, curve=0.7)


def kese() -> list:
    # Keseyi alınca: kağıt hışırtısı
    return envelope(lowpass(noise(0.15, 8), 3000), 0.01, 25.0)


def gunes() -> list:
    # Sıcak, parlak yükselen akor
    out = silence(1.2)
    for k, n in enumerate(["C5", "E5", "G5", "C6"]):
        mix(out, soft_tone(note(n), 1.0), k * 0.05, 0.4)
    mix(out, bell(note("G6"), 0.8, decay=4.0), 0.2, 0.3)
    return out


def ruzgar() -> list:
    # Esinti: yükselip alçalan süzülmüş gürültü
    out = lowpass(noise(1.4, 13), 700)
    n = len(out)
    return [v * math.sin(math.pi * i / n) ** 2 for i, v in enumerate(out)]


def gece() -> list:
    return melody(["G5", "E5", "C5", "G4"], 0.16, 0.8)


def gunduz() -> list:
    return melody(["G4", "C5", "E5", "G5"], 0.13, 0.7)


def topla() -> list:
    return melody(["E5", "G5", "C6"], 0.08, 0.5)


def kesif() -> list:
    # İlk keşif: kutlama melodisi ve parıltı
    out = melody(["C5", "E5", "G5", "C6", None, "G5", "C6", "E6"], 0.12, 0.8)
    for k in range(4):
        mix(out, bell(note("C7"), 0.4, decay=9.0), 0.5 + k * 0.1, 0.25)
    return out


if __name__ == "__main__":
    save_loop("yagmur.wav", yagmur())
    for name, fn in [("tohum", tohum), ("sulandi", sulandi), ("buyume", buyume), ("acilma", acilma), ("sihir", sihir),
                     ("kipir", kipir), ("kurbaga", kurbaga), ("pirilti", pirilti), ("kanat", kanat), ("vizz", vizz),
                     ("hop", hop), ("saklan", saklan), ("tik", tik), ("kese", kese), ("gunes", gunes), ("ruzgar", ruzgar),
                     ("gece", gece), ("gunduz", gunduz), ("topla", topla), ("kesif", kesif)]:
        save(f"{name}.wav", fn())
