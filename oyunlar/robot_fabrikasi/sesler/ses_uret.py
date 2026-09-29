# Robot Fabrikası sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Yumuşak, oyuncak gibi mekanik sesler; ani ya da sert ses yok.

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import bell, envelope, lowpass, melody, mix, noise, note, save as _save, silence, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def al() -> list:
    # Parçayı tutunca: kısa yukarı "pop"
    return sweep(380, 760, 0.1, attack=0.003, decay=26.0, curve=0.6)


def dogru() -> list:
    # Doğru kutu: iki notalı çan + tahta "tok"
    out = silence(0.5)
    mix(out, envelope(lowpass(noise(0.05, 4), 1200), 0.001, 60.0), 0.0, 0.5)
    mix(out, bell(note("E6"), 0.4, decay=8.0), 0.03, 0.7)
    mix(out, bell(note("A6"), 0.4, decay=8.0), 0.1, 0.55)
    return out


def boing() -> list:
    # Yanlış kutu: yaylı, komik "boyoing"
    out = []
    phase = 0.0
    n = int(44100 * 0.5)
    for i in range(n):
        t = i / 44100
        freq = 200 + 80 * math.sin(2 * math.pi * 14 * t) * math.exp(-4 * t) + 140 * math.exp(-9 * t)
        phase += 2 * math.pi * freq / 44100
        out.append(math.sin(phase) * min(1.0, t / 0.004) * math.exp(-5 * t))
    return out


def dolu() -> list:
    # Kutu doldu, kapak kapandı
    out = melody(["C5", "E5", "G5"], 0.08, 0.4)
    mix(out, envelope(lowpass(noise(0.08, 9), 900), 0.002, 40.0), 0.24, 0.6)
    return out


def boru() -> list:
    # Parça boruya girer: aşağı süzülen "fuuup"
    return sweep(700, 220, 0.3, attack=0.01, decay=8.0, curve=0.8)


def dus() -> list:
    # Parça borudan banda düşer: küçük "tık-tık"
    out = silence(0.3)
    mix(out, sweep(900, 500, 0.05, attack=0.001, decay=50.0), 0.0, 0.8)
    mix(out, sweep(760, 420, 0.05, attack=0.001, decay=50.0), 0.1, 0.5)
    return out


def kol() -> list:
    # Büyük kol: mekanik "klak"
    out = envelope(lowpass(noise(0.1, 12), 1500), 0.001, 35.0)
    mix(out, sweep(260, 160, 0.12, attack=0.002, decay=25.0), 0.02, 0.8)
    return out


def montaj() -> list:
    # Parça robota takılır: "çıt"
    out = sweep(1200, 800, 0.06, attack=0.001, decay=45.0)
    mix(out, envelope(lowpass(noise(0.04, 3), 2500), 0.001, 80.0), 0.0, 0.5)
    return out


def uyan() -> list:
    # Robot canlanır: yükselen sıcak ton + çan
    out = sweep(220, 880, 0.6, attack=0.05, decay=2.5, curve=0.6)
    mix(out, bell(note("C6"), 0.7, decay=4.0), 0.45, 0.5)
    return out


def dans() -> list:
    return melody(["C5", "E5", "G5", "E5", "C6", None, "G5", "C6"], 0.14, 0.5)


def kutlama() -> list:
    out = melody(["G5", "C6", "E6", "G6"], 0.1, 0.8)
    for k in range(3):
        mix(out, bell(note("C7"), 0.4, decay=9.0), 0.45 + k * 0.1, 0.25)
    return out


def yardimci() -> list:
    # Yardımcı robot mutlu: iki kısa neşeli ton
    out = silence(0.3)
    mix(out, soft_tone(note("A5"), 0.15), 0.0, 0.7)
    mix(out, soft_tone(note("E6"), 0.2), 0.09, 0.7)
    return out


def tik() -> list:
    return sweep(420, 880, 0.08, attack=0.002, decay=40.0, curve=0.7)


def ucus() -> list:
    # Robot galeriye uçar
    return sweep(400, 1200, 0.5, attack=0.02, decay=4.0, curve=0.5)


if __name__ == "__main__":
    for name, fn in [("al", al), ("dogru", dogru), ("boing", boing), ("dolu", dolu), ("boru", boru), ("dus", dus),
                     ("kol", kol), ("montaj", montaj), ("uyan", uyan), ("dans", dans), ("kutlama", kutlama),
                     ("yardimci", yardimci), ("tik", tik), ("ucus", ucus)]:
        save(f"{name}.wav", fn())
