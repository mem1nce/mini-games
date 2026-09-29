# Araba Yarışı sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde (tepe -6 dBFS, başta/sonda kısa fade).
# Hepsi yumuşak ve kısa; motor sesi kesintisiz döngü (Godot'ta loop açık, perdesi hıza göre değişir).

import math
import os
import struct
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import PEAK, RATE, bell, envelope, lowpass, melody, mix, noise, note, save as _save, silence, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def save_loop(name: str, samples: list) -> None:
    # Döngü sesi: fade yok (döngü noktasında boşluk/tık olmasın)
    peak = max(abs(v) for v in samples) or 1.0
    frames = bytearray()
    for v in samples:
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v / peak * PEAK)) * 32767))
    with wave.open(os.path.join(HERE, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(name, round(len(samples) / RATE, 2), "sn (döngü)")


def motor() -> list:
    # Tatlı, yumuşak bir "vınn": 1 sn içinde tam sayıda devir yapan harmonikler + hafif pıt pıt
    out = []
    for i in range(RATE):
        t = i / RATE
        v = (math.sin(2 * math.pi * 55 * t) + 0.55 * math.sin(2 * math.pi * 110 * t + 0.4)
             + 0.3 * math.sin(2 * math.pi * 165 * t + 1.1) + 0.12 * math.sin(2 * math.pi * 220 * t + 2.0))
        am = 0.78 + 0.22 * math.sin(2 * math.pi * 13 * t) + 0.05 * math.sin(2 * math.pi * 3 * t)
        out.append(v * am)
    return out


def yildiz() -> list:
    # Yıldız: iki parlak çan notası
    out = silence(0.55)
    mix(out, bell(note("E6"), 0.45, decay=7.0), 0.0, 0.8)
    mix(out, bell(note("B6"), 0.45, decay=7.0), 0.06, 0.6)
    return out


def su() -> list:
    # Su sıçraması: yumuşak "şlap" + birkaç kabarcık
    out = envelope(lowpass(noise(0.45, 7), 1800), 0.004, 9.0)
    for k, start in enumerate((0.05, 0.11, 0.19)):
        mix(out, sweep(500 + k * 160, 1100 + k * 200, 0.08, attack=0.004, decay=30.0), start, 0.35)
    return out


def kasis() -> list:
    # Kasis: komik, yaylı "boyoyoing"
    out = []
    phase = 0.0
    for i in range(int(RATE * 0.5)):
        t = i / RATE
        freq = 220 + 90 * math.sin(2 * math.pi * 16 * t) * math.exp(-4 * t) + 120 * math.exp(-10 * t)
        phase += 2 * math.pi * freq / RATE
        out.append(math.sin(phase) * min(1.0, t / 0.004) * math.exp(-5.5 * t))
    return out


def zipla() -> list:
    # Rampadan zıplama: yukarı süzülen yumuşak "fiyuu"
    out = envelope(lowpass(noise(0.5, 11), 1200), 0.08, 5.0)
    mix(out, sweep(320, 760, 0.45, attack=0.03, decay=5.0, curve=0.8), 0.0, 0.5)
    return out


def inis() -> list:
    # Yere iniş: tok, yumuşak "pat"
    out = sweep(170, 60, 0.25, attack=0.002, decay=16.0, curve=0.6)
    mix(out, envelope(lowpass(noise(0.12, 5), 700), 0.002, 30.0), 0.0, 0.7)
    return out


def bip() -> list:
    return envelope(soft_tone(note("A5"), 0.3), 0.005, 9.0)


def basla() -> list:
    out = silence(0.6)
    mix(out, bell(note("E6"), 0.55, decay=4.0), 0.0, 0.8)
    mix(out, soft_tone(note("E5"), 0.5), 0.0, 0.5)
    return out


def bitis() -> list:
    # Bitiş çizgisi: neşeli yükselen dörtlü
    out = melody(["C5", "E5", "G5", "C6"], 0.11, 0.5)
    mix(out, bell(note("C6"), 0.7, decay=3.5), 0.33, 0.5)
    return out


def podyum() -> list:
    # Podyum: kısa kutlama melodisi
    return melody(["G5", "E5", "G5", "C6", None, "A5", "C6", "E6"], 0.13, 0.6)


def tik() -> list:
    return sweep(420, 880, 0.08, attack=0.002, decay=40.0, curve=0.7)


def boya() -> list:
    # Renk seçimi: yumuşak "blop"
    out = sweep(760, 320, 0.18, attack=0.003, decay=18.0, curve=0.6)
    mix(out, sweep(1100, 600, 0.1, attack=0.003, decay=30.0), 0.05, 0.3)
    return out


def hayvan() -> list:
    # Şoför seçimi: iki küçük zıplama sesi
    out = silence(0.3)
    mix(out, sweep(360, 820, 0.1, attack=0.003, decay=26.0, curve=0.7), 0.0, 0.8)
    mix(out, sweep(480, 1100, 0.1, attack=0.003, decay=26.0, curve=0.7), 0.1, 0.7)
    return out


def kilit() -> list:
    # Kilitli pist: yumuşak, alçak "tık"
    return sweep(260, 180, 0.12, attack=0.002, decay=30.0)


def say() -> list:
    # Podyumda yıldız sayarken: kısa çan (perdesi oyunda her yıldızda biraz yükselir)
    return bell(note("C6"), 0.3, decay=10.0)


if __name__ == "__main__":
    save_loop("motor.wav", motor())
    save("yildiz.wav", yildiz())
    save("su.wav", su())
    save("kasis.wav", kasis())
    save("zipla.wav", zipla())
    save("inis.wav", inis())
    save("bip.wav", bip())
    save("basla.wav", basla())
    save("bitis.wav", bitis())
    save("podyum.wav", podyum())
    save("tik.wav", tik())
    save("boya.wav", boya())
    save("hayvan.wav", hayvan())
    save("kilit.wav", kilit())
    save("say.wav", say())
