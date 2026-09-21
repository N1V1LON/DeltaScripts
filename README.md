# Roblox UI to WebUI Emulator Engine

Кросс-платформенный ядро-эмулятор для преобразования и выполнения логики **Roblox Lua UI** в веб-интерфейсе (**WebUI**).

Движок разработан для запуска как на архитектуре **AMD64 (x86_64)**, так и на **ARM / ARM64** под операционными системами **Windows (PowerShell)**, **Linux (Ubuntu / Debian)** и **Android (Termux)**.

---

## 🚀 Особенности

- **Полная эмуляция Roblox API в Lua (через Fengari JS)**:
  - Сервисы: `game:GetService("Players")`, `UserInputService`, `TweenService`.
  - Типы данных: `UDim2`, `UDim`, `Color3`, `Vector3`, `CFrame`, `Enum`.
  - Компоненты UI: `ScreenGui`, `Frame`, `TextButton`, `TextLabel`, `TextBox`, `ScrollingFrame`, `UICorner`, `UIStroke`.
  - Планировщик и глобальные функции: `task.spawn`, `task.delay`, `task.cancel`, `task.wait`, `getgenv()`, `loadstring()`, `pcall()`.
- **Реальное время (WebSocket)**:
  - Иерархия UI элементов транслируется в HTML DOM в реальном времени.
  - Нажатия кнопок (`MouseButton1Click`), события ввода (`InputBegan`/`InputEnded`) и обновление полей ввода (`TextBox.Text`) передаются из WebUI обратно в Lua-среду.
- **Поддержка сложных скриптов**:
  - Полная совместимость с модульной системой скриптов (`ControlerScript.lua`, `WindowBase`, `FloatingWindow`, `SpeedLogic`, `SpeedInterface`, `TPLogic`, `TPInterface`).

---

## 🛠️ Системные требования

- **Node.js** v18+ (универсально для всех ОС).

---

## 📥 Установка и Запуск

### 🟢 Linux / Ubuntu / Android (Termux)
```bash
chmod +x run.sh
./run.sh
```

### 🔵 Windows (PowerShell)
```powershell
.\run.ps1
```

### ⚡ Запуск вручную
```bash
npm install
node src/server.js
```

После запуска откройте в браузере: **`http://localhost:3000`**

---

## 🧪 Интеграционные тесты
Для запуска автоматических тестов эмуляции Roblox API и проверки совместимости Lua скриптов выполните:
```bash
node tests/roblox_env.test.js
```

---

## 📂 Структура проекта

- `src/roblox_env.js` — Движок эмуляции Roblox API на основе Fengari (Lua 5.3 VM в JS).
- `src/server.js` — HTTP и WebSocket сервер синхронизации интерфейса.
- `web/` — Веб-интерфейс (HTML, CSS, JS) для отображения Roblox UI в браузере.
- `Scripts/` — Набор Roblox Lua скриптов и модулей (`ControlerScript.lua` и др.).
- `tests/roblox_env.test.js` — Набор автоматических интеграционных тестов.
