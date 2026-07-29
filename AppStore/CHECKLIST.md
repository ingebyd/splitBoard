# Публикация SplitBoard в App Store

Порядок действий. Всё, что помечено «я», уже сделано в репозитории; «ты» - то,
что можно сделать только из аккаунта.

## 1. Аккаунт и соглашения (ты)

- [x] Публикуем бесплатно: подписывать ничего не нужно, действующего
      Apple Developer Program Agreement достаточно.
- [ ] Если решим брать деньги: App Store Connect → Business → Agreements, Tax,
      and Banking → подписать **Paid Applications Agreement**, добавить
      банковский счёт и налоговые формы (для не-US это W-8BEN). Отдельно стоит
      подать заявку в **App Store Small Business Program** (комиссия 15%).

## 2. Ссылки (ты)

- [x] Support URL: https://ingebyd.github.io/splitBoard/
- [x] Privacy Policy URL: https://ingebyd.github.io/splitBoard/privacy.html
      (страницы уже опубликованы из папки `docs/` через GitHub Pages)

## 3. Запись приложения в App Store Connect (ты)

- [ ] Apps → «+» → New App
- [ ] Platform: iOS, Name: **SplitBoard**, Primary Language: English (U.S.)
- [ ] Bundle ID: `com.ingebyd.splitboard`, SKU: `splitboard-1`
- [ ] Категории: Utilities (основная), Productivity (дополнительная)
- [ ] Возрастной рейтинг: 4+
- [ ] Цена: Free (позже можно поменять, но у уже скачавших останется бесплатной)

## 4. Метаданные (готово, копировать из репозитория)

- [ ] Английская локаль: `AppStore/METADATA-en.md`
- [ ] Русская локаль: `AppStore/METADATA-ru.md`
- [ ] App Review Information → Notes: `AppStore/review-notes.md`
- [ ] App Privacy → «Data Not Collected» на все вопросы

## 5. Скриншоты

- [ ] 13-inch iPad, альбомные 2752x2064, пять штук. Лежат в `AppStore/screenshots/`,
      собраны из настоящих скриншотов с iPad (исходники в `screenshots/`, вне git).
- [ ] 11-inch iPad Apple подтянет из 13-дюймовых автоматически.
- [ ] Пересобрать кадры после правок в дизайне:
      `compose <исходник> <выход> "подпись" <0|1 тёмная>`

## 6. Сборка (я, по команде)

- [ ] Поднять `CURRENT_PROJECT_VERSION`, если это повторная загрузка
- [ ] `./archive.sh` - собирает Release-архив прямо в папку Xcode Organizer
      (`~/Library/Developer/Xcode/Archives/<дата>/`), иначе Organizer его не покажет
- [ ] `greenlight preflight .` перед отправкой (сейчас зелёный)

## 7. Загрузка (ты)

- [ ] Xcode → Window → Organizer → выбрать архив → Distribute App →
      App Store Connect → Upload
- [ ] В App Store Connect дождаться обработки сборки, выбрать её в версии 1.0
- [ ] Submit for Review

## Что ревью может спросить

- **4.1 Copycats / имитация системного интерфейса.** Клавиатура намеренно
  разведена с системной: свой радиус клавиш, модификаторы другого тона,
  скруглённый шрифт, другой способ подачи второго символа. Если всё же
  придерутся, дальше меняем акцентный цвет и глифы, это полчаса работы.
- **Как включить клавиатуру.** Ответ уже в review notes, они это читают.
- **Full Access.** Не запрашивается вообще, это плюс к доверию.

## Грабли первой подачи

Всё это уже поправлено в проекте, но при следующем релизе стоит помнить.

- **Явные App ID.** Xcode подписывает устройство wildcard-профилем `TEAMID.*`, поэтому
  явные идентификаторы не создаются сами. Для App Store их нужно зарегистрировать
  руками на developer.apple.com: `com.ingebyd.splitboard` и
  `com.ingebyd.splitboard.keyboard`. Пока их нет, приложение не выбрать в списке
  Bundle ID при создании записи.
- **XcodeGen перекрывает `TARGETED_DEVICE_FAMILY`.** Значение из корневого `settings`
  не работает: генератор дописывает `"1,2"` в каждый таргет. Настройка живёт
  в `settings.base` конкретного таргета, иначе сборка считается универсальной
  и App Store Connect требует iPhone-скриншоты.
- **Скриншоты без альфа-канала.** App Store Connect отклоняет PNG с прозрачностью,
  даже полностью непрозрачной. Кадры с iPad приходят как RGBA, так что перед
  загрузкой их надо перекодировать (`CGImageAlphaInfo.noneSkipLast`).
- **Organizer видит только свою папку.** Архив должен лежать в
  `~/Library/Developer/Xcode/Archives/<дата>/`, иначе его просто нет в списке.
  `./archive.sh` уже кладёт туда.
- **Номер сборки.** App Store Connect не принимает повторно тот же
  `CURRENT_PROJECT_VERSION`. Перед новой загрузкой поднимать его в `project.yml`.
