# Büyükten Küçüğe sesleri: sadece Python standart kütüphanesiyle üretilir (dışarıdan ses yok).
# Çalıştırma: python ses_uret.py   (bu klasöre .wav yazar, sonunda hepsini denetler)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Bütün sesler save_loudness() ile aynı algılanan yüksekliğe
# eşitlenir; yumuşak, kısa, korkutmayan. Olumsuz (hata) sesi yok: yanlış hamlede sadece yumuşak "geri" sesi.
#
# - pop: nesne tutulunca
# - nota_0 .. nota_5: doğru yerleşme notaları (pentatonik, 0 = en büyük nesne = en pes, 5 = en küçük = en tiz).
#   Kule tamamlanırken ve kutlamada nesneler büyükten küçüğe bu notalarla küçük bir melodi çalar.
# - kayma: halkanın çubuktan aşağı kayması (ahşap üstünde yumuşak "vıjjt")
# - tok: bebeğin açılıp kapanması (ahşap "tok"; kapanırken biraz tiz çalınır)
# - firla: bebeğin içinden dışarı fırlaması
# - geri: yanlış yerden yumuşakça geri dönüş (inen, kısık "vuup")
# - yildiz: kulenin tepesine yıldız konunca çan
# - bolum_sonu, final: kutlamalar

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import (RATE, bandpass, bell, check_all, envelope, lowpass, melody, mix, noise, note,  # noqa: E402
                    save_loudness, silence, soft_tone, sweep)

TARGET = 0.1
NOTES = ["C5", "D5", "E5", "G5", "A5", "C6"]


def save(name: str, samples: list, target: float = TARGET) -> None:
    save_loudness(HERE, name, samples, target)


def pop() -> list:
    out = sweep(360, 1150, 0.1, 0.003, 36.0, 0.6)
    mix(out, sweep(720, 2300, 0.06, 0.002, 60.0, 0.6), 0.0, 0.15)
    return out


def marimba(name: str) -> list:
    # Tahta tokmaklı ksilofon gibi: yumuşak temel + kısa parlak vuruş
    f = note(name)
    out = soft_tone(f, 0.9)
    mix(out, bell(f * 2.0, 0.5, 9.0), 0.0, 0.25)
    mix(out, envelope(bandpass(noise(0.02, 3), 1500, 5000), 0.001, 200.0), 0.0, 0.15)
    return out


def slide() -> list:
    # Halka çubuktan kayar: inen yumuşak ton ve sürtünme hışırtısı
    out = sweep(820, 360, 0.36, 0.02, 3.0, 0.8)
    rub = bandpass(noise(0.36, 5), 900, 3000)
    rub = [v * min(1.0, i / (RATE * 0.03)) * math.exp(-4.0 * i / RATE) for i, v in enumerate(rub)]
    mix(out, rub, 0.0, 0.25)
    return lowpass(out, 4000)


def knock() -> list:
    # Ahşap "tok": kısa, rezonanslı, hızlı sönen
    out = sweep(820, 620, 0.16, 0.001, 30.0, 0.5)
    mix(out, sweep(1650, 1300, 0.06, 0.001, 60.0, 0.5), 0.0, 0.3)
    mix(out, envelope(bandpass(noise(0.015, 8), 2000, 6000), 0.0005, 300.0), 0.0, 0.3)
    return out


def spring_out() -> list:
    # Bebek fırlar: yukarı kıvrılan "fuiit"
    out = sweep(300, 1400, 0.22, 0.004, 9.0, 1.6)
    mix(out, sweep(600, 2600, 0.14, 0.003, 18.0, 1.6), 0.02, 0.2)
    return out


def back() -> list:
    # Yumuşak geri dönüş: inen, kısık, kısa "vuup" (hata sesi değil)
    out = sweep(520, 300, 0.24, 0.02, 7.0, 0.7)
    return lowpass(out, 1800)


def star() -> list:
    out = silence(0.9)
    for k, name in enumerate(["G6", "C7", "E7"]):
        mix(out, bell(note(name), 0.7, 6.0), k * 0.07, 0.5)
    return out


def level_end() -> list:
    out = melody(["C5", "E5", "G5", "E5", "C6"], 0.12, 0.8)
    mix(out, bell(note("C7"), 0.6, 6.0), 0.5, 0.25)
    for name in ["C4", "E4", "G4"]:
        mix(out, soft_tone(note(name), 1.0), 0.48, 0.18)
    return out


def finale() -> list:
    lead = ["C5", "D5", "E5", "G5", "A5", "C6", "", "A5", "G5", "E5", "G5", "C6", "", "", "C6", ""]
    out = melody(lead, 0.15, 0.9)
    for start, chord in [(0.0, ["C4", "E4", "G4"]), (0.6, ["F4", "A4", "C5"]), (1.2, ["A3", "C4", "E4"]), (1.8, ["G3", "B3", "D4"]),
                         (2.1, ["C4", "E4", "G4", "C5"])]:
        for name in chord:
            mix(out, soft_tone(note(name), 1.2), start, 0.28)
    for k, name in enumerate(["C7", "E7", "G7", "C8"]):
        mix(out, bell(note(name), 0.5, 7.0), 2.2 + k * 0.07, 0.15)
    return out


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    save("pop.wav", pop())
    for k, name in enumerate(NOTES):
        save(f"nota_{k}.wav", marimba(name))
    save("kayma.wav", slide(), TARGET * 0.7)
    save("tok.wav", knock())
    save("firla.wav", spring_out(), TARGET * 0.8)
    save("geri.wav", back(), TARGET * 0.6)
    save("yildiz.wav", star())
    save("bolum_sonu.wav", level_end())
    save("final.wav", finale())
    if not check_all(HERE):
        print("\nDenetim: SORUN VAR")
        sys.exit(1)
    print("\nDenetim: hepsi tamam")
