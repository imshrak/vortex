local checks = 0
local function check(value, message)
    checks += 1
    assert(value, message)
end
local function rejects(callback, message)
    check(not pcall(callback), message)
end
local function keyboard(name)
    return { KeyCode = Enum.KeyCode[name], UserInputType = Enum.UserInputType.Keyboard, Position = Vector2.new(0, 0) }
end

local window = Library:CreateWindow({ Title = "Test", Parent = playerGui })
local main = window:AddTab("Main", "rocket")
local settings = window:AddTab("Settings", "gear")
check(main.Frame.Visible and not settings.Frame.Visible, "First tab should be selected")
settings:Select()
check(settings.Frame.Visible and not main.Frame.Visible, "Selecting tabs should switch pages")
rejects(function()
    window:AddTab("Main")
end, "Duplicate tabs must be rejected")
local group = main:AddGroupbox("Controls")
local enabled = group:AddToggle("Enabled", { Default = true })
local observed
enabled:OnChanged(function(value)
    observed = value
end)
enabled:SetValue(false)
check(observed == false and enabled.Value == false, "Toggle callback should receive the new value")
rejects(function()
    group:AddInput("Enabled", {})
end, "Duplicate IDs must be rejected across registries")
enabled:SetDisabled(true)
enabled.Button.Activated:Fire()
check(enabled.Value == false, "Disabled toggles must ignore clicks")
enabled:SetDisabled(false)
enabled.Button.Activated:Fire()
check(enabled.Value == true, "Enabled toggle should respond to clicks")
check(not enabled:SetValue("true"), "Toggle should reject non-booleans")
observed = nil
enabled:SetValue(false, true)
check(observed == nil, "Silent value changes should suppress callbacks")

local slider = group:AddSlider("Volume", { Min = 0, Max = 1, Default = 0.5, Rounding = 2 })
slider:SetValue(0.756)
check(slider.Value == 0.76, "Slider should round to configured precision")
slider:SetValue(9)
check(slider.Value == 1, "Slider should clamp to maximum")
check(not slider:SetValue(0 / 0) and not slider:SetValue(math.huge), "Slider should reject non-finite values")
slider.Box.Text = "invalid"
slider.Box.FocusLost:Fire()
check(slider.Box.Text == "1", "Invalid slider text should restore the previous value")
rejects(function()
    group:AddSlider("BadRange", { Min = 1, Max = 1 })
end, "Empty slider ranges must be rejected")
local input = group:AddInput("Count", { Numeric = true, Default = "12" })
check(not input:SetValue("nan") and input.Value == "12", "Numeric inputs should reject invalid numbers")
input:SetDisabled(true)
check(input.Box.TextEditable == false, "Disabled inputs should not be editable")

local dropdown = group:AddDropdown("Mode", { Values = { "A", "B", "C" }, Default = 2, Searchable = true })
check(dropdown.Value == "B", "Dropdown should accept numeric default indexes")
dropdown:SetOpen(true)
dropdown.Search.Text = "c"
local matches = 0
for _, child in ipairs(dropdown.OptionsFrame:GetChildren()) do
    if child.Name == "Option" then
        matches += 1
    end
end
check(matches == 1, "Search should filter dropdown choices")
local multi = group:AddDropdown("Multi", { Values = { "A", "B" }, Multi = true, Default = { A = true } })
multi:SetOpen(true)
check(not dropdown.Opened and multi.Opened, "Opening a dropdown should close the previous one")
local selected = { B = true }
multi:SetValue(selected)
selected.A = true
check(not multi.Value.A and multi.Value.B, "Dropdown should own a copy of selected values")
check(not multi:SetValue({ Unknown = true }), "Dropdown should reject unknown selections")
multi:SetValues({ "A" })
check(next(multi.Value) == nil, "Refreshing values should remove unavailable selections")
multi:SetVisible(false)
check(not multi.Opened, "Hiding an expanded dropdown should close it")

