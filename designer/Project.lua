local Project = {}
Project.__index = Project

local function field(key, label, kind, default, extra)
    local item = { Key = key, Label = label, Type = kind, Default = default }
    for name, value in pairs(extra or {}) do
        item[name] = value
    end
    return item
end

local function number(key, label, default, minimum, maximum)
    return field(key, label, "Number", default, { Min = minimum, Max = maximum })
end

Project.Kinds = {
    "Toggle",
    "Checkbox",
    "Slider",
    "Input",
    "Dropdown",
    "Button",
    "KeyPicker",
    "ColorPicker",
    "Label",
    "Paragraph",
    "Image",
    "Divider",
}
Project.Theme = {
    Background = "0F0F0F",
    Surface = "1A1A1A",
    Border = "FFFFFF",
    Text = "FFFFFF",
    Muted = "A5A5A5",
    Accent = "FFFFFF",
    Track = "575757",
}
Project.ThemeOrder = { "Background", "Surface", "Border", "Text", "Muted", "Accent", "Track" }
Project.StyleFields = {
    number("TextSize", "Text size", 13, 10, 24),
    number("TextTransparency", "Text transparency", 0.4, 0, 1),
    number("RowSpacing", "Row spacing", 6, 0, 24),
    number("GroupSpacing", "Group spacing", 10, 0, 32),
    number("CardPadding", "Card padding", 16, 8, 32),
    number("VerticalPadding", "Vertical padding", 12, 4, 28),
    number("WindowRadius", "Window radius", 10, 0, 24),
    number("ControlRadius", "Control radius", 6, 0, 18),
    number("AnimationDuration", "Animation duration", 0.13, 0, 1),
}

local common = {
    field("Text", "Label", "String", "Option"),
    field("Visible", "Visible", "Boolean", true),
    field("Disabled", "Disabled", "Boolean", false),
    field("Tooltip", "Tooltip", "String", ""),
    field("Save", "Save value", "Boolean", true),
}
Project.Fields = {
    Window = {
        field("Title", "Title", "String", "vortex"),
        field("Subtitle", "Subtitle", "String", "by shrak."),
        field("Footer", "Footer", "String", ""),
        number("Width", "Width", 580, 400, 1600),
        number("Height", "Height", 460, 300, 1200),
        field("ToggleKey", "Menu key", "Key", "LeftControl"),
        field("Resizable", "Resizable", "Boolean", false),
        field("ShowSettings", "Settings button", "Boolean", true),
        field("ShowMinimize", "Minimize button", "Boolean", true),
        field("ShowClose", "Close button", "Boolean", true),
        field("ShowUserInfo", "User info", "Boolean", true),
        field("ShowFooter", "Footer visible", "Boolean", true),
        field("ShowLauncher", "Launcher", "Boolean", true),
        field("LauncherText", "Launcher text", "String", "V"),
        number("Transparency", "Transparency", 0, 0, 1),
    },
    Tab = {
        field("Name", "Name", "String", "Tab", { Nonempty = true }),
        field("Icon", "Icon", "String", "grid"),
        number("Width", "Tab width", 106, 40, 300),
    },
    Group = {
        field("Name", "Name", "String", "General"),
        field("Side", "Column", "Choice", "Full", { Choices = { "Full", "Left", "Right" } }),
        field("ShowTitle", "Show heading", "Boolean", false),
        number("MinHeight", "Minimum height", 288, 0, 800),
        field("Collapsible", "Collapsible", "Boolean", false),
        field("Collapsed", "Collapsed", "Boolean", false),
    },
    Toggle = { field("Default", "Default", "Boolean", false) },
    Checkbox = { field("Default", "Default", "Boolean", false) },
    Slider = {
        number("Min", "Minimum", 0, -1000000, 1000000),
        number("Max", "Maximum", 100, -1000000, 1000000),
        number("Default", "Default", 50, -1000000, 1000000),
        number("Rounding", "Decimal places", 0, 0, 6),
        number("Step", "Step", 1, 0.000001, 1000000),
        field("Suffix", "Suffix", "String", ""),
    },
    Input = {
        field("Default", "Default", "String", ""),
        field("Placeholder", "Placeholder", "String", ""),
        number("Width", "Field width", 120, 40, 400),
        field("Numeric", "Numeric", "Boolean", false),
        field("Multiline", "Multiline", "Boolean", false),
        field("Finished", "Commit on blur", "Boolean", true),
        number("Height", "Height", 90, 40, 300),
        number("MaxLength", "Character limit", 500, 1, 10000),
    },
    Dropdown = {
        field("Values", "Options", "Lines", { "One", "Two", "Three" }),
        field("Default", "Default", "String", "One"),
        field("Multi", "Multiple selection", "Boolean", false),
        field("Searchable", "Search", "Boolean", true),
        number("MaxVisibleDropdownItems", "Visible items", 6, 1, 20),
    },
    Button = { field("DoubleClick", "Confirm on second click", "Boolean", false) },
    KeyPicker = {
        field("Default", "Key", "Key", "F"),
        field("Mode", "Mode", "Choice", "Toggle", { Choices = { "Toggle", "Hold", "Press", "Always" } }),
    },
    ColorPicker = {
        field("Default", "Color", "Color", "96BEFF"),
        number("Transparency", "Transparency", 0, 0, 1),
    },
    Label = { field("Text", "Text", "String", "Label"), field("Wrapped", "Wrap text", "Boolean", true) },
    Paragraph = { field("Text", "Title", "String", "About"), field("Content", "Content", "Multiline", "") },
    Image = { field("Image", "Image asset", "String", "0"), number("Height", "Height", 140, 24, 500) },
    Divider = {},
}

