local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {
    Version = "1.0.0",
    Options = {},
    Toggles = {},
    Unloaded = false,
    Theme = {
        Background = Color3.fromRGB(15, 15, 15),
        Surface = Color3.fromRGB(26, 26, 26),
        Border = Color3.fromRGB(43, 43, 43),
        Text = Color3.fromRGB(210, 210, 210),
        Muted = Color3.fromRGB(135, 135, 135),
        Accent = Color3.fromRGB(235, 235, 235),
        Track = Color3.fromRGB(60, 60, 60),
    },
    Icons = {
        rocket = "rbxassetid://109537053598807",
        target = "rbxassetid://83752373575368",
        plus = "rbxassetid://10709818399",
        users = "rbxassetid://85332511060401",
        person = "rbxassetid://114567720540659",
        gear = "rbxassetid://106205298246017",
        globe = "rbxassetid://125685532120024",
        grid = "rbxassetid://108197747587523",
    },
    _connections = {},
    _bindings = setmetatable({}, { __mode = "k" }),
    _unloadCallbacks = {},
}

local Group = {}
Group.__index = Group
local Tab = {}
Tab.__index = Tab
local Window = {}
Window.__index = Window

local function make(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, object)
end

local function themed(object, properties)
    Library._bindings[object] = properties
    for property, role in pairs(properties) do
        object[property] = type(role) == "function" and role(Library.Theme) or Library.Theme[role]
    end
    return object
end

local function stroke(object)
    return themed(
        make("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, object),
        { Color = "Border" }
    )
end

local function text(parent, value, size, role)
    return themed(
        make("TextLabel", {
            Name = "Label",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = tostring(value or ""),
            TextSize = size or 13,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, parent),
        { TextColor3 = role or "Text" }
    )
end

local function button(parent, caption)
    local object = themed(
        make("TextButton", {
            Name = "Button",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = caption or "",
            TextSize = 12,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        }, parent),
        { TextColor3 = "Text" }
    )
    return object
end

local function box(parent, placeholder)
    local object = themed(
        make("TextBox", {
            Name = "Input",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = placeholder or "",
            TextSize = 12,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
            ClearTextOnFocus = false,
        }, parent),
        { BackgroundColor3 = "Surface", TextColor3 = "Text", PlaceholderColor3 = "Muted" }
    )
    corner(object, 4)
    stroke(object)
    return object
end

local function list(parent, padding, horizontal)
    return make("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
    }, parent)
end

local function pad(parent, amount)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, amount),
        PaddingRight = UDim.new(0, amount),
        PaddingTop = UDim.new(0, amount),
        PaddingBottom = UDim.new(0, amount),
    }, parent)
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function copy(value)
    return type(value) == "table" and table.clone(value) or value
end

local function equal(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if b[key] ~= value then
            return false
        end
    end
    for key, value in pairs(b) do
        if a[key] ~= value then
            return false
        end
    end
    return true
end

function Library:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Library:SafeCallback(callback, ...)
    if type(callback) ~= "function" or self.Unloaded then
        return
    end
    local arguments = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(callback, table.unpack(arguments, 1, arguments.n))
        if not ok then
            warn("Vortex callback: " .. tostring(err))
        end
    end)
end

function Library:SetTheme(values)
    assert(type(values) == "table", "Theme must be a table")
    for role, color in pairs(values) do
        assert(self.Theme[role] ~= nil and typeof(color) == "Color3", "Invalid theme role: " .. tostring(role))
    end
    for role, color in pairs(values) do
        self.Theme[role] = color
    end
    for object, properties in pairs(self._bindings) do
        if object.Parent then
            for property, role in pairs(properties) do
                object[property] = type(role) == "function" and role(self.Theme) or self.Theme[role]
            end
        end
    end
end

function Library:OnUnload(callback)
    assert(type(callback) == "function", "OnUnload expects a function")
    table.insert(self._unloadCallbacks, callback)
    return self
end

function Library:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    for _, callback in ipairs(self._unloadCallbacks) do
        local ok, err = pcall(callback)
        if not ok then
            warn("Vortex unload: " .. tostring(err))
        end
    end
    if self.Window then
        self.Window.Gui:Destroy()
    end
    table.clear(self._connections)
    table.clear(self._bindings)
    table.clear(self._unloadCallbacks)
    table.clear(self.Options)
    table.clear(self.Toggles)
    self._pointer, self._capture, self._dropdown = nil, nil, nil
end

