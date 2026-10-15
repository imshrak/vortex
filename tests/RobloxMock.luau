local nativeTypeof = typeof
local function typeof(value)
    return type(value) == "table" and value._type or nativeTypeof(value)
end

local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            local connection = { Connected = true }
            function connection:Disconnect()
                self.Connected = false
            end
            table.insert(callbacks, { Connection = connection, Callback = callback })
            return connection
        end,
        Fire = function(_, ...)
            for _, item in ipairs(table.clone(callbacks)) do
                if item.Connection.Connected then
                    item.Callback(...)
                end
            end
        end,
    }
end

local function typed(name, value)
    value._type = name
    return value
end

local Vector2 = {}
local vectorMeta = {
    __add = function(a, b)
        return Vector2.new(a.X + b.X, a.Y + b.Y)
    end,
    __sub = function(a, b)
        return Vector2.new(a.X - b.X, a.Y - b.Y)
    end,
    __div = function(a, b)
        return Vector2.new(a.X / b, a.Y / b)
    end,
    __index = function(value, key)
        if key == "Magnitude" then
            return math.sqrt(value.X ^ 2 + value.Y ^ 2)
        end
    end,
}
function Vector2.new(x, y)
    return setmetatable(typed("Vector2", { X = x, Y = y }), vectorMeta)
end
local UDim = {
    new = function(scale, offset)
        return { Scale = scale, Offset = offset }
    end,
}
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
    return typed("UDim2", { X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0) })
end
function UDim2.fromOffset(x, y)
    return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
    return UDim2.new(x, 0, y, 0)
end

local Color3 = {}
local colorMeta = {
    __index = Color3,
    __eq = function(a, b)
        return a.R == b.R and a.G == b.G and a.B == b.B
    end,
}
function Color3.new(r, g, b)
    return setmetatable(typed("Color3", { R = r, G = g, B = b }), colorMeta)
