# Oyun seslerini sentezlemek için ortak yardımcılar (sadece Python standart kütüphanesi).
# Oyunların sesler/ses_uret.py betikleri bunu içe aktarır:
#     sys.path.insert(0, <proje>/ortak/ses);  from sentez import *
# Sesler yumuşak ve kısa olsun: save() tepe seviyesini -6 dBFS'e ayarlar, başta/sonda kısa fade yapar.

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


def save(folder: str, name: str, samples: list) -> None:
    peak = max(abs(v) for v in samples) or 1.0
    fade = int(RATE * 0.005)
    n = len(samples)
    frames = bytearray()
    for i, v in enumerate(samples):
        g = min(1.0, i / fade, (n - 1 - i) / fade)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v / peak * PEAK * g)) * 32767))
    with wave.open(os.path.join(folder, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(name, round(n / RATE, 2), "sn")
