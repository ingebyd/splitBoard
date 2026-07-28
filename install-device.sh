#!/bin/bash
# Builds SplitBoard and installs it on the connected iPad.
#
#   ./install-device.sh            - build + install on the first connected device
#   ./install-device.sh <UDID>     - build + install on a specific device
set -euo pipefail
cd "$(dirname "$0")"

UDID="${1:-}"
if [ -z "$UDID" ]; then
  UDID=$(xcrun devicectl list devices 2>/dev/null \
        | awk '/connected/ && !/simulator/ {print $(NF-1); exit}')
fi

if [ -z "$UDID" ]; then
  echo "Не вижу подключённый iPad. Подключи кабелем, разблокируй, ответь Trust и запусти снова."
  echo "Список устройств:"
  xcrun devicectl list devices || true
  exit 1
fi

echo "==> Устройство: $UDID"
echo "==> Сборка"
xcodebuild -project SplitBoard.xcodeproj \
           -scheme SplitBoard \
           -configuration Debug \
           -destination "id=$UDID" \
           -derivedDataPath build-device \
           -allowProvisioningUpdates \
           build | tail -5

APP="build-device/Build/Products/Debug-iphoneos/SplitBoard.app"
echo "==> Установка $APP"
xcrun devicectl device install app --device "$UDID" "$APP"

echo
echo "Готово. Дальше на iPad:"
echo "  1. Настройки → Основные → Клавиатура → Клавиатуры → Новые клавиатуры → SplitBoard"
echo "  2. Открой любое поле ввода, зажми 🌐 и выбери SplitBoard"
