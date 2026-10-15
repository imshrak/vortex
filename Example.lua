local repo = "https://raw.githubusercontent.com/imshrak/vortex/main/"
local environment = type(getgenv) == "function" and getgenv() or _G
local previous = environment.VortexExample
if type(previous) == "table" and type(previous.Unload) == "function" then
    previous:Unload()
end
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
environment.VortexExample = Library
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "vortex",
    Subtitle = "by shrak.",
    ToggleKey = Enum.KeyCode.LeftControl,
    Size = Vector2.new(580, 460),
})

local Main = Window:AddTab("Main", "rocket")
local Controls = Window:AddTab("Controls", "grid")
local Settings = Window:AddTab("Settings", "gear")

local General = Main:AddGroupbox("General")
General:AddToggle("Enabled", { Text = "Enabled", Default = false })
General:AddSlider("Intensity", { Text = "Intensity", Default = 50, Min = 0, Max = 100 })
General:AddDropdown("Mode", { Text = "Mode", Values = { "Balanced", "Smooth", "Fast" }, Default = "Balanced" })
General:AddInput("DisplayName", { Text = "Display name", Default = "Vortex", Placeholder = "Your name", Width = 120 })

local Selection = Controls:AddGroupbox("Selection")
Selection:AddDropdown("Categories", {
    Text = "Categories",
    Values = { "Interface", "Audio", "Visuals", "Accessibility" },
    Default = { Interface = true, Visuals = true },
    Multi = true,
    Searchable = true,
})
Selection:AddColorPicker("HighlightColor", {
    Text = "Highlight color",
    Default = Color3.fromRGB(150, 190, 255),
    Transparency = 0,
})
Selection:AddKeyPicker("ActionKey", {
    Text = "Action key",
    Default = "F",
    Mode = "Press",
})

local Interface = Settings:AddGroupbox("Interface")
Interface:AddToggle("ShowUserInfo", { Text = "Show user info", Default = true })
Interface:AddKeyPicker("MenuKey", {
    Text = "Menu key",
    Default = "LeftControl",
    ChangedCallback = function(key)
        Window:SetToggleKey(key)
    end,
})
Interface:AddButton("Unload", function()
    Library:Unload()
end)

Library.Toggles.ShowUserInfo:OnChanged(function(value)
    Window:SetUserInfoVisible(value)
end)

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Settings)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("VortexUI/Example")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKey" })
SaveManager:BuildConfigSection(Settings)

SaveManager:LoadAutoloadConfig()

return Library