function Library:Notify(message, duration)
    if self.Unloaded or not self.Window then
        return
    end
    if type(message) == "table" then
        duration = message.Duration
        message = message.Title and (message.Title .. " · " .. (message.Description or "")) or message.Description
    end
    local holder = self.Window.Notifications
    local card = themed(
        make("Frame", {
            Name = "Notification",
            Size = UDim2.fromOffset(280, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
        }, holder),
        { BackgroundColor3 = "Surface" }
    )
    corner(card, 8)
    stroke(card)
    pad(card, 12)
    local caption = text(card, message, 12)
    caption.Size = UDim2.new(1, 0, 0, 0)
    caption.AutomaticSize = Enum.AutomaticSize.Y
    caption.TextWrapped = true
    caption.TextTruncate = Enum.TextTruncate.None
    task.delay(finite(duration) and math.max(0.1, duration) or 3, function()
        if card.Parent then
            card:Destroy()
        end
    end)
    return card
end

local function control(group, kind, index, info, height)
    info = info or {}
    if index ~= nil then
        assert(type(index) == "string" and index ~= "", "Control IDs must be non-empty strings")
        assert(not Library.Options[index] and not Library.Toggles[index], "Duplicate control ID: " .. index)
    end
    group.Order = group.Order + 1
    local frame = make("Frame", {
        Name = index or kind,
        LayoutOrder = group.Order,
        Size = UDim2.new(1, 0, 0, height or 30),
        BackgroundTransparency = 1,
        Visible = info.Visible ~= false,
    }, group.Content)
    local caption = text(frame, info.Text or index or "", 13)
    caption.Size = UDim2.new(1, -90, 1, 0)
    local object = {
        Type = kind,
        Id = index,
        Frame = frame,
        Label = caption,
        Group = group,
        Disabled = info.Disabled == true,
        Value = nil,
        _listeners = {},
        _callback = info.Callback,
    }
    function object:OnChanged(callback)
        assert(type(callback) == "function", "OnChanged expects a function")
        table.insert(self._listeners, callback)
        return self
    end
    function object:_emit()
        Library:SafeCallback(self._callback, copy(self.Value))
        for _, callback in ipairs(self._listeners) do
            Library:SafeCallback(callback, copy(self.Value))
        end
    end
    function object:SetText(value)
        self.Label.Text = tostring(value)
        return self
    end
    function object:SetVisible(value)
        frame.Visible = value == true
        if not frame.Visible and self.SetOpen then
            self:SetOpen(false)
        end
        return self
    end
    function object:SetDisabled(value)
        self.Disabled = value == true
        caption.TextTransparency = self.Disabled and 0.55 or 0
        if self.Box then
            self.Box.TextEditable = not self.Disabled
        end
        if self.Disabled and self.SetOpen then
            self:SetOpen(false)
        end
        if self.Disabled and Library._capture == self then
            Library._capture = nil
            self.Button.Text = self.Value
        end
        if self.Disabled and self.Type == "KeyPicker" and self.State then
            self:_trigger(false)
        end
        return self
    end
    function object:AddKeyPicker(id, options)
        options = table.clone(options or {})
        options.Text = options.Text or caption.Text
        local picker = group:AddKeyPicker(id, options)
        if options.SyncToggleState and kind == "Toggle" then
            picker:OnClick(function(value)
                self:SetValue(value)
            end)
            self:OnChanged(function(value)
                picker.State = value
            end)
            picker.State = self.Value
        end
        return self
    end
    function object:AddColorPicker(id, options)
        options = table.clone(options or {})
        options.Text = options.Text or caption.Text
        group:AddColorPicker(id, options)
        return self
    end
    if index then
        (kind == "Toggle" and Library.Toggles or Library.Options)[index] = object
    end
    object:SetDisabled(object.Disabled)
    return object
end

function Group:AddLabel(value, wrapped)
    local object = control(self, "Label", nil, { Text = value }, 24)
    object.Label.Size = UDim2.fromScale(1, 1)
    if wrapped then
        object.Frame.AutomaticSize = Enum.AutomaticSize.Y
        object.Frame.Size = UDim2.new(1, 0, 0, 0)
        object.Label.Size = UDim2.new(1, 0, 0, 0)
        object.Label.AutomaticSize = Enum.AutomaticSize.Y
        object.Label.TextWrapped = true
        object.Label.TextTruncate = Enum.TextTruncate.None
    end
    return object
end

function Group:AddDivider()
    local object = control(self, "Divider", nil, {}, 13)
    object.Label:Destroy()
    themed(
        make("Frame", {
            Position = UDim2.fromOffset(0, 6),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
        }, object.Frame),
        { BackgroundColor3 = "Border" }
    )
    return object
end

function Group:AddButton(info, callback)
    if type(info) == "string" then
        info = { Text = info, Func = callback }
    end
    local object = control(self, "Button", nil, info)
    object.Label.Size = UDim2.new(1, -24, 1, 0)
    local arrow = text(object.Frame, "›", 20, "Muted")
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 30)
    arrow.TextXAlignment = Enum.TextXAlignment.Right
    object.Button = button(object.Frame)
    function object:Press()
        if not self.Disabled then
            Library:SafeCallback(info.Func or info.Callback)
        end
    end
    object.Button.Activated:Connect(function()
        object:Press()
    end)
    return object
end

function Group:AddToggle(index, info)
    info = info or {}
    local object = control(self, "Toggle", index, info)
    local pill = themed(
        make("Frame", {
            Name = "Pill",
            Position = UDim2.new(1, -41, 0.5, -10.5),
            Size = UDim2.fromOffset(41, 21),
            BorderSizePixel = 0,
        }, object.Frame),
        { BackgroundColor3 = "Track" }
    )
    corner(pill, 12)
    local knob = themed(
        make("Frame", {
            Name = "Knob",
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(15, 15),
            BorderSizePixel = 0,
        }, pill),
        {
            BackgroundColor3 = function(theme)
                return object.Value and theme.Accent or theme.Muted
            end,
        }
    )
    corner(knob, 10)
    object.Button = button(object.Frame)
    function object:Validate(value)
        return type(value) == "boolean"
    end
    function object:SetValue(value, silent)
        if not self:Validate(value) then
            return false
        end
        local changed = self.Value ~= value
        self.Value = value
        knob.BackgroundColor3 = value and Library.Theme.Accent or Library.Theme.Muted
        if self._tween then
            self._tween:Cancel()
        end
        self._tween =
            TweenService:Create(knob, TweenInfo.new(0.13), { Position = UDim2.fromOffset(value and 23 or 3, 3) })
        self._tween:Play()
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    object.Button.Activated:Connect(function()
        if not object.Disabled then
            object:SetValue(not object.Value)
        end
    end)
    object:SetValue(info.Default == true, true)
    return object
