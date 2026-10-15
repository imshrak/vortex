# Controls

[Documentation home](README.md) · [Layout and dependencies](Layout.md) · [API reference](API.md)

## Common options

```lua
local Enabled = Group:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Visible = true,
    Disabled = false,
    Tooltip = "Enable this option.",
    DisabledTooltip = "This option is currently unavailable.",
    Save = true,
    Callback = function(value) print(value) end,
})
```

| Option | Default | Behavior |
| --- | --- | --- |
| `Text` | ID | Display label |
| `Default` | control-specific | Initial value; construction is silent |
| `Visible` | true | Initial row visibility |
| `Disabled` | false | Prevent user interaction; programmatic setters still work |
| `Tooltip` | nil | Text on mouse hover |
| `DisabledTooltip` | nil | Override tooltip while disabled |
| `Save` | true | Include in saved/exported configs; false also excludes imported values |
| `Callback` | nil | Run when the value changes |

Check boxes and toggles live in `Library.Toggles`. Inputs, sliders, dropdowns, key pickers, and color pickers live in `Library.Options`. All IDs must be unique across both registries. Labels, paragraphs, images, buttons, dividers, and layout containers are unindexed.

## Shared methods

```lua
Enabled:OnChanged(function(value) print(value) end)
Enabled:SetValue(true)
Enabled:SetValue(false, true)
Enabled:SetText("New label")
Enabled:SetTooltip("Updated tooltip")
Enabled:SetVisible(false)
Enabled:SetDisabled(true)
Enabled:Reset()
Enabled:Destroy()
```

`SetValue` returns success. The optional `silent` argument suppresses user callbacks. Dependencies update even when changes are silent. `Reset(silent?)` restores the initial normalized value, including keybind mode or color transparency. It returns false if a dropdown default is no longer among its choices. `Destroy()` removes the control, disconnects dependency subscriptions, and frees its ID for reuse.

`SetCallback(function)` replaces the primary value callback. `OnChanged` adds listeners. For key pickers, these report binding changes; use `OnClick` or the constructor's `Callback` for activation. Tooltips use mouse hover; essential instructions should also appear in labels or paragraphs for touch users.

`Library:ResetAll({ "IgnoredID", ... })` resets every indexed control except IDs in the supplied array. `Save = false` affects persistence, not resetting.

## Toggles and checkboxes

```lua
Group:AddToggle("Enabled", { Text = "Enabled", Default = false })
Group:AddCheckbox("Remember", { Text = "Remember selection", Default = true })
```

Both store booleans and share config behavior. Checkboxes use a compact square indicator. Toggle `Type` remains `"Toggle"` for both; checkbox controls also have `Kind = "Checkbox"`.

## Buttons and confirmation

```lua
Group:AddButton("Run action", function() print("Pressed") end)
Group:AddButton({
    Text = "Reset settings",
    DoubleClick = true,
    ConfirmText = "Click again to reset",
    Tooltip = "Requires a second click.",
    Func = function() Library:ResetAll() end,
})
```

`DoubleClick` arms the button on the first click. A second click within three seconds invokes the action. The temporary label uses `ConfirmText` or `"Click again to confirm"`. Disabled buttons cannot arm or run. `Press()` follows the same rules and returns whether it invoked the action. For richer confirmation, use a [dialog](Dialogs.md).

## Sliders

```lua
local Amount = Group:AddSlider("Amount", {
    Text = "Amount", Min = 0, Max = 10, Default = 2.5,
    Step = 0.25, Rounding = 2, Suffix = "x",
})
Amount:SetRange(1, 20)
Amount:SetSuffix(" units")
```

`Min`/`Max` default to 0/100; Max must exceed Min. `Step` optionally snaps values relative to Min. `Rounding` accepts 0–6 decimal places; it defaults to zero, or is inferred from Step when Step is provided. `Suffix` defaults to an empty string and does not affect the numeric `Value`.

`SetRange` validates and clamps the current value. `SetValue` accepts finite numbers or numeric strings. Numeric entry accepts the configured suffix. Mouse and touch dragging work across the track.

## Inputs

