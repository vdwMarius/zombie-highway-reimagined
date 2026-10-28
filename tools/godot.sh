#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -d /workspace/tooling ]]; then
  default_tooling=/workspace/tooling
else
  default_tooling="$project_root/.local-dev"
fi
tooling_root="${DEAD_MILE_TOOLING_ROOT:-$default_tooling}"
export XDG_DATA_HOME="$tooling_root/xdg/data"
export XDG_CONFIG_HOME="$tooling_root/xdg/config"
export XDG_CACHE_HOME="$tooling_root/xdg/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$project_root/builds"
exec godot --path "$project_root" "$@"
