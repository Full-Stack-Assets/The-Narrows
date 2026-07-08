#!/usr/bin/env bash
# Run the MountHope C++ automation tests headlessly. Requires a local UE 5.8
# install (set UE_ROOT). Shared entry point for local runs and the self-hosted
# unreal-build CI workflow. See Docs/CI_AND_BUILD.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
UPROJECT="${PROJECT_ROOT}/MountHope.uproject"

if [[ -z "${UE_ROOT:-}" ]]; then
  echo "ERROR: UE_ROOT is not set. Point it at your Unreal Engine 5.8 install." >&2
  echo "Example: export UE_ROOT=\"/Users/Shared/Epic Games/UE_5.8\"" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin) EDITOR_CMD="${UE_ROOT}/Engine/Binaries/Mac/UnrealEditor-Cmd" ;;
  *)      EDITOR_CMD="${UE_ROOT}/Engine/Binaries/Linux/UnrealEditor-Cmd" ;;
esac
if [[ ! -x "${EDITOR_CMD}" ]]; then
  echo "ERROR: UnrealEditor-Cmd not found at ${EDITOR_CMD}" >&2
  exit 1
fi

TEST_FILTER="${TEST_FILTER:-MountHope}"
REPORT_DIR="${REPORT_DIR:-${PROJECT_ROOT}/Saved/AutomationReport}"
LOG_FILE="${REPORT_DIR}/run_tests.log"
mkdir -p "${REPORT_DIR}"

echo "Running automation tests (filter: ${TEST_FILTER})..."
# -nullrhi lets tests run on a headless/GPU-less runner. The trailing '|| true'
# keeps us going to the result parse even if the editor's own exit code is noisy.
"${EDITOR_CMD}" "${UPROJECT}" \
  -ExecCmds="Automation RunTests ${TEST_FILTER}; Quit" \
  -unattended -nopause -nosplash -nullrhi -stdout -FullStdOutLogOutput \
  -ReportExportPath="${REPORT_DIR}" 2>&1 | tee "${LOG_FILE}" || true

REPORT_JSON="${REPORT_DIR}/index.json"

# Prefer the structured report; fall back to the log. NOTE: the report schema has
# shifted across engine versions — if this parse misclassifies on your build,
# adjust the marker here (the raw report + log are always uploaded as artifacts).
if [[ -f "${REPORT_JSON}" ]]; then
  if grep -Eiq '"state"[[:space:]]*:[[:space:]]*"?(fail|failed)"?' "${REPORT_JSON}"; then
    echo "Automation tests FAILED — see ${REPORT_JSON}" >&2
    exit 1
  fi
  echo "Automation tests passed. Report: ${REPORT_JSON}"
  exit 0
fi

echo "WARNING: no ${REPORT_JSON}; falling back to log scan." >&2
if grep -Eiq 'Result=\{Fail\}|Test Completed\. Result=\{Failed\}|LogAutomationController: Error' "${LOG_FILE}"; then
  echo "Automation tests FAILED — see ${LOG_FILE}" >&2
  exit 1
fi
echo "Automation tests passed (log scan). Log: ${LOG_FILE}"
