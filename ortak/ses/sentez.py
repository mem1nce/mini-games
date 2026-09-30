# Oyun seslerini sentezlemek için ortak yardımcılar (sadece Python standart kütüphanesi).
# Oyunların sesler/ses_uret.py betikleri bunu içe aktarır:
#     sys.path.insert(0, <proje>/ortak/ses);  from sentez import *
# Sesler yumuşak ve kısa olsun: save() tepe seviyesini -6 dBFS'e ayarlar, başta/sonda kısa fade yapar.
# save_loudness() ise sesleri algılanan yüksekliğe göre eşitler (bir enstrümanın bütün sesleri aynı güçte).
# voice() / resonate(): formantlı çizgi film "ses teli" (hayvan sesleri). check_all(klasör): yazılan wav'ları denetler.

import math
import os
import random
import struct
import wave

RATE = 44100
PEAK = 0.5  # -6 dBFS


def note(name: str) -> float:
    # "C5", "E5", "G#4" gibi nota adlarını frekansa çevirir
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    key, octave = name[:-1], int(name[-1])
    semitone = names[key] + (octave - 4) * 12 - 9
    return 440.0 * 2.0 ** (semitone / 12.0)


def silence(seconds: float) -> list:
    return [0.0] * int(RATE * seconds)


def mix(target: list, source: list, start: float, gain: float = 1.0) -> None:
    offset = int(start * RATE)
    if len(target) < offset + len(source):
        target.extend([0.0] * (offset + len(source) - len(target)))
    for i, value in enumerate(source):
        target[offset + i] += value * gain


def bell(freq: float, seconds: float, decay: float = 5.0) -> list:
    # Çan: temel + iki yumuşak üst kısmi, üstel sönüm
    out = []
    for i in range(int(RATE * seconds)):
        t = i / RATE
        env = math.exp(-decay * t) * min(1.0, t / 0.004)
        v = math.sin(2 * math.pi * freq * t)
        v += 0.35 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-3 * t)
        v += 0.12 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-8 * t)
        out.append(v * env)
    return out


def soft_tone(freq: float, seconds: float) -> list:
    # Melodi notası: sinüs + biraz üst ses, yumuşak atak ve sönüm (marimba benzeri)
    out = []
    for i in range(int(RATE * seconds)):
        t = i / RATE
        env = min(1.0, t / 0.01) * math.exp(-3.2 * t)
        v = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * freq * 3.0 * t) * math.exp(-10 * t)
        out.append(v * env)
    return out


def melody(notes: list, step: float, tail: float) -> list:
    out = silence(step * len(notes) + tail)
    for k, name in enumerate(notes):
        if name:
            mix(out, soft_tone(note(name), tail + step), k * step)
    return out


def sweep(f_start: float, f_end: float, seconds: float, attack: float = 0.003, decay: float = 20.0, curve: float = 1.0) -> list:
    # Perdesi f_start'tan f_end'e kayan sinüs (pop, bonk gibi sesler için)
    out = []
    phase = 0.0
    n = int(RATE * seconds)
    for i in range(n):
        t = i / RATE
        freq = f_start + (f_end - f_start) * (i / n) ** curve
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        out.append(math.sin(phase) * env)
    return out


def noise(seconds: float, seed: int = 1) -> list:
    # Beyaz gürültü (aynı seed hep aynı sesi verir)
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(int(RATE * seconds))]


def lowpass(samples: list, cutoff: float) -> list:
    # Tek kutuplu alçak geçiren süzgeç: gürültüyü yumuşatır ("puf", "hışırtı")
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    out = []
    y = 0.0
    for v in samples:
        y += a * (v - y)
        out.append(y)
    return out


def envelope(samples: list, attack: float, decay: float) -> list:
    # attack saniyede yükselip üstel sönen zarf uygular
    return [v * min(1.0, (i / RATE) / attack) * math.exp(-decay * i / RATE) for i, v in enumerate(samples)]


def highpass(samples: list, cutoff: float) -> list:
    # Tek kutuplu yüksek geçiren süzgeç: tiz gürültü (zil, marakas) için
    low = lowpass(samples, cutoff)
    return [v - l for v, l in zip(samples, low)]


def bandpass(samples: list, low_cut: float, high_cut: float) -> list:
    return lowpass(highpass(samples, low_cut), high_cut)


