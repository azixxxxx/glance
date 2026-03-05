# Ребрендинг Barik → Glance

**Проект:** macOS status bar с кастомными виджетами
**Новое имя:** Glance ("всё одним взглядом")
**Автор:** Azim Sukhanov
**Статус:** PENDING

---

## Контекст

Форк Barik с существенными доработками: три новых виджета (Volume, ActiveApp, Native Spaces), переработанный дизайн spaces, нативная поддержка macOS Spaces через CGS private API. Цель — полностью отвязаться от Barik и сделать самостоятельный проект.

## Текущее состояние

- Проект: `~/Documents/Projects/barik-fork/`
- Конфиг: `~/.barik-config.toml`
- Деплой: `/Applications/Barik.app`
- Документация: `CLAUDE.md` в корне проекта (полное описание архитектуры, изменений, билда)

---

## План ребрендинга

### Фаза 1: Переименование проекта

- [ ] **1.1 Директория исходников**
  - Переименовать `Barik/` → `Glance/`
  - Обновить все пути в `project.pbxproj`

- [ ] **1.2 Xcode проект**
  - Переименовать `Barik.xcodeproj` → `Glance.xcodeproj`
  - Переименовать target: Barik → Glance
  - Переименовать scheme: Barik → Glance
  - Product name: Glance
  - Bundle ID: `com.azimsukhanov.glance`

- [ ] **1.3 Info.plist**
  - Bundle name: Glance
  - Bundle display name: Glance
  - Сохранить `LSUIElement = true`

- [ ] **1.4 Entitlements**
  - Переименовать `Barik.entitlements` → `Glance.entitlements`
  - Обновить ссылку в project.pbxproj

### Фаза 2: Код

- [ ] **2.1 Swift файлы — замена строк "Barik"**
  - `BarikApp.swift` → `GlanceApp.swift` (имя структуры + @main)
  - `AppDelegate.swift` — заменить упоминания Barik
  - `NativeSpacesProvider.swift` — строка `"Barik"` в `systemApps` (фильтр окон, чтобы не показывать само приложение в spaces)
  - `Constants.swift` — проверить на упоминания
  - Любые другие файлы с "Barik" в строках или комментариях

- [ ] **2.2 Конфигурация**
  - `ConfigManager.swift` — путь к конфигу: `~/.barik-config.toml` → `~/.glance-config.toml`
  - Обновить парсинг если есть захардкоженные пути
  - Виджет IDs остаются `default.spaces`, `default.volume` и т.д. (не привязаны к Barik)

### Фаза 3: Ресурсы и дизайн

- [ ] **3.1 Иконка приложения**
  - Создать новую минималистичную иконку для Glance
  - Заменить все размеры в `Resources/Assets.xcassets/AppIcon.appiconset/`
  - Стиль: минимализм, Tokyo Night палитра (тёмно-синий + акцент)

- [ ] **3.2 Убрать upstream артефакты**
  - Удалить `CHANGELOG.md` (старый, от Barik)
  - Удалить `.github/FUNDING.yml` (чужой спонсор)
  - Удалить `resources/` (скриншоты Barik)
  - Удалить `example/` (.yabairc — не наш)
  - Удалить оригинальный `README.md`

