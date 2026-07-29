#!/bin/bash
# Собирает Release-архив для загрузки в App Store Connect.
#   ./archive.sh          - архив в build/SplitBoard.xcarchive
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Проверка перед сборкой"
if command -v greenlight >/dev/null 2>&1; then
  greenlight preflight . | tail -20
fi

echo "==> Архив"
xcodebuild -project SplitBoard.xcodeproj \
           -scheme SplitBoard \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           -archivePath build/SplitBoard.xcarchive \
           -allowProvisioningUpdates \
           archive | tail -5

echo
echo "Готово: build/SplitBoard.xcarchive"
echo "Дальше: Xcode → Window → Organizer → Distribute App → App Store Connect"
