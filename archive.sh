#!/bin/bash
# Собирает Release-архив для загрузки в App Store Connect.
#   ./archive.sh          - архив в build/SplitBoard.xcarchive
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Проверка перед сборкой"
if command -v greenlight >/dev/null 2>&1; then
  greenlight preflight . | tail -20
fi

# Xcode Organizer видит архивы только в своей папке, поэтому кладём сразу туда.
ARCHIVE="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/SplitBoard $(date +%H-%M).xcarchive"
mkdir -p "$(dirname "$ARCHIVE")"

echo "==> Архив"
xcodebuild -project SplitBoard.xcodeproj \
           -scheme SplitBoard \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           -archivePath "$ARCHIVE" \
           -allowProvisioningUpdates \
           archive | tail -5

echo
echo "Готово: $ARCHIVE"
echo "Дальше: Xcode → Window → Organizer → вкладка Archives → Distribute App → App Store Connect"