- [ ] **3.3 Liquid Glass дизайн-система**
  Полный редизайн UI в стиле объёмного liquid glass. Это ключевое визуальное отличие от Barik.

  **3.3.1 Основной бар (фон виджетов)**
  - Заменить текущий плоский blur (`ExperimentalConfigurationModifier.swift`) на многослойное стекло:
    - Слой 1: `.ultraThinMaterial` — базовый blur подложки
    - Слой 2: Градиентный overlay (белый 5-15% сверху → прозрачный снизу) — световой блик
    - Слой 3: Inner shadow (чёрный 10% снизу) — глубина
    - Слой 4: Border с линейным градиентом (белый 20% сверху → белый 5% снизу) — стеклянный край
  - `cornerRadius` увеличить для более "каплевидного" ощущения
  - Subtle drop shadow за каждой капсулой

  **3.3.2 Попапы**
  - Сейчас: `Color.black` плоский фон
  - Новый: многослойный glass background:
    - `NSVisualEffectView` с `.hudWindow` или `.popover` material
    - Градиентный блик по верхнему краю
    - Скруглённые углы с glass border
    - Soft drop shadow
  - Анимация появления: scale(0.95→1.0) + opacity с spring

  **3.3.3 Виджеты**
  - Hover эффект: лёгкое "вдавливание" (brightness shift) вместо цветной подложки
  - Active/focused state: усиленный блик + subtle glow
  - Иконки: drop shadow для парения над стеклом
  - Текст: `.foregroundStyle(.primary)` с subtle text shadow

  **3.3.4 Spaces widget**
  - Focused space: стеклянная подсветка (ярче блик, сильнее border)
  - App иконки: subtle reflection снизу (gradient mask)
  - Переходы между состояниями: плавная анимация прозрачности стекла

  **3.3.5 Система стилей (переключаемая)**

  Liquid Glass — дефолт, но пользователь может выбрать другой стиль.
  Вся визуальная часть проходит через один слой абстракции — `BarStyle`.

  **Стили:**
  | Стиль | Описание | Для кого |
  |---|---|---|
  | **Glass** (default) | Полный liquid glass — blur, блики, тени, gradient border | Основной стиль Glance |
  | **Solid** | Плоский непрозрачный фон, без blur и бликов, чистые цвета | Минималисты, слабые GPU |
  | **Minimal** | Без фона вообще, только текст и иконки поверх десктопа | Максимальный минимализм |
  | **System** | Нативный macOS `.regularMaterial` без кастомных эффектов | Кто хочет "как в системе" |

  **Реализация:**
  ```swift
  // Протокол стиля
  protocol BarStyleProvider {
      func widgetBackground(cornerRadius: CGFloat) -> some View
      func popupBackground() -> some View
      func hoverEffect() -> some ViewModifier
      func focusEffect() -> some ViewModifier
  }

  // Конкретные реализации
  struct GlassStyle: BarStyleProvider { ... }   // blur + highlight + border + shadow
  struct SolidStyle: BarStyleProvider { ... }    // flat color background
  struct MinimalStyle: BarStyleProvider { ... }  // transparent, text/icons only
  struct SystemStyle: BarStyleProvider { ... }   // native macOS material
  ```

  - Каждый ViewModifier (widget background, popup, hover, focus) запрашивает стиль через `@Environment`
  - Переключение стиля: Settings → General → "Bar style: [Glass ▾]"
  - Конфиг: `style = "glass"` / `"solid"` / `"minimal"` / `"system"` в `~/.glance-config.toml`
  - Переключение live — бар перерисовывается мгновенно без перезапуска

  **Файловая структура:**
  ```
  Glance/
    Styles/
      BarStyleProvider.swift      — протокол + @Environment key
      GlassStyle.swift            — liquid glass (default)
      SolidStyle.swift            — flat/opaque
      MinimalStyle.swift          — transparent
      SystemStyle.swift           — native macOS material
      GlassModifier.swift         — core glass ViewModifier (blur + highlight + border)
  ```

  **Конфиг:**
  ```toml
  # Стиль бара
  style = "glass"       # glass | solid | minimal | system

  # Тонкая настройка glass (только для style = "glass")
  [style.glass]
  blur = 15             # интенсивность blur (5-30)
  highlight = true      # верхний блик
  border = true         # стеклянный border
  shadow = true         # drop shadow
  ```

  Это даёт:
  - Для обычных юзеров: выбрал стиль в Settings → готово
  - Для продвинутых: тонкая настройка каждого параметра glass через TOML
  - Для разработки: добавить новый стиль = реализовать протокол

  **Референс стиля:**
  ```
  ┌─────────────────────────────────────────────────┐
  │  ░░░░░ highlight gradient (white 10%) ░░░░░░░░  │  ← верхний блик
  │                                                  │
  │   [1 🔵 🟢]  │  Chrome  │  ♫ Song  │  🔊  17:30 │  ← контент
  │                                                  │
  │  ▓▓▓▓▓ inner shadow (black 8%) ▓▓▓▓▓▓▓▓▓▓▓▓▓  │  ← нижняя тень
  └─────────────────────────────────────────────────┘
       ↑ gradient border (white 20% top → 5% bottom)
       ↑ drop shadow снаружи
       ↑ за всем этим — blur подложка десктопа
  ```

### Фаза 4: Git и документация

