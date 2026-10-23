#!/bin/sh
# Genera SepirizHexaphonos.xcodeproj a partir de project.yml (necesita XcodeGen).
set -eu
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Falta XcodeGen: brew install xcodegen" >&2
  exit 1
fi
xcodegen generate --spec project.yml
echo "Listo: abre SepirizHexaphonos.xcodeproj"
