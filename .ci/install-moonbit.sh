#!/usr/bin/env bash
set -euo pipefail

# The portable gate needs wasm for canonical `moon info`; the native gate
# bundles only its native core. Both modes use the same verified SDK archives.
case "${1:-portable}" in
  portable) targets=(js wasm-gc wasm) ;;
  native) targets=(native) ;;
  *) printf 'Expected portable or native install mode\n' >&2; exit 2 ;;
esac

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
# Official SDK archives ship the binaries without execute bits (mode 0664).
chmod +x "$MOON_HOME"/bin/* "$MOON_HOME/bin/internal/tcc"
curl --fail --location --retry 3 --max-time 120 "${config[2]}" -o "$MOON_HOME/downloads/core.tar.gz"
printf '%s  %s\n' "${config[3]}" "$MOON_HOME/downloads/core.tar.gz" | sha256sum --check --strict
tar -xzf "$MOON_HOME/downloads/core.tar.gz" -C "$MOON_HOME/lib"
export PATH="$MOON_HOME/bin:$PATH"
for target in "${targets[@]}"; do
  moon -C "$MOON_HOME/lib/core" bundle --target "$target" --warn-list -a
done
moon version --all
printf '%s\n' "$MOON_HOME/bin" >> "$GITHUB_PATH"
printf 'MOON_HOME=%s\n' "$MOON_HOME" >> "$GITHUB_ENV"
