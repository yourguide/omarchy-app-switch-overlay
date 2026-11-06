#!/usr/bin/env python3
"""Generate the original Neon Circuit connection sound (MIT, no samples)."""

import math
from pathlib import Path
import random
import struct
import wave


def generate():
    rate = 48000
    duration = 0.16
    rng = random.Random(23)
    samples = []
    phase = 0.0
    for i in range(round(rate * duration)):
        t = i / rate
        attack = min(1.0, (i + 1) / (rate * 0.0015))
        release = min(1.0, (duration - t) / 0.025)
        envelope = attack * math.exp(-t * 26) * release
        phase += math.tau * (680 + 280 * math.exp(-t * 38)) / rate
        tone = math.sin(phase) + 0.2 * math.sin(phase * 1.5)
        transient = rng.uniform(-1, 1) * math.exp(-t * 110)
        value = 0.18 * envelope * (tone * 0.75 + transient * 0.25)
        samples.append(round(max(-1, min(1, value)) * 32767))
    with wave.open(str(Path(__file__).with_name("neon-circuit.wav")), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(struct.pack("<" + "h" * len(samples), *samples))


if __name__ == "__main__":
    generate()