```lua
local Name = Group:AddInput("Name", {
    Text = "Name", Default = "Player", Width = 180, MaxLength = 64,
    Placeholder = "Enter a name", Finished = true,
    Validator = function(value) return value:match("%S") ~= nil end,
})
local Note = Group:AddInput("Note", {
    Text = "Notes", Default = "", Multiline = true, Height = 110,
})
```

| Option | Default | Behavior |
| --- | --- | --- |
| `Numeric` | false | Accept finite numeric strings |
| `AllowEmpty` | false | Permit an empty numeric value |
| `Finished` | true | Commit on focus loss; false commits valid changes while typing |
| `Width` | 58 | Width of a compact field |
| `MaxLength` | nil | Optional positive byte limit |
| `Validator` | nil | Synchronous predicate returning true to accept a value |
| `Multiline` | false | Full-width editor below the label |
| `Height` | 104 when multiline | Total multiline row height |
| `Placeholder` | empty | Empty-field hint |

Inputs always store strings. Invalid values are rejected; invalid committed drafts revert to the previous value. Validators must return a boolean and should not yield. Validation errors are caught and treated as rejection. `SetPlaceholder(text)` changes the hint.

## Dropdowns

```lua
local Quality = Group:AddDropdown("Quality", {
    Text = "Quality",
    Values = { balanced = "Balanced quality", high = "High quality" },
    Default = "balanced", AllowNull = false, Searchable = true,
    DisabledValues = { "high" }, MaxVisibleDropdownItems = 5,
})
```

Use an array of unique strings, or a dictionary of string IDs to string labels. Dictionaries are sorted by ID. Display labels can change while the stored ID remains stable. Numeric defaults refer to one-based positions in the normalized list.

`Multi = true` stores a dictionary of selected IDs to true. Its default may be an ID, index, or selection dictionary. `AllowNull = false` requires a selection when choices exist. If replacing choices removes the selected value, a required dropdown selects its first available choice; an optional dropdown clears it.

| Option | Default | Behavior |
| --- | --- | --- |
| `Values` | empty | Array, dictionary, or provider function returning either |
| `Multi` | false | Enable multiple selections |
| `AllowNull` | true | Allow an empty selection |
| `Searchable` | false | Show search input |
| `DisabledValues` | empty array | IDs that ignore user selection |
| `MaxVisibleDropdownItems` | all | Bound list height and scroll internally |
| `FormatDisplayValue` | nil | Function `(id, label)` returning display text |

Search uses formatted display text. Invalid formatter calls fall back to the label. Disabled values may still be assigned programmatically or loaded from configs; the option blocks user clicks.

```lua
Quality:SetValues({ balanced = "Balanced", ultra = "Ultra" })
Quality:SetDisabledValues({ "ultra" })
Quality:SetValue("balanced")
Quality:SetOpen(true)
```

A Values provider is called on construction and when opening the list. `RefreshValues()` calls it explicitly. Providers should return current choices promptly. Only one dropdown is expanded at a time.

## Keybinds and colors

[Key pickers](API.md#key-pickers) support Toggle, Hold, Press, and Always modes, keyboard/mouse bindings, rebinding, and synchronized toggles. `NoUI = true` excludes a key picker from the [keybind overlay](Dialogs.md#keybind-menu).

[Color pickers](API.md#color-pickers) include hue/saturation/brightness, hex input, and optional transparency. Callbacks receive a Color3; read the control's `Transparency` property for alpha.

## Text and images

```lua
Group:AddLabel("A short label")
Group:AddLabel("A longer explanation that wraps.", true)
local Paragraph = Group:AddParagraph({ Title = "About", Content = "Describe your feature here." })
Paragraph:SetTitle("Details"):SetContent("Updated text")
local Image = Group:AddImage({ Image = 123456789, Height = 140, ScaleType = Enum.ScaleType.Fit })
Image:SetImage(987654321)
Group:AddDivider()
```

Paragraphs resize with content and support `RichText = true` for their body. Images accept a Roblox asset ID, an asset URI, or a registered `Library.Icons` name. `Transparency` is optional. `SetHeight(height)` changes image row height. Media must be accessible to the current Roblox experience.
