# API

## Library

| Member | Purpose |
| --- | --- |
| `Version` | Version string |
| `Options` | Indexed inputs, sliders, dropdowns, key pickers, and color pickers |
| `Toggles` | Indexed toggles |
| `Theme` | Active palette |
| `Icons` | Named icon asset IDs; add your own before creating tabs |
| `Unloaded` | Whether `Unload` has run |
| `CreateWindow(options)` | Create one window |
| `SetTheme(colors)` | Update palette roles and repaint existing elements |
| `Notify(message, duration?)` | Show a notification, including while the menu is hidden |
| `OnUnload(callback)` | Register synchronous cleanup |
| `Unload()` | Disconnect global signals, destroy the GUI, and clear registries |
| `Connect(signal, callback)` | Connect a signal that will be disconnected on unload |

`Notify` accepts a string or `{ Title = "Saved", Description = "Configuration saved", Duration = 3 }`. It returns the notification Frame. Destroy that Frame to dismiss it early.

## Window

```lua
local Window = Library:CreateWindow({
    Title = "vortex",
    Subtitle = "by shrak.",
    Footer = "v1.0.0",
    Size = Vector2.new(580, 460),
    Position = UDim2.fromScale(0.5, 0.5),
    ToggleKey = "LeftControl",
    AutoShow = true,
    ShowUserInfo = true,
    ShowLauncher = true,
    LauncherText = "V",
    LauncherPosition = UDim2.fromOffset(22, 104),
    Scale = 1,
    DisplayOrder = 10000,
})
```

`Parent` optionally specifies a GUI container such as `PlayerGui`. Otherwise the library tries `gethui()` or `CoreGui`, then falls back to `PlayerGui`. `Size` is a Vector2 of at least 400 × 300. `Scale` sets the maximum scale; the window shrinks to fit the viewport. The close button hides the window. The launcher remains available.

| Method | Behavior |
| --- | --- |
| `AddTab(name, icon?)` | Add a uniquely named tab; icon can be a named icon or asset ID |
| `SelectTab(name)` | Select a tab; returns it |
| `SetVisible(boolean)` | Show/hide the window |
| `Toggle()` | Toggle window visibility |
| `SetTitle(text)` | Change title text |
| `SetFooter(text)` | Change footer text |
| `SetUserInfoVisible(boolean)` | Show/hide avatar and user details |
| `SetToggleKey(key)` | Set a key name or EnumItem |
| `Destroy()` | Unload the library |

`Window.Tabs[name]` stores tabs. `Frame`, `Gui`, `Launcher`, and `Scale` expose their Roblox instances.

## Tabs and groupboxes

```lua
local Main = Window:AddTab("Main", "rocket")
local Full = Main:AddGroupbox("General")
local Left = Main:AddLeftGroupbox("Left")
local Right = Main:AddRightGroupbox("Right")
local Custom = Main:AddGroupbox({ Name = "Options", Side = "Full" })
```

`Side` accepts `Full`, `Left`, or `Right`, case-insensitively. Full-width groupboxes appear first; paired columns follow. Both columns share the page scroll. `Tab:Select()` selects the tab. Groupboxes expose `Frame` and `Content`.

## Shared control behavior

Indexed controls take `id, options`. IDs must be nonempty strings and unique across both registries. `Text`, `Visible` (default true), and `Disabled` (default false) are common options. `Callback(value)` is supported on value controls. Defaults initialize silently.

| Method/property | Behavior |
| --- | --- |
| `Value` | Current value |
| `SetValue(value, silent?)` | Validate and set value; returns success |
| `OnChanged(callback)` | Add a listener for value changes; returns the control |
| `SetText(text)` | Change label text |
| `SetVisible(boolean)` | Change visibility and close an open picker |
| `SetDisabled(boolean)` | Block user interaction; programmatic updates still work |
| `Frame`, `Label` | Underlying Roblox instances |

Callbacks run through `task.spawn` with protected error handling. Changes to the same value do not emit again. Dropdown tables are copied before storage and callback delivery; update selections through `SetValue` rather than mutating `Value` directly. Register callbacks before loading configs. Keybind `OnChanged` reports binding changes; `OnClick` reports activation.

## Toggles and buttons

```lua
Group:AddToggle("Enabled", { Text = "Enabled", Default = false })
Group:AddButton("Run action", function() print("Pressed") end)
Group:AddButton({ Text = "Run action", Func = function() print("Pressed") end })
```

Toggles store booleans in `Library.Toggles`. Buttons are unindexed and expose `Press()` and `Button`.

## Sliders

```lua
Group:AddSlider("Opacity", {
    Text = "Opacity", Min = 0, Max = 1, Default = 0.5, Rounding = 2,
})
```

`Min` and `Max` default to 0 and 100. `Max` must exceed `Min`. `Rounding` is the number of decimal places, from 0 to 6. Values are rounded and clamped. Sliders accept mouse/touch dragging and numeric text entry. NaN and infinite values are rejected.

## Inputs

```lua
Group:AddInput("Name", {
    Text = "Name", Default = "", Placeholder = "Enter a name",
    Numeric = false, Finished = true, MaxLength = 64,
})
```

Inputs store strings. `Numeric` accepts only finite numeric strings. `Finished = true` commits on focus loss; false updates valid values while typing. `MaxLength` is an optional byte limit.

