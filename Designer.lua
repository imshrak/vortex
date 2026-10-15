local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Designer = {}
Designer.__index = Designer
Designer.Version = "1.1.0"

local palette = {
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(19, 19, 19),
    Field = Color3.fromRGB(26, 26, 26),
    Border = Color3.fromRGB(37, 37, 37),
    Text = Color3.fromRGB(222, 222, 222),
    Muted = Color3.fromRGB(143, 143, 143),
    Accent = Color3.fromRGB(235, 235, 235),
    Selected = Color3.fromRGB(33, 33, 33),
    Hover = Color3.fromRGB(39, 39, 39),
    Error = Color3.fromRGB(238, 147, 153),
}

local motions = setmetatable({}, { __mode = "k" })
local function animate(object, properties, duration)
    local active = motions[object] or {}
    motions[object] = active
    for property, value in pairs(properties) do
        local previous = active[property]
        if previous and previous.Value == value then
            continue
        end
        if previous then
            previous.Tween:Cancel()
        end
        if object[property] == value then
            continue
        end
        local tween = TweenService:Create(
            object,
            TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { [property] = value }
        )
        local entry = { Tween = tween, Value = value }
        active[property] = entry
        local connection
        connection = tween.Completed:Connect(function()
            if active[property] == entry then
                active[property] = nil
            end
            connection:Disconnect()
        end)
        tween:Play()
    end
end

local function cancelMotion(object, property)
    local active = motions[object]
    if active and active[property] then
        active[property].Tween:Cancel()
    end
end

local function cancelTree(root)
    local objects = root:GetDescendants()
    table.insert(objects, root)
    for _, object in ipairs(objects) do
        local active = motions[object]
        if active then
            for _, entry in pairs(table.clone(active)) do
                entry.Tween:Cancel()
            end
            motions[object] = nil
        end
    end
end

local function make(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 7) }, object)
end

