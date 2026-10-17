# Real bark recording

- Title: Single Dog Bark
- Creator: kwahmah_02
- Source: https://freesound.org/people/kwahmah_02/sounds/277058/
- License: CC0 1.0 Universal, https://creativecommons.org/publicdomain/zero/1.0/
- Download: https://cdn.freesound.org/previews/277/277058_4486188-hq.mp3
- Retrieved: 2026-10-17

The bundled `source-bark.mp3` is the public high-quality preview of the
recording, retained for reproducibility. The source page describes a clean
single dog bark without ambient noise and explicitly licenses it under CC0.

`generate_barks.py` uses ffmpeg to downmix and resample it into mono PCM16
at 32 kHz, pad/trim to 0.4 seconds and fade the last 20 ms. `bjbark.wav`
is the single bark; `bjwait.wav` repeats it twice with a 0.2-second gap.
These replace the earlier synthesized sounds. No claim is made about the
recorded dog's breed. The simple pixel dog icon is original repository art.
