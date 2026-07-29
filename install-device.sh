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

build() {
  xcodebuild -project SplitBoard.xcodeproj \
             -scheme SplitBoard \
             -configuration Debug \
             -destination "id=$UDID" \
             -derivedDataPath build-device \
             -allowProvisioningUpdates \
             -allowProvisioningDeviceRegistration \
             build
}

echo "==> Сборка"
# Первая сборка на новом устройстве регистрирует его в аккаунте и перевыпускает
# профиль; Xcode при этом иногда не успевает положить файл на диск, поэтому
# второй заход.
if ! build | tail -5; then
  echo "==> Повтор сборки после обновления профиля"
  build | tail -5
fi

APP="build-device/Build/Products/Debug-iphoneos/SplitBoard.app"
echo "==> Установка $APP"
if ! xcrun devicectl device install app --device "$UDID" "$APP"; then
  echo
  echo "Установка не прошла. Самая частая причина - выключен режим разработчика:"
  echo "  Настройки → Конфиденциальность и безопасность → Режим разработчика → включить,"
  echo "  перезагрузить iPad и подтвердить. После этого запусти скрипт снова."
  exit 1
fi

echo
echo "Готово. Дальше на iPad:"
echo "  1. Настройки → Основные → Клавиатура → Клавиатуры → Новые клавиатуры → SplitBoard"
echo "  2. Открой любое поле ввода, зажми 🌐 и выбери SplitBoard"
