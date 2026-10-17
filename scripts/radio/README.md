# Radio scripts (EdgeTX / RadioMaster Pocket)

Lua scripts for the handheld radio, not the aircraft. Target hardware:
RadioMaster Pocket, EdgeTX, 128x64 mono screen, internal ExpressLRS module.

## Contents

| File | Origin | Purpose |
|------|--------|---------|
| `bjorn-elrs-finder.lua` | ours | Finder using `TRSS`/`1RSS` RSSI first, then SNR/link-quality fallbacks, with a numeric strength bar, source label, tip, peak marker, and simple floppy-eared pixel dog. Screen title: `BJORN FINDER`. |
| `bjorn-elrs-finder-simple.lua` | ours | Archived minimal alternative; not installed by the current upload script. |
| `ELRS_Finder.lua` | [iamsunilchahal/edgetx-lua-scripts-bw](https://github.com/iamsunilchahal/edgetx-lua-scripts-bw) | Community reference finder (kept for comparison). |
| `ELRS-Finder-Pro.lua` | [nerdCopter/ELRS-Finder-Pro](https://github.com/nerdCopter/ELRS-Finder-Pro) | Community finder with automatic TX-power stepping. |
| `upload_radio_scripts.sh` | ours | Installs `bjfind`, `elfind`, and `elpro` under `SCRIPTS/TOOLS`, removes their stale compiled caches, and verifies the copies. Bjorn telemetry is optional. |
| `simulate_finders.lua` | ours | Desktop-only EdgeTX API simulation for the two Bjorn finders. |

## Reinstall the three finder tools

Run these commands from the **Bjorn repository**, not from another checkout.
`/dev/sde1` was the Pocket partition on 2026-10-17; device letters can change.
Identify the radio's approximately 239 MB FAT partition each time. The
placeholder `/dev/sdX1` is not a working device path.

```bash
cd /home/ares/Documents/gitrepos/bjorn-microdrones
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
sudo mkdir -p /mnt/radio
sudo mount -o rw /dev/sde1 /mnt/radio       # use the partition found above
findmnt /mnt/radio -o SOURCE,FSTYPE,OPTIONS # confirm the source and rw
scripts/radio/upload_radio_scripts.sh
sync
sudo umount /mnt/radio
```

The installer prints a temporary backup directory for the previous finder
files and byte-verifies the new copies. It installs `bjfind`, `elfind`, and
`elpro` in **SYS → Tools**, removes old `bjsimp` copies and known compiled
`.luac` caches for these names, and removes old finder telemetry-screen copies.
Other factory radio scripts are left alone. Reboot the radio after unmounting.

### Recorded reinstall (2026-10-17)

Observed on the connected Pocket: `/dev/sde1` was the 239.3 MB FAT volume.
The first attempt failed because `/dev/sdX1` was copied literally and the
command was run from `k3s-platform-lab`, where this installer does not exist.
The volume initially appeared read only. After unmounting, a read-only
`fsck.vfat -n` reported the existing `TBSAgentLite.` filename fragment;
mounting with `-o rw` then succeeded. The old finder files were backed up
under `/tmp/bjorn-radio-files.r5RpfF` and by the final installer under
`/tmp/bjorn-radio-backup.JQQ9Im` (temporary local paths).

The final installer run byte-verified `bjfind.lua`, `elfind.lua`, and
`elpro.lua` in `SCRIPTS/TOOLS`. Directory inspection showed no `bjsimp`,
no finder `.luac` caches, no old `zztest.lua` diagnostic, and no finder
copies in `SCRIPTS/TELEMETRY`. The card was synced and unmounted. These are
filesystem observations; appearance in **SYS → Tools** and behavior with a
powered Mobula 7 still need confirmation on the radio.

Later that day, the updated `bjfind.lua` with the waiting bar, pixel dog,
and raw RSSI readout was copied and byte-verified on the same card, then
synced and unmounted. The live telemetry result remains unverified.

The subsequent source/strength/tip update added SNR and link-quality
fallbacks and a distinct no-signal chirp. Its `bjfind.lua` copy was again
byte-verified on the card, synced, and unmounted. The Pocket's live sensor
values and audible behavior remain to be checked with the powered model.

To keep **Bjorn Finder** on a telemetry screen too, use
`scripts/radio/upload_radio_scripts.sh /mnt/radio --bjorn-telemetry` instead
of the installer command above, then assign `bjfind` in **Model → Display**.
The two community scripts remain Tools entries only.

If `findmnt` reports `ro`, do not run the installer. Unmount and inspect the
FAT filesystem without repairing it:

```bash
sudo umount /mnt/radio
sudo fsck.vfat -n /dev/sde1               # use the current radio partition
sudo mount -o rw /dev/sde1 /mnt/radio
findmnt /mnt/radio -o SOURCE,FSTYPE,OPTIONS
```

Proceed only if the filesystem mounted `rw`. The 2026-10-17 read-only check
reported the previously documented orphaned `TBSAgentLite.` long-name
fragment and no additional error. These commands do not flash EdgeTX or
change Mobula 7 firmware; the finder Lua files live on the Pocket.

### If a script is missing from the Tools list

Once a copy on the radio got corrupted (a NUL byte replaced the first `-`
of the `toolName` header, so EdgeTX silently skipped it). The upload
script's `cmp` check catches this. To check an existing card by hand:

```bash
head -1 /mnt/radio/SCRIPTS/TOOLS/elpro.lua | od -c | head -1
# good:  -   -       t   o   o   l   N   a   m   e  ...
# bad:  \0   -       t   o   o   l   N   a   m   e  ...  -> re-run the upload script
```

Always let `sync` and unmount complete before unplugging. A damaged header
alone does not establish what caused the corruption.

### Pocket TOOLS directory repair (2026-10-16)

Observed on the connected RadioMaster Pocket's ~239 MB FAT16 partition:

- Linux listed all four short-name scripts in both `SCRIPTS/TOOLS` and
  `SCRIPTS/TELEMETRY`. Their contents matched between folders and contained
  no NUL bytes. The radio still did not list the new tools.
- An unmounted `fsck.vfat -n` reported an orphaned `TBSAgentLite.` long-name
  fragment. The two FAT allocation tables were identical.
- Reading the raw TOOLS directory revealed a premature `0x00` entry at
  directory-relative byte offset 1536, before `zztest` and all four new
  scripts. A FAT directory reader stops at that marker; Linux's directory
  listing nevertheless exposed the later entries. This explained why a
  successful `cp`/`cmp` did not guarantee visibility on the radio.

Repair performed on the unmounted partition:

1. Read the FAT boot-sector geometry, followed the root directory to
   `SCRIPTS`, then followed its `TOOLS` cluster chain. Inspected the raw
   32-byte directory entries, including entries beyond the first end marker.
2. Confirmed that the premature marker preceded the expected new script
   entries. Its partition-relative byte offset on **this filesystem** was
   1820160.
3. Saved the original TOOLS directory cluster to the private local file
   `/tmp/bjorn-tools-directory-before-repair.bin`, with its starting disk
   offset in the adjacent `.offset` file. These temporary files are not
   repository artifacts and may disappear. A full-partition backup was
   started but interrupted because of slow transfer; that partial image
   must not be treated as a complete backup.
4. Changed only the premature entry's first byte from `0x00` (end of
   directory) to `0xE5` (deleted entry), then flushed the device with `fsync`.
   Readers can skip the deleted entry and continue to the later scripts.
5. Read the directory again using stop-at-end-marker semantics: it now
   reached `ZZTEST`, `BJSIMP`, `BJFIND`, `ELFIND`, and `ELPRO`. A final
   read-only `fsck.vfat -n` still reported the separate TBSAgentLite
   long-name warning. The partition was left unmounted.

Do not reuse those byte offsets on another filesystem or after directory
changes. Any repeat repair needs a fresh device identification, unmount,
backup, geometry/cluster inspection, and verification of the exact entry
before writing. The scripts used for this investigation were temporary
diagnostics, not a general-purpose repair utility.

Hardware verification: the directory bytes were read back from the attached
radio after repair. Visibility in **SYS -> Tools** after unplugging and a
full power cycle has not yet been confirmed. The cause of the premature
marker and the remaining TBSAgentLite filename damage are unresolved.

## Install the finders in SYS -> Tools

These three scripts run from the radio's **SYS -> Tools** page. The repo keeps
the descriptive source filenames; the SD card copies use short names so the
radio's Tools list can display them clearly.

1. Power the radio on, connect USB, and choose **USB storage mode**.
2. Follow the [reinstall commands](#reinstall-the-three-finder-tools) above.
3. Reboot the radio, then open **SYS -> Tools**. Look for `bjfind`,
   `elfind`, and `elpro`. If they appear in the radio's SD Card browser under
   `SCRIPTS/TOOLS` but not in Tools after a reboot, record the EdgeTX version
   from **SYS -> Version** for troubleshooting.

## Optional: use the Bjorn finder on a telemetry screen

Telemetry scripts run on a model's **Model -> Display** screen. Use the
`--bjorn-telemetry` installer option above to copy only `bjfind.lua` into
`SCRIPTS/TELEMETRY/`, then reboot and assign it to a Script screen.

## First-time setup

1. Power the drone, confirm ELRS link is up.
2. On the radio, use **Model -> Telemetry -> Discover new sensors**. Confirm
   that `TRSS` appears for the preferred downlink reading, or `1RSS` for the
   uplink fallback. `TQly` and `RQly` help detect a lost telemetry stream.
3. Both the Tools and telemetry-screen finders need live ELRS telemetry from
   the selected model to report signal strength.

## Using a finder in the field

- Keep TX power fixed while comparing readings. Lower it manually if the
  reading saturates and the link has adequate margin. The Bjorn scripts do
  not change transmitter power; ELRS Finder Pro has a separate power editor.
- Slow single barks = weaker RSSI. Fast single barks = stronger RSSI.
  The full finder shows its source, raw reading with the correct unit, a
  smoothed strength percentage, a bar, and a peak marker. Press Enter to
  open or close sensor diagnostics. Reopen the tool to reset the peak. `TRSS` is radio-side downlink RSSI;
  `1RSS` is model-side uplink RSSI.
- If neither RSSI source is available, the full finder checks `TSNR`,
  `RSNR`, `TQly`, `RQly`, then legacy `RSSI`. SNR is shown in dB and link
  quality in percent. These are coarse link-health clues, not dBm or a
  distance estimate; their bark rate is capped. Antenna orientation,
  obstructions, and power settings also affect every reading.
- If no usable source exists, the full finder shows `NO SIGNAL`, `Src:NA`,
  and `Str:--`, with a distinct double bark every 3 seconds. It does
  not emit the single proximity bark. The archived simple finder still shows
  `NO TELEMETRY` and stays silent.
- The full Bjorn screen keeps its empty bar and dog visible while waiting.
  It shows the raw `TRSS` (`TR`) and `1RSS` (`1R`) values. If both
  are zero, verify the selected model, receiver power, and **Model → Telemetry
  → Discover new sensors** with propellers removed. EdgeTX returns zero for a
  missing or stopped telemetry source. The community finders still draw a bar
  and may beep at their default weak-signal value when both sources are zero;
  that sound does not prove the model is linked.
- Only works while the lost drone's battery still powers the receiver.
  For the last few meters use a buzzer or Betaflight DShot beacon
  (motor chirp on a switch) instead.

## Desktop simulation

```bash
lua scripts/radio/simulate_finders.lua
```

This stubs the EdgeTX LCD, tone, time, and telemetry APIs. It checks source
selection, RSSI/SNR/link-quality fallback, no-signal double bark, telemetry
recovery, the waiting bar and dog, numeric strength, sensor diagnostics,
text bounds and logo separation, and script exit. It does
not verify performance on a powered model or confirm radio installation.

Hardware verification pending: with propellers removed, select the intended
model, confirm the live sensor names and downlink updates on the Pocket, and
compare both finder screens while moving the radio. Record the EdgeTX and
ExpressLRS versions before treating the behavior as verified on hardware.

The sensor definitions above follow the [ExpressLRS FAQ](https://www.expresslrs.org/faq/),
and the script behavior follows the [EdgeTX Lua telemetry API](https://luadoc.edgetx.org/lua-api-reference/variables/getvalue)
and [telemetry script guide](https://luadoc.edgetx.org/overview/script-types/telemetry-scripts).

## Updating community copies

```bash
curl -L -o scripts/radio/ELRS_Finder.lua \
  https://raw.githubusercontent.com/iamsunilchahal/edgetx-lua-scripts-bw/main/SCRIPTS/TOOLS/ELRS_Finder.lua
curl -L -o scripts/radio/ELRS-Finder-Pro.lua \
  https://raw.githubusercontent.com/nerdCopter/ELRS-Finder-Pro/master/ELRS-Finder-Pro.lua
```

## Briard layout and missing-signal diagnosis (2026-10-17)

The finder now reserves the upper-right corner for a simple pixel dog
face with floppy ears, eyes and a muzzle. The reading, source, strength,
peak and bar occupy separate rows. Enter opens/closes a sensor screen;
tones pause while that screen is open. The peak resets when the tool reopens.

On the sensor screen, `--` means the named sensor is unavailable to Lua;
`0` means the sensor exists but currently returns zero. A zero RSSI is not
a usable dBm reading. `TR`/`1R` mean TRSS/1RSS; `TS`/`RS` mean TSNR/RSNR;
`TQ`/`RQ` mean TQly/RQly, and `RI` means legacy RSSI. A double bark on
`NO SIGNAL` only confirms that the script is running.

To obtain a real reading, with propellers removed:

1. Select the correct model on the Pocket, power the receiver and confirm
   the ExpressLRS link is established.
2. In the ExpressLRS Lua tool, check that **Telem Ratio** is not **Off**.
3. Open **Model → Telemetry → Discover new sensors**, wait for sensors,
   then stop discovery. Check whether `TRSS` or `1RSS` updates live.
4. Reopen Bjorn Finder and press Enter. Record the seven displayed values
   if it still says `NO SIGNAL`. Missing sensors point to discovery/names;
   existing zero readings require checking the live link and telemetry.
5. If the Mobula 7 uses an integrated SPI ELRS receiver, inspect its
   Betaflight Receiver tab telemetry setting. Confirm the actual board,
   receiver type and installed Betaflight version before changing settings.
   No flight-controller changes or flashing are part of this script update.

See the official [ExpressLRS troubleshooting guide](https://www.expresslrs.org/quick-start/troubleshooting/)
and [sensor discovery instructions](https://www.expresslrs.org/quick-start/pre-1stflight/).

Observed on hardware: the user reports audible chirps and `NO SIGNAL` with
an earlier script. The revised layout and sensor view are desktop-checked;
live signal acquisition and appearance on the Pocket still need confirmation.
Use the reinstall commands above to transfer this revision.

## Bark sounds

The installer also backs up, copies and byte-verifies `sounds/bjbark.wav`
and `sounds/bjwait.wav` under `/SOUNDS/bjorn/` on the radio. Run the same
reinstall commands above for both the Lua script and its sounds.

- A single 400 ms recorded bark repeats every 1.8 seconds at minimum strength,
  accelerating to every 0.6 seconds at maximum RSSI strength.
- A double bark repeats every 3 seconds when there is no usable signal.
- Enter pauses finder sounds while the sensor diagnostic screen is open.
- The radio's WAV volume controls bark loudness. If silent, check that
  volume and use the SD browser to play `/SOUNDS/bjorn/bjbark.wav` directly.

The sound is a real dog recording: **Single Dog Bark** by **kwahmah_02**,
released under CC0. The original downloaded preview, converted WAVs and
[source/license details](sounds/SOURCES.md) are kept in the repository.
Both WAV assets are mono, 16-bit PCM at 32 kHz. Regenerate them with
`python3 scripts/radio/sounds/generate_barks.py` (requires `ffmpeg`).
The shortest repetition interval exceeds the bark duration. Desktop checks
verify scheduling and WAV format; sound quality and audio queue behavior on
the Pocket remain to be checked. The script uses the documented EdgeTX
[playFile API](https://luadoc.edgetx.org/lua-api-reference/audio-sound/playfile)
and [supported WAV format](https://github.com/EdgeTX/edgetx-sdcard-sounds).