end
function Color3.fromRGB(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHex(value)
    return Color3.fromRGB(tonumber(value:sub(1, 2), 16), tonumber(value:sub(3, 4), 16), tonumber(value:sub(5, 6), 16))
end
function Color3:ToHex()
    return string.format("%02x%02x%02x", math.round(self.R * 255), math.round(self.G * 255), math.round(self.B * 255))
end
function Color3.fromHSV(h, s, v)
    local sector = math.floor(h * 6) % 6
    local fraction = h * 6 - math.floor(h * 6)
    local p, q, t = v * (1 - s), v * (1 - fraction * s), v * (1 - (1 - fraction) * s)
    local colors = { { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } }
    return Color3.new(table.unpack(colors[sector + 1]))
end
function Color3:ToHSV()
    local highest, lowest = math.max(self.R, self.G, self.B), math.min(self.R, self.G, self.B)
    local delta, h = highest - lowest, 0
    if delta > 0 then
        if highest == self.R then
            h = ((self.G - self.B) / delta) % 6
        elseif highest == self.G then
            h = (self.B - self.R) / delta + 2
        else
            h = (self.R - self.G) / delta + 4
        end
    end
    return h / 6, highest == 0 and 0 or delta / highest, highest
end

local Enum = setmetatable({}, {
    __index = function(self, category)
        local items = setmetatable({}, {
            __index = function(group, name)
                if category == "KeyCode" and name == "InvalidKey" then
                    error("Invalid key")
                end
                local item = typed("EnumItem", { Name = name })
                rawset(group, name, item)
                return item
            end,
        })
        rawset(self, category, items)
        return items
    end,
})
local Font = {
    new = function(family, weight, style)
        return typed("Font", { Family = family, Weight = weight, Style = style })
    end,
}
local TweenInfo = {
    new = function(...)
        return { ... }
    end,
}
local callbackErrors = {}
local delayed = {}
local task = {
    spawn = function(callback, ...)
        callback(...)
    end,
    defer = function(callback, ...)
        callback(...)
    end,
    delay = function(_, callback)
        table.insert(delayed, callback)
    end,
}
local function warn(message)
    table.insert(callbackErrors, message)
end

local instanceMethods = {}
local function guiClass(class)
    return table.find(
        { "Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame" },
        class
    ) ~= nil
end
function instanceMethods:IsA(class)
    return self.ClassName == class or class == "GuiObject" and guiClass(self.ClassName)
end
function instanceMethods:GetChildren()
    return table.clone(self._children)
end
function instanceMethods:GetDescendants()
    local result = {}
    for _, child in ipairs(self._children) do
        table.insert(result, child)
        for _, descendant in ipairs(child:GetDescendants()) do
            table.insert(result, descendant)
        end
    end
    return result
end
function instanceMethods:FindFirstChild(name)
    for _, child in ipairs(self._children) do
        if child.Name == name then
            return child
        end
    end
end
function instanceMethods:GetPropertyChangedSignal(key)
    if not self._signals[key] then
        self._signals[key] = signal()
    end
    return self._signals[key]
end
function instanceMethods:SetAttribute(name, value)
    self._attributes = self._attributes or {}
    self._attributes[name] = value
end
function instanceMethods:GetAttribute(name)
    return self._attributes and self._attributes[name]
end
function instanceMethods:FindFirstChildOfClass(class)
    for _, child in ipairs(self._children) do
        if child.ClassName == class then
            return child
        end
    end
end
function instanceMethods:Destroy()
    for _, child in ipairs(self:GetChildren()) do
        child:Destroy()
    end
    self.Parent = nil
    self.Destroyed = true
end
function instanceMethods:ReleaseFocus()
    self.Focused = false
end
function instanceMethods:WaitForChild(name)
    return self[name]
end
local Instance = {}
function Instance.new(class)
    local properties = {
        ClassName = class,
        Name = class,
        Position = UDim2.new(),
        Size = UDim2.new(),
        AbsoluteSize = Vector2.new(1280, 720),
        AbsolutePosition = Vector2.new(0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        Visible = true,
        Activated = signal(),
        MouseEnter = signal(),
        MouseLeave = signal(),
        InputBegan = signal(),
        InputEnded = signal(),
        Focused = signal(),
        FocusLost = signal(),
        Text = "",
        TextBounds = Vector2.new(0, 0),
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
    }
    local object = { _children = {}, _signals = {}, _properties = properties }
    return setmetatable(object, {
        __index = function(self, key)
            return instanceMethods[key] or self._properties[key]
        end,
        __newindex = function(self, key, value)
            if key == "Parent" then
                local oldParent = properties.Parent
                if oldParent then
                    local position = table.find(oldParent._children, self)
                    if position then
                        table.remove(oldParent._children, position)
                    end
                end
                if value then
                    table.insert(value._children, self)
                end
            end
            local changed = properties[key] ~= value
            properties[key] = value
            if changed and self._signals[key] then
                self._signals[key]:Fire()
            end
        end,
    })
end

local jsonValues, jsonSequence = {}, 0
local HttpService = {}
function HttpService:JSONEncode(value)
    jsonSequence += 1
    local key = "json:" .. jsonSequence
    jsonValues[key] = value
    return key
end
function HttpService:JSONDecode(value)
    assert(jsonValues[value], "Malformed JSON")
    return jsonValues[value]
end
local UIS = { InputBegan = signal(), InputChanged = signal(), InputEnded = signal() }
function UIS:GetFocusedTextBox()
    return self.FocusedTextBox
end
local playerGui = Instance.new("PlayerGui")
local services = {
    Players = {
        LocalPlayer = {
            UserId = 1,
            DisplayName = "Test",
            Name = "test",
            WaitForChild = function()
                return playerGui
            end,
        },
    },
    UserInputService = UIS,
    CoreGui = Instance.new("CoreGui"),
    TweenService = {
        Create = function(_, target, _, properties)
            local tween = { Completed = signal() }
            tween.Play = function()
                for key, value in pairs(properties) do
                    target[key] = value
                end
                tween.Completed:Fire(Enum.PlaybackState.Completed)
            end
            tween.Cancel = function()
                tween.Completed:Fire(Enum.PlaybackState.Cancelled)
            end
            return tween
        end,
    },
    HttpService = HttpService,
}
local game = {
    GetService = function(_, name)
        assert(services[name], name)
        return services[name]
    end,
}
local files, folders = {}, {}
local storage = {
    readfile = function(path)
        assert(files[path], "Missing file")
        return files[path]
    end,
    writefile = function(path, value)
        files[path] = value
    end,
    isfile = function(path)
        return files[path] ~= nil
    end,
    makefolder = function(path)
        folders[path] = true
    end,
    isfolder = function(path)
        return folders[path] == true
    end,
    delfile = function(path)
        files[path] = nil
    end,
    listfiles = function(path)
        local result = {}
        for entry in pairs(files) do
            if entry:sub(1, #path + 1) == path .. "/" then
                table.insert(result, entry)
            end
        end
        return result
    end,
}
