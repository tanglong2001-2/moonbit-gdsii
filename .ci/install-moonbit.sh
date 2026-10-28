#!/usr/bin/env bash
set -euo pipefail

# Versioned official archives; follow the official installer's SDK/core layout.
mapfile -t config < <(python3 - <<'PY'
import json
with open('.ci/toolchain.json', encoding='utf-8') as source:
    config = json.load(source)
for key in ('linuxArchive', 'linuxSha256', 'coreArchive', 'coreSha256'):
    print(config[key])
PY
)
export MOON_HOME="${RUNNER_TEMP:?}/gdsii-moonbit"
mkdir -p "$MOON_HOME/downloads" "$MOON_HOME/lib"
curl --fail --location --retry 3 --max-time 240 "${config[0]}" -o "$MOON_HOME/downloads/sdk.tar.gz"
printf '%s  %s\n' "${config[1]}" "$MOON_HOME/downloads/sdk.tar.gz" | sha256sum --check --strict
tar -xzf "$MOON_HOME/downloads/sdk.tar.gz" -C "$MOON_HOME"
curl --fail --location --retry 3 --max-time 120 "${config[2]}" -o "$MOON_HOME/downloads/core.tar.gz"
printf '%s  %s\n' "${config[3]}" "$MOON_HOME/downloads/core.tar.gz" | sha256sum --check --strict
tar -xzf "$MOON_HOME/downloads/core.tar.gz" -C "$MOON_HOME/lib"
export PATH="$MOON_HOME/bin:$PATH"
moon -C "$MOON_HOME/lib/core" bundle --target js --warn-list -a
moon -C "$MOON_HOME/lib/core" bundle --target wasm-gc --warn-list -a
# `moon info` writes the canonical interface from the default wasm backend.
moon -C "$MOON_HOME/lib/core" bundle --target wasm --warn-list -a
moon version --all
printf '%s\n' "$MOON_HOME/bin" >> "$GITHUB_PATH"
printf 'MOON_HOME=%s\n' "$MOON_HOME" >> "$GITHUB_ENV"