def loudness(samples: list, window: float = 0.3) -> float:
    # Algılanan yükseklik için kaba ölçü: en yüksek kısa pencerenin (varsayılan 300 ms) RMS'i
    size = max(1, int(RATE * window))
    step = max(1, size // 4)
    best = 0.0
    for start in range(0, max(1, len(samples) - size + 1), step):
        part = samples[start:start + size]
        best = max(best, math.sqrt(sum(v * v for v in part) / len(part)))
    return best


def save_loudness(folder: str, name: str, samples: list, target: float = 0.1) -> None:
    # save() gibi, ama sesleri tepeye göre değil yüksekliğe (loudness) göre eşitler: hepsinin kısa pencere
    # RMS'i target olur. Tepe yine PEAK'i (-6 dBFS) geçmez; geçecekse ses biraz kısılır.
    level = loudness(highpass(samples, 100.0)) or 1.0   # çok pes kısım (telefon hoparlöründe duyulmaz) sayılmaz
    peak = max(abs(v) for v in samples) or 1.0
    _write(folder, name, samples, min(target / level, PEAK / peak))


def save(folder: str, name: str, samples: list) -> None:
    peak = max(abs(v) for v in samples) or 1.0
    _write(folder, name, samples, PEAK / peak)


def _write(folder: str, name: str, samples: list, gain: float) -> None:
    fade = int(RATE * 0.005)
    n = len(samples)
    frames = bytearray()
    for i, v in enumerate(samples):
        g = min(1.0, i / fade, (n - 1 - i) / fade)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v * gain * g)) * 32767))
    with wave.open(os.path.join(folder, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(name, round(n / RATE, 2), "sn")


# --- Ses teli ve formantlar (hayvan sesleri; Müzik Kutusu ve Hayvanları Besle kullanır) ---

def resonate(samples: list, formants) -> list:
    # Zamanla değişebilen formant süzgeçleri (ünlü rengi). formants(t) -> [(frekans, bant genişliği, kazanç), ...]
    out = [0.0] * len(samples)
    states = None
    for i, x in enumerate(samples):
        bank = formants(i / RATE)
        if states is None:
            states = [[0.0, 0.0] for _ in bank]
        y_total = 0.0
        for k, (freq, bw, gain) in enumerate(bank):
            r = math.exp(-math.pi * bw / RATE)
            a1 = -2 * r * math.cos(2 * math.pi * freq / RATE)
            a2 = r * r
            y = (1 - r) * x - a1 * states[k][0] - a2 * states[k][1]
            states[k][1] = states[k][0]
            states[k][0] = y
            y_total += y * gain
        out[i] = y_total
    return out


def voice(seconds: float, f0, amp, formants, buzz: float = 1.0, breath: float = 0.0, seed: int = 1) -> list:
    # Ses teli: testere dişi (buzz) + nefes gürültüsü, perde f0(t), genlik amp(t), sonra formantlar
    rng = random.Random(seed)
    source = []
    phase = 0.0
    for i in range(int(RATE * seconds)):
        t = i / RATE
        phase = (phase + f0(t) / RATE) % 1.0
        saw = 2.0 * phase - 1.0
        source.append((buzz * saw + breath * rng.uniform(-1, 1)) * amp(t))
    return resonate(source, formants)


def smooth_env(t: float, seconds: float, attack: float, release: float) -> float:
    if t < attack:
        return math.sin(0.5 * math.pi * t / attack)
    if t > seconds - release:
        return max(0.0, math.cos(0.5 * math.pi * (t - (seconds - release)) / release))
    return 1.0


def glide(points: list, t: float) -> float:
    # [(zaman, değer), ...] noktaları arasında yumuşak (kosinüs) geçiş
    if t <= points[0][0]:
        return points[0][1]
    for (t0, v0), (t1, v1) in zip(points, points[1:]):
        if t <= t1:
            k = (1 - math.cos(math.pi * (t - t0) / (t1 - t0))) / 2
            return v0 + (v1 - v0) * k
    return points[-1][1]


# --- Denetim ---

def read_wav(path: str) -> list:
    with wave.open(path, "rb") as f:
        channels, width, rate, n = f.getnchannels(), f.getsampwidth(), f.getframerate(), f.getnframes()
        data = f.readframes(n)
    if width != 2:
        raise ValueError("%s: sadece 16 bit WAV okunur" % path)
    values = struct.unpack("<%dh" % (n * channels), data)
    mono = [sum(values[i * channels:(i + 1) * channels]) / channels / 32768.0 for i in range(n)]
    if rate != RATE:
        ratio = rate / RATE
        mono = [mono[min(n - 1, int(i * ratio))] for i in range(int(n / ratio))]
    return mono


def count_clicks(s: list) -> int:
    # Tık: çevresindeki sese göre çok büyük, tek örneklik sıçrama (gürültülü seslerde doğal sıçramalar sayılmaz)
    size = int(RATE * 0.002)
    clicks = 0
    for i in range(1, len(s)):
        jump = abs(s[i] - s[i - 1])
        if jump < 0.05:
            continue
        around = s[max(0, i - size):i - 1] + s[i + 1:i + size]
        local = [abs(b - a) for a, b in zip(around, around[1:])]
        typical = sorted(local)[len(local) // 2] if local else 0.0
        if jump > 10 * typical + 0.02:
            clicks += 1
    return clicks


def check_all(folder: str) -> bool:
    # Yazılan her dosyayı geri okuyup denetler: tepe, baş/son yumuşaklığı, DC kayması, tık (ani sıçrama), yükseklik
    ok = True
    print("\n%-16s %6s %7s %7s %7s %6s" % ("dosya", "sn", "tepe dB", "yük. dB", "DC", "baş/son"))
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".wav"):
            continue
        s = read_wav(os.path.join(folder, name))
        peak = max(abs(v) for v in s)
        dc = sum(s) / len(s)
        edge = max(abs(s[0]), abs(s[-1]))
        level = loudness(highpass(s, 100.0))
        clicks = count_clicks(s)
        problems = []
        if peak > 0.51:
            problems.append("tepe -6 dBFS'i aşıyor")
        if edge > 0.002:
            problems.append("baş/son sessiz değil (tık)")
        if abs(dc) > 0.01:
            problems.append("DC kayması")
        if clicks:
            problems.append("%d tık/cızırtı" % clicks)
        if any(v != v for v in s):
            problems.append("NaN")
        ok = ok and not problems
        print("%-16s %6.2f %7.1f %7.1f %7.4f %6.4f %s" % (
            name, len(s) / RATE, 20 * math.log10(peak), 20 * math.log10(max(level, 1e-9)), dc, edge,
            " ".join(problems) or "tamam"))
    return ok
