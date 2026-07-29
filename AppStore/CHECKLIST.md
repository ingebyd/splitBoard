# Публикация SplitBoard в App Store

Порядок действий. Всё, что помечено «я», уже сделано в репозитории; «ты» - то,
что можно сделать только из аккаунта.

## 1. Аккаунт и соглашения (ты)

- [ ] Бесплатная публикация: ничего подписывать не нужно, действующего
      Apple Developer Program Agreement достаточно.
- [ ] Если решим брать деньги: App Store Connect → Business → Agreements, Tax,
      and Banking → подписать **Paid Applications Agreement**, добавить
      банковский счёт и налоговые формы (для не-US это W-8BEN). Отдельно стоит
      подать заявку в **App Store Small Business Program** (комиссия 15%).

## 2. Ссылки (ты)

- [ ] Support URL - обязателен. Хватит репозитория на GitHub или простой страницы.
- [ ] Privacy Policy URL - обязателен для клавиатуры. Текст готов:
      `AppStore/privacy-policy.md`, публикуется как есть на GitHub Pages.

## 3. Запись приложения в App Store Connect (ты)

- [ ] Apps → «+» → New App
- [ ] Platform: iOS, Name: **SplitBoard**, Primary Language: English (U.S.)
- [ ] Bundle ID: `com.sherkhan.splitboard`, SKU: `splitboard-1`
- [ ] Категории: Utilities (основная), Productivity (дополнительная)
- [ ] Возрастной рейтинг: 4+
- [ ] Цена: Free (позже можно поменять, но у уже скачавших останется бесплатной)

## 4. Метаданные (готово, копировать из репозитория)

- [ ] Английская локаль: `AppStore/METADATA-en.md`
- [ ] Русская локаль: `AppStore/METADATA-ru.md`
- [ ] App Review Information → Notes: `AppStore/review-notes.md`
- [ ] App Privacy → «Data Not Collected» на все вопросы

## 5. Скриншоты

- [ ] 13-inch iPad: 2064x2752, от 1 до 10 штук. Лежат в `AppStore/screenshots/`.
- [ ] 11-inch iPad Apple подтянет из 13-дюймовых автоматически.

## 6. Сборка (я, по команде)

- [ ] Поднять `CURRENT_PROJECT_VERSION`, если это повторная загрузка
- [ ] `./archive.sh` - собирает Release-архив в `build/SplitBoard.xcarchive`
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
