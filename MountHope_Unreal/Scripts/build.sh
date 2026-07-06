#!/usr/bin/env bash
# Compile Mount Hope when Unreal Engine is installed locally.
# Set UE_ROOT to your engine install (e.g. /Users/Shared/Epic Games/UE_5.8).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
UPROJECT="${PROJECT_ROOT}/MountHope.uproject"

if [[ -z "${UE_ROOT:-}" ]]; then
  echo "ERROR: UE_ROOT is not set. Point it at your Unreal Engine install directory." >&2
  echo "Example: export UE_ROOT=\"/Users/Shared/Epic Games/UE_5.8\"" >&2
  exit 1
fi

PLATFORM="${PLATFORM:-Linux}"
CONFIGURATION="${CONFIGURATION:-Development}"
TARGET="${TARGET:-MountHopeEditor}"

RUNUBT="${UE_ROOT}/Engine/Build/BatchFiles/RunUBT.sh"
if [[ ! -x "${RUNUBT}" ]]; then
  echo "ERROR: RunUBT.sh not found at ${RUNUBT}" >&2
  exit 1
fi

echo "Building ${TARGET} ${PLATFORM} ${CONFIGURATION}..."
"${RUNUBT}" "${TARGET}" "${PLATFORM}" "${CONFIGURATION}" \
  -Project="${UPROJECT}" \
  -WaitMutex \
  -FromMsBuild

echo "Build succeeded."
