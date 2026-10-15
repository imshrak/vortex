local ThemeManager = {
    DefaultTheme = "Graphite",
    Themes = {
        Graphite = {
            Background = Color3.fromRGB(15, 15, 15),
            Surface = Color3.fromRGB(26, 26, 26),
            Border = Color3.new(1, 1, 1),
            Text = Color3.new(1, 1, 1),
            Muted = Color3.fromRGB(165, 165, 165),
            Accent = Color3.new(1, 1, 1),
            Track = Color3.fromRGB(87, 87, 87),
        },
        Midnight = {
            Background = Color3.fromRGB(13, 16, 24),
            Surface = Color3.fromRGB(23, 28, 40),
            Border = Color3.fromRGB(39, 48, 66),
            Text = Color3.fromRGB(220, 227, 240),
            Muted = Color3.fromRGB(133, 148, 174),
            Accent = Color3.fromRGB(116, 164, 255),
            Track = Color3.fromRGB(51, 64, 87),
        },
        Rose = {
            Background = Color3.fromRGB(22, 15, 19),
            Surface = Color3.fromRGB(35, 24, 31),
            Border = Color3.fromRGB(57, 37, 48),
            Text = Color3.fromRGB(239, 218, 228),
            Muted = Color3.fromRGB(164, 132, 147),
            Accent = Color3.fromRGB(239, 148, 181),
            Track = Color3.fromRGB(77, 49, 63),
        },
    },
}

function ThemeManager:SetLibrary(library)
    self.Library = library
    return self
end

function ThemeManager:AddTheme(name, colors)
    assert(type(name) == "string" and name ~= "" and type(colors) == "table", "Provide a theme name and colors")
    local theme = table.clone(self.Themes.Graphite)
    for role, value in pairs(colors) do
        assert(theme[role] and typeof(value) == "Color3", "Invalid theme role: " .. tostring(role))
        theme[role] = value
    end
    self.Themes[name] = theme
    return self
end

function ThemeManager:ApplyTheme(name)
    assert(self.Library, "Call SetLibrary first")
    assert(self.Themes[name], "Unknown theme: " .. tostring(name))
    self.CurrentTheme = name
    self.Library:SetTheme(self.Themes[name])
    local accent = self.Library.Options.VortexAccent
    if accent then
        accent:SetValue(self.Themes[name].Accent, true)
    end
    return self
end

function ThemeManager:SetDefault(name)
    assert(self.Themes[name], "Unknown theme")
    self.DefaultTheme = name
    return self
end

function ThemeManager:ApplyToGroupbox(group)
    assert(self.Library, "Call SetLibrary first")
    local names = {}
    for name in pairs(self.Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    self:ApplyTheme(self.DefaultTheme)
    group:AddDropdown("VortexTheme", {
        Text = "Theme",
        Values = names,
        Default = self.DefaultTheme,
        Callback = function(name)
            if name then
                self:ApplyTheme(name)
            end
        end,
    })
    group:AddColorPicker("VortexAccent", {
        Text = "Accent",
        Default = self.Library.Theme.Accent,
        Callback = function(color)
            self.Library:SetTheme({ Accent = color })
        end,
    })
    return group
end

function ThemeManager:GetThemeNames()
    local names = {}
    for name in pairs(self.Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end
function ThemeManager:GetTheme(name)
    assert(self.Themes[name], "Unknown theme")
    return table.clone(self.Themes[name])
end
function ThemeManager:ApplyToTab(tab, options)
    return self:ApplyToGroupbox(tab:AddGroupbox(options or "Appearance"))
end

return ThemeManager
