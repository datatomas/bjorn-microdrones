#!/usr/bin/env python3
"""Static checks for the curated Betaflight CLI snippets."""

from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]
cli_files = sorted((ROOT / "aircraft").glob("*/config/*.cli"))
assert len(cli_files) == 11, f"Expected eleven curated CLI files, found {len(cli_files)}"

for path in cli_files:
    lines = [line.strip() for line in path.read_text().splitlines()
             if line.strip() and not line.lstrip().startswith("#")]
    assert lines[-1] == "save", f"{path}: missing final save"
    assert lines.count("save") == 1, f"{path}: unexpected intermediate save"
    assert not any(line.startswith("defaults") for line in lines), f"{path}: contains defaults"
    assert not any(re.search(r"(mcu_id|expresslrs_uid|signature)", line, re.I)
                   for line in lines), f"{path}: device identifier"
    if "vtx" in path.name:
        bands = int(next(line.split()[2] for line in lines if line.startswith("vtxtable bands ")))
        channels = int(next(line.split()[2] for line in lines if line.startswith("vtxtable channels ")))
        definitions = [line for line in lines if line.startswith("vtxtable band ")]
        assert len(definitions) == bands, f"{path}: band count mismatch"
        assert all(len(line.split()) == 6 + channels for line in definitions), f"{path}: channel count mismatch"
        powers = int(next(line.split()[2] for line in lines if line.startswith("vtxtable powerlevels ")))
        for key in ("powervalues", "powerlabels"):
            values = next(line.split()[2:] for line in lines if line.startswith(f"vtxtable {key} "))
            assert len(values) == powers, f"{path}: {key} count mismatch"

firmware = next((ROOT / "aircraft/mobula7/firmware").glob("*.hex"))
digest = hashlib.sha256(firmware.read_bytes()).hexdigest()
assert digest == "ed0fe8c7947e4bb7b5278802544947e072ca98e470e0adb7f288167250eaaa98", "Firmware hash differs from source README"
print(f"Checked {len(cli_files)} CLI files and Mobula 7 firmware hash")