local color = group:AddColorPicker("Color", { Default = Color3.fromRGB(255, 0, 0), Transparency = 0.25 })
color:SetValueRGB(Color3.fromRGB(0, 255, 0), 0.5)
check(color.Value:ToHex() == "00ff00" and color.Transparency == 0.5, "Color should track RGB and transparency")
check(not color:SetValueRGB("bad"), "Color should reject invalid values")
local key = group:AddKeyPicker("Hotkey", { Default = "F", Mode = "Hold" })
UIS.InputBegan:Fire(keyboard("F"), false)
check(key:GetState(), "Hold keybind should activate on key down")
UIS.InputEnded:Fire(keyboard("F"))
check(not key:GetState(), "Hold keybind should release on key up")
UIS.InputBegan:Fire(keyboard("F"), true)
check(not key:GetState(), "Processed keys should be ignored")
key:SetValue({ "G", "Toggle" })
UIS.FocusedTextBox = true
UIS.InputBegan:Fire(keyboard("G"), false)
check(not key:GetState(), "Typing should suppress keybinds")
UIS.FocusedTextBox = nil
key.Button.Activated:Fire()
UIS.InputBegan:Fire(keyboard("Escape"), false)
check(key.Value == "G", "Escape should cancel binding capture")
key.Button.Activated:Fire()
UIS.InputBegan:Fire(keyboard("H"), false)
check(key.Value == "H", "Binding capture should update the key")
check(not key:SetValue("InvalidKey"), "Invalid enum names should be rejected")
key:SetValue({ "H", "Toggle" })
UIS.InputBegan:Fire(keyboard("H"), false)
check(key:GetState(), "Toggle keybind should activate")
key:SetDisabled(true)
check(not key:GetState() and not key.State, "Disabling active keybinds should release them")
key:SetDisabled(false)
key.Button.Activated:Fire()
key:SetDisabled(true)
check(Library._capture == nil and key.Button.Text == "H", "Disabling a picker should cancel capture")
key:SetDisabled(false)
local touch = { UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(25, 110) }
window.Launcher.InputBegan:Fire(touch)
touch.Position = Vector2.new(100, 150)
UIS.InputChanged:Fire(touch)
check(
    window.Launcher.Position.X.Offset == 97 and window.Launcher.Position.Y.Offset == 144,
    "Launcher should follow touch movement"
)
UIS.InputEnded:Fire(touch)
check(Library._pointer == nil, "Touch release should clear dragging state")
local linked = group:AddToggle("Linked", { Text = "Linked", Default = false })
linked:AddKeyPicker("LinkedKey", { Default = "J", SyncToggleState = true })
UIS.InputBegan:Fire(keyboard("J"), false)
check(linked.Value and Library.Options.LinkedKey:GetState(), "Chained keybind should activate its toggle")
linked:SetValue(false)
check(not Library.Options.LinkedKey:GetState(), "Linked toggle should update keybind state")
window:SetVisible(true)
UIS.InputBegan:Fire(keyboard("LeftControl"), false)
check(
    not window.Frame.Visible and window.Launcher.Visible,
    "Menu key should hide the window while keeping the launcher"
)
window.Launcher.Activated:Fire()
check(not window.Frame.Visible, "Launcher drag should suppress accidental activation")
window:Toggle()
check(window.Frame.Visible, "Window should reopen programmatically")

checks += verifyAppearance(Library, window, group, enabled, slider, input, dropdown, key)
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(settings)
ThemeManager:ApplyTheme("Midnight")
check(
    window.Frame.BackgroundColor3 == ThemeManager.Themes.Midnight.Background,
    "Themes should repaint existing objects"
)
rejects(function()
    Library:SetTheme({ BadRole = Color3.new(1, 1, 1) })
end, "Invalid theme roles should be rejected")
local currentTheme = Library.Theme.Background
rejects(function()
    Library:SetTheme({ Background = Color3.new(0, 0, 0), BadRole = Color3.new(1, 1, 1) })
end, "Invalid themes should be rejected atomically")
check(Library.Theme.Background == currentTheme, "Invalid theme should not partially apply")

