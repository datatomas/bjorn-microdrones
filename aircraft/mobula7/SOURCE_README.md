# Mobula 7 Betaflight setup

Configuration for a Mobula 7 1S with the **HAMO CRAZYBEEF4SX1280** flight controller, based on the local Betaflight 2026.6.2 exports. Each CLI file can be applied independently:

Repository description: **Mobula 7 1S Betaflight firmware and independent VTX, ARM, and flight mode CLI settings for CRAZYBEEF4SX1280.**

| File | Changes |
| --- | --- |
| [config/vtx.cli](config/vtx.cli) | Six-band VTX table and Raceband R8 at 5917 MHz, power level 3 |
| [config/arm-aux1.cli](config/arm-aux1.cli) | ARM on AUX1 high; AUX1 low disarms |
| [config/flight-modes-aux3.cli](config/flight-modes-aux3.cli) | ANGLE on AUX3 low, HORIZON on AUX3 middle, ACRO on AUX3 high |

## Firmware image

The supplied local firmware image is [firmware/betaflight_2026.6.1_STM32F411_CRAZYBEEF4SX1280_00f70332FINAL2.hex](firmware/betaflight_2026.6.1_STM32F411_CRAZYBEEF4SX1280_00f70332FINAL2.hex). It is an Intel HEX file for the `CRAZYBEEF4SX1280` target. Its filename says **2026.6.1**, while the configuration exports used for this repository report **2026.6.2**. The exact build provenance and whether this image produced those exports have not been verified. Keep a backup of the current flight controller configuration before flashing, and confirm the target and version shown by Betaflight Configurator after flashing.

SHA-256:

```text
ed0fe8c7947e4bb7b5278802544947e072ca98e470e0adb7f288167250eaaa98  firmware/betaflight_2026.6.1_STM32F411_CRAZYBEEF4SX1280_00f70332FINAL2.hex
```

To check the downloaded file, run `sha256sum firmware/*.hex` from the repository directory and compare it with the value above.

### Get a newer firmware build from Betaflight

1. Remove the propellers and save a current `diff all` backup before flashing. Open **Betaflight Configurator → Firmware Flasher**. You can choose the firmware build **before connecting** to the flight controller.
2. In **Board & Build**, select `CRAZYBEEF4SX1280` and choose the newest compatible version offered in the version list. The reference screenshot shows **2026.6.2**; that is the version selected in the screenshot, not a promise that it is still the newest release. Use **Detect** only when the controller is connected and the detected target matches. See the [Board & Build screenshot](docs/images/firmware-board-and-build.png).
3. Enable **Expert Mode** to reveal **Custom Defines**. Select the build features needed by this board, including the radio and VTX options. Add the gyro driver define for the **actual gyro chip on your board** in Custom Defines before building. This is a build option, not a CLI command to paste after flashing. The screenshot's Custom Defines field is empty, so it does not record which define was used. Betaflight's [target definition](https://github.com/betaflight/unified-targets/blob/master/configs/default/HAMO-CRAZYBEEF4SX1280.config) lists several possible gyro chips; a define for one chip should not be assumed to work on every board revision. Betaflight documents the [Custom Defines syntax](https://betaflight.com/docs/wiki/app/firmware-flasher-tab#custom-defines) For the Mobula7 / CRAZYBEEF4SX1280, the custom define we used was ACCGYRO_LSM6DSV16X:.
4. Choose **Load Firmware [Online]** and wait for the build to complete. On the **Flash** tab, confirm the target and version, then flash. See the [Flash screenshot](docs/images/firmware-flash.png). Save the generated HEX file if you want to preserve the exact build you used.
5. Reconnect and check the reported target and firmware version. In **Sensors** or CLI `status`, confirm a gyro is detected before restoring configuration or attempting to arm. If the gyro is missing, verify the physical gyro chip and rebuild with its matching driver define.

The included local HEX is a separate saved image whose filename says 2026.6.1. The screenshots show an online build of 2026.6.2; they do not establish that the included HEX is that same build.

## Switches and video

| Function | Radio channel | Active position | Betaflight CLI |
| --- | --- | --- | --- |
| ARM | AUX1 | High, 1700–2100 µs | `aux 0 0 0 1700 2100 0 0` |
| DISARM | AUX1 | Low, below 1700 µs | ARM range inactive; no separate CLI mode |
| ANGLE | AUX3 | Low, 900–1300 µs | `aux 1 1 2 900 1300 0 0` |
| HORIZON | AUX3 | Middle, 1300–1700 µs | `aux 2 2 2 1300 1700 0 0` |
| ACRO | AUX3 | High, above 1700 µs | No mode range; default when neither self-leveling mode is active |

Set the radio's ARM switch to output AUX1 and its three-position flight mode switch to output AUX3. These are **channel assignments**, not physical switch names; your transmitter may call the switches something else. Keep ARM low while setting up. At the 1300 µs boundary, check the selected mode in Betaflight and adjust the ranges if your radio output sits on an edge.

VTX is set to **Raceband R8, 5917 MHz, power level 3 (label 25)**. The CLI includes all six bands and eight channels from the saved VTX table. The power labels are the source configuration's labels; verify actual output and legal frequencies for your hardware and location. Match goggles to R8 before powering up for a test.

## Apply

1. Remove propellers. In Betaflight Configurator, connect and save a fresh `diff all` backup for this exact flight controller.
2. Confirm the target is `CRAZYBEEF4SX1280` and firmware accepts the CLI commands. To flash the included image, use Betaflight Configurator's **Firmware Flasher** to load the local HEX file, flash it, then reconnect and confirm the reported target, version, and gyro detection. To build a newer image, follow the steps above. Do not flash either image to another board.
3. Open **CLI** and paste one desired file at a time. Each file ends with `save`, which reboots the controller. Reconnect before applying another file. The files have no dependency on one another; apply all three for the complete setup.
4. In **Receiver**, confirm AUX1 goes low/high with the arm switch and AUX3 goes low/middle/high with the mode switch. In **Modes**, confirm ARM, ANGLE and HORIZON activate only in the expected positions. Check that ACRO is selected at AUX3 high.
5. With propellers still removed, check motor direction, receiver failsafe, arming behavior, and the VTX channel in Betaflight. Refit propellers only after these checks.

These files are **incremental setups**: they do not run `defaults nosave` or restore unrelated calibration, PID, radio binding, motor, or OSD values from an old export. Back up and check those settings separately after any firmware flash. The saved `expresslrs_uid` and board `mcu_id` are intentionally omitted from the public setup.

## Source notes

- VTX table, R8 channel and power level: `mobula7-vtx-restore.txt` and `BTFL_cli_backup_20261001_163829_CRAZYBEEF4SX1280FINAL2.txt`.
- AUX1 ARM and AUX3 ANGLE/HORIZON mapping: `modesaux.txt` (the newer mode mapping supplied in this folder).
- Earlier exports differ: the September 2026 backup uses AUX2 for flight modes, and its ARM threshold starts at 1850 µs. This setup follows `modesaux.txt`; confirm the radio's actual channel output before flight.

## Push changes to GitHub

The repository and `origin` already exist. The firmware and documentation are committed locally; from this repository directory, publish that commit with:

```bash
git push origin main
```

If this is a different checkout without a remote, add the existing repository with `git remote add origin https://github.com/datatomas/mobula_7.git` before pushing.

To set the GitHub repository description after pushing:

```bash
gh repo edit datatomas/mobula_7 --description "Mobula 7 1S Betaflight firmware and independent VTX, ARM, and flight mode CLI settings for CRAZYBEEF4SX1280"
```
