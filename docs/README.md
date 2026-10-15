# Vortex documentation

Build a Roblox menu with your own controls, behavior, branding, and themes. The default layout is compact, with horizontal tabs and a neutral header. Every feature below is part of Vortex's own API.

## Start here

1. [Getting started](GettingStarted.md): installation, Studio, structure, and storage adapters.
2. [Quick example](../Example.lua): the smallest complete setup with themes and configurations.
3. [Advanced example](../examples/Advanced.lua): resizing, dependencies, tabboxes, dialogs, overlays, import/export, and style controls.

## Guides

| Guide | Contents |
| --- | --- |
| [Window and appearance](Customization.md) | Constructor options, size bounds, header actions, typography, spacing, corners, palettes |
| [Controls](Controls.md) | Shared options, validation, stepped sliders, dictionary dropdowns, tooltips, reset, lifecycle |
| [Layout and dependencies](Layout.md) | Tabs, columns, collapsible groups, tabboxes, conditional rows and sections |
| [Dialogs and overlays](Dialogs.md) | Modal dialogs, footer notifications, watermark, keybind menu |
| [Configuration](Configuration.md) | Profiles, autoload, exclusions, JSON import/export, storage integration |
| [API reference](API.md) | Core methods, examples, addon APIs, and links to detailed options |

## Loading

```lua
local repo = "https://raw.githubusercontent.com/imshrak/vortex/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Window = Library:CreateWindow({ Title = "My menu", Subtitle = "My project" })
local Main = Window:AddTab("Main", "rocket")
local General = Main:AddGroupbox("")
General:AddToggle("Enabled", { Text = "Enabled", Default = false })
```

The HTTP loader needs an environment with `loadstring` and `game:HttpGet`. In Studio, use `require` on the library ModuleScript from a LocalScript. See [installation](GettingStarted.md).

## Values and callbacks

Toggles and checkboxes are stored in `Library.Toggles`. Other indexed controls are in `Library.Options`. IDs must be unique across both tables, including controls on different tabs.

```lua
Library.Toggles.Enabled:OnChanged(function(value)
    print("Enabled:", value)
end)
Library.Toggles.Enabled:SetValue(true)
Library.Toggles.Enabled:SetValue(false, true)
Library.Toggles.Enabled:Reset()
```

Defaults do not invoke callbacks. The second `SetValue` argument suppresses callbacks. Dependencies still refresh immediately. Attach behavior before loading settings. `Library:Unload()` destroys both menu and launcher and disconnects global input listeners.

## API scope

Vortex uses a familiar window → tab → groupbox structure. Its supported options are documented here; it does not implement every option in Obsidian or act as a drop-in replacement. Existing `v1.1` scripts continue to use the same default layout and methods.
