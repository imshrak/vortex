# Dialogs and overlays

[Documentation home](README.md) · [Customization](Customization.md)

## Dialogs

```lua
local Dialog = Library:Dialog({
    Title = "Reset settings?",
    Content = "Your controls will return to their initial values.",
    Width = 380,
    Height = 210,
    Buttons = {
        { Text = "Reset", Callback = function() Library:ResetAll() end },
        { Text = "Cancel" },
    },
})
```

Dialogs are centered inside the window and open it if hidden. The background dims, dropdowns close, and menu keybind activation is suspended until dismissal. Escape closes the dialog. Opening another dialog dismisses the previous one.

| Option | Default | Behavior |
| --- | --- | --- |
| `Title` | `"Vortex"` | Heading |
| `Content` | empty | Wrapped body text; Description is also accepted |
| `Width` | 380 | At least 240, clamped to available window width |
| `Height` | 210 | At least 160, clamped to available window height |
| `Buttons` | one OK button | Array of one to three button tables |

Each button has `Text`, optional `Callback`, and `Close` (default true). Set `Close = false` to keep the dialog open after the action. Callbacks run after automatic closing. Returned fields are `Frame`, `Buttons`, and `Closed`; `Dialog:Close()` dismisses it safely. Keep content brief or increase Height for longer messages.

## Footer notifications

```lua
Library:Notify("Settings saved", 3)
Library:Notify({ Title = "Saved", Description = "Configuration updated", Duration = 3 })
```

Notifications temporarily replace the footer and use the same compact styling as the menu. A newer message replaces the previous message. The returned TextLabel is shared. Notifications appear inside the window, so minimizing hides them. `ShowFooter = false` hides the normal footer without disabling notifications.

## Watermark

```lua
local Watermark = Library:SetWatermark("My project · v1.0", {
    Position = UDim2.fromOffset(16, 16),
    Width = 300,
})
Library:SetWatermark(nil)
```

Watermarks are optional text overlays. Position defaults to 16,16 and Width to 300 pixels. Width must be at least 40. Passing nil or an empty string hides it. The returned TextLabel can be styled directly. It belongs to the main ScreenGui and remains available when the window frame is minimized.

## Keybind menu

```lua
Library:SetKeybindsVisible(true, {
    Position = UDim2.fromOffset(16, 180),
    Width = 210,
})
```

The menu lists key pickers by ID, with their display labels and assigned keys. Active bindings use brighter text. Clicking a Toggle-mode row changes its state, including on touch devices. Hold and Press modes remain driven by their normal input behavior. `NoUI = true` on a key picker excludes it from this list.

The overlay lives in the launcher ScreenGui and remains visible while the main window is minimized. Width must be at least 120. Passing false hides it. `Library.KeybindFrame` exposes the Frame after creation. `UpdateKeybindMenu()` explicitly rebuilds the list when needed; binding and activation changes also update it.
