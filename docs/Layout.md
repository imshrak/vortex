# Layout and dependencies

[Documentation home](README.md) · [Controls](Controls.md)

## Tabs

```lua
local Main = Window:AddTab("Main", "rocket")
local Tools = Window:AddTab({ Name = "Tools", Icon = "grid", Width = 100, Visible = true })
Tools:SetName("Utilities")
Tools:SetWidth(110)
Tools:SetVisible(false)
Tools:SetVisible(true):Select()
```

Tab options are `Name`, `Icon`, `Width`, and `Visible`. Width must be at least 40 pixels. Existing names retain the familiar default widths; custom names receive an estimated width. Pass Width when a label needs more room.

Hiding a selected tab selects the first remaining visible tab. Hiding every tab leaves the page area empty. Showing a tab when none is selected selects it. `Window.Tabs` updates when a tab is renamed. Renaming preserves its width; call `SetWidth` if needed.

## Groupboxes

```lua
local General = Main:AddGroupbox("")
local Extra = Main:AddGroupbox({
    Name = "Extra settings", ShowTitle = true,
    Description = "A short description", MinHeight = 42,
    Side = "Full", Visible = true,
    Collapsible = true, Collapsed = false,
})
Extra:SetCollapsed(true)
Extra:SetDescription("Updated description")
Extra:Hide()
Extra:Show()
```

| Option | Default | Behavior |
| --- | --- | --- |
| `Name` | empty | Group name |
| `Side` | Full | Full, Left, or Right; case-insensitive |
| `ShowTitle` | false | Show the group heading |
| `Description` | empty | One-line description; enables heading layout |
| `MinHeight` | 288 for the first full-width group, otherwise 42 | Minimum expanded height |
| `Visible` | true | Initial visibility |
| `Collapsible` | false | Enable a clickable heading; forces ShowTitle |
| `Collapsed` | false | Initially collapse a collapsible group |

Full-width groups appear first. Left and right groups follow in paired columns with a shared page scroll. Use `AddLeftGroupbox(name)` and `AddRightGroupbox(name)` as shortcuts. Hidden groups leave no layout gap. Collapsing closes open pickers in that group and removes body height while retaining its heading. `SetDescription` requires a heading.

## Tabboxes

Tabboxes switch between small pages inside a group. Each page supports the normal AddToggle/AddInput/AddSlider methods.

```lua
local Tabbox = Main:AddTabbox({ Name = "Settings", ShowTitle = true, MinHeight = 42, TabWidth = 100 })
local Display = Tabbox:AddTab("Display")
local Audio = Tabbox:AddTab("Audio")
Display:AddToggle("Effects", { Text = "Effects", Default = true })
Audio:AddSlider("Volume", { Text = "Volume", Min = 0, Max = 100, Default = 65 })
Tabbox:SelectTab("Audio")
Display:Select()
```

You can also call `existingGroup:AddTabbox({ TabWidth = 100 })`. `TabWidth` is optional; page names otherwise receive an estimated width. The tab strip scrolls horizontally if needed. The outer group resizes to the selected page. `AddLeftTabbox()` and `AddRightTabbox()` create column tabboxes.

## Conditional rows

```lua
local Enabled = General:AddToggle("Enabled", { Text = "Enabled", Default = false })
local Amount = General:AddSlider("Amount", { Text = "Amount", Min = 0, Max = 100, Default = 50 })
Amount:DependsOn({ { Enabled, true } })
```

Dependencies accept control objects or registered ID strings. All conditions must match. With the default Visible mode, unmatched rows disappear and layout reflows.

```lua
Amount:DependsOn({ { "Enabled", true } }, "Disabled")
```

Disabled mode keeps the row visible but blocks editing while conditions are unmet. Manual visibility/disabled settings remain in force. Empty conditions remove dependencies. Rules refresh synchronously for both normal and silent value changes.

Predicates support more complex conditions:

```lua
local Details = General:AddInput("Details", { Text = "Details", Default = "", Width = 160 })
Details:DependsOn({ { Enabled, true }, { Amount, function(value) return value >= 50 end } })
```

Predicates receive the current value and must return true to match. An omitted expected value means true. They should not yield. Predicate errors are caught and treated as unmet conditions. Do not use dependencies that cause their own source values to change.

## Conditional sections

```lua
local Advanced = General:AddDependencyBox()
Advanced:AddInput("Label", { Text = "Label", Default = "Custom", Width = 140 })
Advanced:AddSlider("Size", { Text = "Size", Min = 1, Max = 10, Default = 5 })
Advanced:SetupDependencies({ { Enabled, true } })
```

Dependency boxes contain normal controls and appear inline without an extra card border. Their entire section collapses when conditions are unmet. IDs remain global across tabs, tabboxes, and dependency boxes, so configurations can restore all controls regardless of current visibility.
