# Müzik Kutusu sesleri: sadece Python standart kütüphanesiyle üretilir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav yazar, sonunda hepsini denetler)
# Ortak yardımcılar ortak/ses/sentez.py içinde. Bütün sesler save_loudness() ile aynı algılanan yüksekliğe
# eşitlenir (tepe en fazla -6 dBFS), başı ve sonu yumuşak kesilir.
#
# - Ksilofon: ksilofon_1..8.wav (Do5 ... Do6), her nota ayrı sentezlenir.
# - Davul seti: bas, trampet, tom_ince, tom_kalin, zil, marakas.
# - Hayvanlar: kedi, köpek, inek, koyun, ördek, horoz, kurbağa kaynak/ içindeki CC0 kayıtlardan kesilir (bkz.
#   CREDITS.md); kayıt yoksa sentez kullanılır. Aslan hâlâ sentezlenmiş yer tutucudur; gerçek kayıtla
#   değiştirmek için aynı adla (aslan.wav) bu klasöre koymak yeter.
# - kutlama.wav: şarkı bitince çalan kısa neşeli arpej.

import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "kaynak")
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "ortak", "ses"))
from sentez import (RATE, bandpass, bell, check_all, envelope, glide, highpass, lowpass, melody, mix, noise, note,  # noqa: E402
                    read_wav, save_loudness, silence, smooth_env, soft_tone, voice)

TARGET = 0.1                      # bütün seslerin ortak yüksekliği (kısa pencere RMS)
XYLO_NOTES = ["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"]


def save(name: str, samples: list, target: float = TARGET) -> None:
    save_loudness(HERE, name, samples, target)


# --- Ksilofon ---

def xylophone(freq: float) -> list:
    # Ahşap tuş: temel + ayarlı 3. kısmi (xylofonlarda ~3f) + tiz kısmiler; hepsi üstel söner, tizler daha hızlı.
    # 2.76f'deki küçük kısmi hafif metalik (çelik ksilofon) bir parıltı katar. Başta tokmağın kısa "tık"ı.
    out = []
    for i in range(int(RATE * 1.3)):
        t = i / RATE
        attack = min(1.0, t / 0.0015)
        v = math.sin(2 * math.pi * freq * t) * math.exp(-4.2 * t)
        v += 0.32 * math.sin(2 * math.pi * freq * 3.0 * t) * math.exp(-13.0 * t)
        v += 0.10 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-9.0 * t)
        v += 0.07 * math.sin(2 * math.pi * freq * 6.27 * t) * math.exp(-32.0 * t)
        out.append(v * attack)
    click = envelope(lowpass(noise(0.02, 7), 3500), 0.0005, 260.0)
    mix(out, click, 0.0, 0.35)
    return out


# --- Davul seti ---

def pitch_drop(f_start: float, f_end: float, drop: float, seconds: float, decay: float, second: float = 0.0) -> list:
    # Perdesi üstel olarak f_start'tan f_end'e hızla düşen sinüs (davul gövdesi); second: 2. harmonik oranı
    out = []
    phase = 0.0
    for i in range(int(RATE * seconds)):
        t = i / RATE
        freq = f_end + (f_start - f_end) * math.exp(-drop * t)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.001) * math.exp(-decay * t)
        out.append((math.sin(phase) + second * math.sin(2 * phase)) * env)
    return out


def bass_drum() -> list:
    # Bas davul: 170 Hz'ten 55 Hz'e düşen tok gövde (+2. harmonik telefon hoparlöründe duyulsun diye) ve tık
    out = pitch_drop(170, 55, 28.0, 0.7, 6.5, 0.35)
    mix(out, envelope(lowpass(noise(0.03, 3), 3000), 0.0005, 180.0), 0.0, 0.4)
    return out


def snare() -> list:
    # Trampet: iki kısa ton + bant geçiren gürültü (tel sesi)
    out = pitch_drop(240, 190, 30.0, 0.4, 18.0)
    mix(out, pitch_drop(360, 330, 30.0, 0.3, 24.0), 0.0, 0.5)
    wires = envelope(bandpass(noise(0.4, 11), 1500, 7000), 0.001, 13.0)
    mix(out, wires, 0.0, 1.4)
    return soften_peaks(out, 1.8)


def tom(f_start: float, f_end: float) -> list:
    out = pitch_drop(f_start, f_end, 14.0, 0.75, 6.5, 0.15)
    mix(out, envelope(bandpass(noise(0.08, 5), 400, 3000), 0.001, 60.0), 0.0, 0.35)
    return out


