# Zıpla Zıpla sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde (tepe -6 dBFS, başta/sonda kısa fade).
# Hepsi yumuşak ve komik: düşme bile korkutucu değil, kayan bir "fiyuuu".

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, envelope, lowpass, melody, mix, noise, note, save as _save, silence, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def zipla() -> list:
    # Zıplama: yukarı kayan, hafif titreşimli "boing"
    out = []
    phase = 0.0
    n = int(RATE * 0.26)
    for i in range(n):
        t = i / RATE
        freq = 220 + 520 * (i / n) ** 0.55 + 18 * math.sin(2 * math.pi * 28 * t)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.004) * math.exp(-9.0 * t)
        out.append((math.sin(phase) + 0.2 * math.sin(2 * phase)) * env)
    return out


def kon() -> list:
    # Konma: yumuşak, tok "pat"
    out = sweep(260, 110, 0.14, attack=0.002, decay=28.0, curve=0.5)
    mix(out, envelope(lowpass(noise(0.06, 4), 1200), 0.001, 60.0), 0.0, 0.5)
    return out


def cin() -> list:
    # Ödül toplama: parlak iki notalı "çın"
    out = bell(note("G6"), 0.45, 8.0)
    mix(out, bell(note("C7"), 0.5, 8.0), 0.07, 0.6)
    return out


def titre() -> list:
    # Basamak titremesi: kısa, hızlı tık tık tıkırtı
    out = silence(0.45)
    for k in range(9):
        mix(out, envelope(lowpass(noise(0.03, 20 + k), 1800), 0.001, 90.0), k * 0.05, 0.6 + 0.04 * k)
        mix(out, sweep(420, 380, 0.03, attack=0.001, decay=80.0), k * 0.05, 0.25)
    return out


def ufalan() -> list:
    # Basamak ufalanması: boğuk gürültü ve dağılan küçük çıtırtılar
    body = lowpass(lowpass(noise(0.55, 9), 900), 900)
    out = [v * min(1.0, (i / RATE) / 0.01) * math.exp(-6.0 * i / RATE) for i, v in enumerate(body)]
    for k, start in enumerate([0.03, 0.09, 0.14, 0.22, 0.3]):
        mix(out, envelope(lowpass(noise(0.03, 40 + k), 2600), 0.001, 110.0), start, 0.5)
    mix(out, sweep(180, 90, 0.3, attack=0.005, decay=10.0), 0.0, 0.35)
    return out


def dus() -> list:
    # Düşme: aşağı kayan kaydıraklı düdük "fiyuuu" (hafif vibrato)
    out = []
    phase = 0.0
    seconds = 1.0
    n = int(RATE * seconds)
    for i in range(n):
        t = i / RATE
        freq = 1300 * (0.28 ** (i / n)) * (1.0 + 0.025 * math.sin(2 * math.pi * 6.5 * t))
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.04) * (1.0 - 0.6 * (i / n))
        out.append((math.sin(phase) + 0.15 * math.sin(3 * phase)) * env)
    return out


def oyun_sonu() -> list:
    # Oyun sonu: sakin, olumlu küçük melodi (ceza hissi vermesin)
    out = melody(["E5", "G5", "E5", "C5", "D5", "", "C5"], 0.15, 0.8)
    for name in ["C4", "E4", "G4"]:
        mix(out, soft_tone(note(name), 1.4), 0.6, 0.25)
    return out


def rekor() -> list:
    # Rekor kırılınca: neşeli yükselen arpej ve parıltılar
    out = melody(["C5", "E5", "G5", "C6", "", "G5", "C6"], 0.1, 0.9)
    for k, name in enumerate(["C7", "E7", "G7", "C7"]):
        mix(out, bell(note(name), 0.5, 7.0), 0.45 + k * 0.08, 0.25)
    for name in ["C4", "G4", "E5"]:
        mix(out, soft_tone(note(name), 1.3), 0.6, 0.2)
    return out


if __name__ == "__main__":
    save("zipla.wav", zipla())
    save("kon.wav", kon())
    save("cin.wav", cin())
    save("titre.wav", titre())
    save("ufalan.wav", ufalan())
    save("dus.wav", dus())
    save("oyun_sonu.wav", oyun_sonu())
    save("rekor.wav", rekor())
