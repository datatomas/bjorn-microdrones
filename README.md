# Bjorn FPV lab

Configuration lab for three distinct Betaflight aircraft. Each aircraft has its own target, firmware, receiver, modes, and VTX settings. Apply only the CLI files for the matching aircraft after checking the live hardware.

| Aircraft | Target / firmware | Source | Status |
| --- | --- | --- | --- |
| [Bjorn 2.5-inch carbon quad](aircraft/bjorn-25/README.md) | SPEEDYBEEF405MINI / Betaflight 4.4.2 | Configuration and diagnostics supplied in this conversation | Proposed mode and analog VTX snippets; flight tune not validated |
| [Apex 3-inch quad](aircraft/apex-3/README.md) | Target and firmware unknown | Owner-reported ELRS on UART4, Rush Tank Mini SmartAudio on UART5 | Proposed modes and VTX table; ports and hardware pending verification |
| [Mobula 7 1S](aircraft/mobula7/README.md) | CRAZYBEEF4SX1280 / Betaflight 2026.6.x | Curated files copied from local `mobula_7` repo | Source configuration; firmware provenance caveat retained |

## Use

1. Remove propellers. Save a fresh `diff all` from the exact flight controller.
2. Read the aircraft README and verify target, receiver channels, and wiring.
3. Apply one CLI file at a time. A `save` command reboots the controller.
4. Verify receiver, modes, failsafe, motors, and video before flight.

The CLI files are incremental. They do not reset the board or restore calibration, binding, motor mapping, or PID data. Do not cross-apply files between aircraft.

## Agent lab

[AGENTS.md](AGENTS.md) sets the operating rules. [inventory.yaml](inventory.yaml) identifies hardware and evidence. [docs/backlog.md](docs/backlog.md) records open checks for future automated agents. No agent is authorized by this repository to flash, arm, spin motors, or publish changes unattended.


# open betaflight
chromium https://app.betaflight.com/
