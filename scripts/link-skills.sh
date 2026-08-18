#!/usr/bin/env bash
set -euo pipefail
# Symlink every skills/<name>/ into the local skill dirs used by each harness.
# Symlinks, so a `git pull` keeps installed skills current.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")
for DEST in "${DESTS[@]}"; do
  mkdir -p "$DEST"
  for src in "$REPO"/skills/*/; do
    src="${src%/}"; name="$(basename "$src")"; target="$DEST/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "skip $name: $target exists and is not a symlink" >&2; continue
    fi
    ln -sfn "$src" "$target"; echo "linked $name -> $src ($DEST)"
  done
done
