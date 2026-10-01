# Tren Rayı sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Yumuşak arayüz ve kutlama sesleri; ani ya da sert ses yok.
# Trenin kendi sesleri (düdük, "çuf çuf", fren) burada üretilmez: gerçek buhar kayıtlarından hazırlanıp
# ortak seslere kondu (ortak/sesler/tren_*.ogg, kaynaklar ortak/sesler/SESLER.md).

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import RATE, bell, envelope, highpass, lowpass, melody, mix, noise, note, save_loudness, silence, sweep  # noqa: E402


def save(name: str, samples: list, target: float = 0.1) -> None:
    save_loudness(HERE, name + ".wav", samples, target)


def tik() -> list:
    # Parça döndü: tahta "tık" + küçük yukarı kayan "klik"
    out = silence(0.18)
    mix(out, envelope(lowpass(noise(0.04, 3), 2400), 0.001, 90.0), 0.0, 0.9)
    mix(out, sweep(900, 1400, 0.05, attack=0.001, decay=60.0), 0.012, 0.5)
    return out


def civata() -> list:
    # Sabit parça: dönmeyen, yumuşak metal "tonk"
    out = silence(0.35)
    mix(out, bell(310, 0.3, decay=16.0), 0.0, 0.8)
    mix(out, envelope(lowpass(noise(0.03, 5), 900), 0.001, 80.0), 0.0, 0.5)
    return out


def tamam() -> list:
    # Yol istasyona bağlandı: parlak üç notalı çan
    out = silence(0.8)
    for k, n in enumerate(["G5", "B5", "D6"]):
        mix(out, bell(note(n), 0.6, decay=6.0), k * 0.09, 0.6)
    return out






def soru() -> list:
    # "Hım?": yumuşakça yükselen iki ton
    out = silence(0.6)
    mix(out, sweep(330, 360, 0.2, attack=0.02, decay=4.0), 0.0, 0.8)
    mix(out, sweep(360, 560, 0.3, attack=0.02, decay=4.0, curve=1.6), 0.22, 0.8)
    return out


def yolcu() -> list:
    # Yolcu bindi: "pop" + tek çan
    out = silence(0.6)
    mix(out, sweep(420, 900, 0.1, attack=0.003, decay=24.0, curve=0.6), 0.0, 0.8)
    mix(out, bell(note("E6"), 0.5, decay=7.0), 0.1, 0.55)
    return out


def varis() -> list:
    # İstasyon çanı: ding-dong
    out = silence(1.3)
    mix(out, bell(note("E5"), 1.0, decay=3.5), 0.0, 0.8)
    mix(out, bell(note("C5"), 1.0, decay=3.5), 0.35, 0.8)
    return out


def kutlama() -> list:
    return melody(["C5", "E5", "G5", "C6", None, "G5", "C6"], 0.11, 0.6)


def vagon() -> list:
    # Vagon eklendi: metal "klank" + parıltılı arpej
    out = silence(1.0)
    mix(out, bell(220, 0.25, decay=18.0), 0.0, 0.7)
    mix(out, envelope(lowpass(noise(0.06, 17), 1200), 0.001, 50.0), 0.0, 0.6)
    for k, n in enumerate(["C6", "E6", "G6", "C7"]):
        mix(out, bell(note(n), 0.4, decay=9.0), 0.18 + k * 0.07, 0.35)
    return out


def yildiz() -> list:
    # Bütün yolcular alındı: ek yıldız
    out = silence(1.0)
    for k, n in enumerate(["G5", "C6", "E6", "G6", "C7"]):
        mix(out, bell(note(n), 0.5, decay=6.0), k * 0.06, 0.45)
    return out


def dokun() -> list:
    return sweep(500, 760, 0.08, attack=0.002, decay=30.0, curve=0.6)


if __name__ == "__main__":
    save("tik", tik())
    save("civata", civata())
    save("tamam", tamam())
    save("soru", soru())
    save("yolcu", yolcu())
    save("varis", varis())
    save("kutlama", kutlama())
    save("vagon", vagon())
    save("yildiz", yildiz())
    save("dokun", dokun())