## Dropdowns

```lua
Group:AddDropdown("Mode", {
    Text = "Mode", Values = { "Balanced", "Smooth", "Fast" }, Default = "Balanced",
    Searchable = true, MaxVisibleDropdownItems = 6,
})
Group:AddDropdown("Filters", {
    Text = "Filters", Values = { "One", "Two", "Three" },
    Multi = true, Default = { One = true, Three = true },
})
```

`Values` must be an array of unique strings. A single dropdown stores a string or nil. A multi dropdown stores a dictionary of selected names to true. `Default` accepts a string or one-based index; multi dropdowns also accept a dictionary. `SetValues(array, silent?)` replaces choices and removes unavailable selections. `SetOpen(boolean)` expands/collapses the inline list. Only one dropdown is open at a time. Expanded lists have a bounded height and scroll internally.

## Key pickers

```lua
local Key = Group:AddKeyPicker("ActionKey", {
    Text = "Action key", Default = "F", Mode = "Toggle",
    Callback = function(active) print(active) end,
    ChangedCallback = function(key) print("Bound to", key) end,
})
Key:OnClick(function(active) print(active) end)
Key:OnChanged(function(key) print(key) end)
Key:SetValue({ "G", "Hold" })
```

`Mode` accepts `Toggle`, `Hold`, `Press`, or `Always`. `GetState()` returns activation state, or false when disabled. Press callbacks receive true and then state resets. Always state remains true while enabled without repeated activation callbacks. Bindings accept Roblox KeyCode names, `MB1`, `MB2`, `MB3`, or `None`. Typing and processed input suppress activation. Hold key release still clears its state while typing.

Click the binding to capture a new key. Escape cancels and Backspace clears. `ChangedCallback`/`OnChanged` receive the key name. Mode changes also emit a binding change. `Value` stores the key name; `Mode` stores the mode.

## Color pickers

```lua
local Color = Group:AddColorPicker("Highlight", {
    Text = "Highlight", Default = Color3.fromRGB(100, 180, 255), Transparency = 0,
})
Color:SetValueRGB(Color3.fromRGB(255, 100, 150), 0.25)
```

Click the swatch to reveal hue, saturation, brightness, and a six-digit hex input. Setting `Transparency` enables its slider; omit it for an opaque picker. `Value` is a Color3. `Transparency` is a number from 0 to 1. `SetValueRGB(color, transparency?, silent?)` updates both. `SetValue(color, silent?)` keeps transparency. Callbacks receive the Color3; read `Transparency` from the control for alpha.

Labels and toggles also support chained `AddColorPicker(id, options)` and `AddKeyPicker(id, options)`. These add a new row immediately after the parent and return the parent for further chaining. `SyncToggleState = true` on a chained toggle key picker links activation and toggle state.

## Labels and dividers

```lua
Group:AddLabel("A short label")
Group:AddLabel("A longer label that wraps to fit the groupbox.", true)
Group:AddDivider()
```

## ThemeManager

| Method | Behavior |
| --- | --- |
| `SetLibrary(Library)` | Attach to a library |
| `SetDefault(name)` | Choose the initial theme |
| `AddTheme(name, colors)` | Register a custom palette; omitted roles inherit Graphite |
| `ApplyTheme(name)` | Apply a named theme |
| `ApplyToTab(tab)` | Add the theme selector and accent picker |

Built-in themes: `Graphite`, `Midnight`, `Rose`. Palette roles: `Background`, `Surface`, `Border`, `Text`, `Muted`, `Accent`, `Track`. Each role takes a Color3. To change just the accent directly, call `Library:SetTheme({ Accent = color })`.

## SaveManager

| Method | Behavior |
| --- | --- |
| `SetLibrary(Library)` | Attach to a library |
| `SetFolder(path)` | Set a relative storage folder |
| `SetStorage(adapter)` | Supply storage functions |
| `SetIgnoreIndexes({ id, ... })` | Add IDs to the exclusion set |
| `IgnoreThemeSettings()` | Exclude theme selector and accent picker |
| `Save(name)` | Write a named JSON configuration |
| `Load(name)` | Validate all recognized values, then apply them |
| `Delete(name)` | Delete a config and clear its autoload pointer if selected |
| `RefreshConfigList()` | Return `success, sortedNamesOrError` |
| `SetAutoloadConfig(name)` | Select an existing config for loading on startup |
| `ClearAutoloadConfig()` | Remove the autoload selection |
| `LoadAutoloadConfig()` | Load the selected config, if any |
| `BuildConfigSection(tab)` | Add save/load/delete/refresh/autoload controls |

File operations return `true, result` or `false, error`; errors are caught. Config names use letters, digits, underscores, or hyphens, up to 64 characters. Files are stored at `<folder>/settings/<name>.json`; autoload uses `<folder>/autoload.txt`. There is no periodic autosave. Call `Save` when you want to persist current values.

Unknown control IDs are skipped when loading. Invalid values or type mismatches for existing controls reject the config before any values are applied. Sliders clamp numeric values to their current range. Loading emits normal change callbacks. Saved keybinds include their mode; saved colors include transparency.

Use `IgnoreThemeSettings` when theme selection should remain independent of game settings. The generated config name/list controls always exclude themselves from saved configs.