end

function Group:AddSlider(index, info)
    info = info or {}
    local minimum, maximum = info.Min or 0, info.Max or 100
    local rounding = info.Rounding or 0
    assert(finite(minimum) and finite(maximum) and maximum > minimum, "Slider Max must exceed Min")
    assert(
        finite(rounding) and rounding >= 0 and rounding <= 6 and rounding % 1 == 0,
        "Rounding must be an integer from 0 to 6"
    )
    local object = control(self, "Slider", index, info, 48)
    object.Min, object.Max, object.Rounding = minimum, maximum, rounding
    object.Label.Size = UDim2.new(1, -65, 0, 23)
    local valueBox = box(object.Frame)
    valueBox.Position = UDim2.new(1, -56, 0, 0)
    valueBox.Size = UDim2.fromOffset(56, 23)
    object.Box = valueBox
    local track = themed(
        make("Frame", {
            Name = "Track",
            Position = UDim2.new(0, 0, 0, 35),
            Size = UDim2.new(1, -6, 0, 3),
            BorderSizePixel = 0,
        }, object.Frame),
        { BackgroundColor3 = "Track" }
    )
    local fill = themed(
        make("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track),
        { BackgroundColor3 = "Accent" }
    )
    local knob = themed(
        make("Frame", {
            Name = "Knob",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11),
            BorderSizePixel = 0,
        }, track),
        { BackgroundColor3 = "Accent" }
    )
    corner(knob, 10)
    local hit = button(object.Frame)
    hit.Position = UDim2.fromOffset(0, 25)
    hit.Size = UDim2.new(1, 0, 0, 23)
    function object:Validate(value)
        return finite(value)
    end
    function object:SetValue(value, silent)
        value = tonumber(value)
        if not self:Validate(value) then
            return false
        end
        local factor = 10 ^ rounding
        value = math.clamp(math.round(value * factor) / factor, minimum, maximum)
        local changed = self.Value ~= value
        self.Value = value
        valueBox.Text = tostring(value)
        local fraction = (value - minimum) / (maximum - minimum)
        knob.Position = UDim2.fromScale(fraction, 0.5)
        fill.Size = UDim2.fromScale(fraction, 1)
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    local function fromInput(input)
        if object.Disabled or track.AbsoluteSize.X <= 0 then
            return
        end
        object:SetValue(
            minimum
                + math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    * (maximum - minimum)
        )
    end
    hit.InputBegan:Connect(function(input)
        if object.Disabled then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            Library._pointer = { Input = input, Move = fromInput }
            fromInput(input)
        end
    end)
    valueBox.FocusLost:Connect(function()
        if object.Disabled or not object:SetValue(valueBox.Text) then
            valueBox.Text = tostring(object.Value)
        end
    end)
    object:SetValue(info.Default or minimum, true)
    object:SetDisabled(object.Disabled)
    return object
end

function Group:AddInput(index, info)
    info = info or {}
    assert(
        info.MaxLength == nil or finite(info.MaxLength) and info.MaxLength > 0 and info.MaxLength % 1 == 0,
        "MaxLength must be a positive integer"
    )
    local object = control(self, "Input", index, info, 38)
    object.Numeric = info.Numeric == true
    local field = box(object.Frame, info.Placeholder)
    field.Position = UDim2.new(0.48, 0, 0.5, -12)
    field.Size = UDim2.new(0.52, 0, 0, 24)
    object.Label.Size = UDim2.new(0.46, 0, 1, 0)
    object.Box = field
    function object:Validate(value)
        return type(value) == "string" and (not self.Numeric or finite(tonumber(value)))
    end
    function object:SetValue(value, silent)
        value = tostring(value)
        if not self:Validate(value) then
            return false
        end
        if info.MaxLength then
            value = value:sub(1, info.MaxLength)
        end
        local changed = self.Value ~= value
        self.Value = value
        field.Text = value
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    field.FocusLost:Connect(function()
        if object.Disabled or not object:SetValue(field.Text) then
            field.Text = object.Value
        end
    end)
    if info.Finished == false then
        field:GetPropertyChangedSignal("Text"):Connect(function()
            if not object.Disabled and object:Validate(field.Text) then
                object:SetValue(field.Text)
            end
        end)
    end
    assert(object:SetValue(info.Default or (object.Numeric and "0" or ""), true), "Invalid input default")
    object:SetDisabled(object.Disabled)
    return object
end