local function outline(object, color)
    return make(
        "UIStroke",
        { Color = color or palette.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
        object
    )
end

local function frame(parent, name, position, size, color, class)
    return make(class or "Frame", {
        Name = name,
        Position = position,
        Size = size,
        BorderSizePixel = 0,
        BackgroundColor3 = color or palette.Surface,
    }, parent)
end

local function text(parent, value, position, size, color, fontSize)
    return make("TextLabel", {
        Name = "Label",
        Text = value,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextColor3 = color or palette.Text,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = fontSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function icon(parent, name, position, color)
    local root = frame(parent, "Icon_" .. name, position, UDim2.fromOffset(16, 16))
    root.BackgroundTransparency = 1
    local parts = {}
    local function line(x1, y1, x2, y2, thickness)
        local dx, dy = x2 - x1, y2 - y1
        local item = frame(
            root,
            "Stroke",
            UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
            UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), thickness or 1.3),
            color or palette.Muted
        )
        item.AnchorPoint, item.Rotation = Vector2.new(0.5, 0.5), math.deg(math.atan2(dy, dx))
        corner(item, 1)
        table.insert(parts, { item, "BackgroundColor3" })
    end
    local function rect(x, y, width, height, radius)
        local item = frame(root, "Shape", UDim2.fromOffset(x, y), UDim2.fromOffset(width, height))
        item.BackgroundTransparency = 1
        corner(item, radius or 2)
        local border = outline(item, color or palette.Muted)
        border.Thickness = 1.2
        table.insert(parts, { border, "Color" })
    end
    local function dot(x, y, radius)
        local item = frame(
            root,
            "Dot",
            UDim2.fromOffset(x - radius, y - radius),
            UDim2.fromOffset(radius * 2, radius * 2),
            color or palette.Muted
        )
        corner(item, 100)
        table.insert(parts, { item, "BackgroundColor3" })
    end
    if name == "Undo" or name == "Redo" then
        local function stroke(x1, y1, x2, y2)
            if name == "Redo" then
                x1, x2 = 16 - x1, 16 - x2
            end
            line(x1, y1, x2, y2)
        end
        stroke(13, 12, 13, 9)
        stroke(13, 9, 10, 6)
        stroke(10, 6, 3, 6)
        stroke(3, 6, 6, 3)
        stroke(3, 6, 6, 9)
    elseif name == "New" then
        rect(3, 2, 10, 12)
        line(5, 8, 11, 8)
        line(8, 5, 8, 11)
    elseif name == "Open" or name == "Group" then
        rect(2, 5, 12, 9)
        line(2, 5, 2, 3)
        line(2, 3, 7, 3)
        line(7, 3, 9, 5)
        if name == "Open" then
            line(3, 12, 5, 8)
            line(5, 8, 13, 8)
        end
    elseif name == "Save" then
        rect(2, 2, 12, 12)
        rect(5, 2, 6, 4, 1)
        rect(5, 9, 6, 5, 1)
    elseif name == "Preview" then
        line(5, 3, 13, 8)
        line(13, 8, 5, 13)
        line(5, 13, 5, 3)
    elseif name == "Export" then
        line(8, 2, 8, 10)
        line(5, 5, 8, 2)
        line(8, 2, 11, 5)
        line(2, 10, 2, 14)
        line(2, 14, 14, 14)
        line(14, 14, 14, 10)
    elseif name == "Minimize" then
        line(4, 8, 12, 8)
    elseif name == "Close" then
        line(4, 4, 12, 12)
        line(12, 4, 4, 12)
    elseif name == "Plus" then
        line(8, 3, 8, 13)
        line(3, 8, 13, 8)
    elseif name == "Check" or name == "Checkbox" then
        if name == "Checkbox" then
            rect(2, 2, 12, 12)
        end
        line(4, 8, 7, 11)
        line(7, 11, 12, 5)
    elseif name == "Toggle" then
        rect(1, 5, 14, 7, 4)
        dot(11, 8.5, 2)
    elseif name == "Slider" or name == "Properties" then
        for index, x in ipairs({ 5, 11, 7 }) do
            local y = index * 4
            line(2, y, x - 2, y)
            line(x + 2, y, 14, y)
            dot(x, y, 1.7)
        end
    elseif name == "Input" then
        rect(1, 4, 14, 9)
        line(6, 6, 6, 11)
        line(4, 6, 8, 6)
        line(4, 11, 8, 11)
    elseif name == "Dropdown" then
        rect(2, 3, 12, 10)
        line(5, 7, 8, 10)
        line(8, 10, 11, 7)
    elseif name == "Button" then
        rect(2, 3, 12, 10)
        line(7, 5.5, 10, 8)
        line(10, 8, 7, 10.5)
    elseif name == "KeyPicker" then
        rect(1, 4, 14, 9)
        line(4, 7, 5, 7)
        line(8, 7, 9, 7)
        line(11, 7, 12, 7)
        line(5, 10, 11, 10)
    elseif name == "ColorPicker" or name == "Theme" then
        rect(2, 2, 12, 12, 7)
        dot(5, 6, 0.8)
        dot(8, 4.5, 0.8)
        dot(11, 6, 0.8)
        dot(5, 9.5, 0.8)
        rect(9, 9, 4, 4, 2)
    elseif name == "Label" or name == "Style" then
        line(3, 3, 13, 3)
        line(8, 3, 8, 13)
        line(5, 13, 11, 13)
    elseif name == "Paragraph" then
        line(2, 4, 14, 4)
        line(2, 8, 14, 8)
        line(2, 12, 10, 12)
    elseif name == "Image" then
        rect(2, 2, 12, 12)
        line(3, 12, 7, 8)
        line(7, 8, 13, 13)
        dot(10.5, 5.5, 1)
    elseif name == "Divider" then
        line(2, 8, 14, 8)
    elseif name == "Copy" or name == "Duplicate" then
        rect(5, 5, 9, 9)
        line(3, 11, 2, 11)
        line(2, 11, 2, 2)
        line(2, 2, 11, 2)
        line(11, 2, 11, 3)
    elseif name == "Delete" then
        rect(4, 5, 8, 9, 1)
        line(3, 4, 13, 4)
        line(6, 2, 10, 2)
        line(6.5, 7, 6.5, 12)
        line(9.5, 7, 9.5, 12)
    elseif name == "Up" or name == "Down" then
        local a, b = name == "Up" and 10 or 6, name == "Up" and 5 or 11
        line(3, a, 8, b)
        line(8, b, 13, a)
    elseif name == "Reset" then
        line(3, 6, 5, 3)
        line(5, 3, 11, 3)
        line(11, 3, 14, 6)
        line(14, 6, 14, 11)
        line(14, 11, 11, 14)
        line(11, 14, 5, 14)
        line(5, 14, 2, 11)
        line(2, 4, 3, 7)
        line(3, 7, 6, 6)
    elseif name == "Vortex" then
        line(2, 3, 8, 13, 2)
        line(8, 13, 14, 3, 2)
    else
        rect(2, 3, 12, 10)
        line(2, 6, 14, 6)
    end
    return root,
        function(value)
            for _, part in ipairs(parts) do
                animate(part[1], { [part[2]] = value })
            end
        end
end

local iconNames = {
    ["+ Tab"] = "Plus",
    ["+ Group"] = "Plus",
    ["−"] = "Minimize",
    ["×"] = "Close",
    ["✓"] = "Check",
    ["Move up"] = "Up",
    ["Move down"] = "Down",
    ["Reset view"] = "Reset",
    ["Save file"] = "Save",
    ["Load file"] = "Open",
    ["Keybind"] = "KeyPicker",
    ["Color"] = "ColorPicker",
    ["V"] = "Vortex",
}

local function setSelected(object, selected)
    object:SetAttribute("Selected", selected == true)
    animate(object, {
        BackgroundColor3 = selected and palette.Selected
            or object:GetAttribute("Flat") and palette.Surface
            or palette.Field,
        TextColor3 = selected and palette.Accent or palette.Muted,
        BackgroundTransparency = object:GetAttribute("Quiet") and not selected and 1 or 0,
    })
end

local function button(parent, caption, position, size, callback, accent, iconName, iconOnly)
    iconName = iconName
        or iconNames[caption]
        or ({
                Undo = true,
                Redo = true,
                New = true,
                Open = true,
                Save = true,
                Preview = true,
                Export = true,
                Window = true,
                Properties = true,
                Theme = true,
                Style = true,
                Copy = true,
                Duplicate = true,
                Delete = true,
                Toggle = true,
                Checkbox = true,
                Slider = true,
                Input = true,
                Dropdown = true,
                Button = true,
                Label = true,
                Paragraph = true,
                Image = true,
                Divider = true,
            })[caption]
            and caption
    iconOnly = iconOnly or caption == "−" or caption == "×" or caption == "✓" or caption == "V"
    local object = make("TextButton", {
        Name = caption,
        Text = caption,
        Position = position,
        Size = size,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = accent and palette.Selected or palette.Field,
        TextColor3 = accent and palette.Accent or palette.Muted,
        TextSize = 12,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
    }, parent)
    object:SetAttribute("Selected", accent == true)
    local tooltip
    if iconName then
        object.TextTransparency = 1
        local glyph, tint = icon(
            object,
            iconName,
            iconOnly and UDim2.new(0.5, -8, 0.5, -8) or UDim2.new(0, 9, 0.5, -8),
            object.TextColor3
        )
        if not iconOnly then
            local label = text(object, caption, UDim2.fromOffset(31, 0), UDim2.new(1, -36, 1, 0), object.TextColor3, 11)
            label.Name = "Caption"
            object:GetPropertyChangedSignal("Text"):Connect(function()
                label.Text = object.Text
            end)
            object:GetPropertyChangedSignal("TextColor3"):Connect(function()
                label.TextColor3 = object.TextColor3
            end)
        elseif caption ~= "✓" and caption ~= "V" then
            local hint = caption == "×" and "Close" or caption == "−" and "Minimize" or caption
            tooltip = text(
                object,
                hint,
                UDim2.new(0.5, 0, 1, 7),
                UDim2.fromOffset(math.max(54, #hint * 7 + 18), 25),
                palette.Text,
                11
            )
            tooltip.Name, tooltip.AnchorPoint, tooltip.Visible, tooltip.ZIndex =
                "Tooltip", Vector2.new(0.5, 0), false, 120
            tooltip.BackgroundColor3, tooltip.BackgroundTransparency = palette.Field, 0.02
            tooltip.TextXAlignment = Enum.TextXAlignment.Center
            corner(tooltip, 5)
            outline(tooltip)
        end
        object:GetPropertyChangedSignal("TextColor3"):Connect(function()
            tint(object.TextColor3)
        end)
        glyph.Name = "Icon_" .. iconName
    end
    corner(object, (caption == "−" or caption == "×") and 14 or 6)
    object.MouseEnter:Connect(function()
        animate(object, { BackgroundColor3 = palette.Hover, TextColor3 = palette.Accent, BackgroundTransparency = 0 })
        if tooltip then
            tooltip.Visible = true
        end
    end)
    object.MouseLeave:Connect(function()
        setSelected(object, object:GetAttribute("Selected"))
        if tooltip then
            tooltip.Visible = false
        end
    end)
    object.InputBegan:Connect(function(event)
        if
            event.UserInputType == Enum.UserInputType.MouseButton1
            or event.UserInputType == Enum.UserInputType.Touch
        then
            animate(object, { BackgroundColor3 = palette.Border }, 0.06)
        end
    end)
    object.InputEnded:Connect(function(event)
        if
            event.UserInputType == Enum.UserInputType.MouseButton1
            or event.UserInputType == Enum.UserInputType.Touch
        then
            setSelected(object, object:GetAttribute("Selected"))
        end
    end)
    if callback then
        object.Activated:Connect(callback)
    end
    return object
end

local function input(parent, value, position, size, multiline)
    local object = make("TextBox", {
        Name = "Input",
        Text = tostring(value),
        Position = position,
        Size = size,
        BackgroundColor3 = palette.Field,
        BorderSizePixel = 0,
        TextColor3 = palette.Text,
        PlaceholderColor3 = palette.Muted,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 12,
        ClearTextOnFocus = false,
        MultiLine = multiline == true,
        TextWrapped = multiline == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
    }, parent)
    corner(object, 5)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, multiline and 8 or 0),
        PaddingBottom = UDim.new(0, multiline and 8 or 0),
    }, object)
    return object