- [ ] **4.1 Чистая git история**
  - Удалить `.git/`
  - `git init` заново
  - Первый коммит: "Initial commit: Glance — macOS status bar"
  - Это полностью убирает связь с upstream Barik

- [ ] **4.2 Новый README.md**
  - Название: Glance
  - Описание: Modern macOS status bar replacement
  - Скриншот (сделать после ребрендинга)
  - Список виджетов
  - Инструкция по установке и конфигурации
  - Лицензия

- [ ] **4.3 Обновить CLAUDE.md**
  - Заменить все упоминания Barik → Glance
  - Обновить пути (build команда, конфиг, деплой)
  - Обновить структуру проекта

- [ ] **4.4 Новый .gitignore**
  - Оставить нужное (build/, .DS_Store, xcuserdata)
  - Убрать лишнее если есть

### Фаза 5: Билд и деплой

- [ ] **5.1 Новая команда билда**
  ```bash
  xcodebuild -project Glance.xcodeproj -scheme Glance -configuration Release \
    -derivedDataPath build build \
    CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
  ```

- [ ] **5.2 Деплой**
  ```bash
  pkill -x Glance; sleep 2
  rm -rf /Applications/Glance.app
  cp -R build/Build/Products/Release/Glance.app /Applications/Glance.app
  open /Applications/Glance.app
  ```

- [ ] **5.3 Миграция конфига**
  ```bash
  cp ~/.barik-config.toml ~/.glance-config.toml
  ```

- [ ] **5.4 Убрать старый Barik**
  ```bash
  pkill -x Barik
  rm -rf /Applications/Barik.app
  ```

---

## Критические моменты

1. **project.pbxproj** — самый сложный файл. Все ссылки на пути, имена таргетов, product name. Нужно аккуратно заменить все вхождения.
2. **Строка "Barik" в systemApps** (`NativeSpacesProvider.swift`) — ОБЯЗАТЕЛЬНО заменить на "Glance", иначе приложение будет показывать своё собственное окно в spaces.
3. **Config path** — если не обновить путь к конфигу, приложение не найдёт настройки.
4. **Scheme name** — если не переименовать, xcodebuild не найдёт scheme.

## После ребрендинга — план развития

Когда Glance будет стоять как самостоятельный проект:

**Приоритет 1 — визуальная идентичность:**
1. **Liquid Glass дизайн** (Фаза 3.3) — реализовать полностью, это главное отличие
2. **Анимации** — плавные переходы, spring physics, микро-интеракции

**Приоритет 2 — новые виджеты:**
3. **CPU / Memory монитор** — sparkline графики в баре, детали в попапе
4. **Weather** — Open-Meteo API (бесплатный, без ключа), температура + иконка
5. **Pomodoro таймер** — обратный отсчёт в баре, управление в попапе

**Приоритет 3 — GUI Settings (ключевое для массовости):**
6. **Settings UI** — полноценное окно настроек (см. Фаза 6 ниже)

**Приоритет 4 — продвинутый функционал:**
7. **Clipboard history** — последние N скопированных элементов
8. **Plugin API** — загрузка виджетов из конфигов
9. **Window tiling из бара** — клик на иконку → popup с вариантами расположения

---

## Фаза 6: GUI Settings (полноценное окно настроек)

Цель: любой человек без технического бэкграунда может установить Glance, открыть Settings и настроить бар под себя — без редактирования файлов.

### Архитектура

**Подход:** Отдельное SwiftUI Window (не popup, а полноценное окно).
- Открывается по клику правой кнопкой на бар → "Settings..." или через menu bar icon
- Также через keyboard shortcut (Cmd+,) — стандарт macOS
- Настройки сохраняются в тот же `~/.glance-config.toml` — GUI является визуальным редактором конфига
- Изменения применяются мгновенно (live preview) — бар обновляется в реальном времени

### Структура окна Settings

