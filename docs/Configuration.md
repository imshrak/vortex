# Configuration

[Documentation home](README.md) · [Storage adapters](GettingStarted.md#storage-adapters)

## Setup

```lua
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
SaveManager:SetLibrary(Library):SetFolder("MyProject/Settings")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "SessionOnly", "MenuKey" })
SaveManager:BuildConfigSection(Settings, { Name = "Configuration", ShowTitle = true, MinHeight = 42 })
```

`BuildConfigSection` accepts a tab plus optional groupbox options, or an existing groupbox. Its controls support saving, loading, deleting, refreshing, selecting autoload, and clearing autoload. Build this section once per library because its control IDs are shared.

Create all controls and attach callbacks before loading a configuration. There is no automatic periodic saving. Use the Save button or call `Save(name)` when you want to persist current values.

## Named profiles

```lua
local ok, err = SaveManager:Save("default")
local loaded, loadError = SaveManager:Load("default")
SaveManager:SetAutoloadConfig("default")
SaveManager:LoadAutoloadConfig()
```

File operations return `true, result` or `false, error`. Profile names use letters, digits, underscores, or hyphens and contain at most 64 characters. Files live at `<folder>/settings/<name>.json`; autoload uses `<folder>/autoload.txt`. Deleting an autoload profile also removes its autoload selection.

## Exclusions

```lua
Group:AddInput("SessionOnly", { Text = "Temporary note", Default = "", Save = false })
SaveManager:SetIgnoreIndexes({ "AnotherID" })
SaveManager:IgnoreThemeSettings()
```

Both `Save = false` and manager exclusions prevent writing and importing the control's value. Unknown IDs are skipped when loading. Generated profile-name and profile-list controls exclude themselves automatically.

`IgnoreThemeSettings` keeps the theme selector and accent independent of regular settings. Omit it if profiles should restore those values. Style and window properties are not serialized automatically; expose sliders/toggles with callbacks, as shown in the [advanced example](../examples/Advanced.lua), if those preferences should be saved.

## JSON export and import

```lua
local exported, json = SaveManager:Export()
local imported, err
if exported then
    imported, err = SaveManager:Import(json)
end
```

Export builds a JSON string from current controls without accessing files. Import reads that string without a storage adapter. This supports custom clipboard buttons, text editors, or an application-specific storage service. Neither method sends data anywhere.

Import and Load validate every recognized value before applying any values. Invalid JSON, invalid control values, or type mismatches return an error. Unknown IDs are ignored. Successful loads emit normal value callbacks; internal dependencies refresh even when only the source is changing.

Sliders clamp finite numeric values to their current range. Colors include transparency; keybinds include mode. Checkboxes share the same boolean format as toggles. Dropdowns store IDs, so dictionary labels can be renamed without changing saved settings.

## Roblox Studio

The UI and JSON import/export work in a LocalScript. Studio does not provide executor file functions. For file-based profiles, supply a [storage adapter](GettingStarted.md#storage-adapters). For persistent player preferences in a published Roblox experience, use your own server-side persistence layer and expose only the settings your experience supports.