def cymbal() -> list:
    # Zil: tiz gürültü + birbirine oransız metalik kısmiler, uzun yumuşak sönüm. En tiz ucu kırpılır (kulak tırmalamasın).
    seconds = 2.2
    rng = random.Random(21)
    partials = [(f, rng.uniform(0, math.tau)) for f in (342, 527, 811, 1107, 1383, 1627, 2139, 2786, 3541, 4210)]
    tone = []
    for i in range(int(RATE * seconds)):
        t = i / RATE
        tone.append(sum(math.sin(2 * math.pi * f * t + p) for f, p in partials) / len(partials))
    hiss = bandpass(noise(seconds, 23), 3000, 8500)
    out = [(0.5 * a + 1.6 * b) for a, b in zip(tone, hiss)]
    out = [v * min(1.0, (i / RATE) / 0.004) * math.exp(-2.4 * i / RATE) for i, v in enumerate(out)]
    return lowpass(out, 9000)


def soften_peaks(samples: list, drive: float = 2.5) -> list:
    # Gürültülü vurmalıların tek tük sivri tepelerini yumuşatır (tanh); tepe inince aynı tepe sınırında daha dolgun duyulur
    peak = max(abs(v) for v in samples) or 1.0
    return [math.tanh(drive * v / peak) for v in samples]


def maracas() -> list:
    # Marakas: iki kısa tiz gürültü patlaması ("çık-çık"), ikincisi biraz daha kısık
    out = silence(0.36)
    for start, gain, seed in ((0.0, 1.0, 31), (0.14, 0.7, 32)):
        burst = envelope(bandpass(noise(0.12, seed), 3500, 10000), 0.006, 38.0)
        mix(out, burst, start, gain)
    return soften_peaks(out)


# --- Hayvanlar (çizgi film tarzı sentez) ---

def cow() -> list:
    # "Möö": derin, alçak perde; kapalı "m" ile başlayıp "öö"ye açılır
    s = 1.3
    return lowpass(voice(
        s,
        lambda t: glide([(0, 105), (0.35, 128), (1.3, 92)], t),
        lambda t: smooth_env(t, s, 0.12, 0.35),
        lambda t: [(glide([(0, 260), (0.3, 420)], t), 90, 1.0), (glide([(0, 700), (0.3, 1250)], t), 120, 0.5), (2400, 200, 0.12)],
        breath=0.08, seed=3), 3000)


def sheep() -> list:
    # "Mee": titrek (7 Hz vibrato + genlik titremesi) "e" ünlüsü
    s = 0.95
    return voice(
        s,
        lambda t: glide([(0, 360), (0.15, 400), (0.95, 350)], t) * (1 + 0.07 * math.sin(2 * math.pi * 7 * t)),
        lambda t: smooth_env(t, s, 0.05, 0.25) * (0.7 + 0.3 * math.sin(2 * math.pi * 7 * t)),
        lambda t: [(glide([(0, 350), (0.1, 520)], t), 90, 1.0), (1900, 140, 0.7), (2600, 200, 0.3)],
        breath=0.05, seed=4)


def duck() -> list:
    # "Vak vak": burundan, vızıltılı iki kısa ses
    out = silence(0.52)
    for start in (0.0, 0.25):
        q = 0.17
        part = voice(
            q,
            lambda t: glide([(0, 330), (0.17, 250)], t),
            lambda t, q=q: smooth_env(t, q, 0.012, 0.06),
            lambda t: [(900, 110, 1.0), (1650, 130, 0.8), (2800, 220, 0.3)],
            breath=0.1, seed=5)
        mix(out, part, start)
    return out


def rooster() -> list:
    # "Ü-ürü-üüü": dört hece, son hece uzun ve önce yükselip sonra iner
    out = silence(1.45)
    syllables = [(0.0, 0.13, [(0, 560), (0.13, 620)]), (0.18, 0.13, [(0, 700), (0.13, 760)]),
                 (0.35, 0.15, [(0, 780), (0.15, 820)]), (0.55, 0.8, [(0, 800), (0.2, 900), (0.8, 640)])]
    for start, length, contour in syllables:
        part = voice(
            length,
            lambda t, c=contour: glide(c, t) * (1 + 0.01 * math.sin(2 * math.pi * 30 * t)),
            lambda t, n=length: smooth_env(t, n, 0.02, min(0.06, n / 3) if n < 0.5 else 0.25),
            lambda t: [(320, 90, 1.0), (1750, 150, 0.6), (2700, 220, 0.25)],
            breath=0.15, seed=6)
        mix(out, part, start)
    return out


def frog() -> list:
    # "Vrak vrak": 32 Hz'lik titreşimle "rrr"lı iki kısa vraklama
    out = silence(0.62)
    for start in (0.0, 0.3):
        q = 0.22
        part = voice(
            q,
            lambda t: glide([(0, 190), (0.22, 160)], t),
            lambda t, q=q: smooth_env(t, q, 0.015, 0.06) * (0.35 + 0.65 * max(0.0, math.sin(2 * math.pi * 32 * t))),
            lambda t: [(620, 120, 1.0), (1150, 150, 0.6)],
            breath=0.05, seed=7)
        mix(out, part, start)
    return lowpass(out, 3500)


