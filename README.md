# Bjorn FPV lab

Configuration lab for three distinct Betaflight aircraft. Each aircraft has its own target, firmware, receiver, modes, and VTX settings. Apply only the CLI files for the matching aircraft after checking the live hardware.

| Aircraft | Target / firmware | Source | Status |
| --- | --- | --- | --- |
| [Bjorn 2.5-inch carbon quad](aircraft/bjorn-25/README.md) | SPEEDYBEEF405MINI / Betaflight 4.4.2 | Configuration and diagnostics supplied in this conversation | Proposed mode and analog VTX snippets; flight tune not validated |
| [Apex 3-inch quad](aircraft/apex-3/README.md) | Diatone Mamba F722, target `MAMBAF722_2022A`; Betaflight 2026.6.2 download selected, installation unverified (latest CLI backup reports 4.5.1) | Owner-reported ELRS on UART4, Rush Tank Mini SmartAudio on UART5 | Proposed modes and VTX table; ports and hardware pending verification |
| [Mobula 7 1S](aircraft/mobula7/README.md) | CRAZYBEEF4SX1280 / Betaflight 2026.6.x | Curated files copied from local `mobula_7` repo | Source configuration; firmware provenance caveat retained |

## Use

1. Remove propellers. Save a fresh `diff all` from the exact flight controller.
2. Read the aircraft README and verify target, receiver channels, and wiring.
3. Apply one CLI file at a time. A `save` command reboots the controller.
4. Verify receiver, modes, failsafe, motors, and video before flight.

The CLI files are incremental. They do not reset the board or restore calibration, binding, motor mapping, or PID data. Do not cross-apply files between aircraft.

## Inspecting and changing rates

Rates control how quickly the quad rotates for a given stick input; they are separate from PID tuning. In Betaflight Configurator, open **PID Tuning** and find **Rateprofile Settings** (the Rate Profile selector and rates graph). Depending on the Configurator version or window size, this section may be lower on the PID Tuning page, so scroll down. Select the profile you actually use for flight before editing it.

To inspect an Apex rate profile from the **CLI** tab, enter these one at a time. This example reads profile 0 and the pitch axis values; change `0` to the profile you want to inspect:

```text
rateprofile 0
get rates_type
get pitch_rc_rate
get pitch_expo
get pitch_srate
```

For all axes, throttle curve values, and saved rate differences, use [docs/inspect-current-rates.cli](docs/inspect-current-rates.cli). It prints values for the currently selected profile and does not change or save settings. In CLI, select the profile first with `rateprofile 0` (replace `0` with the profile number you want), then paste the file’s commands.

The `rateprofile` command selects the active rate profile; `get` only reads settings. To inspect saved changes across rate profiles, use `diff rates`. To apply a rate change, edit the values in **PID Tuning → Rateprofile Settings**, or use the matching `set` commands in CLI, then enter `save` to write and reboot. The Apex 3 [rates-config.cli](aircraft/apex-3/config/rates-config.cli) proposes reducing pitch center sensitivity (`pitch_rc_rate`) and maximum pitch rotation (`pitch_srate`) for a gentler stick response. It is not flight-tested; confirm the active rate profile, ACTUAL rates type, and live values before applying. No rate adjustment is proposed for the Mobula 7 or Bjorn 2.5.

## Radio finder scripts

[scripts/radio/README.md](scripts/radio/README.md) records the RadioMaster Pocket finder install and recovery process. The installer keeps three Tools entries: Bjorn Finder, ELRS Finder, and ELRS Finder Pro. It is separate from the Mobula 7 flight controller configuration.

## Agent lab

[AGENTS.md](AGENTS.md) sets the operating rules. [inventory.yaml](inventory.yaml) identifies hardware and evidence. [docs/backlog.md](docs/backlog.md) records open checks for future automated agents. No agent is authorized by this repository to flash, arm, spin motors, or publish changes unattended.


# open betaflight
chromium https://app.betaflight.com/
