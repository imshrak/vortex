# Vortex

A compact Roblox UI library by [shrak](https://github.com/imshrak).

[Documentation](docs/README.md) · [Designer](docs/Designer.md) · [API reference](docs/API.md) · [Advanced example](examples/Advanced.lua)

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/vortex/main/Library.lua"))()

local Window = Library:CreateWindow({ Title = "My menu" })
local Main = Window:AddTab("Main", "rocket")
local General = Main:AddGroupbox("General")

General:AddToggle("Enabled", { Text = "Enabled", Default = false })
General:AddSlider("Amount", { Text = "Amount", Min = 0, Max = 100, Default = 50 })
```

The loader requires `loadstring` and `game:HttpGet`. See [Example.lua](Example.lua) for themes and saved configurations.

## Studio

Sync [default.project.json](default.project.json) with Rojo, or follow the [manual setup](docs/GettingStarted.md#roblox-studio).