def lion() -> list:
    # Korkutmayan, yumuşak "roaar": yavaş başlar (ani yüksek ses yok), hırıltı için gürültü, "a" ünlüsü
    s = 1.2
    return lowpass(voice(
        s,
        lambda t: glide([(0, 85), (0.4, 125), (1.2, 80)], t) * (1 + 0.04 * math.sin(2 * math.pi * 23 * t)),
        lambda t: smooth_env(t, s, 0.18, 0.45),
        lambda t: [(glide([(0, 500), (0.35, 750)], t), 140, 1.0), (1150, 160, 0.6), (2500, 250, 0.15)],
        buzz=0.8, breath=0.6, seed=8), 2500)


def cat_synth() -> list:
    # Kayıt yoksa: "miyav" (i -> a -> u, perde önce yükselir sonra düşer)
    s = 0.7
    return voice(
        s,
        lambda t: glide([(0, 520), (0.3, 760), (0.7, 480)], t),
        lambda t: smooth_env(t, s, 0.04, 0.2),
        lambda t: [(glide([(0, 350), (0.3, 850), (0.7, 450)], t), 110, 1.0),
                   (glide([(0, 2300), (0.3, 1350), (0.7, 900)], t), 150, 0.6)],
        breath=0.05, seed=9)


def dog_synth() -> list:
    # Kayıt yoksa: iki kısa "hav"
    out = silence(0.55)
    for start in (0.0, 0.28):
        q = 0.16
        part = voice(q, lambda t: glide([(0, 420), (0.16, 280)], t), lambda t, q=q: smooth_env(t, q, 0.008, 0.08),
                     lambda t: [(750, 130, 1.0), (1300, 160, 0.6)], breath=0.4, seed=10)
        mix(out, part, start)
    return out


# --- CC0 kayıtlardan kesme ---

def cut(samples: list, start: float, end: float, fade: float = 0.012) -> list:
    part = samples[int(start * RATE):int(end * RATE)]
    size = int(fade * RATE)
    n = len(part)
    return [v * min(1.0, i / size, (n - 1 - i) / size) for i, v in enumerate(part)]


def from_recording(file: str, start: float, end: float, fallback) -> tuple:
    path = os.path.join(SOURCE, file)
    if os.path.exists(path):
        samples = cut(read_wav(path), start, end)
        return highpass(samples, 60.0), "kayıt (CC0): " + file
    return fallback(), "sentez (kayıt bulunamadı)"


# --- Kutlama ---

def celebration() -> list:
    out = melody(["C5", "E5", "G5", "C6", "", "G5", "C6"], 0.11, 0.9)
    for k, name in enumerate(["E6", "G6", "C7"]):
        mix(out, bell(note(name), 0.6, 6.0), 0.5 + k * 0.09, 0.25)
    for name in ["C4", "E4", "G4"]:
        mix(out, soft_tone(note(name), 1.4), 0.55, 0.2)
    return out


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    for k, name in enumerate(XYLO_NOTES):
        save("ksilofon_%d.wav" % (k + 1), xylophone(note(name)))
    save("bas.wav", bass_drum())
    save("trampet.wav", snare())
    save("tom_ince.wav", tom(250, 205))
    save("tom_kalin.wav", tom(165, 130))
    save("zil.wav", cymbal(), TARGET * 0.8)          # uzun ve tiz: biraz daha kısık
    save("marakas.wav", maracas())
    kinds = {}
    samples, kinds["kedi.wav"] = from_recording("cat_mewfood.wav", 0.5, 1.08, cat_synth)
    save("kedi.wav", samples)
    samples, kinds["kopek.wav"] = from_recording("dog_barking_mono.wav", 0.0, 0.82, dog_synth)
    save("kopek.wav", samples)
    for name, file, start, end, fallback in (("inek.wav", "cow_moo_0546.wav", 0.12, 1.28, cow),
                                             ("koyun.wav", "sheep_2343.wav", 0.0, 0.85, sheep),
                                             ("ordek.wav", "ducks_0276.wav", 0.06, 0.95, duck),
                                             ("horoz.wav", "rooster_0283.wav", 0.05, 2.15, rooster),
                                             ("kurbaga.wav", "frog_ribbit_03.wav", 0.0, 0.5, frog)):
        samples, kinds[name] = from_recording(file, start, end, fallback)
        if name == "kurbaga.wav":
            samples = soften_peaks(samples, 3.0)       # kısa ve keskin tepeli kayıt: yoksa diğerlerinden kısık kalır
        save(name, samples)
    save("aslan.wav", lion(), TARGET * 0.85)
    kinds["aslan.wav"] = "sentez (yer tutucu)"
    save("kutlama.wav", celebration())
    print("\nHayvan sesleri:")
    for name, kind in kinds.items():
        print("  %-12s %s" % (name, kind))
    if not check_all(HERE):
        sys.exit("\nDenetimde sorun var!")
    print("\nDenetim: hepsi tamam")