SaveManager:SetLibrary(Library):SetStorage(storage):SetFolder("Vortex/Tests")
SaveManager:IgnoreThemeSettings()
slider:SetValue(0.42)
enabled:SetValue(true)
check(SaveManager:Save("default"), "Saving valid settings should succeed")
check(folders["Vortex"] and folders["Vortex/Tests/settings"], "Save manager should create nested folders")
slider:SetValue(0)
enabled:SetValue(false)
color:SetValueRGB(Color3.fromRGB(0, 0, 255), 0)
key:SetValue({ "Z", "Press" })
check(SaveManager:Load("default"), "Saved config should load")
check(slider.Value == 0.42 and enabled.Value == true, "Load should restore values")
check(color.Value:ToHex() == "00ff00" and color.Transparency == 0.5, "Load should restore color and alpha")
check(key.Value == "H" and key.Mode == "Toggle", "Load should restore key and mode")
check(not SaveManager:Save("../escape"), "Path traversal should be rejected")
check(not SaveManager:Load("missing"), "Missing configs should return an error")
files["Vortex/Tests/settings/broken.json"] = "invalid"
check(not SaveManager:Load("broken"), "Malformed JSON should return an error")
files["Vortex/Tests/settings/invalid.json"] = HttpService:JSONEncode({
    Version = 1,
    Objects = { Enabled = { Type = "Toggle", Value = false }, Volume = { Type = "Slider", Value = "bad" } },
})
check(not SaveManager:Load("invalid"), "Invalid control values should reject the config")
check(enabled.Value == true, "Rejected configs should not partially apply")
check(SaveManager:SetAutoloadConfig("default"), "Existing configs should support autoload")
slider:SetValue(0)
check(SaveManager:LoadAutoloadConfig() and slider.Value == 0.42, "Autoload should restore the selected config")
local listed, names = SaveManager:RefreshConfigList()
check(listed and table.find(names, "default"), "Config list should include saved files")
check(SaveManager:Delete("default"), "Deleting an existing config should succeed")
check(not files["Vortex/Tests/autoload.txt"], "Deleting the autoload config should clear its pointer")
SaveManager.Ignore.VortexTheme = nil
SaveManager.Ignore.VortexAccent = nil
Library.Options.VortexTheme:SetValue("Rose")
Library.Options.VortexAccent:SetValue(Color3.fromRGB(10, 20, 30))
check(SaveManager:Save("theme"), "Theme settings should be savable when included")
Library.Options.VortexTheme:SetValue("Graphite")
check(SaveManager:Load("theme"), "Theme settings should load")
check(Library.Theme.Accent:ToHex() == "0a141e", "Custom saved accent should apply after the named theme")
local originalStorage = SaveManager.Storage
SaveManager:SetStorage({
    readfile = storage.readfile,
    isfile = storage.isfile,
    writefile = function()
        error("Storage full")
    end,
})
local wrote, writeError = SaveManager:Save("failure")
check(not wrote and writeError:find("Storage full", 1, true), "Storage failures should return a useful error")
SaveManager:SetStorage(originalStorage)
SaveManager:BuildConfigSection(settings)
check(Library.Options.VortexConfigList ~= nil, "Config UI should build")

local unloaded = false
Library:OnUnload(function()
    unloaded = true
end)
local connections = table.clone(Library._connections)
Library:Unload()
Library:Unload()
check(unloaded and Library.Unloaded and window.Gui.Destroyed, "Unload should be idempotent and destroy the UI")
for _, connection in ipairs(connections) do
    check(not connection.Connected, "Unload should disconnect global listeners")
end
check(next(Library.Options) == nil and next(Library.Toggles) == nil, "Unload should clear control registries")
check(#callbackErrors == 0, "Callbacks must not produce hidden errors: " .. table.concat(callbackErrors, "; "))
print("PASS: " .. checks .. " Vortex behavior checks")
