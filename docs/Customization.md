# Window and appearance

[Documentation home](README.md) · [Controls](Controls.md) · [Layout](Layout.md)

## Create a window

```lua
local Window = Library:CreateWindow({
    Title = "My menu",
    Subtitle = "My project",
    Footer = "v1.0",
    Size = Vector2.new(640, 500),
    MinSize = Vector2.new(480, 360),
    MaxSize = Vector2.new(1100, 800),
    Position = UDim2.fromScale(0.5, 0.5),
    Resizable = true,
    Draggable = true,
    ToggleKey = "LeftControl",
    ShowSettings = true,
    ShowMinimize = true,
    ShowClose = true,
    ShowLauncher = true,
    ShowUserInfo = true,
    ShowFooter = true,
    Transparency = 0,
    Scale = 1,
})
```

| Option | Type | Default | Behavior |
| --- | --- | --- | --- |
| `Title` | string | `"vortex"` | Header title |
| `Subtitle` | string | `"by shrak."` | Header subtitle |
| `Footer` | string | `""` | Footer text, temporarily replaced by notifications |
| `Size` | Vector2 | `580, 460` | Initial dimensions in layout pixels |
| `MinSize` | Vector2 | `400, 300` | Minimum dimensions; cannot be below 400 × 300 |
| `MaxSize` | Vector2 | `1600, 1200` | Maximum dimensions |
| `Position` | UDim2 | centered | Window anchor position |
| `Resizable` | boolean | false | Show a resize handle in the lower-right corner |
| `Draggable` | boolean | true | Allow dragging by the header |
| `AutoShow` | boolean | true | Initial visibility |
| `Scale` | number | 1 | Maximum scale; automatically reduced to fit the viewport |
| `ToggleKey` | string or EnumItem | `"LeftControl"` | Menu visibility key |
| `Transparency` | number, 0–1 | 0 | Window background transparency |
| `ShowSettings` | boolean | true | Show the header gear |
| `ShowMinimize` | boolean | true | Show minimize |
| `ShowClose` | boolean | true | Show close/unload |
| `ShowUserInfo` | boolean | true | Show avatar and user details |
| `ShowFooter` | boolean | true | Show normal footer text; notifications remain available |
| `ShowLauncher` | boolean | true | Show the independent launcher |
| `LauncherText` | string | `"V"` | Launcher lettering |
| `LauncherIcon` | asset string or number | nil | Replace launcher text with an image |
| `LauncherPosition` | UDim2 | `22, 104` offset | Initial launcher position |
| `DisplayOrder` | number | 10000 | Menu ScreenGui display order |
| `Parent` | Instance | automatic | Custom GUI parent; normally `PlayerGui` in Studio |
| `Theme` | table | nil | Initial palette overrides |
| `Style` | table | nil | Initial typography and spacing overrides |

Minimize hides the window. The launcher or menu key reopens it. Close unloads the library and removes the launcher. Hidden header buttons leave no empty gaps.

## Runtime methods

```lua
Window:SetSize(Vector2.new(700, 540))
Window:SetPosition(UDim2.fromOffset(500, 350))
Window:Center()
Window:SetScale(0.9)
Window:SetTransparency(0.1)
Window:SetSubtitle("Updated subtitle")
Window:SetResizable(true)
Window:SetLauncherVisible(false)
Window:SetHeaderButtons({ Settings = false, Minimize = true, Close = true })
Window:Toggle(false)
Window:Toggle(true)
```

Size setters clamp to `MinSize`/`MaxSize` and reflow groups and nested controls. `SetScale` accepts a number greater than zero and at most three. `Toggle()` with no argument toggles visibility; a boolean forces a state.

```lua
local windowSize, menuVisible = Vector2.new(640, 500), true
Window:OnResize(function(size) windowSize = size end)
Window:OnToggle(function(visible) menuVisible = visible end)
```

Other window methods are [listed in the API reference](API.md#window). One library instance manages one window. Load a fresh library instance after unloading; Studio's `require` cache is discussed in [getting started](GettingStarted.md).

## Style settings

```lua
Library:SetStyle({
    FontFamily = "rbxassetid://12187365364",
    TextSize = 14,
    TextTransparency = 0.3,
    RowSpacing = 8,
    GroupSpacing = 12,
    CardPadding = 18,
    VerticalPadding = 12,
    WindowRadius = 12,
    ControlRadius = 7,
    AnimationDuration = 0.15,
})
```

`SetStyle` updates current controls and layout, and supplies defaults for controls created later. Header title sizes and compact numeric fields retain their own hierarchy; `TextSize` controls row labels. Changing `FontFamily` updates text throughout the menu while preserving font weight.

| Setting | Default | Valid range |
| --- | --- | --- |
| `FontFamily` | `rbxassetid://12187365364` | Nonempty Roblox font asset URI |
| `TextSize` | 13 | 9–24 |
| `TextTransparency` | 0.4 | 0–1 |
| `RowSpacing` | 6 | 0–24 |
| `GroupSpacing` | 10 | 0–32 |
| `CardPadding` | 16 | 8–32, horizontal padding |
| `VerticalPadding` | 12 | 4–28 |
| `WindowRadius` | 10 | 0–24 |
| `ControlRadius` | 6 | 0–18; cards use this value plus two |
| `AnimationDuration` | 0.13 | 0–1 seconds |

Invalid styles are rejected before any settings change. `Library:GetStyle()` returns a copy, so editing that table does not change the live UI. Header hover circles and functional toggle/slider shapes keep their intended geometry when corner settings change.

## Colors and themes

```lua
Library:SetTheme({
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(26, 26, 26),
    Accent = Color3.fromRGB(146, 173, 255),
})
```

Palette roles are `Background`, `Surface`, `Border`, `Text`, `Muted`, `Accent`, and `Track`. Values must be Color3 objects. `GetTheme()` returns a copy. Palette changes repaint theme-bound elements; small decorative details retain their original neutral colors.

```lua
ThemeManager:SetLibrary(Library)
ThemeManager:AddTheme("My theme", {
    Background = Color3.fromRGB(13, 16, 24),
    Accent = Color3.fromRGB(146, 173, 255),
})
ThemeManager:SetDefault("My theme")
ThemeManager:ApplyToTab(Appearance, { Name = "Appearance", ShowTitle = true })
```

Custom palettes inherit omitted roles from Graphite. Built-in themes are Graphite, Midnight, and Rose. `ApplyToGroupbox(existingGroup)` adds the selector and accent picker to an existing group. `GetThemeNames()` returns sorted names; `GetTheme(name)` returns a palette copy. Build the theme controls once per library because their IDs are shared.
