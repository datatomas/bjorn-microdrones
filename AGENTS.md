# Agent instructions for Bjorn

- Treat each aircraft directory as a separate hardware target. Never copy a CLI setting between targets without verifying Betaflight version, board, wiring, and mode mapping.
- Separate observed facts, proposed settings, and unresolved questions in documentation. A conversation recommendation is not a measured flight tune.
- Before changing a CLI file, preserve its source and explain why the change is needed. Keep files incremental; never insert `defaults nosave` in an apply file.
- Do not commit raw `diff all` exports, ExpressLRS binding identifiers, MCU IDs, serial numbers, credentials, or personal data. Sanitize diagnostics first.
- Never automate flashing, arming, motor tests, or VTX power changes on attached hardware. Require a human to perform physical checks with props removed.
- Confirm current manufacturer and Betaflight documentation for version-specific commands and VTX tables.
- Run `python3 scripts/check_profiles.py` before proposing changes. Record what was verified on real hardware separately from static checks.
- Keep source Mobula 7 firmware and configs identifiable; its firmware image name reports 2026.6.1 while the source README discusses 2026.6.2 configuration exports.
