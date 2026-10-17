#!/usr/bin/env python3
"""Convert the bundled CC0 dog recording into EdgeTX cues. Requires ffmpeg."""
from pathlib import Path
import subprocess
import wave

ROOT = Path(__file__).resolve().parent
subprocess.run([
    'ffmpeg', '-v', 'error', '-y', '-i', str(ROOT / 'source-bark.mp3'),
    '-ac', '1', '-ar', '32000', '-af',
    'atrim=duration=0.4,apad=whole_dur=0.4,afade=t=out:st=0.38:d=0.02',
    '-c:a', 'pcm_s16le', str(ROOT / 'bjbark.wav'),
], check=True)
with wave.open(str(ROOT / 'bjbark.wav'), 'rb') as source:
    frames = source.readframes(source.getnframes())
with wave.open(str(ROOT / 'bjwait.wav'), 'wb') as out:
    out.setparams((1, 2, 32000, 0, 'NONE', 'not compressed'))
    out.writeframes(frames + bytes(round(32000 * 0.2) * 2) + frames)
print('Converted real bark: single 0.4s; double 1.0s; mono PCM16 32kHz')
