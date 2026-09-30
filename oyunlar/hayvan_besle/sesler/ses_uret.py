# Hayvanları Besle sesleri: sadece Python standart kütüphanesiyle üretilir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav yazar, sonunda hepsini denetler)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Bütün sesler save_loudness() ile aynı algılanan yüksekliğe
# eşitlenir (tepe en fazla -6 dBFS); yumuşak, korkutmayan, kısa.
#
# - Oyun sesleri: pop (yiyecek tutulunca), hapur (çiğneme "hım hım"), yutma, guruldama (karın, kısık),
#   ih_ih (kibar ret: inen iki yumuşak ton), nokta (balondaki nokta dolunca), kikir (dokununca kıkırdama),
#   bolum_sonu (kutlama), final (son bölüm büyük kutlama melodisi).
# - Hayvan sesleri: kedi.wav, kopek.wav (CC0 kayıtlardan kesilmiş) ve inek.wav Müzik Kutusu'ndan KOPYADIR
#   (bu betik yazmaz; bkz. CREDITS.md). Tavşan, maymun, fare, ayı, sincap, panda ve kuş burada
#   çizgi film tarzında sentezlenir: YER TUTUCUDUR. Gerçek kayıtla değiştirmek için aynı adla bu klasöre koymak yeter.

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import (RATE, bandpass, bell, check_all, envelope, glide, lowpass, melody, mix, noise, note,  # noqa: E402
                    save_loudness, silence, smooth_env, soft_tone, sweep, voice)

TARGET = 0.1                      # ortak yükseklik (kısa pencere RMS); oyun içinde ayrıca dB ile ayarlanır


def save(name: str, samples: list, target: float = TARGET) -> None:
    save_loudness(HERE, name, samples, target)


# --- Oyun sesleri ---

def pop() -> list:
    # Kısa, yukarı süzülen yumuşak "pop"
    out = sweep(360, 1150, 0.1, 0.003, 36.0, 0.6)
    mix(out, sweep(720, 2300, 0.06, 0.002, 60.0, 0.6), 0.0, 0.15)
    return out


def chew() -> list:
    # "Hım hım": iki kısa, kapalı ağız mırıltısı ve üstünde hafif çıtırtı
    out = silence(0.42)
    for start, f in ((0.0, 190), (0.2, 170)):
        hum = voice(0.16, lambda t, f=f: glide([(0, f), (0.16, f * 0.9)], t), lambda t: smooth_env(t, 0.16, 0.02, 0.07),
                    lambda t: [(260, 80, 1.0), (900, 150, 0.2)], breath=0.05, seed=12)
        mix(out, hum, start)
        crunch = envelope(bandpass(noise(0.07, 40 + int(start * 10)), 1800, 5000), 0.002, 45.0)
        mix(out, crunch, start + 0.02, 0.35)
    return lowpass(out, 5000)


def gulp() -> list:
    # Yutma: aşağı kayan tok "gulp" ve küçük bir "blup"
    out = sweep(420, 150, 0.16, 0.006, 16.0, 0.8)
    mix(out, sweep(260, 520, 0.08, 0.004, 30.0, 0.7), 0.13, 0.5)
    return lowpass(out, 3000)


def rumble() -> list:
    # Karın guruldaması: pes, dalgalanan, yumuşak (ürkütücü değil)
    s = 0.9
    out = voice(s, lambda t: glide([(0, 70), (0.3, 95), (0.6, 75), (0.9, 88)], t) * (1 + 0.08 * math.sin(2 * math.pi * 9 * t)),
                lambda t: smooth_env(t, s, 0.15, 0.3) * (0.6 + 0.4 * math.sin(2 * math.pi * 5 * t) ** 2),
                lambda t: [(300, 120, 1.0), (620, 160, 0.4)], buzz=0.7, breath=0.3, seed=13)
    return lowpass(out, 1200)


def refuse() -> list:
    # "Iıh-ıh": inen iki yumuşak, kapalı ağız tonu (hayır ama tatlı)
    out = silence(0.55)
    for start, (f1, f2) in ((0.0, (330, 300)), (0.24, (280, 240))):
        part = voice(0.2, lambda t, a=f1, b=f2: glide([(0, a), (0.2, b)], t), lambda t: smooth_env(t, 0.2, 0.03, 0.09),
                     lambda t: [(320, 90, 1.0), (1100, 140, 0.25)], breath=0.04, seed=14)
        mix(out, part, start)
    return lowpass(out, 3500)


def dot() -> list:
    # Nokta dolunca: tatlı kısa çan
    out = bell(note("A5"), 0.5, 7.0)
    mix(out, bell(note("E6"), 0.4, 9.0), 0.04, 0.35)
    return out


def giggle() -> list:
    # Kıkırdama: hızla inip çıkan üç kısa "hi"
    out = silence(0.5)
    for k, f in enumerate((780, 700, 820)):
        part = voice(0.09, lambda t, f=f: glide([(0, f), (0.09, f * 0.85)], t), lambda t: smooth_env(t, 0.09, 0.01, 0.04),
                     lambda t: [(700, 120, 1.0), (2300, 200, 0.4)], breath=0.25, seed=15 + k)
        mix(out, part, k * 0.13)
    return out


def level_end() -> list:
    out = melody(["C5", "E5", "G5", "E5", "C6"], 0.12, 0.8)
    mix(out, bell(note("C7"), 0.6, 6.0), 0.5, 0.25)
    for name in ["C4", "E4", "G4"]:
        mix(out, soft_tone(note(name), 1.0), 0.48, 0.18)
    return out


