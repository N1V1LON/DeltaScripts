# TODO

## Сделано — V26.1.0R (релиз)

- [x] GlobalControler: синглтон, запускается первым, сам поднимает всё остальное
- [x] Поиск Base (Scripts/) по кандидатам путей Delta
- [x] Config.json: theme, language, window, icons, modules
- [x] Загрузка GS → GM через readfile/loadstring с ретраями (5 проходов)
- [x] Контракт GetTable / GetPosition → вкладки + сортировка
- [x] ClaimPosition / ReleaseWindow — проверка X/Y, окна не перекрываются
- [x] Демо-модули: SpeedLogic+SpeedWindow, TPLogic+TPWindow, WindowBase
- [x] V26.0.3D: лаунчер [N]; вкладки Player|Server|Settings
- [x] V26.0.4D: драг; 16:9; RenderTab; prechunk
- [x] V26.0.5D: UIS/hit-test драг; 480×270; HarvestEnv; статус с ошибкой
- [x] V26.0.6D: embed всех 5 модулей внутри GC; драг классический InputBegan + UDim
- [x] V26.0.7D: попытка (хаб прятался) — отменена, см. 0.8D
- [x] V26.0.8D: модуль открывается **внутри хаба** (без отдельного окна); ← назад к карточкам; WindowBase._embedded
- [x] V26.0.9D: Speed — **ползунок** (без клавиатуры) + **ON/OFF**; min/max из Config; всё внутри модуля в хабе
- [x] V26.0.10D: ← Назад в хабе; resize-грип ⤡; EMBEDDED пересобран; Config 560×360
- [x] V26.0.11D: перенос дизайна Stitch Aether HUD — bg `#0f131d`, accent `#00f2fe`, radius 4, палитры THEMES/WindowBase/hardcoded, EMBEDDED sync
- [x] V26.0.12D: **fix драг хаба** (header → TextButton, Active/Selectable, ZIndex title/close, порог 4px, skip close); **fix Speed Open** (stateLabel был nil до объявления → краш; forward-decl + guard); `pcall(fn, cfg)` без лишнего self
- [x] V26.0.13D: **Stitch unified-hub** (upload `9038745645475446119` + design system applied); GUI: version badge mono в шапке, ✕ error_container `#93000a`/`#ffb4ab`, radius 4 везде, featured cyan stroke на 1-й карточке, empty-state icon+title+desc, TP coords mono справа, status «Загружено модулей: N»
- [x] V26.0.14D: **полный редизайн GUI** по unified-hub: inset-панель (margin 12), header bar с ← слева + badge/✕ справа, tab-bar в surface-рамке (equal width), status внизу + разделитель mono, карточки модулей вертикальные featured/обычные с chevron, empty-state на всю высоту, лаунчер panel+accent stroke, Speed = state-card + slider-box (readout mono 32/24), TP = hint + rows + full-width кнопка, WindowBase content padding; EMBEDDED пересобран; `luac -p` OK
- [x] V26.0.15D: **компакт-верстка** — hub M 12→6, header 40→32, tabs 36→28, status 22, gaps 12→6, карточки 76/60→56/48, list gap 8→4; WindowBase header 36→28, content pad 12/8→8/6; Speed card 88→64, slider 110→84, ширина 320→300; TP rows 48→40, btn 44→36, ширина 300→280; `_hubM`/`_hubHeaderH` на self; EMBEDDED + `luac -p` OK
- [x] V26.0.16D: **убрана вторая шапка модуля** — при `_embedded` WindowBase не создаёт Header/title/min/✕ (их делает хаб: ← + название + badge + ✕); Content на весь ModuleHost (pad 4); setTitle — guard на nil Title; одна шапка вместо двух
- [x] V26.0.17D: **fix resize/драг на таче** — MIN 340×240; list/status/moduleHost только Offset-высота (`math.max`, без Scale Y); dual-старт (GuiObject + UIS + hit-test `guiPointOver`); шаг через `UIS.InputChanged` + Heartbeat `GetMouseLocation`; стоп только по `UIS.InputEnded` (убран `grip.InputEnded`); `_relayoutHub` = applyList (также тянет status/statusLine); ZIndex/Active title/headRight/badge; pointerPos — общий хелпер; EMBEDDED sync + `luac -p` OK
- [x] V26.0.18D: **NoClip + Бесконечный прыжок** — GS `NoclipLogic`/`JumpLogic` + GM `NoclipWindow`/`JumpWindow` (state-card ON/OFF + hint; у Jump ползунок JumpPower 20–120 из Config); Player GetPosition 3/4; EMBEDDED 9 модулей; `luac -p` OK
- [x] V26.0.19D: **quick-toggle на карточке + сохранение** — ON/OFF pill справа (без входа в меню); `QuickToggle`/`IsOn`/`SetOn`/`Restore` у Speed/Noclip/Jump; `GC:SaveConfig` (debounce 0.4s, writefile Config.json) + `SaveModuleState`; restore при старте; respawn keep в Logic; FALLBACK/LOAD_ORDER = 9 модулей
- [x] V26.0.20D: **модуль Настройки** (Settings) — язык RU/EN, тема Dark/Light, палитра accent-цветов, прозрачность меню (0–85%); GC API `SetLanguage`/`SetTheme`/`SetAccent`/`SetHubTransparency` + `ApplyAppearance`/`RebuildHub`; STRINGS.en; Config `accent`+`ui.transparency`; FALLBACK/LOAD_ORDER = 10 модулей
- [x] V26.0.21D: **цвета по палитре** — тумблеры/quick-toggle/треки слайдеров берут `P.accent`/`P.accentOn`/`P.btn`/`P.textDim` вместо хардкода cyan; `accent` в Config только при ручном выборе (сброс → цвет темы); `accentDim` для featured-обводки; fix `btn.Parent` в SpeedWindow, palette в JumpWindow makeToggle
- [x] V26.0.22D: **i18n + убран дубль «Настройки»** — карточка Settings = «Интерфейс»/`Interface`; Name/Desc всех модулей через `GC:Str` (функции); вкладки Player/Server/Settings локализованы; `RefreshTitles` при смене языка; подписи Speed/TP/NoClip/Jump/Settings UI на RU+EN
- [x] V26.0.23D: **Server + scroll + fix transparency** — GS `ServerLogic` (Anti-AFK Idled/VirtualUser) + GM `ServerWindow` (GetTable=Server, QuickToggle); Settings content в ScrollingFrame (окно 300×340); `ApplyHubTransparency` — hub+header+tabs+grip+statusLine (раньше видна была только прозрачная подложка hub, шапка/tabs оставались opaque); FALLBACK/LOAD_ORDER = 12
- [x] V26.0.24D: **профили + TP persist + transparency на модулях** — Settings секция «Сохранения» (Сохранить/Загрузить-picker/Сброс) в `GlobalSystemFiles/Profiles/<placeId>.json` (placeName через MarketplaceService); автозагрузка профиля при входе в игру (`TryAutoLoadProfile`); TP-точки → `Config.modules.TPWindow.points` + `RestoreTPPoints` на старте; `ApplyHubTransparency` + `WindowBase` embedded Root/Header; deep `mergeConfig`
- [x] V26.0.25D: **fix статус + fix transparency в модулях** — статус «Загружено модулей: N» = `CountUIModules` (только GetTable-карточки, не Logic/WindowBase — было 12 vs 6 карточек); `ApplyHubTransparency` идёт по Registry и гасит Section/StateCard/SliderBox/Empty + panel-bg фреймы (раньше только Root — внутри модуля всё opaque); `ApplyHubTransparency` после успешного OpenInHub
- [x] V26.0.26D: **fix кнопки Save/Load/Delete + fix ползунок α + fix счётчик** — `makeBtn.Size` был `UDim2.new(w, -6,…)` (Scale → текст уезжал) → `fromOffset`; третья кнопка = **Delete**/«Удалить» (`settingsResetAll`); слайдер прозрачности: хит-зона TextButton 40px (трек 6px на таче не попадал), трек 8px; статус «карточек N · файлов M» = сумма `_byTab` (не путает Logic+WindowBase с карточками); EMBEDDED sync
- [x] V26.0.27D: **A не сбрасывалась при выходе из модуля** — раньше `ApplyHubTransparency` вызывался только в `OpenInHub` (видно только внутри модуля), а `RenderTab`/`ExitModuleView` пересоздавали карточки/hub без A → теперь A переприменяется в конце `RenderTab`, в `ExitModuleView`, `ShowHub`, `←`-кнопке, табе, `RebuildHub`, `BuildHub`, после `OpenInHub`/ошибки; карточки рождаются уже с `BackgroundTransparency = GetHubTransparency()`; `WindowBase:Destroy` (embedded) тоже рендерит hub + A
- [x] V26.0.28D: **A внутри модуля** — fix walk: раньше alpha ставилась на **таблицу** `win`, а не на `win.Root` (модуль почти не гасился); теперь paint по `Root`/`Header`/`Content`/всем descendants: имена `Section|StateCard|SliderBox|Empty|Content|*Root|Header` + panel-цвета `(23,28,37)/(15,19,29)/(27,32,41)/(38,42,52)`; SKIP `Track/Fill/Knob/Accent/Thumb/AlphaHit`; `ModuleHost` = fully transparent; EMBEDDED sync
- [x] V26.0.29D: **light-панели в A** — `isSolidPanel` больше не хардкодит только dark RGB; собирает panel-цвета (`bg/header/panel/panelAlt/btn`) из `THEMES.dark` + `THEMES.light` + текущих `Theme`/`ModuleTheme` (tol 8) — светлые секции/карточки/кнопки в модулях тоже гаснут; EMBEDDED не трогали (Apply только в GC)
- [x] V26.0.30D: **Server → Spoofing + Players + FastHeal** — старый Anti-AFK (`ServerLogic`/`ServerWindow`) удалён; вкладка Server: **Spoofing** (`GetTable=Server`, pos 1, QuickToggle; 3 флага speed/jump/tp: keep-loop 0.08s + опц. `hookmetamethod` __index spoof WalkSpeed/JumpPower→base когда Speed/Jump выкл; wrap `TPLogic.teleportTo` → `noteTeleport` lock 1.2s) и **Players** (pos 2, QuickToggle; Highlight accent + Billboard name·dist·m·HP%, тумблеры dist/hp); вкладка Player: **FastHeal** (pos 5, QuickToggle; +HP/тик 1–50 из Config); STRINGS RU/EN; Config без ServerWindow; FALLBACK/LOAD_ORDER = 16; EMBEDDED 16; `luac` OK
- [x] V26.1.0R: **релиз** — пользователь подтвердил на устройстве (Spoofing/Players/FastHeal работают); bump demo→release

