#!/usr/bin/env bash
# Prepare Godot 4.6 and run the same strict verification gate used by CI.
set -euo pipefail

GODOT_VERSION="4.6-stable"
TPL_VERSION="4.6.stable"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${HERE}/.vercel-godot"
HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"
mkdir -p "$WORK"

# Sandbox Godot's user directories inside the build workspace.
export XDG_DATA_HOME="$WORK/data"
export XDG_CONFIG_HOME="$WORK/config"
export XDG_CACHE_HOME="$WORK/cache"

GODOT_BIN="${GODOT_BIN:-}"
USING_DOWNLOADED_GODOT=false
if [ -z "$GODOT_BIN" ]; then
  USING_DOWNLOADED_GODOT=true
  case "$HOST_OS" in
    Darwin)
      GODOT_ARCHIVE="Godot_v${GODOT_VERSION}_macos.universal.zip"
      GODOT_BIN="$WORK/Godot.app/Contents/MacOS/Godot"
      ;;
    Linux)
      if [ "$HOST_ARCH" != "x86_64" ]; then
        echo "Unsupported Linux architecture: $HOST_ARCH" >&2
        exit 1
      fi
      GODOT_ARCHIVE="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
      GODOT_BIN="$WORK/Godot_v${GODOT_VERSION}_linux.x86_64"
      ;;
    *)
      echo "Unsupported host operating system: $HOST_OS" >&2
      exit 1
      ;;
  esac

  if [ ! -x "$GODOT_BIN" ]; then
    echo "Downloading Godot ${GODOT_VERSION} for ${HOST_OS}/${HOST_ARCH}..."
    curl -fsSL -o "$WORK/godot.zip" \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ARCHIVE}"
    unzip -oq "$WORK/godot.zip" -d "$WORK"
    chmod +x "$GODOT_BIN"
  fi
fi

# Keep downloaded editor state and export templates fully inside the workspace.
# Godot detects this marker beside the executable or macOS .app bundle.
if [ "$USING_DOWNLOADED_GODOT" = true ]; then
  touch "$WORK/._sc_"
fi

if ! "$GODOT_BIN" --version | grep -F "4.6"; then
  echo "Godot 4.6 is required; received: $("$GODOT_BIN" --version 2>&1)" >&2
  exit 1
fi

# Install the committed web template in the sandboxed Godot data directory.
if [ "$USING_DOWNLOADED_GODOT" = true ]; then
  TPL_DIR="$WORK/editor_data/export_templates/${TPL_VERSION}"
else
  TPL_DIR="$XDG_DATA_HOME/godot/export_templates/${TPL_VERSION}"
fi
mkdir -p "$TPL_DIR"
cp "$HERE/.godot-templates/web_nothreads_release.zip" "$TPL_DIR/"
echo "${TPL_VERSION}" > "$TPL_DIR/version.txt"

export BUILD_DATE="${BUILD_DATE:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"
python3 "$HERE/scripts/generate_build_info.py"

restore_local_build_info() {
  VERCEL_GIT_COMMIT_SHA="" BUILD_DATE="" \
    python3 "$HERE/scripts/generate_build_info.py"
}
trap restore_local_build_info EXIT

GODOT_BIN="$GODOT_BIN" bash "$HERE/scripts/verify.sh"

echo "Web build ready in build/web:"
ls -lh "$HERE/build/web"