def finale() -> list:
    lead = ["G4", "C5", "E5", "G5", "E5", "G5", "C6", "", "A5", "G5", "E5", "C5", "D5", "E5", "C5", ""]
    out = melody(lead, 0.15, 0.9)
    for start, chord in [(0.0, ["C4", "E4", "G4"]), (0.6, ["F4", "A4", "C5"]), (1.2, ["A3", "C4", "E4"]), (1.8, ["G3", "B3", "D4"]),
                         (2.1, ["C4", "E4", "G4", "C5"])]:
        for name in chord:
            mix(out, soft_tone(note(name), 1.2), start, 0.28)
    for k, name in enumerate(["C7", "E7", "G7", "C8"]):
        mix(out, bell(note(name), 0.5, 7.0), 2.2 + k * 0.07, 0.15)
    return out


# --- Hayvanlar (çizgi film tarzı sentez, yer tutucu) ---

def rabbit() -> list:
    # Tavşan: burnunu çeken minik, tiz "fıs-fıs" ve kısa sevimli "ii"
    out = silence(0.6)
    for start in (0.0, 0.11):
        sniff = envelope(bandpass(noise(0.07, 21), 2500, 7000), 0.01, 40.0)
        mix(out, sniff, start, 0.5)
    squeak = voice(0.22, lambda t: glide([(0, 900), (0.1, 1150), (0.22, 950)], t), lambda t: smooth_env(t, 0.22, 0.02, 0.1),
                   lambda t: [(1200, 150, 1.0), (2800, 220, 0.4)], breath=0.1, seed=22)
    mix(out, squeak, 0.28)
    return out


def monkey() -> list:
    # Maymun: "u-u-a-a!" dört hece, yükselen
    out = silence(0.95)
    syll = [(0.0, 380, 330), (0.17, 420, 360), (0.36, 560, 640), (0.56, 640, 720)]
    for k, (start, f1, f2) in enumerate(syll):
        vowel_u = k < 2
        part = voice(0.14, lambda t, a=f1, b=f2: glide([(0, a), (0.14, b)], t), lambda t: smooth_env(t, 0.14, 0.015, 0.05),
                     (lambda t: [(380, 90, 1.0), (900, 120, 0.4)]) if vowel_u else (lambda t: [(850, 130, 1.0), (1300, 150, 0.6)]),
                     breath=0.12, seed=23 + k)
        mix(out, part, start)
    return out


def mouse() -> list:
    # Fare: iki minik "cik"
    out = silence(0.4)
    for k, start in enumerate((0.0, 0.16)):
        part = voice(0.08, lambda t: glide([(0, 2100), (0.04, 2600), (0.08, 2200)], t), lambda t: smooth_env(t, 0.08, 0.008, 0.035),
                     lambda t: [(2400, 300, 1.0), (4200, 400, 0.3)], breath=0.05, seed=27 + k)
        mix(out, part, start)
    return out


def bear() -> list:
    # Ayı: yumuşak, keyifli "hımmm-ooh" (pes ama sıcak, gürlemeyen)
    s = 0.9
    return lowpass(voice(s, lambda t: glide([(0, 120), (0.35, 150), (0.9, 110)], t),
                         lambda t: smooth_env(t, s, 0.12, 0.3),
                         lambda t: [(glide([(0, 300), (0.4, 550)], t), 100, 1.0), (glide([(0, 900), (0.4, 950)], t), 140, 0.4)],
                         breath=0.15, seed=29), 2500)


def squirrel() -> list:
    # Sincap: hızlı, tiz "çık-çık-çık"
    out = silence(0.5)
    for k in range(4):
        part = voice(0.05, lambda t: glide([(0, 1500), (0.05, 1250)], t), lambda t: smooth_env(t, 0.05, 0.004, 0.025),
                     lambda t: [(1500, 250, 1.0), (3200, 350, 0.5)], breath=0.35, seed=30 + k)
        mix(out, part, k * 0.09)
    return out


def panda() -> list:
    # Panda: yavru gibi yumuşak, burundan "mee-eh"
    s = 0.6
    return voice(s, lambda t: glide([(0, 500), (0.2, 580), (0.6, 460)], t) * (1 + 0.04 * math.sin(2 * math.pi * 6 * t)),
                 lambda t: smooth_env(t, s, 0.05, 0.2),
                 lambda t: [(glide([(0, 450), (0.2, 650)], t), 100, 1.0), (1700, 150, 0.5)],
                 breath=0.08, seed=34)


def bird() -> list:
    # Kuş: iki cıvıltı ("cik-cirik")
    out = silence(0.5)
    for start, pts in ((0.0, [(0, 2600), (0.06, 3400)]), (0.14, [(0, 2400), (0.05, 3600), (0.12, 2800)])):
        dur = pts[-1][0] + 0.02
        chirp = []
        phase = 0.0
        for i in range(int(RATE * dur)):
            t = i / RATE
            phase += 2 * math.pi * glide(pts, t) / RATE
            chirp.append(math.sin(phase) * smooth_env(t, dur, 0.008, 0.02))
        mix(out, chirp, start)
    return out


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    save("pop.wav", pop())
    save("hapur.wav", chew())
    save("yutma.wav", gulp())
    save("guruldama.wav", rumble(), TARGET * 0.7)
    save("ih_ih.wav", refuse())
    save("nokta.wav", dot())
    save("kikir.wav", giggle())
    save("bolum_sonu.wav", level_end())
    save("final.wav", finale())
    save("tavsan.wav", rabbit())
    save("maymun.wav", monkey())
    save("fare.wav", mouse(), TARGET * 0.8)
    save("ayi.wav", bear())
    save("sincap.wav", squirrel(), TARGET * 0.85)
    save("panda.wav", panda())
    save("kus.wav", bird(), TARGET * 0.8)
    if not check_all(HERE):
        print("\nDenetim: SORUN VAR")
        sys.exit(1)
    print("\nDenetim: hepsi tamam")
