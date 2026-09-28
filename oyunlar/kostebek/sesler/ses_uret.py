# Köstebek Vurma sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde (tepe -6 dBFS, başta/sonda kısa fade).
# Hepsi yumuşak: ani, keskin ya da korkutucu ses yok (bomba bile sadece yumuşak bir "puf").

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, envelope, lowpass, melody, mix, noise, note, save as _save, silence, soft_tone, sweep  # noqa: E402


def save(name: str, samples: list) -> None:
    _save(HERE, name, samples)


def pop() -> list:
    # Nesne çukurdan çıkarken: kısa, yukarı süzülen "pop"
    return sweep(300, 1000, 0.1, attack=0.003, decay=34.0, curve=0.6)


def bonk() -> list:
    # Köstebeğe vurunca: tok, aşağı kayan "bonk" + çok hafif boğuk vuruş
    out = sweep(520, 170, 0.28, attack=0.002, decay=13.0, curve=0.5)
    mix(out, sweep(1040, 340, 0.12, attack=0.002, decay=30.0, curve=0.5), 0.0, 0.25)
    mix(out, envelope(lowpass(noise(0.05, 3), 900), 0.001, 70.0), 0.0, 0.6)
    return out


def cin() -> list:
    # Meyve toplama: kısa, parlak "çın"
    out = bell(note("E6"), 0.5, 8.0)
    mix(out, bell(note("B6"), 0.45, 9.0), 0.05, 0.45)
    return out


def kask() -> list:
    # Kask kırılma: kuru "tak" ve arkasından birkaç küçük çıtırtı
    out = envelope(lowpass(noise(0.08, 7), 2600), 0.001, 55.0)
    mix(out, sweep(900, 600, 0.06, attack=0.001, decay=60.0), 0.0, 0.5)
    for k, (start, cutoff) in enumerate([(0.07, 3200), (0.11, 2800), (0.16, 3600)]):
        mix(out, envelope(lowpass(noise(0.03, 11 + k), cutoff), 0.001, 120.0), start, 0.45)
    return out


def puf() -> list:
    # Bomba: yavaş atak, alçak geçiren süzgeçli gürültü; keskin tepe yok
    body = lowpass(lowpass(noise(0.7, 5), 700), 700)
    out = [v * min(1.0, (i / RATE) / 0.05) * math.exp(-5.5 * i / RATE) for i, v in enumerate(body)]
    mix(out, sweep(160, 70, 0.5, attack=0.04, decay=7.0), 0.0, 0.25)
    return out


def can() -> list:
    # Can kaybı: yumuşak, iki notalı inen "ooh"
    out = silence(0.7)
    mix(out, soft_tone(note("E5"), 0.5), 0.0, 1.0)
    mix(out, soft_tone(note("C5"), 0.6), 0.16, 1.0)
    return out


def seviye() -> list:
    # Seviye atlama: kısa neşeli arpej ve parıltı
    out = melody(["C5", "E5", "G5", "C6"], 0.09, 0.5)
    mix(out, bell(note("C7"), 0.5, 7.0), 0.3, 0.2)
    return out


def oyun_sonu() -> list:
    # Oyun sonu: sakin, olumlu küçük melodi (ceza hissi vermesin)
    out = melody(["G5", "E5", "C5", "D5", "E5", "", "C5"], 0.16, 0.8)
    for name in ["C4", "E4", "G4"]:
        mix(out, soft_tone(note(name), 1.4), 0.64, 0.25)
    return out


def bip() -> list:
    # Geri sayım: 3, 2, 1
    return bell(note("A5"), 0.25, 14.0)


def bip_son() -> list:
    # Geri sayım sonu: daha tiz ve uzun
    out = bell(note("E6"), 0.5, 7.0)
    mix(out, bell(note("A6"), 0.45, 8.0), 0.0, 0.3)
    return out


if __name__ == "__main__":
    save("pop.wav", pop())
    save("bonk.wav", bonk())
    save("cin.wav", cin())
    save("kask.wav", kask())
    save("puf.wav", puf())
    save("can.wav", can())
    save("seviye.wav", seviye())
    save("oyun_sonu.wav", oyun_sonu())
    save("bip.wav", bip())
    save("bip_son.wav", bip_son())