```
┌──────────────────────────────────────────────────────┐
│  ⚙ Glance Settings                          [─ □ ✕] │
├──────────┬───────────────────────────────────────────┤
│          │                                           │
│ General  │  Theme: [Dark ▾]                          │
│          │                                           │
│ Widgets  │  Bar height: [━━━━━●━━] 35px              │
│          │                                           │
│ Spaces   │  Blur intensity: [━━●━━━━] 4              │
│          │                                           │
│ Time     │  Horizontal padding: [━━━●━━] 20          │
│          │                                           │
│ Volume   │  Widget spacing: [━━●━━━━] 12             │
│          │                                           │
│ Network  │  ☑ Show widget backgrounds                │
│          │                                           │
│ About    │  Widget background blur: [━━●━━] 5        │
│          │                                           │
├──────────┴───────────────────────────────────────────┤
│  Glance v1.0 — made by Azim Sukhanov                │
└──────────────────────────────────────────────────────┘
```

### Табы Settings

**General**
- Theme: Dark / Light / System
- Bar height: slider (25-55)
- Background blur: slider (0-20)
- Horizontal padding: slider (0-40)
- Widget spacing: slider (4-24)
- Widget backgrounds: toggle + blur slider
- Launch at login: toggle
- Show in Dock: toggle (LSUIElement flip)

**Widgets (Drag & Drop)**
- Список активных виджетов (drag to reorder)
- Список доступных виджетов (drag to add)
- Удаление виджетом: перетащить в "Remove" зону или кнопка ✕
- Визуальный preview бара в реальном времени прямо в окне
- Добавление divider / spacer через кнопку "+"

```
  Активные виджеты:          Доступные:
  ┌──────────────────┐       ┌──────────────┐
  │ ≡ Spaces         │       │ + Battery    │
  │ ≡ ── Divider     │       │ + Pomodoro   │
  │ ≡ Active App     │       │ + CPU        │
  │ ≡ Now Playing    │       │ + Weather    │
  │ ≡ ── Spacer      │       └──────────────┘
  │ ≡ Volume         │
  │ ≡ Network        │
  │ ≡ ── Divider     │
  │ ≡ Time           │
  └──────────────────┘
```

**Spaces**
- Show space number: toggle
- Show window title on focus: toggle
- Window title max length: slider
- Always show app name for: list editor (add/remove app names)

**Time**
- Date format: текстовое поле с live preview ("E d MMM, H:mm" → "Wed 5 Mar, 17:30")
- Preset форматы: dropdown с популярными вариантами
  - `H:mm` → 17:30
  - `h:mm a` → 5:30 PM
  - `E d MMM, H:mm` → Wed 5 Mar, 17:30
  - `d.MM.yyyy H:mm` → 05.03.2026 17:30
  - Custom...
- Calendar event format: то же самое
- Show next event: toggle
- Time zone: dropdown (System / список зон)

**Volume**
- Scroll sensitivity: slider
- Show percentage on hover: toggle

**Network**
- Show Wi-Fi icon: toggle
- Show Ethernet icon: toggle

**About**
- Версия приложения
- Автор
- Ссылки: GitHub, сайт
- Check for updates
- Лицензия

### Техническая реализация

**Файловая структура:**
```
Glance/
  Settings/
    SettingsWindow.swift        — основное окно (NSWindow + SwiftUI hosting)
    SettingsView.swift          — корневой SwiftUI view с sidebar
    Tabs/
      GeneralSettingsTab.swift  — General таб
      WidgetsSettingsTab.swift  — Widgets drag & drop
      SpacesSettingsTab.swift   — Spaces настройки
      TimeSettingsTab.swift     — Time формат
      VolumeSettingsTab.swift   — Volume настройки
      NetworkSettingsTab.swift  — Network настройки
      AboutSettingsTab.swift    — About
    Components/
      WidgetDragList.swift      — drag & drop список виджетов
      SliderRow.swift           — переиспользуемый slider с label + value
      ToggleRow.swift           — toggle с описанием
      FormatPreview.swift       — live preview для date format
```

**Связь с конфигом:**
- `ConfigManager` уже ObservableObject — Settings биндятся напрямую
- При изменении в GUI → `ConfigManager` обновляет значение → записывает `~/.glance-config.toml` → бар обновляется через существующий механизм `@ObservedObject`
- При ручном редактировании TOML → `ConfigManager` перечитывает файл (FSEvents watcher) → GUI обновляется
- Двусторонняя синхронизация: GUI и TOML всегда в консистентном состоянии

**Live Preview:**
- Миниатюрный preview бара в верхней части окна Settings
- Обновляется мгновенно при изменении любой настройки
- Показывает реальные данные (текущее время, активные spaces)