end

local function scroll(parent, name, position, size)
    return make("ScrollingFrame", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = palette.Border,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, parent)
end

local function clear(parent)
    cancelTree(parent)
    for _, child in ipairs(parent:GetChildren()) do
        child:Destroy()
    end
end

local function inside(point, object)
    local origin, size = object.AbsolutePosition, object.AbsoluteSize
    return object.Visible
        and point.X >= origin.X
        and point.Y >= origin.Y
        and point.X <= origin.X + size.X
        and point.Y <= origin.Y + size.Y
end

function Designer:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

function Designer:_status(message, failed)
    self.Status.Text = message or ""
    self.Status.TextColor3 = failed and palette.Error or palette.Muted
end

function Designer:_apply(ok, err)
    if not ok then
        self:_status(err, true)
        return false
    end
    self:_status("")
    self.Dirty = true
    self:Render()
    return true
end

function Designer:_change(key, property, value, section)
    local ok, err = self.Model:Update(key, property, value, section)
    if self:_apply(ok, err) then
        return true
    end
    return false
end

function Designer:Select(key)
    if not self.Model:Get(key) then
        return
    end
    self.Model.Selection = key
    self.InspectorMode = "Properties"
    local node, _, _, parent, tab = self.Model:Get(key)
    local selectedTab = node.Kind == "Tab" and node or tab or parent and parent.Kind == "Tab" and parent
    if selectedTab and self.PreviewWindow and not self.PreviewLibrary.Unloaded then
        self.PreviewWindow:SelectTab(selectedTab.Name)
        self.ActiveTab = selectedTab.Key
    end
    self:RenderOutline()
    self:RenderInspector()
    self:_highlight()
end

function Designer:Add(kind)
    self:_apply(self.Model:Add(kind))
end

function Designer:Delete()
    self:_apply(self.Model:Remove(self.Model.Selection))
end

function Designer:Duplicate()
    self:_apply(self.Model:Duplicate(self.Model.Selection))
end

function Designer:Undo()
    if self.Model:Undo() then
        self:_apply(true)
    end
end

function Designer:Redo()
    if self.Model:Redo() then
        self:_apply(true)
    end
end

function Designer:_moveBy(delta)
    local node, list, index = self.Model:Get(self.Model.Selection)
    local target = list and list[index + delta]
    if node and target then
        self:_apply(self.Model:Move(node.Key, target.Key, delta > 0))
    end
end

function Designer:_highlight()
    for key, selection in pairs(self.SelectionOutlines or {}) do
        selection.Enabled = not self.Testing and key == self.Model.Selection
    end
end

function Designer:RenderOutline()
    local oldPosition = self.Tree.CanvasPosition
    clear(self.Tree)
    self.TreeRows = {}
    local y = 0
    local function row(key, caption, depth, kind)
        local selected = key == self.Model.Selection
        local object = button(self.Tree, "", UDim2.fromOffset(8, y), UDim2.new(1, -19, 0, 30), nil)
        object.Name = "Item_" .. key
        object:SetAttribute("Flat", true)
        setSelected(object, selected)
        icon(object, kind, UDim2.fromOffset(8 + depth * 13, 7), selected and palette.Accent or palette.Muted)
        text(
            object,
            caption,
            UDim2.fromOffset(29 + depth * 13, 0),
            UDim2.new(1, -37 - depth * 13, 1, 0),
            selected and palette.Text or palette.Muted
        )
        table.insert(self.TreeRows, { Key = key, Object = object })
        object.Activated:Connect(function()
            if os.clock() >= self.SuppressClickUntil then
                self:Select(key)
            end
        end)
        object.InputBegan:Connect(function(event)
            if
                key ~= "window"
                and (
                    event.UserInputType == Enum.UserInputType.MouseButton1
                    or event.UserInputType == Enum.UserInputType.Touch
                )
            then
                self.Drag = { Key = key, Start = event.Position, Input = event, Active = false }
            end
        end)
        y += 32
    end
    row("window", self.Model.Data.Window.Title ~= "" and self.Model.Data.Window.Title or "Window", 0, "Window")
    for _, tab in ipairs(self.Model.Data.Tabs) do
        row(tab.Key, tab.Name, 0, "Tab")
        for _, group in ipairs(tab.Groups) do
            row(group.Key, group.Name ~= "" and group.Name or "Group", 1, "Group")
            for _, control in ipairs(group.Controls) do
                row(control.Key, control.Text or control.Kind, 2, control.Kind)
            end
        end
    end
    frame(self.Tree, "Extent", UDim2.fromOffset(0, y + 3), UDim2.fromOffset(1, 1), palette.Surface).BackgroundTransparency =
        1
    self.Tree.CanvasPosition = oldPosition
    self.UndoButton.TextColor3 = #self.Model.UndoStack > 0 and palette.Text or palette.Muted
    self.RedoButton.TextColor3 = #self.Model.RedoStack > 0 and palette.Text or palette.Muted
end

