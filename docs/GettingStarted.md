# Getting started

## Structure

```text
Library
└── Window
    ├── Tab
    │   ├── Full-width groupbox
    │   │   └── Controls
    │   └── Left / right groupboxes
    │       └── Controls
    └── Tab
```

Load `Library.lua` once, create a window, then add tabs and groupboxes. A library instance manages one window. Use `Library:Unload()` when replacing it; load a fresh copy for another window. In Studio, `require` caches a ModuleScript's result, so a fresh client session or a cloned ModuleScript is needed after unloading.

```lua
local Window = Library:CreateWindow({ Title = "My interface" })
local Main = Window:AddTab("Main", "rocket")
local General = Main:AddGroupbox("General")
local Enabled = General:AddToggle("Enabled", { Text = "Enabled", Default = false })

Enabled:OnChanged(function(value)
    print(value)
end)
```

Use `Library.Toggles.Enabled.Value` to read a toggle. Other indexed controls live in `Library.Options`. `SetValue` changes a control programmatically, including disabled controls. Pass `true` as its second argument to suppress callbacks.

## Local files

In an environment with `readfile` and `loadstring`:

```lua
local Library = loadstring(readfile("VortexUI/Library.lua"))()
```

The path belongs to that environment's file sandbox. A Windows folder does not automatically become accessible through `readfile`; copy the library into the environment's accessible folder if needed.

## Roblox Studio

Use the repository's Rojo project or create this structure manually:

```text
ReplicatedStorage
└── Vortex (ModuleScript containing Library.lua)
    └── addons (Folder)
        ├── ThemeManager (ModuleScript)
        └── SaveManager (ModuleScript)
StarterPlayer
└── StarterPlayerScripts
    └── VortexExample (LocalScript containing examples/Studio.client.lua)
```

```lua
local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Vortex"))
local Window = Library:CreateWindow({
    Title = "My interface",
    Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
})
```

Studio does not provide the executor file functions. UI creation and themes work without those functions. Add a storage adapter if you need configuration saving.

## Storage adapters

`SaveManager:SetStorage` accepts plain functions with these signatures:

| Function | Required | Result |
| --- | --- | --- |
| `readfile(path)` | Yes | String contents; raise an error if missing |
| `writefile(path, contents)` | Yes | Write a string |
| `isfile(path)` | Yes | Boolean |
| `makefolder(path)` | For filesystem adapters needing directories | Create a directory |
| `isfolder(path)` | Recommended with `makefolder` | Boolean |
| `listfiles(path)` | For listing/config UI refresh | Array of file paths |
| `delfile(path)` | For deletion/clearing autoload | Delete a file |

An in-memory adapter can be useful during Studio development. It lasts only for the current session:

```lua
local files = {}
SaveManager:SetStorage({
    readfile = function(path)
        assert(files[path], "File does not exist")
        return files[path]
    end,
    writefile = function(path, contents) files[path] = contents end,
    isfile = function(path) return files[path] ~= nil end,
    delfile = function(path) files[path] = nil end,
    listfiles = function(folder)
        local result = {}
        for path in pairs(files) do
            if path:sub(1, #folder + 1) == folder .. "/" then
                table.insert(result, path)
            end
        end
        return result
    end,
})
```

## Migrating UI from Rattex

The library contains presentation and control state. Add game-specific behavior in your own callbacks. Original game modules, remotes, automation, webhook handling, and the Discord popup are outside this library.

| Rattex helper | Vortex equivalent |
| --- | --- |
| `page(name)` | `Window:AddTab(name)` then `Tab:AddGroupbox("")` |
| `toggle(content, title, key)` | `Group:AddToggle(key, { Text = title })` |
| `action(content, title, callback)` | `Group:AddButton(title, callback)` |
| `slider(content, title, key, min, max)` | `Group:AddSlider(key, { Text = title, Min = min, Max = max })` |
| `inputField(...)` | `Group:AddInput(id, options)` |
| `dropdown(...)` | `Group:AddDropdown(id, options)` |
| `keybind(...)` | `Group:AddKeyPicker(id, options)` |
| `state:ToggleMenu()` | `Window:Toggle()` |
| `state:Destroy()` | `Library:Unload()` |

Vortex supports the documented API. It does not implement every Obsidian option or provide full drop-in compatibility.