## Дальше

- [ ] Тема light: проверить на устройстве, доработать контраст (0.29D — A на light; контраст текста/акцентов отдельно)
- [ ] Spoofing/Players/FastHeal: проверить на устройстве (ESP billboard, флаги обхода, хил +HP/тик)
- [ ] Иконки: путь в Config сейчас имя файла, нужен путь к Assets (getcustomasset)
- [ ] Анти-чит обходы: ревизия TP-форса, speed keep (проверить в актуальных играх)
- [ ] Ещё демо-модуль (например, Noclip) для проверки позиционирования вкладок → частично: Noclip/Jump сделаны, Server добавлен
- [ ] Diagnostics-скрипт (по образцу Test.lua из истории git) — грузится ли Base/Config
- [ ] i18n: hub+карточки+основные подписи модулей EN есть; остатки: статусы ON/OFF внутри модулей, toast/логи
- [ ] надо продумать компактность хаба очень длинный надо чтоб можно было увилечивать и уменьшить 
- [ ] Load picker: сейчас берётся список всех профилей — при many profiles нужен scroll в picker

## Если тут есть задача ее надо делать сразу!

- [x] есть проблема когда я выбираю какой то модуль он посылается не так как хочется
я хочу чтоб он должен быть сразу доступен 
  → V26.0.7D: после успешного Open хаб прячется (лаунчер [N] остаётся); окно модуля DisplayOrder=20 поверх хаба (10); ClaimPosition ищет свободное место по спирали, а не по диагонали (раньше окно могло уехать далеко/под хаб)
↑ я просил чтоб он сразу был доступен то есть без открытие одного окна!
  → V26.0.8D: **без отдельного окна** — модуль рендерится прямо в хабе (ModuleHost); карточки скрываются, ← возвращает; отдельное ScreenGui/ClaimPosition не используется

- [x] Speed: без клавиатуры — ползунок (значение сразу при тяге) + toggle ON/OFF; открытие модуля = внутри хаба
  → V26.0.9D: TextBox/Применить убраны; makeSlider + makeToggle; ON применяет/держит скорость, OFF сбрасывает; min/max в Config.modules.SpeedWindow
  
  
  
  
  
  