function Designer:RenderInspector()
    local oldPosition = self.Properties.CanvasPosition
    clear(self.Properties)
    self.PropertyInputs = {}
    for name, object in pairs(self.InspectorButtons) do
        object:SetAttribute("Flat", true)
        setSelected(object, name == self.InspectorMode)
    end
    local selectedKey = self.Model.Selection
    local node = self.Model:Get(selectedKey)
    local kind = self.Model.Selection == "window" and "Window" or node.Kind
    local fields, values, section
    if self.InspectorMode == "Theme" then
        fields, values, section = {}, self.Model.Data.Theme, "Theme"
        for _, role in ipairs(self.Project.ThemeOrder) do
            table.insert(fields, { Key = role, Label = role, Type = "Color" })
        end
    elseif self.InspectorMode == "Style" then
        fields, values, section = self.Project.StyleFields, self.Model.Data.Style, "Style"
    else
        fields, values = self.Project.GetFields(kind), node
    end
    local y = 8
    text(
        self.Properties,
        self.InspectorMode == "Properties" and kind or self.InspectorMode,
        UDim2.fromOffset(14, y),
        UDim2.new(1, -28, 0, 26),
        palette.Text,
        14
    )
    y += 38
    for _, item in ipairs(fields) do
        local value = values[item.Key]
        if item.Type == "Boolean" then
            local row =
                frame(self.Properties, item.Key, UDim2.fromOffset(14, y), UDim2.new(1, -31, 0, 32), palette.Surface)
            text(row, item.Label, UDim2.fromOffset(0, 0), UDim2.new(1, -45, 1, 0), palette.Muted)
            local toggle = button(
                row,
                value and "✓" or "",
                UDim2.new(1, -31, 0, 5),
                UDim2.fromOffset(25, 23),
                function()
                    self:_change(selectedKey, item.Key, not value, section)
                end,
                value
            )
            outline(toggle)
            self.PropertyInputs[item.Key] = toggle
            y += 38
        else
            text(self.Properties, item.Label, UDim2.fromOffset(14, y), UDim2.new(1, -28, 0, 20), palette.Muted, 11)
            y += 24
            if item.Type == "Choice" then
                local choice = button(
                    self.Properties,
                    tostring(value) .. "  ›",
                    UDim2.fromOffset(14, y),
                    UDim2.new(1, -31, 0, 32),
                    function()
                        local index = table.find(item.Choices, value) or 0
                        self:_change(selectedKey, item.Key, item.Choices[index % #item.Choices + 1], section)
                    end
                )
                self.PropertyInputs[item.Key] = choice
                y += 44
            else
                local multiline = item.Type == "Lines" or item.Type == "Multiline"
                local rendered = item.Type == "Lines" and table.concat(value, "\n")
                    or item.Type == "Color" and "#" .. value
                    or tostring(value)
                local box = input(
                    self.Properties,
                    rendered,
                    UDim2.fromOffset(14, y),
                    UDim2.new(1, -31, 0, multiline and 88 or 32),
                    multiline
                )
                self.PropertyInputs[item.Key] = box
                local border = outline(box)
                if item.Type == "Color" then
                    border.Color = Color3.fromHex(value)
                end
                local restingColor = border.Color
                box.Focused:Connect(function()
                    animate(border, { Color = palette.Muted }, 0.16)
                    animate(box, { BackgroundColor3 = palette.Selected }, 0.16)
                end)
                box.FocusLost:Connect(function()
                    if self.Destroyed then
                        return
                    end
                    local nextValue = box.Text
                    if item.Type == "Number" then
                        nextValue = tonumber(nextValue)
                    elseif item.Type == "Color" then
                        nextValue = nextValue:gsub("^#", ""):upper()
                    elseif item.Type == "Lines" then
                        nextValue = {}
                        for entry in box.Text:gmatch("[^\r\n]+") do
                            entry = entry:match("^%s*(.-)%s*$")
                            if entry ~= "" then
                                table.insert(nextValue, entry)
                            end
                        end
                    end
                    local same = type(nextValue) == "table"
                            and table.concat(nextValue, "\n") == table.concat(value, "\n")
                        or nextValue == value
                    if not same and not self:_change(selectedKey, item.Key, nextValue, section) then
                        box.Text = rendered
                        border.Color = palette.Error
                    elseif same then
                        animate(border, { Color = restingColor }, 0.16)
                        animate(box, { BackgroundColor3 = palette.Field }, 0.16)
                    end
                end)
                y += multiline and 100 or 44
            end
        end
    end
    if self.InspectorMode == "Properties" and self.Model.Selection ~= "window" then
        y += 8
        button(self.Properties, "Duplicate", UDim2.fromOffset(14, y), UDim2.new(0.5, -20, 0, 32), function()
            self:Duplicate()
        end)
        button(self.Properties, "Delete", UDim2.new(0.5, 3, 0, y), UDim2.new(0.5, -20, 0, 32), function()
            self:Delete()
        end)
        y += 46
        button(self.Properties, "Move up", UDim2.fromOffset(14, y), UDim2.new(0.5, -20, 0, 30), function()
            self:_moveBy(-1)
        end)
        button(self.Properties, "Move down", UDim2.new(0.5, 3, 0, y), UDim2.new(0.5, -20, 0, 30), function()
            self:_moveBy(1)
        end)
        y += 42
    end
    frame(self.Properties, "Extent", UDim2.fromOffset(0, y), UDim2.fromOffset(1, 1), palette.Surface).BackgroundTransparency =
        1
    self.Properties.CanvasPosition = oldPosition
end

function Designer:_fitPreview()
    if not self.PreviewWindow or self.PreviewLibrary.Unloaded then
        return
    end
    local size = self.PreviewWindow.Size
    local available = self.Stage.AbsoluteSize / self.Scale.Scale
    local scale = math.max(0.05, math.min(1, (available.X - 50) / size.X, (available.Y - 50) / size.Y))
    self.PreviewWindow.Scale.Scale = scale
    self.PreviewWindow.Frame.Position = UDim2.fromScale(0.5, 0.5)
end

function Designer:_clearPreview()
    if self.PreviewLibrary then
        self.Rebuilding = true
        self.PreviewLibrary:Unload()
        if self.PreviewWindow then
            self.PreviewWindow.Frame:Destroy()
        end
        self.PreviewLibrary, self.PreviewWindow = nil, nil
        self.Rebuilding = false
    end
end

function Designer:RenderPreview()
    self:_clearPreview()
    local library = self.LoadLibrary()
    self.PreviewLibrary = library
    local ok, window, objects = pcall(function()
        return self.Model:Build(library, {
            Parent = self.Gui.Parent,
            ShowLauncher = false,
            Draggable = false,
            Resizable = false,
            ToggleKey = "None",
            DisplayOrder = self.Gui.DisplayOrder - 1,
        })
    end)
    if not ok then
        library:Unload()
        self:_status(tostring(window), true)
        return
    end
    self.PreviewWindow, self.PreviewObjects, self.SelectionOutlines = window, objects, {}
    window.Frame.Parent = self.Stage
    window.Gui.Enabled = false
    window._fit = function()
        self:_fitPreview()
    end
    library:Connect(window.Gui:GetPropertyChangedSignal("AbsoluteSize"), function()
        task.defer(function()
            if not self.Destroyed and self.PreviewWindow == window then
                self:_fitPreview()
            end
        end)
    end)
    library:OnUnload(function()
        if not self.Destroyed and not self.Rebuilding then
            task.defer(function()
                if not self.Destroyed then
                    self:RenderPreview()
                end
            end)
        end
    end)
    local function selectable(key, object, hit)
        self.SelectionOutlines[key] = make("UIStroke", {
            Name = "DesignerSelection",
            Color = palette.Accent,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Enabled = false,
        }, object)
        if hit then
            local overlay = make("TextButton", {
                Name = "DesignerSelect",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 80,
            }, object)
            overlay.Visible = not self.Testing
            overlay.Activated:Connect(function()
                self:Select(key)
            end)
        end
    end
    selectable("window", window.Frame, false)
    local header = window.Frame:FindFirstChild("Header")
    if header then
        local hit = make("TextButton", {
            Name = "DesignerHeader",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 80,
            Visible = not self.Testing,
        }, header)
        hit.Activated:Connect(function()
            self:Select("window")
        end)
    end
    for _, tab in ipairs(self.Model.Data.Tabs) do
        local tabObject = objects[tab.Key]
        tabObject.Button.Activated:Connect(function()
            self:Select(tab.Key)
        end)
        for _, group in ipairs(tab.Groups) do
            local groupObject = objects[group.Key]
            selectable(group.Key, groupObject.Frame, false)
            for _, control in ipairs(group.Controls) do
                selectable(control.Key, objects[control.Key].Frame, true)
            end
        end
    end
    local selected = self.Model:Get(self.Model.Selection)
    local _, _, _, parent, selectedTab = self.Model:Get(self.Model.Selection)
    selectedTab = selected.Kind == "Tab" and selected
        or selectedTab
        or parent and parent.Kind == "Tab" and parent
        or self.Model:Get(self.ActiveTab)
    if selectedTab and selectedTab.Kind == "Tab" then
        window:SelectTab(selectedTab.Name)
        self.ActiveTab = selectedTab.Key
    end
    self:_highlight()
    self:_fitPreview()
    task.defer(function()
        if not self.Destroyed and self.PreviewWindow == window then
            self:_fitPreview()
        end
    end)
end

function Designer:Render()
    self:RenderOutline()
    self:RenderInspector()
    self:RenderPreview()
    self.ProjectTitle.Text = self.Model.Data.Window.Title .. (self.Dirty and "  ·" or "")
end

function Designer:SetTesting(value)
    self.Testing = value == true
    self.TestButton.Text = self.Testing and "Editing" or "Preview"
    setSelected(self.TestButton, self.Testing)
    self:RenderPreview()
end

function Designer:ImportJSON(source)
    if type(source) ~= "string" or #source > 524288 then
        return false, "Project must be smaller than 512 KB"
    end
    local decoded, data = pcall(HttpService.JSONDecode, HttpService, source)
    if not decoded then
        return false, "Invalid project JSON"
    end
    local ok, err = self.Model:Replace(data)
    if ok then
        self.Dirty = false
        self:Render()
    end
    return ok, err
end

function Designer:ExportJSON()
    return HttpService:JSONEncode(self.Model.Data)
end

function Designer:ExportLua(mode)
    return self.Model:Generate(mode)
end

function Designer:_closeModal()
    if self.Modal then
        cancelTree(self.Modal)
        self.Modal:Destroy()
        self.Modal = nil
    end
end

function Designer:_modal(title)
    self:_closeModal()
    local overlay = make("TextButton", {
        Name = "Modal",
        Text = "",
        AutoButtonColor = false,
        Modal = true,
        Active = true,
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.25,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 100,
    }, self.Root)
    local panel =
        frame(overlay, "Panel", UDim2.new(0.5, 0, 0.5, 12), UDim2.fromOffset(780, 570), palette.Surface, "CanvasGroup")
    panel.GroupTransparency = 1
    panel.AnchorPoint, panel.ZIndex = Vector2.new(0.5, 0.5), 101
    corner(panel, 10)
    outline(panel)
    text(panel, title, UDim2.fromOffset(20, 12), UDim2.new(1, -80, 0, 32), palette.Text, 16)
    button(panel, "×", UDim2.new(1, -46, 0, 14), UDim2.fromOffset(28, 28), function()
        self:_closeModal()
    end)
    self.Modal = overlay
    overlay.BackgroundTransparency = 1
    animate(overlay, { BackgroundTransparency = 0.35 }, 0.18)
    animate(panel, { Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0 }, 0.18)
    return panel
end

function Designer:_filename(extension)
    local title = self.Model.Data.Window.Title:lower():gsub("[^%w_-]", "-"):sub(1, 64)
    return (title ~= "" and title or "menu") .. extension
end

function Designer:_saveFile(filename, contents)
    if type(writefile) ~= "function" or type(makefolder) ~= "function" then
        return false, "File access unavailable; use Copy"
    end
    local ok, err = pcall(function()
        if type(isfolder) ~= "function" or not isfolder("VortexUI") then
            makefolder("VortexUI")
        end
        if type(isfolder) ~= "function" or not isfolder("VortexUI/Designer") then
            makefolder("VortexUI/Designer")
        end
        writefile("VortexUI/Designer/" .. filename, contents)
    end)
    return ok, ok and "Saved to VortexUI/Designer/" .. filename or tostring(err)
end

function Designer:ShowExport(initialMode)
    local panel = self:_modal("Export")
    local mode = initialMode or "Lua"
    local output = input(panel, "", UDim2.fromOffset(20, 100), UDim2.new(1, -40, 1, -170), true)
    output.Font, output.TextSize, output.TextWrapped = Enum.Font.Code, 13, false
    output.TextEditable = false
    output.AutomaticSize = Enum.AutomaticSize.None
    local scroller = scroll(panel, "Code", output.Position, output.Size)
    scroller.ScrollingDirection, scroller.AutomaticCanvasSize = Enum.ScrollingDirection.XY, Enum.AutomaticSize.XY
    output.Parent, output.Position = scroller, UDim2.fromOffset(0, 0)
    output.Size, output.AutomaticSize = UDim2.new(1, -8, 1, -8), Enum.AutomaticSize.XY
    local note = text(panel, "", UDim2.new(0, 20, 1, -57), UDim2.new(1, -246, 0, 32), palette.Muted, 11)
    local modes = {}
    local function update()
        output.Text = mode == "Project" and self:ExportJSON() or self:ExportLua(mode)
        note.Text = self:_filename(mode == "Project" and ".vortex.json" or ".lua")
        for name, object in pairs(modes) do
            object.TextColor3 = name == mode and palette.Accent or palette.Muted
            object.BackgroundColor3 = name == mode and palette.Selected or palette.Field
        end
    end
    for index, name in ipairs({ "Lua", "Studio", "Project" }) do
        modes[name] = button(
            panel,
            name,
            UDim2.fromOffset(20 + (index - 1) * 108, 56),
            UDim2.fromOffset(100, 30),
            function()
                mode = name
                update()
            end
        )
    end
    button(panel, "Copy", UDim2.new(1, -220, 1, -56), UDim2.fromOffset(92, 32), function()
        local copy = type(setclipboard) == "function" and setclipboard
            or type(toclipboard) == "function" and toclipboard
        if copy then
            local ok = pcall(copy, output.Text)
            note.Text = ok and "Copied" or "Copy failed"
        else
            output:CaptureFocus()
            output.SelectionStart, output.CursorPosition = 1, #output.Text + 1
            note.Text = "Press Ctrl+C"
        end
    end)
    button(panel, "Save file", UDim2.new(1, -118, 1, -56), UDim2.fromOffset(98, 32), function()
        local ok, message = self:_saveFile(self:_filename(mode == "Project" and ".vortex.json" or ".lua"), output.Text)
        note.Text, note.TextColor3 = message, ok and palette.Muted or palette.Error
        if ok and mode == "Project" then
            self.Dirty = false
            self.ProjectTitle.Text = self.Model.Data.Window.Title
        end
    end, true)
    update()
end

function Designer:ShowImport()
    local panel = self:_modal("Open project")
    local filename = input(panel, self:_filename(".vortex.json"), UDim2.fromOffset(20, 58), UDim2.new(1, -158, 0, 32))
    local source = input(panel, "", UDim2.fromOffset(20, 104), UDim2.new(1, -40, 1, -178), true)
    source.PlaceholderText, source.Font = "Paste project JSON", Enum.Font.Code
    local note = text(panel, "", UDim2.new(0, 20, 1, -57), UDim2.new(1, -160, 0, 32), palette.Muted, 11)
    button(panel, "Load file", UDim2.new(1, -128, 0, 58), UDim2.fromOffset(108, 32), function()
        if type(readfile) ~= "function" then
            note.Text = "File access unavailable; paste JSON"
            return
        end
        local name = filename.Text
        if not name:match("^[%w_-]+%.vortex%.json$") then
            note.Text = "Use a .vortex.json filename"
            return
        end
        local ok, contents = pcall(readfile, "VortexUI/Designer/" .. name)
        if ok then
            source.Text = contents
        else
            note.Text = "File not found"
        end
    end)
    button(panel, "Open", UDim2.new(1, -128, 1, -56), UDim2.fromOffset(108, 32), function()
        local ok, err = self:ImportJSON(source.Text)
        if ok then
            self:_closeModal()
            self:_status("")
        else
            note.Text, note.TextColor3 = err, palette.Error
        end
    end, true)
end

function Designer:_confirm(title, callback)
    local panel = self:_modal(title)
    panel.Size = UDim2.fromOffset(380, 170)
    text(panel, "Discard unsaved changes?", UDim2.fromOffset(20, 58), UDim2.new(1, -40, 0, 24), palette.Muted)
    button(panel, "Cancel", UDim2.new(1, -214, 1, -52), UDim2.fromOffset(92, 32), function()
        self:_closeModal()
    end)
    button(panel, "Discard", UDim2.new(1, -112, 1, -52), UDim2.fromOffset(92, 32), function()
        self:_closeModal()
        callback()
    end, true)
end

function Designer:New()
    local function reset()
        self.Model:Replace(self.Project.new().Data)
        self.Dirty, self.ActiveTab = false, nil
        self:Render()
    end
    if self.Dirty then
        self:_confirm("New project", reset)
    else
        reset()
    end
end

function Designer:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.WindowDrag = nil
    cancelTree(self.Gui)
    self:_clearPreview()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    self.Gui:Destroy()
end

function Designer:Close()
    local function dismiss()
        if self.Closing then
            return
        end
        self.Closing, self.WindowDrag = true, nil
        animate(self.Root, { GroupTransparency = 1 }, 0.12)
        task.delay(0.12, function()
            if not self.Destroyed then
                self:Destroy()
            end
        end)
    end
    if self.Dirty then
        self:_confirm("Close designer", function()
            dismiss()
        end)
    else
        dismiss()
    end
end

function Designer:_clampPosition(value)
    local viewport = self.Gui.AbsoluteSize
    local half = Vector2.new(640 * self.Scale.Scale, 380 * self.Scale.Scale)
    local minX, minY = math.min(half.X + 8, viewport.X / 2), math.min(half.Y + 8, viewport.Y / 2)
    return UDim2.fromOffset(
        math.clamp(value.X, minX, math.max(minX, viewport.X - half.X - 8)),
        math.clamp(value.Y, minY, math.max(minY, viewport.Y - half.Y - 8))
    )
end

function Designer:_beginWindowDrag(event)
    if self.Modal or self.Closing or self.WindowDrag or not self.Root.Visible then
        return
    end
    if event.UserInputType ~= Enum.UserInputType.MouseButton1 and event.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    cancelMotion(self.Root, "Position")
    local position, viewport = self.Root.Position, self.Gui.AbsoluteSize
    self.WindowDrag = {
        Input = event,
        Start = Vector2.new(event.Position.X, event.Position.Y),
        Center = Vector2.new(
            position.X.Scale * viewport.X + position.X.Offset,
            position.Y.Scale * viewport.Y + position.Y.Offset
        ),
    }
end

function Designer:_moveWindowDrag(event)
    local drag = self.WindowDrag
    if not drag then
        return
    end
    if
        event ~= drag.Input
        and not (
            drag.Input.UserInputType == Enum.UserInputType.MouseButton1
            and event.UserInputType == Enum.UserInputType.MouseMovement
        )
    then
        return
    end
    local delta = Vector2.new(event.Position.X, event.Position.Y) - drag.Start
    animate(self.Root, { Position = self:_clampPosition(drag.Center + delta) }, 0.06)
end

function Designer:Minimize()
    if self.Closing or not self.Root.Visible then
        return
    end
    self.VisibilityToken += 1
    local token = self.VisibilityToken
    self.WindowDrag = nil
    cancelMotion(self.Root, "Position")
    self.HiddenPosition = self.Root.Position
    animate(self.Root, { GroupTransparency = 1 }, 0.12)
    task.delay(0.12, function()
        if not self.Destroyed and token == self.VisibilityToken then
            self.Root.Visible, self.Restore.Visible = false, true
        end
    end)
end

function Designer:RestoreWindow()
    if self.Destroyed or self.Closing then
        return
    end
    self.VisibilityToken += 1
    local saved, viewport = self.HiddenPosition or self.Root.Position, self.Gui.AbsoluteSize
    local position = self:_clampPosition(
        Vector2.new(saved.X.Scale * viewport.X + saved.X.Offset, saved.Y.Scale * viewport.Y + saved.Y.Offset)
    )
    self.Root.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + 10)
    self.Root.Visible, self.Restore.Visible = true, false
    animate(self.Root, { GroupTransparency = 0, Position = position }, 0.18)
end

function Designer:_buildUI(parent)
    self.Gui = make("ScreenGui", {
        Name = "VortexDesigner",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 11000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if parent then
        self.Gui.Parent = parent
    else
        local ok = pcall(function()
            self.Gui.Parent = type(gethui) == "function" and gethui() or game:GetService("CoreGui")
        end)
        if not ok then
            self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end
    self.Root = frame(
        self.Gui,
        "Designer",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(1280, 760),
        palette.Background,
        "CanvasGroup"
    )
    self.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Root.GroupTransparency = 1
    corner(self.Root, 10)
    outline(self.Root)
    self.Scale = make("UIScale", { Scale = 1 }, self.Root)
    local function fit()
        local size = self.Gui.AbsoluteSize
        self.Scale.Scale = math.max(0.1, math.min(1, (size.X - 24) / 1280, (size.Y - 24) / 760))
        if self.Root.Position.X.Scale == 0 and self.Root.Position.Y.Scale == 0 then
            self.Root.Position =
                self:_clampPosition(Vector2.new(self.Root.Position.X.Offset, self.Root.Position.Y.Offset))
        end
        self:_fitPreview()
    end
    self:_connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
    fit()
    local header = frame(self.Root, "Header", UDim2.new(), UDim2.new(1, 0, 0, 56), palette.Background)
    header.ZIndex = 5
    self.DragHandle = make("TextButton", {
        Name = "DragHandle",
        Text = "",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -532, 1, 0),
        Active = true,
    }, header)
    self.DragHandle.InputBegan:Connect(function(event)
        self:_beginWindowDrag(event)
    end)
    icon(header, "Vortex", UDim2.fromOffset(22, 20), palette.Accent)
    local brand = text(header, "vortex", UDim2.fromOffset(50, 10), UDim2.fromOffset(78, 34), palette.Text, 20)
    brand.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
    text(header, "designer", UDim2.fromOffset(132, 12), UDim2.fromOffset(76, 32), palette.Muted, 11)
    self.ProjectTitle = text(header, "", UDim2.fromOffset(234, 12), UDim2.fromOffset(390, 32), palette.Muted, 11)
    self.UndoButton = button(header, "Undo", UDim2.new(1, -520, 0, 13), UDim2.fromOffset(32, 30), function()
        self:Undo()
    end, false, "Undo", true)
    self.RedoButton = button(header, "Redo", UDim2.new(1, -480, 0, 13), UDim2.fromOffset(32, 30), function()
        self:Redo()
    end, false, "Redo", true)
    frame(header, "ToolbarDivider", UDim2.new(1, -434, 0, 20), UDim2.fromOffset(1, 16), palette.Border)
    button(header, "New", UDim2.new(1, -418, 0, 13), UDim2.fromOffset(32, 30), function()
        self:New()
    end, false, "New", true)
    button(header, "Open", UDim2.new(1, -378, 0, 13), UDim2.fromOffset(32, 30), function()
        if self.Dirty then
            self:_confirm("Open project", function()
                self:ShowImport()
            end)
        else
            self:ShowImport()
        end
    end, false, "Open", true)
    button(header, "Save", UDim2.new(1, -338, 0, 13), UDim2.fromOffset(32, 30), function()
        self:ShowExport("Project")
    end, false, "Save", true)
    self.TestButton = button(header, "Preview", UDim2.new(1, -294, 0, 13), UDim2.fromOffset(90, 30), function()
        self:SetTesting(not self.Testing)
    end)
    button(header, "Export", UDim2.new(1, -196, 0, 13), UDim2.fromOffset(94, 30), function()
        self:ShowExport()
    end, true)
    button(header, "−", UDim2.new(1, -88, 0, 13), UDim2.fromOffset(28, 30), function()
        self:Minimize()
    end)
    button(header, "×", UDim2.new(1, -50, 0, 13), UDim2.fromOffset(28, 30), function()
        self:Close()
    end)
    for _, child in ipairs(header:GetChildren()) do
        if
            child:IsA("TextButton")
            and child ~= self.DragHandle
            and child ~= self.TestButton
            and child.Name ~= "Export"
        then
            child:SetAttribute("Flat", true)
            child:SetAttribute("Quiet", true)
            setSelected(child, false)
        end
    end
    frame(self.Root, "Divider", UDim2.fromOffset(12, 55), UDim2.new(1, -24, 0, 1), palette.Border)
    local left = frame(self.Root, "Outline", UDim2.fromOffset(12, 68), UDim2.new(0, 214, 1, -108))
    corner(left, 8)
    text(left, "Outline", UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 30), palette.Muted, 11)
    button(left, "+ Tab", UDim2.fromOffset(12, 42), UDim2.fromOffset(90, 29), function()
        self:Add("Tab")
    end)
    button(left, "+ Group", UDim2.fromOffset(110, 42), UDim2.fromOffset(92, 29), function()
        self:Add("Group")
    end)
    self.Tree = scroll(left, "Tree", UDim2.fromOffset(0, 82), UDim2.new(1, 0, 1, -360))
    local insert = frame(left, "Insert", UDim2.new(0, 0, 1, -270), UDim2.new(1, 0, 0, 270))
    text(insert, "Insert", UDim2.fromOffset(14, 0), UDim2.new(1, -28, 0, 30), palette.Muted, 11)
    local labels = { KeyPicker = "Keybind", ColorPicker = "Color" }
    for index, kind in ipairs(self.Project.Kinds) do
        local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
        button(
            insert,
            labels[kind] or kind,
            UDim2.fromOffset(12 + column * 98, 36 + row * 37),
            UDim2.fromOffset(90, 29),
            function()
                self:Add(kind)
            end
        )
    end
    local center =
        frame(self.Root, "Canvas", UDim2.fromOffset(238, 68), UDim2.new(1, -524, 1, -108), palette.Background)
    text(center, "Canvas", UDim2.fromOffset(12, 1), UDim2.new(1, -220, 0, 30), palette.Muted, 11)
    button(center, "Window", UDim2.new(1, -175, 0, 0), UDim2.fromOffset(76, 28), function()
        self:Select("window")
    end)
    button(center, "Reset view", UDim2.new(1, -91, 0, 0), UDim2.fromOffset(86, 28), function()
        self:RenderPreview()
    end)
    self.Stage = frame(center, "Stage", UDim2.fromOffset(0, 40), UDim2.new(1, 0, 1, -40), Color3.fromRGB(11, 11, 11))
    self.Stage.ClipsDescendants = true
    corner(self.Stage, 8)
    outline(self.Stage, Color3.fromRGB(27, 27, 27))
    self:_connect(self.Stage:GetPropertyChangedSignal("AbsoluteSize"), function()
        self:_fitPreview()
    end)
    local right = frame(self.Root, "Inspector", UDim2.new(1, -274, 0, 68), UDim2.new(0, 262, 1, -108))
    corner(right, 8)
    self.InspectorButtons = {}
    for index, name in ipairs({ "Properties", "Theme", "Style" }) do
        self.InspectorButtons[name] = button(
            right,
            name,
            UDim2.fromOffset(({ 10, 112, 186 })[index], 10),
            UDim2.fromOffset(({ 98, 70, 66 })[index], 30),
            function()
                self.InspectorMode = name
                self:RenderInspector()
            end
        )
    end
    self.Properties = scroll(right, "Properties", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 1, -50))
    self.Status = text(self.Root, "", UDim2.new(0, 20, 1, -32), UDim2.new(1, -380, 0, 24), palette.Muted, 11)
    self.Restore = button(self.Gui, "V", UDim2.fromOffset(22, 104), UDim2.fromOffset(48, 48), function()
        self:RestoreWindow()
    end, true)
    self.Restore.Visible = false
    self.Restore.TextSize = 24
    self.DragLabel = text(self.Root, "", UDim2.new(), UDim2.fromOffset(180, 30), palette.Accent)
    self.DragLabel.BackgroundColor3, self.DragLabel.BackgroundTransparency = palette.Selected, 0.05
    self.DragLabel.Visible, self.DragLabel.ZIndex = false, 90
    corner(self.DragLabel, 5)
    self:_connect(UIS.InputChanged, function(event)
        self:_moveWindowDrag(event)
        local drag = self.Drag
        if
            not drag
            or not (
                event == drag.Input
                or event.UserInputType == Enum.UserInputType.MouseMovement
                    and drag.Input.UserInputType == Enum.UserInputType.MouseButton1
            )
        then
            return
        end
        if
            (Vector2.new(event.Position.X, event.Position.Y) - Vector2.new(drag.Start.X, drag.Start.Y)).Magnitude > 7
        then
            drag.Active = true
        end
        if drag.Active then
            drag.Position = event.Position
            local node = self.Model:Get(drag.Key)
            self.DragLabel.Visible, self.DragLabel.Text = true, "  " .. (node.Text or node.Name or node.Kind)
            self.DragLabel.Position = UDim2.fromOffset(
                (event.Position.X - self.Root.AbsolutePosition.X) / self.Scale.Scale + 12,
                (event.Position.Y - self.Root.AbsolutePosition.Y) / self.Scale.Scale + 12
            )
            for _, row in ipairs(self.TreeRows) do
                row.Object.BackgroundColor3 = inside(event.Position, row.Object)
                        and row.Key ~= drag.Key
                        and palette.Selected
                    or row.Key == self.Model.Selection and palette.Selected
                    or palette.Surface
            end
            if inside(event.Position, self.Tree) then
                local position, size = self.Tree.AbsolutePosition, self.Tree.AbsoluteSize
                local delta = event.Position.Y < position.Y + 30 and -10
                    or event.Position.Y > position.Y + size.Y - 30 and 10
                    or 0
                self.Tree.CanvasPosition = Vector2.new(
                    0,
                    math.clamp(
                        self.Tree.CanvasPosition.Y + delta,
                        0,
                        math.max(0, self.Tree.AbsoluteCanvasSize.Y - size.Y)
                    )
                )
            end
        end
    end)
    self:_connect(UIS.InputEnded, function(event)
        local windowDrag = self.WindowDrag
        if
            windowDrag
            and (
                event == windowDrag.Input
                or event.UserInputType == Enum.UserInputType.MouseButton1
                    and windowDrag.Input.UserInputType == Enum.UserInputType.MouseButton1
            )
        then
            self.WindowDrag = nil
        end
        local drag = self.Drag
        if
            not drag
            or not (
                event == drag.Input
                or event.UserInputType == Enum.UserInputType.MouseButton1
                    and drag.Input.UserInputType == Enum.UserInputType.MouseButton1
            )
        then
            return
        end
        self.Drag, self.DragLabel.Visible = nil, false
        if drag.Active then
            self.SuppressClickUntil = os.clock() + 0.3
            local point = drag.Position or event.Position
            if inside(point, self.Tree) then
                for _, row in ipairs(self.TreeRows) do
                    if row.Key ~= drag.Key and inside(point, row.Object) then
                        self:_apply(
                            self.Model:Move(
                                drag.Key,
                                row.Key,
                                point.Y > row.Object.AbsolutePosition.Y + row.Object.AbsoluteSize.Y / 2
                            )
                        )
                        return
                    end
                end
            end
            self:RenderOutline()
        end
    end)
    self:_connect(UIS.InputBegan, function(event, processed)
        if processed or not self.Root.Visible or UIS:GetFocusedTextBox() then
            return
        end
        if self.Modal then
            if event.KeyCode == Enum.KeyCode.Escape then
                self:_closeModal()
            end
            return
        end
        local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
        local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        if ctrl and event.KeyCode == Enum.KeyCode.Z then
            if shift then
                self:Redo()
            else
                self:Undo()
            end
        elseif ctrl and event.KeyCode == Enum.KeyCode.Y then
            self:Redo()
        elseif ctrl and event.KeyCode == Enum.KeyCode.D then
            self:Duplicate()
        elseif ctrl and event.KeyCode == Enum.KeyCode.S then
            self:ShowExport("Project")
        elseif event.KeyCode == Enum.KeyCode.Delete then
            self:Delete()
        end
    end)
end

function Designer:Create(options)
    options = options or {}
    local repo = "https://raw.githubusercontent.com/imshrak/vortex/main/"
    local project = options.ProjectModule
    if not project then
        project = loadstring(game:HttpGet(repo .. "designer/Project.lua"))()
    end
    local factory = options.LoadLibrary
    if not factory then
        local source = game:HttpGet(repo .. "Library.lua")
        factory = function()
            return loadstring(source)()
        end
    end
    local self = setmetatable({
        Project = project,
        Model = project.new(options.Data),
        LoadLibrary = factory,
        Connections = {},
        InspectorMode = "Properties",
        Testing = false,
        Dirty = false,
        VisibilityToken = 0,
        SuppressClickUntil = 0,
    }, Designer)
    local ok, err = pcall(function()
        self:_buildUI(options.Parent)
        self:Render()
        local position = self.Root.Position
        self.Root.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + 10)
        animate(self.Root, { GroupTransparency = 0, Position = position }, 0.22)
    end)
    if not ok then
        self.Destroyed = true
        self:_clearPreview()
        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end
        if self.Gui then
            self.Gui:Destroy()
        end
        error(err, 2)
    end
    return self
end

return Designer