local indexed = {
    Toggle = true,
    Checkbox = true,
    Slider = true,
    Input = true,
    Dropdown = true,
    KeyPicker = true,
    ColorPicker = true,
}
local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = clone(item)
    end
    return result
end
Project.Clone = clone

function Project.GetFields(kind)
    local result = {}
    if indexed[kind] then
        table.insert(result, field("Id", "ID", "String", kind, { Nonempty = true }))
    end
    if indexed[kind] or kind == "Button" then
        for _, item in ipairs(common) do
            table.insert(result, item)
        end
    end
    for _, item in ipairs(Project.Fields[kind] or {}) do
        table.insert(result, item)
    end
    return result
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function validateField(item, value)
    local kind = item.Type
    if kind == "Number" then
        assert(finite(value) and value >= item.Min and value <= item.Max, item.Label .. " is out of range")
        if item.Key == "Rounding" or item.Key == "MaxLength" or item.Key == "MaxVisibleDropdownItems" then
            assert(value % 1 == 0, item.Label .. " must be a whole number")
        end
    elseif kind == "Boolean" then
        assert(type(value) == "boolean", item.Label .. " must be true or false")
    elseif kind == "Lines" then
        assert(type(value) == "table" and #value > 0 and #value <= 64, "Use 1 to 64 options")
        local seen = {}
        for key, entry in pairs(value) do
            assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #value, "Invalid options list")
            assert(
                type(entry) == "string" and #entry > 0 and #entry <= 200 and not seen[entry],
                "Options must be unique"
            )
            seen[entry] = true
        end
    else
        assert(
            type(value) == "string" and #value <= (kind == "Multiline" and 10000 or 500),
            item.Label .. " is invalid"
        )
        assert(not item.Nonempty or value:match("%S"), item.Label .. " cannot be blank")
        if kind == "Choice" then
            assert(table.find(item.Choices, value), "Invalid " .. item.Label)
        elseif kind == "Color" then
            assert(value:match("^%x%x%x%x%x%x$"), "Use a six-digit hex color")
        elseif kind == "Key" then
            local ok, code = pcall(function()
                return Enum.KeyCode[value]
            end)
            assert(
                value == "None" or value:match("^MB[123]$") or ok and code ~= nil and code ~= Enum.KeyCode.Unknown,
                "Invalid key name"
            )
        end
    end
end

local function fieldsInto(target, source, fields)
    for _, item in ipairs(fields) do
        local value = source[item.Key]
        if value == nil then
            value = clone(item.Default)
        end
        validateField(item, value)
        target[item.Key] = clone(value)
    end
end

local function array(value, limit)
    assert(type(value) == "table" and #value <= limit, "Project is too large")
    for key in pairs(value) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #value, "Invalid project list")
    end
end

function Project.Validate(data)
    assert(type(data) == "table" and data.Version == 1, "Unsupported project version")
    assert(
        type(data.Window) == "table" and type(data.Theme) == "table" and type(data.Style) == "table",
        "Invalid project"
    )
    local result = { Version = 1, Window = {}, Theme = {}, Style = {}, Tabs = {} }
    fieldsInto(result.Window, data.Window, Project.Fields.Window)
    fieldsInto(result.Style, data.Style, Project.StyleFields)
    for _, role in ipairs(Project.ThemeOrder) do
        local value = data.Theme[role] or Project.Theme[role]
        validateField(field(role, role, "Color"), value)
        result.Theme[role] = value:upper()
    end
    array(data.Tabs, 24)
    local keys, ids, names, count = { window = true }, {}, {}, 0
    local function node(source, kind)
        assert(type(source) == "table" and source.Kind == kind, "Invalid item kind")
        assert(
            type(source.Key) == "string" and source.Key:match("^n%d+$") and #source.Key < 20 and not keys[source.Key],
            "Invalid item key"
        )
        keys[source.Key] = true
        count += 1
        assert(count <= 300, "Use at most 300 items")
        local target = { Kind = kind, Key = source.Key }
        fieldsInto(target, source, Project.GetFields(kind))
        if indexed[kind] then
            assert(not ids[target.Id], "Control IDs must be unique")
            ids[target.Id] = true
        end
        if kind == "Slider" then
            assert(target.Max > target.Min, "Maximum must exceed minimum")
            assert(target.Default >= target.Min and target.Default <= target.Max, "Default must be within the range")
        elseif kind == "Dropdown" then
            assert(target.Default == "" or table.find(target.Values, target.Default), "Default must match an option")
        elseif kind == "Input" and target.Numeric then
            assert(target.Default == "" or finite(tonumber(target.Default)), "Numeric default must be a number")
        end
        return target
    end
    for _, sourceTab in ipairs(data.Tabs) do
        local tab = node(sourceTab, "Tab")
        assert(not names[tab.Name], "Tab names must be unique")
        names[tab.Name] = true
        tab.Groups = {}
        array(sourceTab.Groups, 48)
        for _, sourceGroup in ipairs(sourceTab.Groups) do
            local group = node(sourceGroup, "Group")
            group.Controls = {}
            array(sourceGroup.Controls, 200)
            for _, sourceControl in ipairs(sourceGroup.Controls) do
                assert(
                    type(sourceControl) == "table" and table.find(Project.Kinds, sourceControl.Kind),
                    "Unsupported control"
                )
                table.insert(group.Controls, node(sourceControl, sourceControl.Kind))
            end
            table.insert(tab.Groups, group)
        end
        table.insert(result.Tabs, tab)
    end
    return result
end

function Project.new(data)
    local self = setmetatable({ UndoStack = {}, RedoStack = {}, Selection = "window" }, Project)
    self.Data = Project.Validate(data or {
        Version = 1,
        Window = {},
        Theme = {},
        Style = {},
        Tabs = {
            {
                Key = "n1",
                Kind = "Tab",
                Name = "Main",
                Groups = {
                    {
                        Key = "n2",
                        Kind = "Group",
                        Controls = {
                            { Key = "n3", Kind = "Toggle", Id = "Enabled", Text = "Enabled" },
                            { Key = "n4", Kind = "Slider", Id = "Amount", Text = "Amount" },
                        },
                    },
                },
            },
        },
    })
    return self
end

function Project:Get(key, data)
    data = data or self.Data
    if key == "window" then
        return data.Window, nil, nil, nil
    end
    for index, tab in ipairs(data.Tabs) do
        if tab.Key == key then
            return tab, data.Tabs, index, nil
        end
        for groupIndex, group in ipairs(tab.Groups) do
            if group.Key == key then
                return group, tab.Groups, groupIndex, tab
            end
            for controlIndex, control in ipairs(group.Controls) do
                if control.Key == key then
                    return control, group.Controls, controlIndex, group, tab
                end
            end
        end
    end
end

function Project:_commit(callback)
    local data = clone(self.Data)
    local ok, result = pcall(function()
        local selection = callback(data)
        return { Data = Project.Validate(data), Selection = selection or self.Selection }
    end)
    if not ok then
        return false, tostring(result):gsub("^.-:%d+: ", "")
    end
    table.insert(self.UndoStack, { Data = self.Data, Selection = self.Selection })
    if #self.UndoStack > 60 then
        table.remove(self.UndoStack, 1)
    end
    self.Data, self.Selection, self.RedoStack = result.Data, result.Selection, {}
    if not self:Get(self.Selection) then
        self.Selection = "window"
    end
    return true
end

function Project:Update(key, property, value, section)
    return self:_commit(function(data)
        assert(section == nil or section == "Theme" or section == "Style", "Unknown property section")
        assert(section ~= "Theme" or Project.Theme[property], "Unknown theme color")
        local target = section and data[section] or self:Get(key, data)
        assert(target, "Select an item")
        local fields = section == "Style" and Project.StyleFields
            or section == "Theme" and { field(property, property, "Color") }
            or Project.GetFields(key == "window" and "Window" or target.Kind)
        local known = false
        for _, item in ipairs(fields) do
            if item.Key == property then
                known = true
            end
        end
        assert(known, "Unknown property")
        target[property] = clone(value)
        if target.Kind == "Dropdown" and property == "Values" and not table.find(value, target.Default) then
            target.Default = value[1]
        end
    end)
end

local function nextKey(self, data)
    local index = 1
    while self:Get("n" .. index, data) do
        index += 1
    end
    return "n" .. index
end

local function unique(self, data, base, names)
    local used = {}
    for _, tab in ipairs(data.Tabs) do
        used[names and tab.Name or ""] = true
        for _, group in ipairs(tab.Groups) do
            for _, control in ipairs(group.Controls) do
                used[control.Id or ""] = true
            end
        end
    end
    local value, index = base, 2
    while used[value] do
        value, index = base .. " " .. index, index + 1
    end
    return value
end

function Project:Add(kind, parentKey)
    return self:_commit(function(data)
        assert(Project.Fields[kind] and kind ~= "Window", "Unsupported item")
        local target = self:Get(parentKey or self.Selection, data)
        local list
        if kind == "Tab" then
            list = data.Tabs
        elseif kind == "Group" then
            if target and target.Kind ~= "Tab" then
                local _, _, _, parent, tab = self:Get(target.Key, data)
                target = tab or (parent and parent.Kind == "Tab" and parent) or nil
            end
            target = target and target.Kind == "Tab" and target or data.Tabs[1]
            assert(target, "Add a tab first")
            list = target.Groups
        else
            if target and target.Kind ~= "Group" then
                local _, _, _, parent = self:Get(target.Key, data)
                target = parent and parent.Kind == "Group" and parent or nil
            end
            if not target then
                local tab = self:Get(parentKey or self.Selection, data)
                if tab and tab.Kind == "Tab" then
                    target = tab.Groups[1]
                else
                    target = data.Tabs[1] and data.Tabs[1].Groups[1]
                end
            end
            assert(target, "Add a group first")
            list = target.Controls
        end
        local value = { Key = nextKey(self, data), Kind = kind }
        fieldsInto(value, {}, Project.GetFields(kind))
        if kind == "Tab" then
            value.Name, value.Groups = unique(self, data, "Tab", true), {}
        elseif kind == "Group" then
            value.Controls = {}
            if #list > 0 then
                value.MinHeight = 42
            end
        else
            if indexed[kind] then
                value.Id = unique(self, data, kind, false)
            end
            if value.Text == "Option" then
                value.Text = kind == "KeyPicker" and "Action key" or kind == "ColorPicker" and "Color" or kind
            end
        end
        table.insert(list, value)
        return value.Key
    end)
end

function Project:Remove(key)
    return self:_commit(function(data)
        local _, list, index, parent = self:Get(key, data)
        assert(list, "The window cannot be removed")
        table.remove(list, index)
        return parent and parent.Key or "window"
    end)
end

function Project:Duplicate(key)
    return self:_commit(function(data)
        local value, list, index = self:Get(key, data)
        assert(list, "Select a tab, group, or control")
        value = clone(value)
        local pending = {}
        local function renew(node)
            local serial = 1
            while self:Get("n" .. serial, data) or pending["n" .. serial] do
                serial += 1
            end
            node.Key = "n" .. serial
            pending[node.Key] = true
            if node.Id then
                local base, suffix = node.Id, 2
                node.Id = unique(self, data, base, false)
                while pending[node.Id] do
                    node.Id, suffix = base .. " " .. suffix, suffix + 1
                end
                pending[node.Id] = true
            end
            if node.Kind == "Tab" then
                node.Name = unique(self, data, node.Name, true)
            end
            for _, child in ipairs(node.Groups or node.Controls or {}) do
                renew(child)
            end
        end
        renew(value)
        table.insert(list, index + 1, value)
        return value.Key
    end)
end

function Project:CanMove(key, targetKey)
    local node, source = self:Get(key)
    local target = self:Get(targetKey)
    if not source or not target or key == targetKey then
        return false
    end
    if node.Kind == "Tab" then
        return target.Kind == "Tab"
    end
    if node.Kind == "Group" then
        return target.Kind == "Tab" or target.Kind == "Group"
    end
    return table.find(Project.Kinds, node.Kind) ~= nil
        and (target.Kind == "Group" or table.find(Project.Kinds, target.Kind) ~= nil)
end

function Project:Move(key, targetKey, after)
    return self:_commit(function(data)
        local node, source, sourceIndex = self:Get(key, data)
        local target, targetList, targetIndex = self:Get(targetKey, data)
        assert(source and target and key ~= targetKey, "Choose another item")
        local destination, index
        if node.Kind == "Group" and target.Kind == "Tab" then
            destination, index = target.Groups, #target.Groups + 1
        elseif indexed[node.Kind] or table.find(Project.Kinds, node.Kind) then
            if target.Kind == "Group" then
                destination, index = target.Controls, #target.Controls + 1
            elseif table.find(Project.Kinds, target.Kind) then
                destination, index = targetList, targetIndex + (after and 1 or 0)
            end
        elseif node.Kind == "Tab" and target.Kind == "Tab" then
            destination, index = targetList, targetIndex + (after and 1 or 0)
        end
        if node.Kind == "Group" and target.Kind == "Group" then
            destination, index = targetList, targetIndex + (after and 1 or 0)
        end
        assert(destination, "Drop onto a matching item or its parent")
        table.remove(source, sourceIndex)
        if source == destination and sourceIndex < index then
            index -= 1
        end
        table.insert(destination, index, node)
        return key
    end)
end

function Project:Undo()
    local previous = table.remove(self.UndoStack)
    if not previous then
        return false
    end
    table.insert(self.RedoStack, { Data = self.Data, Selection = self.Selection })
    self.Data, self.Selection = previous.Data, previous.Selection
    return true
end

function Project:Redo()
    local following = table.remove(self.RedoStack)
    if not following then
        return false
    end
    table.insert(self.UndoStack, { Data = self.Data, Selection = self.Selection })
    self.Data, self.Selection = following.Data, following.Selection
    return true
end

function Project:Replace(data)
    return self:_commit(function(draft)
        local validated = Project.Validate(data)
        table.clear(draft)
        for key, value in pairs(validated) do
            draft[key] = value
        end
        return "window"
    end)
end

local function literal(value)
    if type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) ~= "table" then
        return tostring(value)
    end
    local parts = {}
    for _, entry in ipairs(value) do
        table.insert(parts, literal(entry))
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

local function color(value)
    return "Color3.fromRGB("
        .. tonumber(value:sub(1, 2), 16)
        .. ", "
        .. tonumber(value:sub(3, 4), 16)
        .. ", "
        .. tonumber(value:sub(5, 6), 16)
        .. ")"
end

function Project:Generate(mode)
    local data = Project.Validate(self.Data)
    local lines = {
        mode == "Studio" and 'local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Vortex"))'
            or 'local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/vortex/main/Library.lua"))()',
    }
    local function emit(value)
        table.insert(lines, value)
    end
    emit("")
    emit("local Window = Library:CreateWindow({")
    for _, item in ipairs(Project.Fields.Window) do
        if item.Key ~= "Width" and item.Key ~= "Height" then
            emit("    " .. item.Key .. " = " .. literal(data.Window[item.Key]) .. ",")
        end
    end
    emit("    Size = Vector2.new(" .. data.Window.Width .. ", " .. data.Window.Height .. "),")
    emit("    MaxSize = Vector2.new(1600, 1200),")
    emit("    Theme = {")
    for _, role in ipairs(Project.ThemeOrder) do
        emit("        " .. role .. " = " .. color(data.Theme[role]) .. ",")
    end
    emit("    },")
    emit("    Style = {")
    for _, item in ipairs(Project.StyleFields) do
        emit("        " .. item.Key .. " = " .. literal(data.Style[item.Key]) .. ",")
    end
    emit("    },")
    emit("})")
    for tabIndex, tab in ipairs(data.Tabs) do
        local tabVariable = "Tab" .. tabIndex
        emit("")
        emit(
            "local "
                .. tabVariable
                .. " = Window:AddTab({ Name = "
                .. literal(tab.Name)
                .. ", Icon = "
                .. literal(tab.Icon)
                .. ", Width = "
                .. tab.Width
                .. " })"
        )
        for groupIndex, group in ipairs(tab.Groups) do
            local variable = "Group" .. tabIndex .. "_" .. groupIndex
            emit("local " .. variable .. " = " .. tabVariable .. ":AddGroupbox({")
            for _, item in ipairs(Project.Fields.Group) do
                emit("    " .. item.Key .. " = " .. literal(group[item.Key]) .. ",")
            end
            emit("})")
            for _, control in ipairs(group.Controls) do
                local kind = control.Kind
                if kind == "Label" then
                    emit(variable .. ":AddLabel(" .. literal(control.Text) .. ", " .. literal(control.Wrapped) .. ")")
                elseif kind == "Divider" then
                    emit(variable .. ":AddDivider()")
                else
                    emit(
                        variable
                            .. ":Add"
                            .. kind
                            .. "("
                            .. (indexed[kind] and literal(control.Id) .. ", " or "")
                            .. "{"
                    )
                    for _, item in ipairs(Project.GetFields(kind)) do
                        if
                            item.Key ~= "Id"
                            and not (kind == "Input" and item.Key == "Height" and not control.Multiline)
                        then
                            local value = literal(control[item.Key])
                            local key = kind == "Paragraph" and item.Key == "Text" and "Title" or item.Key
                            if kind == "ColorPicker" and key == "Default" then
                                value = color(control.Default)
                            elseif kind == "Dropdown" and key == "Default" then
                                value = control.Default == "" and "nil"
                                    or control.Multi and "{ [" .. literal(control.Default) .. "] = true }"
                                    or value
                            end
                            emit("    " .. key .. " = " .. value .. ",")
                        end
                    end
                    if kind == "Button" then
                        emit("    Func = function() end,")
                    end
                    emit("})")
                end
            end
        end
    end
    emit("")
    emit("return Library")
    return table.concat(lines, "\n") .. "\n"
end

function Project:Build(library, overrides)
    local data = self.Data
    local info = clone(data.Window)
    info.Size, info.MaxSize, info.Theme, info.Style =
        Vector2.new(info.Width, info.Height), Vector2.new(1600, 1200), {}, clone(data.Style)
    for role, hex in pairs(data.Theme) do
        info.Theme[role] = Color3.fromHex(hex)
    end
    for key, value in pairs(overrides or {}) do
        info[key] = value
    end
    local window = library:CreateWindow(info)
    local objects = { window = window }
    for _, tab in ipairs(data.Tabs) do
        local tabObject = window:AddTab({ Name = tab.Name, Icon = tab.Icon, Width = tab.Width })
        objects[tab.Key] = tabObject
        for _, group in ipairs(tab.Groups) do
            local groupObject = tabObject:AddGroupbox(group)
            objects[group.Key] = groupObject
            for _, control in ipairs(group.Controls) do
                local options, object = clone(control), nil
                if control.Kind == "ColorPicker" then
                    options.Default = Color3.fromHex(control.Default)
                elseif control.Kind == "Dropdown" then
                    options.Default = control.Default ~= ""
                            and (control.Multi and { [control.Default] = true } or control.Default)
                        or nil
                elseif control.Kind == "Input" and not control.Multiline then
                    options.Height = nil
                end
                if control.Kind == "Label" then
                    object = groupObject:AddLabel(control.Text, control.Wrapped)
                elseif control.Kind == "Divider" then
                    object = groupObject:AddDivider()
                elseif control.Kind == "Paragraph" then
                    options.Title = control.Text
                    object = groupObject:AddParagraph(options)
                elseif indexed[control.Kind] then
                    object = groupObject["Add" .. control.Kind](groupObject, control.Id, options)
                else
                    object = groupObject["Add" .. control.Kind](groupObject, options)
                end
                objects[control.Key] = object
            end
        end
    end
    return window, objects
end

return Project
