#!/usr/bin/env python3
"""Original, deliberately restrained frontier sound effects (MIT, no samples)."""

import math
from pathlib import Path
import random
import struct
import wave


def write(name, duration, synth):
    rate = 48000
    rng = random.Random(1876)
    samples = []
    for i in range(round(rate * duration)):
        t = i / rate
        attack = min(1, (i + 1) / (rate * 0.0005))
        release = min(1, (duration - t) / 0.025)
        value = synth(t, rng) * attack * release
        samples.append(round(max(-0.35, min(0.35, value)) * 32767))
    with wave.open(str(Path(__file__).with_name(name)), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(struct.pack("<" + "h" * len(samples), *samples))


def creak(t, rng):
    wood = math.sin(math.tau * (210 * t + 35 * t * t + 0.5 * math.sin(45 * t)))
    rasp = rng.uniform(-1, 1) * (0.2 + 0.2 * math.sin(190 * t) ** 2)
    return 0.11 * math.exp(-t * 22) * (0.75 * wood + rasp)


def shot(t, rng):
    crack = rng.uniform(-1, 1) * math.exp(-t * 100)
    body = math.sin(math.tau * (110 * t + 1.3 * (1 - math.exp(-t * 40)))) * math.exp(-t * 32)
    wood = rng.uniform(-1, 1) * math.exp(-t * 18) * (0.25 + 0.75 * math.sin(230 * t) ** 8)
    return 0.25 * crack + 0.11 * body + 0.08 * wood


if __name__ == "__main__":
    write("cowboy-creak.wav", 0.18, creak)
    write("cowboy-shot.wav", 0.3, shot)
