# Gölge Eşleştirme sesleri: sadece Python standart kütüphanesiyle sentezlenir.
# Çalıştırma: python ses_uret.py   (bu klasöre .wav dosyalarını yazar)
# Sesler yumuşak ve kısa; tepe seviyesi -6 dBFS, başta/sonda kısa fade (tık sesi olmasın).

import math
import os
import struct
import wave

RATE = 44100
PEAK = 0.5  # -6 dBFS
HERE = os.path.dirname(os.path.abspath(__file__))


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


def pop() -> list:
    # Kısa, yukarı süzülen "pop"
    out = []
    phase = 0.0
    n = int(RATE * 0.09)
    for i in range(n):
        t = i / RATE
        freq = 380 + 900 * (t / 0.09) ** 0.6
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.003) * math.exp(-38 * t)
        out.append(math.sin(phase) * env)
    return out


def ding() -> list:
    out = bell(note("E6"), 0.8, 5.5)
    mix(out, bell(note("B6"), 0.7, 7.0), 0.0, 0.35)
    return out


def boing() -> list:
    # Yumuşak "boing": aşağı inip hafif yukarı dönen, titreşimli sinüs
    out = []
    phase = 0.0
    seconds = 0.45
    for i in range(int(RATE * seconds)):
        t = i / RATE
        x = t / seconds
        freq = 330 - 150 * math.sin(math.pi * min(x * 1.4, 1.0)) + 25 * math.sin(2 * math.pi * 14 * t) * (1 - x)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.01) * math.exp(-5.5 * t)
        out.append((math.sin(phase) + 0.15 * math.sin(2 * phase)) * env)
    return out


def melody(notes: list, step: float, tail: float) -> list:
    out = silence(step * len(notes) + tail)
    for k, name in enumerate(notes):
        if name:
            mix(out, soft_tone(note(name), tail + step), k * step)
    return out


def level_end() -> list:
    out = melody(["C5", "E5", "G5", "C6"], 0.13, 0.8)
    mix(out, bell(note("C7"), 0.6, 6.0), 0.52, 0.25)
    return out


def finale() -> list:
    lead = ["C5", "E5", "G5", "C6", "G5", "C6", "E6", "", "D6", "C6", "G5", "E5", "G5", "C6", "", ""]
    out = melody(lead, 0.15, 0.9)
    # Alt armoni: uzun, yumuşak akorlar
    for start, chord in [(0.0, ["C4", "E4", "G4"]), (0.6, ["F4", "A4", "C5"]), (1.2, ["G4", "B4", "D5"]), (1.8, ["C4", "E4", "G4", "C5"])]:
        for name in chord:
            mix(out, soft_tone(note(name), 1.2), start, 0.3)
    # Sonda parıltılı çanlar
    for k, name in enumerate(["C7", "E7", "G7", "C8"]):
        mix(out, bell(note(name), 0.5, 7.0), 1.95 + k * 0.07, 0.15)
    return out


def save(name: str, samples: list) -> None:
    peak = max(abs(v) for v in samples) or 1.0
    fade = int(RATE * 0.005)
    n = len(samples)
    frames = bytearray()
    for i, v in enumerate(samples):
        g = min(1.0, i / fade, (n - 1 - i) / fade)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v / peak * PEAK * g)) * 32767))
    with wave.open(os.path.join(HERE, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(name, round(n / RATE, 2), "sn")


if __name__ == "__main__":
    save("pop.wav", pop())
    save("ding.wav", ding())
    save("boing.wav", boing())
    save("bolum_sonu.wav", level_end())
    save("final.wav", finale())