function Group:AddDropdown(index, info)
    info = info or {}
    assert(
        info.MaxVisibleDropdownItems == nil
            or finite(info.MaxVisibleDropdownItems)
                and info.MaxVisibleDropdownItems >= 1
                and info.MaxVisibleDropdownItems % 1 == 0,
        "MaxVisibleDropdownItems must be a positive integer"
    )
    local object = control(self, "Dropdown", index, info, 35)
    object.Multi, object.Values, object.Opened = info.Multi == true, {}, false
    object.Label.Position = UDim2.fromOffset(12, 0)
    object.Label.Size = UDim2.new(1, -38, 0, 35)
    themed(object.Frame, { BackgroundColor3 = "Surface" })
    object.Frame.BackgroundTransparency = 0.6
    corner(object.Frame)
    stroke(object.Frame)
    local arrow = text(object.Frame, "+", 16, "Muted")
    arrow.Position = UDim2.new(1, -27, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 35)
    object.Button = button(object.Frame)
    object.Button.Size = UDim2.new(1, 0, 0, 35)
    local body = make("Frame", {
        Name = "Expanded",
        Position = UDim2.fromOffset(8, 38),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, object.Frame)
    local search
    if info.Searchable then
        search = box(body, "Search...")
        search.Size = UDim2.new(1, 0, 0, 28)
        search.TextXAlignment = Enum.TextXAlignment.Left
        pad(search, 8)
    end
    local offset = search and 34 or 0
    local options = make("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.fromOffset(0, offset),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, body)
    list(options, 0)
    object.Search, object.OptionsFrame = search, options
    local function display()
        local selected = {}
        if object.Multi then
            for _, value in ipairs(object.Values) do
                if object.Value[value] then
                    table.insert(selected, value)
                end
            end
        elseif object.Value then
            table.insert(selected, object.Value)
        end
        object.Label.Text = (info.Text or index) .. (#selected > 0 and " · " .. table.concat(selected, ", ") or "")
    end
    function object:Refresh()
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        local query = search and search.Text:lower() or ""
        local count = 0
        for _, value in ipairs(self.Values) do
            if value:lower():find(query, 1, true) then
                count = count + 1
                local selected = self.Multi and self.Value[value] or self.Value == value
                local item = button(options, (selected and "✓  " or "") .. value)
                item.Name = "Option"
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.Size = UDim2.new(1, -4, 0, 30)
                item.LayoutOrder = count
                pad(item, 10)
                item.Activated:Connect(function()
                    if self.Disabled then
                        return
                    end
                    if self.Multi then
                        local nextValue = table.clone(self.Value)
                        nextValue[value] = not nextValue[value] or nil
                        self:SetValue(nextValue)
                    else
                        self:SetValue(value)
                        self:SetOpen(false)
                    end
                end)
            end
        end
        if count == 0 then
            local empty = text(options, "No results", 12, "Muted")
            empty.Size = UDim2.new(1, 0, 0, 30)
        end
        local visible = math.min(math.max(count, 1), info.MaxVisibleDropdownItems or 6)
        options.Size = UDim2.new(1, 0, 0, visible * 30)
        body.Size = UDim2.new(1, -16, 0, offset + visible * 30)
        if self.Opened then
            self.Frame.Size = UDim2.new(1, 0, 0, 46 + offset + visible * 30)
        end
        display()
    end
    function object:Validate(value)
        if self.Multi then
            if type(value) ~= "table" then
                return false
            end
            for entry, selected in pairs(value) do
                if type(selected) ~= "boolean" or not table.find(self.Values, entry) then
                    return false
                end
            end
            return true
        end
        return value == nil or table.find(self.Values, value) ~= nil
    end
    function object:SetValue(value, silent)
        if not self:Validate(value) then
            return false
        end
        local normalized = value
        if self.Multi then
            normalized = {}
            for entry, selected in pairs(value) do
                if selected then
                    normalized[entry] = true
                end
            end
        end
        local changed = not equal(self.Value, normalized)
        self.Value = copy(normalized)
        if self.Opened then
            self:Refresh()
        else
            display()
        end
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    function object:SetValues(values, silent)
        assert(type(values) == "table", "Dropdown Values must be an array of strings")
        local nextValues = {}
        for _, value in ipairs(values) do
            assert(
                type(value) == "string" and not table.find(nextValues, value),
                "Dropdown values must be unique strings"
            )
            table.insert(nextValues, value)
        end
        self.Values = nextValues
        local nextValue = self.Multi and {} or nil
        if self.Multi then
            for entry, selected in pairs(self.Value or {}) do
                if selected and table.find(nextValues, entry) then
                    nextValue[entry] = true
                end
            end
        elseif table.find(nextValues, self.Value) then
            nextValue = self.Value
        end
        self:SetValue(nextValue, silent)
        if self.Opened then
            self:Refresh()
        end
        return self
    end
    function object:SetOpen(value)
        value = value == true and not self.Disabled and self.Frame.Visible
        if value then
            if Library._dropdown and Library._dropdown ~= self then
                Library._dropdown:SetOpen(false)
            end
            Library._dropdown = self
        elseif Library._dropdown == self then
            Library._dropdown = nil
        end
        self.Opened, body.Visible = value, value
        arrow.Text = value and "−" or "+"
        if value then
            self:Refresh()
        else
            self.Frame.Size = UDim2.new(1, 0, 0, 35)
            if search then
                search:ReleaseFocus()
            end
        end
        return self
    end
    object.Button.Activated:Connect(function()
        object:SetOpen(not object.Opened)
    end)
    if search then
        search:GetPropertyChangedSignal("Text"):Connect(function()
            if object.Opened then
                object:Refresh()
            end
        end)
    end
    object.Value = object.Multi and {} or nil
    object:SetValues(info.Values or {}, true)
    local default = info.Default
    if type(default) == "number" then
        default = object.Values[default]
    end
    if object.Multi and type(default) == "string" then
        default = { [default] = true }
    end
    assert(object:SetValue(default or (object.Multi and {} or nil), true), "Invalid dropdown default")
    return object
end

local function validKey(value)
    if type(value) ~= "string" then
        return false
    end
    if value == "None" or value == "MB1" or value == "MB2" or value == "MB3" then
        return true
    end
    local ok, key = pcall(function()
        return Enum.KeyCode[value]
    end)
    return ok and key ~= nil and key ~= Enum.KeyCode.Unknown
end

local function inputKey(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode.Name
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        return "MB1"
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        return "MB2"
    end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        return "MB3"
    end
end

function Group:AddKeyPicker(index, info)
    info = info or {}
    local object = control(self, "KeyPicker", index, info)
    object.Mode, object.State, object._clickListeners = info.Mode or "Toggle", false, {}
    local modes = { Toggle = true, Hold = true, Press = true, Always = true }
    assert(modes[object.Mode], "Invalid keybind mode")
    local binder = button(object.Frame)
    binder.Position = UDim2.new(1, -92, 0.5, -11)
    binder.Size = UDim2.fromOffset(92, 22)
    binder.BackgroundTransparency = 0
    themed(binder, { BackgroundColor3 = "Surface", TextColor3 = "Muted" })
    corner(binder, 4)
    stroke(binder)
    object.Button = binder
    function object:Validate(value)
        if type(value) == "table" then
            return validKey(value[1]) and modes[value[2]] == true
        end
        return validKey(value)
    end
    function object:SetValue(value, silent)
        if not self:Validate(value) then
            return false
        end
        local key, mode = value, self.Mode
        if type(value) == "table" then
            key, mode = value[1], value[2]
        end
        local changed = self.Value ~= key or self.Mode ~= mode
        self.Value, self.Mode, self.State = key, mode, false
        binder.Text = key
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    function object:GetState()
        return not self.Disabled and (self.Mode == "Always" or self.State)
    end
    function object:OnClick(callback)
        assert(type(callback) == "function", "OnClick expects a function")
        table.insert(self._clickListeners, callback)
        return self
    end
    function object:_trigger(value)
        self.State = value
        Library:SafeCallback(info.Callback, value)
        for _, callback in ipairs(self._clickListeners) do
            Library:SafeCallback(callback, value)
        end
    end
    object._callback = info.ChangedCallback
    binder.Activated:Connect(function()
        if object.Disabled then
            return
        end
        if Library._capture then
            Library._capture.Button.Text = Library._capture.Value
        end
        Library._capture, binder.Text = object, "..."
    end)
    assert(object:SetValue(info.Default or "None", true), "Invalid keybind default")
    return object
end

function Group:AddColorPicker(index, info)
    info = info or {}
    assert(info.Transparency == nil or finite(info.Transparency), "Transparency must be finite")
    local object = control(self, "ColorPicker", index, info, 35)
    local swatch = button(object.Frame)
    swatch.Position = UDim2.new(1, -42, 0, 7)
    swatch.Size = UDim2.fromOffset(42, 21)
    swatch.BackgroundTransparency = 0
    corner(swatch, 4)
    stroke(swatch)
    local body = make("Frame", {
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, object.Frame)
    list(body, 4)
    local inner = setmetatable({ Content = body, Order = 0 }, Group)
    local hue = inner:AddSlider(nil, { Text = "Hue", Min = 0, Max = 360, Rounding = 0 })
    local saturation = inner:AddSlider(nil, { Text = "Saturation", Min = 0, Max = 100 })
    local brightness = inner:AddSlider(nil, { Text = "Brightness", Min = 0, Max = 100 })
    local alpha
    if info.Transparency ~= nil then
        alpha = inner:AddSlider(nil, { Text = "Transparency", Min = 0, Max = 100 })
    end
    local hex = box(body, "#FFFFFF")
    hex.Size = UDim2.new(1, 0, 0, 26)
    hex.LayoutOrder = 5
    object.Transparency = math.clamp(tonumber(info.Transparency) or 0, 0, 1)
    object.Button, object.Opened = swatch, false
    function object:Validate(value)
        return typeof(value) == "Color3"
    end
    function object:SetValueRGB(value, transparency, silent, fromSliders)
        if not self:Validate(value) or (transparency ~= nil and not finite(transparency)) then
            return false
        end
        local nextAlpha = transparency ~= nil and math.clamp(transparency, 0, 1) or self.Transparency
        local changed = self.Value ~= value or self.Transparency ~= nextAlpha
        self.Value, self.Transparency = value, nextAlpha
        swatch.BackgroundColor3 = value
        swatch.BackgroundTransparency = self.Transparency
        hex.Text = "#" .. value:ToHex()
        if not fromSliders then
            local h, s, v = value:ToHSV()
            hue:SetValue(h * 360, true)
            saturation:SetValue(s * 100, true)
            brightness:SetValue(v * 100, true)
        end
        if alpha then
            alpha:SetValue(self.Transparency * 100, true)
        end
        if changed and not silent then
            self:_emit()
        end
        return true
    end
    function object:SetValue(value, silent)
        return self:SetValueRGB(value, nil, silent)
    end
    function object:SetOpen(value)
        self.Opened = value == true and not self.Disabled and self.Frame.Visible
        body.Visible = self.Opened
        self.Frame.Size = UDim2.new(1, 0, 0, self.Opened and (38 + (alpha and 4 or 3) * 52 + 30) or 35)
        return self
    end
    local function update()
        if object.Disabled then
            return
        end
        object:SetValueRGB(
            Color3.fromHSV(hue.Value / 360, saturation.Value / 100, brightness.Value / 100),
            alpha and alpha.Value / 100 or nil,
            false,
            true
        )
    end
    hue:OnChanged(update)
    saturation:OnChanged(update)
    brightness:OnChanged(update)
    if alpha then
        alpha:OnChanged(update)
    end
    swatch.Activated:Connect(function()
        object:SetOpen(not object.Opened)
    end)
    hex.FocusLost:Connect(function()
        local digits = hex.Text:gsub("^#", "")
        if not object.Disabled and digits:match("^%x%x%x%x%x%x$") then
            object:SetValue(Color3.fromHex(digits))
        else
            hex.Text = "#" .. object.Value:ToHex()
        end
    end)
    assert(object:SetValueRGB(info.Default or Color3.new(1, 1, 1), object.Transparency, true), "Invalid color default")
    local baseDisabled = object.SetDisabled
    function object:SetDisabled(value)
        baseDisabled(self, value)
        hue:SetDisabled(value)
        saturation:SetDisabled(value)
        brightness:SetDisabled(value)
        if alpha then
            alpha:SetDisabled(value)
        end
        hex.TextEditable = not self.Disabled
        return self
    end
    object:SetDisabled(object.Disabled)
    return object
end

function Tab:AddGroupbox(info)
    if type(info) == "string" then
        info = { Name = info }
    end
    info = info or {}
    local side = (info.Side or "Full"):lower()
    assert(side == "full" or side == "left" or side == "right", "Groupbox Side must be Full, Left, or Right")
    local parent = side == "full" and self.Content or self.Columns[side]
    self.Order = self.Order + 1
    local card = themed(
        make("Frame", {
            Name = info.Name or "Groupbox",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = self.Order,
        }, parent),
        { BackgroundColor3 = "Background" }
    )
    corner(card, 8)
    stroke(card)
    pad(card, 16)
    list(card, 8)
    if info.Name and info.Name ~= "" then
        local heading = text(card, info.Name, 12, "Muted")
        heading.Size = UDim2.new(1, 0, 0, 20)
        heading.LayoutOrder = 0
    end
    local content = make("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
    }, card)
    list(content, 6)
    return setmetatable({ Frame = card, Content = content, Order = 0, Tab = self }, Group)
end

function Tab:AddLeftGroupbox(name)
    return self:AddGroupbox({ Name = name, Side = "Left" })
end
function Tab:AddRightGroupbox(name)
    return self:AddGroupbox({ Name = name, Side = "Right" })
end
function Tab:Select()
    return self.Window:SelectTab(self.Name)
end

function Window:AddTab(name, icon)
    assert(type(name) == "string" and not self.Tabs[name], "Tab name must be unique")
    local nav = button(self.Navigation, name)
    nav.Name = name
    nav.Size = UDim2.fromOffset(math.max(72, #name * 7 + (icon and 38 or 24)), 32)
    nav.LayoutOrder = #self.TabOrder + 1
    corner(nav, 6)
    themed(nav, {
        BackgroundColor3 = "Surface",
        TextColor3 = function(theme)
            return self.SelectedTab == name and theme.Text or theme.Muted
        end,
    })
    if icon then
        local asset = Library.Icons[icon] or tostring(icon)
        if tonumber(asset) then
            asset = "rbxassetid://" .. asset
        end
        themed(
            make("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Image = asset,
                Position = UDim2.fromOffset(10, 9),
                Size = UDim2.fromOffset(14, 14),
            }, nav),
            { ImageColor3 = "Muted" }
        )
        pad(nav, 8).PaddingLeft = UDim.new(0, 28)
    end
    local viewport = make("ScrollingFrame", {
        Name = name .. "Page",
        Position = UDim2.fromOffset(16, 102),
        Size = UDim2.new(1, -32, 1, -140),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, self.Frame)
    local content = make("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, viewport)
    list(content, 10)
    local columns = make("Frame", {
        Name = "Columns",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 100000,
    }, content)
    local sides = {}
    for _, side in ipairs({ "left", "right" }) do
        local column = make("Frame", {
            Name = side,
            Position = side == "left" and UDim2.new() or UDim2.new(0.5, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, columns)
        list(column, 10)
        sides[side] = column
    end
    local tab = setmetatable({
        Name = name,
        Window = self,
        Frame = viewport,
        Content = content,
        Columns = sides,
        Button = nav,
        Order = 0,
    }, Tab)
    self.Tabs[name] = tab
    table.insert(self.TabOrder, tab)
    nav.Activated:Connect(function()
        self:SelectTab(name)
    end)
    if not self.SelectedTab then
        self:SelectTab(name)
    end
    return tab
end

function Window:SelectTab(name)
    assert(self.Tabs[name], "Unknown tab: " .. tostring(name))
    if Library._dropdown then
        Library._dropdown:SetOpen(false)
    end
    self.SelectedTab = name
    for _, tab in ipairs(self.TabOrder) do
        local selected = tab.Name == name
        tab.Frame.Visible = selected
        tab.Button.BackgroundTransparency = selected and 0.35 or 1
        tab.Button.TextColor3 = selected and Library.Theme.Text or Library.Theme.Muted
    end
    return self.Tabs[name]
end

function Window:SetVisible(value)
    self.Frame.Visible = value == true
    if not self.Frame.Visible and Library._dropdown then
        Library._dropdown:SetOpen(false)
    end
    Library._pointer = nil
    return self
end

function Window:Toggle()
    return self:SetVisible(not self.Frame.Visible)
end
function Window:SetTitle(value)
    self.Title.Text = tostring(value)
    return self
end
function Window:SetFooter(value)
    self.Footer.Text = tostring(value)
    return self
end
function Window:SetUserInfoVisible(value)
    self.UserInfo.Visible = value == true
    return self
end
function Window:SetToggleKey(value)
    if typeof(value) == "EnumItem" then
        value = value.Name
    end
    assert(validKey(value), "Invalid menu key")
    self.ToggleKey = value
    self.Hint.Text = value:upper() .. "  /  MENU"
    return self
end
function Window:Destroy()
    Library:Unload()
end

function Library:CreateWindow(info)
    assert(not self.Window and not self.Unloaded, "Load a fresh Library module for another window")
    info = info or {}
    local player = Players.LocalPlayer
    assert(player, "Vortex must run on the client")
    local gui = make("ScreenGui", {
        Name = "VortexUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = info.DisplayOrder or 10000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if info.Parent then
        gui.Parent = info.Parent
    else
        local ok = pcall(function()
            gui.Parent = type(gethui) == "function" and gethui() or game:GetService("CoreGui")
        end)
        if not ok then
            gui.Parent = player:WaitForChild("PlayerGui")
        end
    end
    local size = info.Size or Vector2.new(580, 460)
    assert(
        typeof(size) == "Vector2" and size.X >= 400 and size.Y >= 300,
        "Size must be a Vector2 of at least 400 × 300"
    )
    assert(info.Scale == nil or finite(info.Scale) and info.Scale > 0, "Scale must be positive")
    local frame = themed(
        make("Frame", {
            Name = "Window",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = info.Position or UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(size.X, size.Y),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = info.AutoShow ~= false,
        }, gui),
        { BackgroundColor3 = "Background" }
    )
    corner(frame, 10)
    stroke(frame)
    local scale = make("UIScale", { Scale = 1 }, frame)
    local header = button(frame)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    local title = text(header, info.Title or "vortex", 20)
    local titleWidth = math.clamp(#tostring(info.Title or "vortex") * 11, 80, size.X * 0.42)
    title.Position = UDim2.fromOffset(22, 10)
    title.Size = UDim2.fromOffset(titleWidth, 28)
    themed(
        make("Frame", {
            Position = UDim2.fromOffset(30 + titleWidth, 16),
            Size = UDim2.fromOffset(1, 18),
            BorderSizePixel = 0,
        }, header),
        { BackgroundColor3 = "Border" }
    )
    local subtitle = text(header, info.Subtitle or "by shrak.", 10, "Muted")
    subtitle.Position = UDim2.fromOffset(44 + titleWidth, 18)
    subtitle.Size = UDim2.new(1, -100 - titleWidth, 0, 20)
    local close = button(header, "×")
    close.Position = UDim2.new(1, -42, 0, 12)
    close.Size = UDim2.fromOffset(24, 24)
    close.TextSize = 20
    for _, y in ipairs({ 48, size.Y - 30 }) do
        themed(
            make("Frame", {
                Position = UDim2.fromOffset(16, y),
                Size = UDim2.new(1, -32, 0, 1),
                BorderSizePixel = 0,
            }, frame),
            { BackgroundColor3 = "Border" }
        )
    end
    local navigation = make("ScrollingFrame", {
        Name = "Navigation",
        Position = UDim2.fromOffset(16, 57),
        Size = UDim2.new(1, -32, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, frame)
    list(navigation, 5, true)
    local userInfo = make("Frame", {
        Name = "UserInfo",
        Position = UDim2.new(0, 16, 1, -27),
        Size = UDim2.fromOffset(190, 24),
        BackgroundTransparency = 1,
        Visible = info.ShowUserInfo ~= false,
    }, frame)
    local avatar = make("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarBust&id=" .. player.UserId .. "&w=48&h=48",
    }, userInfo)
    corner(avatar, 20)
    local displayName = text(userInfo, player.DisplayName, 11)
    displayName.Position = UDim2.fromOffset(32, 0)
    displayName.Size = UDim2.fromOffset(155, 12)
    local username = text(userInfo, "@" .. player.Name, 10, "Muted")
    username.Position = UDim2.fromOffset(32, 12)
    username.Size = UDim2.fromOffset(155, 12)
    local footer = text(frame, info.Footer or "", 10, "Muted")
    footer.Position = UDim2.new(0.36, 0, 1, -26)
    footer.Size = UDim2.new(0.36, 0, 0, 22)
    local hint = text(frame, "", 10, "Muted")
    hint.Position = UDim2.new(1, -150, 1, -26)
    hint.Size = UDim2.fromOffset(134, 22)
    hint.TextXAlignment = Enum.TextXAlignment.Right
    local launcher = button(gui, info.LauncherText or "V")
    launcher.Name = "Launcher"
    launcher.Position = info.LauncherPosition or UDim2.fromOffset(22, 104)
    launcher.Size = UDim2.fromOffset(52, 52)
    launcher.BackgroundTransparency = 0.12
    launcher.TextSize = 28
    launcher.Visible = info.ShowLauncher ~= false
    themed(launcher, { BackgroundColor3 = "Surface", TextColor3 = "Accent" })
    corner(launcher, 16)
    stroke(launcher)
    local notifications = make("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(280, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, gui)
    local notificationLayout = list(notifications, 8)
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    local window = setmetatable({
        Gui = gui,
        Frame = frame,
        Title = title,
        Subtitle = subtitle,
        Footer = footer,
        UserInfo = userInfo,
        Hint = hint,
        Navigation = navigation,
        Launcher = launcher,
        Notifications = notifications,
        Scale = scale,
        Tabs = {},
        TabOrder = {},
    }, Window)
    self.Window = window
    window:SetToggleKey(info.ToggleKey or "LeftControl")
    local function fit()
        local viewport = gui.AbsoluteSize
        if viewport.X <= 0 or viewport.Y <= 0 then
            return
        end
        scale.Scale = math.max(0.05, math.min(info.Scale or 1, (viewport.X - 32) / size.X, (viewport.Y - 32) / size.Y))
        local half = Vector2.new(size.X * scale.Scale / 2, size.Y * scale.Scale / 2)
        local center = Vector2.new(
            frame.Position.X.Scale * viewport.X + frame.Position.X.Offset,
            frame.Position.Y.Scale * viewport.Y + frame.Position.Y.Offset
        )
        frame.Position = UDim2.fromOffset(
            math.clamp(center.X, half.X, math.max(half.X, viewport.X - half.X)),
            math.clamp(center.Y, half.Y, math.max(half.Y, viewport.Y - half.Y))
        )
        launcher.Position = UDim2.fromOffset(
            math.clamp(launcher.Position.X.Offset, 0, math.max(0, viewport.X - 52)),
            math.clamp(launcher.Position.Y.Offset, 0, math.max(0, viewport.Y - 52))
        )
    end
    self:Connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
    task.defer(function()
        if not self.Unloaded then
            fit()
        end
    end)
    local draggedUntil = 0
    local function beginDrag(target, input)
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        local start, position = target.Position, input.Position
        self._pointer = {
            Input = input,
            Move = function(changed)
                local delta = Vector2.new(changed.Position.X - position.X, changed.Position.Y - position.Y)
                local viewport = gui.AbsoluteSize
                if target == launcher then
                    if delta.Magnitude > 4 then
                        draggedUntil = os.clock() + 0.2
                    end
                    target.Position = UDim2.fromOffset(
                        math.clamp(start.X.Offset + delta.X, 0, math.max(0, viewport.X - 52)),
                        math.clamp(start.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - 52))
                    )
                else
                    local half = frame.AbsoluteSize / 2
                    local x = start.X.Scale * viewport.X + start.X.Offset + delta.X
                    local y = start.Y.Scale * viewport.Y + start.Y.Offset + delta.Y
                    frame.Position = UDim2.fromOffset(
                        math.clamp(x, half.X, math.max(half.X, viewport.X - half.X)),
                        math.clamp(y, half.Y, math.max(half.Y, viewport.Y - half.Y))
                    )
                end
            end,
        }
    end
    header.InputBegan:Connect(function(input)
        if input.Position.X < close.AbsolutePosition.X then
            beginDrag(frame, input)
        end
    end)
    launcher.InputBegan:Connect(function(input)
        beginDrag(launcher, input)
    end)
    launcher.Activated:Connect(function()
        if os.clock() >= draggedUntil then
            window:Toggle()
        end
    end)
    close.Activated:Connect(function()
        window:SetVisible(false)
    end)
    self:Connect(UIS.InputChanged, function(input)
        local pointer = self._pointer
        if
            pointer
            and (
                input == pointer.Input
                or (
                    pointer.Input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseMovement
                )
            )
        then
            pointer.Move(input)
        end
    end)
    self:Connect(UIS.InputEnded, function(input)
        local pointer = self._pointer
        if
            pointer
            and (
                input == pointer.Input
                or (
                    pointer.Input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseButton1
                )
            )
        then
            self._pointer = nil
        end
        local key = inputKey(input)
        for _, option in pairs(self.Options) do
            if option.Type == "KeyPicker" and option.Mode == "Hold" and option.Value == key and option.State then
                option:_trigger(false)
            end
        end
    end)
    self:Connect(UIS.InputBegan, function(input, processed)
        local key = inputKey(input)
        if not key then
            return
        end
        if self._capture then
            local capture = self._capture
            self._capture = nil
            if key == "Escape" then
                capture.Button.Text = capture.Value
            else
                capture:SetValue(key == "Backspace" and "None" or key)
            end
            return
        end
        if processed or UIS:GetFocusedTextBox() then
            return
        end
        if key == window.ToggleKey then
            window:Toggle()
        end
        for _, option in pairs(self.Options) do
            if option.Type == "KeyPicker" and not option.Disabled and option.Value == key then
                if option.Mode == "Toggle" then
                    option:_trigger(not option.State)
                elseif option.Mode == "Hold" then
                    option:_trigger(true)
                elseif option.Mode == "Press" then
                    option:_trigger(true)
                    option.State = false
                end
            end
        end
    end)
    return window
end

return Library