**Drag & Drop виджетов:**
- SwiftUI `onDrag` / `onDrop` или `draggable` / `dropDestination` (macOS 13+)
- Каждый виджет — карточка с иконкой и названием
- Перетаскивание меняет порядок в `widgets.displayed` массиве конфига

**Открытие Settings:**
- Правый клик по бару → контекстное меню → "Settings..."
- Cmd+, (стандарт macOS) — через `@Environment(\.openSettings)`
- Menu bar icon (опционально) → "Preferences..."

### Дизайн Settings окна

Settings окно тоже в стиле Liquid Glass:
- Sidebar с glass background
- Каждый таб — glass panel
- Слайдеры и toggle в стиле macOS native (не кастомные)
- Общий вайб: как System Settings в macOS Ventura+, но с glass акцентами

---

## Фаза 7: Запуск и монетизация

Цель: $1000 (окупить Claude Code) + принести пользу людям.
$1000 = 100 человек по $10, или 200 по $5. Для macOS утилиты с GUI — реальная цель.

### Модель: Open Source + Pay What You Want

Не freemium, не подписка. Простая модель:
- **Приложение бесплатное и open source** (MIT или подобное)
- **На сайте и в README**: "If Glance saves you time, consider supporting development" + ссылки на оплату
- **Gumroad / LemonSqueezy**: страница "Download Glance — Pay what you want ($0+, suggested $5)"
- **GitHub Sponsors**: для recurring поддержки

Почему эта модель:
- Нет барьера: каждый может попробовать → больше пользователей → больше сарафанного радио
- Open source = доверие (после скандала с Bartender люди ценят прозрачность)
- Люди реально платят за хорошие бесплатные утилиты — доказано iina, Raycast, Arc

### Альтернатива: честный Freemium

Если pay-what-you-want не наберёт:
- Бесплатно: все базовые виджеты + GUI Settings
- $10 единоразово: Pro-виджеты (CPU/RAM графики, Weather, Pomodoro, Clipboard), кастомные темы
- Активация: простой license key через Gumroad

### Площадки для запуска

**Порядок действий (после готовности продукта):**

1. **GitHub** — красивый README со скриншотами/видео liquid glass, звёзды
2. **Homebrew Cask** — `brew install --cask glance-bar` (название, чтобы не конфликтовать)
3. **r/macapps** (200k+ подписчиков) — пост "I built a free macOS status bar replacement with liquid glass UI"
4. **r/mac**, **r/apple** — кросс-пост
5. **ProductHunt** — запуск с видео-демо
6. **Hacker News** — "Show HN: Glance — open source macOS status bar with glass UI"
7. **Twitter/X** — gif/видео бара в действии, теги #macOS #dev #opensource
8. **YouTube** — короткое демо-видео (1-2 мин)

### Что конвертирует бесплатных в платящих

- **Качество** — если выглядит premium, люди хотят поддержать
- **Личная история** — "Built by one developer, supported by community"
- **Прозрачность** — открытый код, честная коммуникация
- **Благодарность в приложении** — About tab: список спонсоров/поддержавших

### Timeline к $1000

```
Месяц 1: Ребрендинг + Liquid Glass + GUI Settings
Месяц 2: Новые виджеты (CPU, Weather, Pomodoro) + полировка
Месяц 3: Запуск — GitHub + Homebrew + Reddit + ProductHunt
         Gumroad "Pay what you want" страница
Месяц 4+: Итерация по фидбеку, новые виджеты
```

Если Reddit-пост залетит (а r/macapps любит красивые нативные утилиты) —
1000 звёзд на GitHub + 100 платных скачиваний вполне реально.

### Что нужно для запуска

- [ ] Готовый продукт с GUI Settings
- [ ] Красивый сайт (может быть одностраничный, GitHub Pages бесплатно)
- [ ] README со скриншотами и gif-анимациями liquid glass
- [ ] Демо-видео (30-60 сек)
- [ ] Gumroad / LemonSqueezy страница
- [ ] Homebrew cask формула
- [ ] GitHub Sponsors профиль

---

## Как продолжить в новой сессии

1. Открыть Claude в `~/Documents/Projects/barik-fork/`
2. Сказать: "Продолжаем ребрендинг Barik → Glance по плану REBRAND-PLAN.md"
3. Claude прочитает этот файл + CLAUDE.md и подхватит работу
