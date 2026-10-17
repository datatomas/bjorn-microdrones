#!/usr/bin/env bash
# Install the three selected finder tools on a mounted RadioMaster Pocket.
# Usage: scripts/radio/upload_radio_scripts.sh [mountpoint] [--bjorn-telemetry]
# Run from any directory. Identify the actual radio partition before mounting.
set -euo pipefail

MNT=${1:-/mnt/radio}
TELEMETRY=${2:-none}
if [[ "$TELEMETRY" != none && "$TELEMETRY" != --bjorn-telemetry ]]; then
    printf 'Usage: %s [mountpoint] [--bjorn-telemetry]\n' "$0" >&2
    exit 2
fi
mountpoint -q "$MNT"
if ! findmnt -no OPTIONS "$MNT" | tr ',' '\n' | rg -qx rw; then
    printf 'Radio mount is read only: %s\n' "$MNT" >&2
    exit 1
fi

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
stage=$(mktemp -d /tmp/bjorn-radio-stage.XXXXXX)
trap 'rm -rf "$stage"' EXIT
backup=$(mktemp -d /tmp/bjorn-radio-backup.XXXXXX)
mkdir -p "$backup/TOOLS" "$backup/TELEMETRY"
for dir in TOOLS TELEMETRY; do
    for name in bjfind.lua bjfind.luac bjsimp.lua bjsimp.luac elfind.lua elfind.luac elpro.lua elpro.luac bjorn-elrs-finder.lua bjorn-elrs-finder-simple.lua zztest.lua; do
        if [[ -f "$MNT/SCRIPTS/$dir/$name" ]]; then
            cp -p "$MNT/SCRIPTS/$dir/$name" "$backup/$dir/$name"
        fi
    done
done

make_tool() { # source-file dest-name display-title
    printf '%s\n' "-- toolName = TNS|$3|TNE" > "$stage/$2.lua"
    cat "$REPO_ROOT/scripts/radio/$1" >> "$stage/$2.lua"
}
make_tool bjorn-elrs-finder.lua bjfind "Bjorn Finder"
make_tool ELRS_Finder.lua       elfind "ELRS Finder"
make_tool ELRS-Finder-Pro.lua   elpro  "ELRS Finder Pro"

sudo mkdir -p "$MNT/SCRIPTS/TOOLS" "$MNT/SCRIPTS/TELEMETRY"
for name in bjfind elfind elpro; do
    sudo cp "$stage/$name.lua" "$MNT/SCRIPTS/TOOLS/$name.lua"
    sudo cmp "$stage/$name.lua" "$MNT/SCRIPTS/TOOLS/$name.lua"
done

# Old compiled copies can shadow new Lua sources. Remove only these known files.
for name in bjfind.luac bjsimp.lua bjsimp.luac elfind.luac elpro.luac zztest.lua; do
    sudo rm -f "$MNT/SCRIPTS/TOOLS/$name"
done

# Keep telemetry screens opt-in; only Bjorn is useful there for this setup.
for name in bjfind.lua bjsimp.lua elfind.lua elpro.lua bjorn-elrs-finder.lua bjorn-elrs-finder-simple.lua; do
    sudo rm -f "$MNT/SCRIPTS/TELEMETRY/$name"
done
if [[ "$TELEMETRY" == --bjorn-telemetry ]]; then
    sudo cp "$stage/bjfind.lua" "$MNT/SCRIPTS/TELEMETRY/bjfind.lua"
    sudo cmp "$stage/bjfind.lua" "$MNT/SCRIPTS/TELEMETRY/bjfind.lua"
fi
sync
printf 'Installed bjfind, elfind, elpro in TOOLS; telemetry: %s\n' "$TELEMETRY"
printf 'Previous finder copies backed up at %s\n' "$backup"
printf 'Now run: sync && sudo umount %s\n' "$MNT"
