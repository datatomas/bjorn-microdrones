#!/usr/bin/env python3
"""Create original synthetic woof cues; no downloaded recordings or dependencies."""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 32000
ROOT = Path(__file__).resolve().parent


def woof(pitch, duration, seed):
    rng = random.Random(seed)
    phase = 0.0
    noise = 0.0
    result = []
    for i in range(round(RATE * duration)):
        t = i / RATE
        progress = t / duration
        phase += 2 * math.pi * pitch * (1.3 - 0.45 * progress) / RATE
        noise = 0.72 * noise + 0.28 * rng.uniform(-1, 1)
        voice = sum(math.sin(phase * h) / h for h in range(1, 10)) / 1.8
        envelope = min(1, t / 0.008) * (1 - progress) ** 1.6
        rasp = 0.85 + 0.15 * math.sin(2 * math.pi * 43 * t)
        result.append(0.7 * envelope * rasp * (0.7 * voice + 0.3 * noise))
    return result


def save(name, samples):
    with wave.open(str(ROOT / name), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, s)) * 32767)) for s in samples))


save('bjbark.wav', woof(170, 0.18, 7))
save('bjwait.wav', woof(110, 0.18, 8) + [0] * round(RATE * 0.12) + woof(100, 0.18, 9))
print('Generated bjbark.wav (180 ms) and bjwait.wav (480 ms), mono PCM16 at 32 kHz')
