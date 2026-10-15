# Vortex

A compact Roblox UI library by [shrak](https://github.com/imshrak).

Vortex keeps the graphite palette, horizontal navigation, rounded controls, user footer, and draggable launcher. Its window → tab → groupbox API takes inspiration from [Obsidian](https://github.com/deividcomsono/Obsidian). It is an independent implementation with its own supported API.

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/vortex/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "vortex",
    Subtitle = "by shrak.",
    Footer = "v1.1.3",
})

local Main = Window:AddTab("Main", "rocket")
local General = Main:AddGroupbox("General")

General:AddToggle("Enabled", { Text = "Enabled", Default = false })
General:AddSlider("Amount", { Text = "Amount", Min = 0, Max = 100, Default = 50 })

Library.Toggles.Enabled:OnChanged(function(value)
    print("Enabled:", value)
end)
```

The HTTP loader requires an environment that provides `loadstring` and `game:HttpGet`. For a normal Roblox experience, use a ModuleScript and a LocalScript as described below.

## Included

| File | Purpose |
| --- | --- |
| [Library.lua](Library.lua) | Self-contained client UI library |
| [Example.lua](Example.lua) | Full example with controls, themes, and configs |
| [addons/ThemeManager.lua](addons/ThemeManager.lua) | Graphite, Midnight, Rose, and custom palettes |
| [addons/SaveManager.lua](addons/SaveManager.lua) | Named JSON configs, autoload, and config controls |
| [examples/Studio.client.lua](examples/Studio.client.lua) | LocalScript example for Roblox Studio |
| [docs/API.md](docs/API.md) | Complete supported API |
| [docs/GettingStarted.md](docs/GettingStarted.md) | Installation, structure, and storage adapters |

## Controls

Toggles, buttons, sliders with numeric entry, inputs, searchable single and multi dropdowns, keybinds, color pickers with optional transparency, labels, and dividers. Controls support visibility and disabled states. Windows support mouse/touch dragging, viewport scaling, scrollable tabs and pages, notifications, a menu hotkey, and a draggable launcher.

Use full-width groupboxes for the compact single-card layout. Groupbox titles are hidden by default; enable `ShowTitle` when a visible heading is useful. `AddLeftGroupbox` and `AddRightGroupbox` provide a two-column layout.

## Studio

With Rojo, sync [default.project.json](default.project.json). It creates `ReplicatedStorage.Vortex`, its addon modules, and the example LocalScript in `StarterPlayerScripts`.

Without Rojo, create a ModuleScript named `Vortex` in `ReplicatedStorage` and paste `Library.lua` into it. Add a folder named `addons` beneath it with the two addon ModuleScripts. Put `examples/Studio.client.lua` in `StarterPlayerScripts` and start Play.

The UI works in a client LocalScript. File APIs are optional; the save manager needs a storage adapter when those APIs are unavailable. Keep persistent player data on the server in a normal Roblox experience.

## Themes and configurations

```lua
local repo = "https://raw.githubusercontent.com/imshrak/vortex/main/"
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Settings = Window:AddTab("Settings", "gear")

ThemeManager:SetLibrary(Library):ApplyToTab(Settings)
SaveManager:SetLibrary(Library):SetFolder("VortexUI/MyProject")
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Settings)
SaveManager:LoadAutoloadConfig()
```

Create controls and attach callbacks before loading configs. IDs must be unique across `Library.Options` and `Library.Toggles`. Callbacks run when a value changes; construction does not invoke them. Config operations return `success, resultOrError`.
