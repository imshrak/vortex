local repo = "https://raw.githubusercontent.com/imshrak/vortex/main/"
local environment = type(getgenv) == "function" and getgenv() or _G
local previous = environment.VortexExample
if type(previous) == "table" and type(previous.Unload) == "function" then
    previous:Unload()
end
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
environment.VortexExample = Library

local Window = Library:CreateWindow({
    Title = "vortex",
    Subtitle = "by shrak.",
    Size = Vector2.new(640, 500),
    MinSize = Vector2.new(480, 360),
    MaxSize = Vector2.new(1100, 800),
    Resizable = true,
    Draggable = true,
    Style = { RowSpacing = 6, GroupSpacing = 10, ControlRadius = 6 },
})
local Overview = Window:AddTab("Overview", "rocket")
local Controls = Window:AddTab("Controls", "grid")
local Layout = Window:AddTab("Layout", "users")
local Appearance = Window:AddTab("Appearance", "plus")
local Settings = Window:AddTab("Settings", "gear")

local General = Overview:AddGroupbox("")
local Enabled = General:AddToggle("AdvancedEnabled", { Text = "Enable adjustments", Default = true })
General:AddSlider("AdvancedAmount", {
    Text = "Amount",
    Min = 0,
    Max = 10,
    Default = 2.5,
    Step = 0.25,
    Rounding = 2,
    Suffix = "x",
    DisabledTooltip = "Enable adjustments first.",
}):DependsOn({ { Enabled, true } }, "Disabled")
General:AddButton("Reset settings", function()
    Library:Dialog({
        Title = "Reset settings?",
        Content = "Restore control defaults.",
        Buttons = {
            {
                Text = "Reset",
                Callback = function()
                    Library:ResetAll({ "VortexConfigName", "VortexConfigList" })
                end,
            },
            { Text = "Cancel" },
        },
    })
end)
General:AddKeyPicker("AdvancedAction", {
    Text = "Action key",
    Default = "F6",
    Mode = "Toggle",
})
General:AddCheckbox("AdvancedKeybinds", {
    Text = "Show keybind overlay",
    Default = false,
    Save = false,
    Callback = function(value)
        Library:SetKeybindsVisible(value)
    end,
})
General:AddCheckbox("AdvancedWatermark", {
    Text = "Show watermark",
    Default = false,
    Save = false,
    Callback = function(value)
        Library:SetWatermark(value and "Vortex · v" .. Library.Version or nil)
    end,
})

local Fields = Controls:AddGroupbox({
    Name = "Fields",
    ShowTitle = true,
})
Fields:AddInput("AdvancedName", {
    Text = "Name",
    Default = "Player",
    Width = 180,
    Validator = function(value)
        return value:match("%S") ~= nil
    end,
    Tooltip = "Names cannot be blank.",
})
Fields:AddDropdown("AdvancedQuality", {
    Text = "Quality",
    Values = { balanced = "Balanced quality", detailed = "Detailed quality", compact = "Compact quality" },
    Default = "balanced",
    AllowNull = false,
    Searchable = true,
    MaxVisibleDropdownItems = 4,
})
Fields:AddDropdown("AdvancedFilters", {
    Text = "Filters",
    Values = { "Interface", "Visuals", "Audio", "Accessibility" },
    Default = { Interface = true },
    Multi = true,
    Searchable = true,
})
Fields:AddInput("AdvancedNote", { Text = "Notes", Default = "", Multiline = true, Height = 104, MaxLength = 500 })
Fields:AddColorPicker(
    "AdvancedColor",
    { Text = "Highlight", Default = Color3.fromRGB(150, 190, 255), Transparency = 0 }
)

local Tabbox = Layout:AddTabbox({ Name = "Tabbed settings", ShowTitle = true, MinHeight = 42, TabWidth = 106 })
local Display = Tabbox:AddTab("Display")
local Audio = Tabbox:AddTab("Audio")
local Details = Display:AddCheckbox("AdvancedDetails", { Text = "Show extra fields", Default = false })
local Conditional = Display:AddDependencyBox()
Conditional:AddInput("AdvancedDetailName", { Text = "Detail label", Default = "Custom", Width = 140 })
Conditional:AddSlider("AdvancedDetailSize", { Text = "Detail size", Min = 1, Max = 10, Default = 5 })
Conditional:SetupDependencies({ { Details, true } })
Audio:AddSlider("AdvancedVolume", { Text = "Volume", Min = 0, Max = 100, Default = 65, Suffix = "%" })
Audio:AddCheckbox("AdvancedMuted", { Text = "Muted", Default = false })
local Collapsible = Layout:AddGroupbox({
    Name = "More options",
    ShowTitle = true,
    Collapsible = true,
    Collapsed = true,
    MinHeight = 42,
})
Collapsible:AddToggle("AdvancedExtra", { Text = "Extra option", Default = false })

ThemeManager:SetLibrary(Library)
ThemeManager:AddTheme("Custom", { Accent = Color3.fromRGB(146, 173, 255) })
ThemeManager:ApplyToTab(Appearance, { Name = "Theme", ShowTitle = true, MinHeight = 42 })
local Style = Appearance:AddGroupbox({ Name = "Spacing and type", ShowTitle = true, MinHeight = 42 })
Style:AddSlider("AdvancedTextSize", {
    Text = "Text size",
    Min = 10,
    Max = 18,
    Default = 13,
    Callback = function(value)
        Library:SetStyle({ TextSize = value })
    end,
})
Style:AddSlider("AdvancedSpacing", {
    Text = "Row spacing",
    Min = 0,
    Max = 16,
    Default = 6,
    Callback = function(value)
        Library:SetStyle({ RowSpacing = value })
    end,
})
Style:AddSlider("AdvancedCorners", {
    Text = "Corner radius",
    Min = 0,
    Max = 14,
    Default = 6,
    Callback = function(value)
        Library:SetStyle({ ControlRadius = value })
    end,
})
Style:AddSlider("AdvancedTransparency", {
    Text = "Transparency",
    Min = 0,
    Max = 0.5,
    Rounding = 2,
    Step = 0.05,
    Default = 0,
    Callback = function(value)
        Window:SetTransparency(value)
    end,
})

SaveManager:SetLibrary(Library):SetFolder("VortexUI/Advanced"):IgnoreThemeSettings()
SaveManager:BuildConfigSection(Settings, { Name = "Configuration", ShowTitle = true, MinHeight = 42 })
local Transfer = Settings:AddGroupbox({ Name = "Import and export", ShowTitle = true, MinHeight = 42 })
local JSON = Transfer:AddInput(
    "AdvancedConfigJSON",
    { Text = "Configuration JSON", Default = "", Multiline = true, Height = 120, Save = false }
)
Transfer:AddButton("Export settings", function()
    local ok, result = SaveManager:Export()
    if ok then
        JSON:SetValue(result)
    else
        Library:Notify(result)
    end
end)
Transfer:AddButton("Import settings", function()
    local ok, err = SaveManager:Import(JSON.Value)
    Library:Notify(ok and "Settings imported" or err)
end)
Transfer:AddButton({
    Text = "Reset controls",
    DoubleClick = true,
    Func = function()
        Library:ResetAll({ "VortexConfigName", "VortexConfigList" })
    end,
})
Transfer:AddButton("Unload", function()
    Library:Unload()
end)

Overview:Select()
return Library
