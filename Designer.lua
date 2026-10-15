local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Designer = {}
Designer.__index = Designer
Designer.Version = "1.0.0"

local palette = {
    Background = Color3.fromRGB(15, 16, 19),
    Surface = Color3.fromRGB(22, 23, 27),
    Field = Color3.fromRGB(30, 31, 37),
    Border = Color3.fromRGB(47, 49, 57),
    Text = Color3.fromRGB(230, 231, 237),
    Muted = Color3.fromRGB(135, 139, 153),
    Accent = Color3.fromRGB(159, 149, 255),
    Selected = Color3.fromRGB(48, 43, 73),
    Error = Color3.fromRGB(238, 147, 153),
}

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

local function frame(parent, name, position, size, color)
    return make("Frame", {
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
        Font = Enum.Font.Gotham,
        TextSize = fontSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function button(parent, caption, position, size, callback, accent)
    local object = make("TextButton", {
        Name = caption,
        Text = caption,
        Position = position,
        Size = size,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = accent and palette.Selected or palette.Field,
        TextColor3 = accent and palette.Accent or palette.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    }, parent)
    corner(object, 6)
    object.MouseEnter:Connect(function()
        object.BackgroundColor3 = palette.Selected
    end)
    object.MouseLeave:Connect(function()
        object.BackgroundColor3 = accent and palette.Selected or palette.Field
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
        Font = Enum.Font.Gotham,
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
        object.BackgroundColor3 = selected and palette.Selected or palette.Surface
        object.MouseLeave:Connect(function()
            object.BackgroundColor3 = key == self.Model.Selection and palette.Selected or palette.Surface
        end)
        local marker = kind == "Window" and "◈" or kind == "Tab" and "▤" or kind == "Group" and "▢" or "·"
        text(
            object,
            marker,
            UDim2.fromOffset(8 + depth * 13, 0),
            UDim2.fromOffset(19, 30),
            selected and palette.Accent or palette.Muted,
            14
        )
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
        object.TextColor3 = name == self.InspectorMode and palette.Accent or palette.Muted
        object.BackgroundColor3 = name == self.InspectorMode and palette.Selected or palette.Surface
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
    local size, available = self.PreviewWindow.Size, self.Stage.AbsoluteSize
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
    self.TestButton.BackgroundColor3 = self.Testing and palette.Selected or palette.Field
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
    local panel = frame(overlay, "Panel", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(780, 570), palette.Surface)
    panel.AnchorPoint, panel.ZIndex = Vector2.new(0.5, 0.5), 101
    corner(panel, 10)
    outline(panel)
    text(panel, title, UDim2.fromOffset(20, 12), UDim2.new(1, -80, 0, 32), palette.Text, 16)
    button(panel, "×", UDim2.new(1, -46, 0, 14), UDim2.fromOffset(28, 28), function()
        self:_closeModal()
    end)
    self.Modal = overlay
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
    self:_clearPreview()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    self.Gui:Destroy()
end

function Designer:Close()
    if self.Dirty then
        self:_confirm("Close designer", function()
            self:Destroy()
        end)
    else
        self:Destroy()
    end
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
    self.Root = frame(self.Gui, "Designer", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(1280, 760), palette.Background)
    self.Root.AnchorPoint = Vector2.new(0.5, 0.5)
    corner(self.Root, 12)
    outline(self.Root)
    self.Scale = make("UIScale", { Scale = 1 }, self.Root)
    local function fit()
        local size = self.Gui.AbsoluteSize
        self.Scale.Scale = math.max(0.1, math.min(1, (size.X - 24) / 1280, (size.Y - 24) / 760))
    end
    self:_connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
    fit()
    local header = frame(self.Root, "Header", UDim2.new(), UDim2.new(1, 0, 0, 56), palette.Background)
    text(header, "V", UDim2.fromOffset(20, 13), UDim2.fromOffset(24, 30), palette.Accent, 24).Font =
        Enum.Font.GothamBold
    text(header, "Vortex Designer", UDim2.fromOffset(54, 12), UDim2.fromOffset(164, 32), palette.Text, 16)
    self.ProjectTitle = text(header, "", UDim2.fromOffset(232, 12), UDim2.fromOffset(310, 32), palette.Muted)
    self.UndoButton = button(header, "Undo", UDim2.new(1, -666, 0, 13), UDim2.fromOffset(62, 30), function()
        self:Undo()
    end)
    self.RedoButton = button(header, "Redo", UDim2.new(1, -596, 0, 13), UDim2.fromOffset(62, 30), function()
        self:Redo()
    end)
    button(header, "New", UDim2.new(1, -514, 0, 13), UDim2.fromOffset(58, 30), function()
        self:New()
    end)
    button(header, "Open", UDim2.new(1, -448, 0, 13), UDim2.fromOffset(62, 30), function()
        if self.Dirty then
            self:_confirm("Open project", function()
                self:ShowImport()
            end)
        else
            self:ShowImport()
        end
    end)
    button(header, "Save", UDim2.new(1, -378, 0, 13), UDim2.fromOffset(62, 30), function()
        self:ShowExport("Project")
    end)
    self.TestButton = button(header, "Preview", UDim2.new(1, -296, 0, 13), UDim2.fromOffset(84, 30), function()
        self:SetTesting(not self.Testing)
    end)
    button(header, "Export", UDim2.new(1, -204, 0, 13), UDim2.fromOffset(84, 30), function()
        self:ShowExport()
    end, true)
    button(header, "−", UDim2.new(1, -92, 0, 13), UDim2.fromOffset(30, 30), function()
        self.Root.Visible = false
        self.Restore.Visible = true
    end)
    button(header, "×", UDim2.new(1, -54, 0, 13), UDim2.fromOffset(30, 30), function()
        self:Close()
    end)
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
    self.Stage = frame(center, "Stage", UDim2.fromOffset(0, 40), UDim2.new(1, 0, 1, -40), Color3.fromRGB(18, 19, 23))
    self.Stage.ClipsDescendants = true
    corner(self.Stage, 8)
    for x = 24, 750, 24 do
        for y = 24, 600, 24 do
            local dot = frame(self.Stage, "Dot", UDim2.fromOffset(x, y), UDim2.fromOffset(1, 1), palette.Border)
            dot.BackgroundTransparency = 0.5
        end
    end
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
            UDim2.fromOffset(10 + (index - 1) * 82, 10),
            UDim2.fromOffset(78, 30),
            function()
                self.InspectorMode = name
                self:RenderInspector()
            end
        )
    end
    self.Properties = scroll(right, "Properties", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 1, -50))
    self.Status = text(self.Root, "", UDim2.new(0, 20, 1, -32), UDim2.new(1, -380, 0, 24), palette.Muted, 11)
    text(
        self.Root,
        "Ctrl+Z   Undo      Ctrl+Shift+Z   Redo",
        UDim2.new(1, -296, 1, -32),
        UDim2.fromOffset(276, 24),
        palette.Muted,
        10
    )
    self.Restore = button(self.Gui, "V", UDim2.fromOffset(22, 104), UDim2.fromOffset(48, 48), function()
        self.Root.Visible, self.Restore.Visible = true, false
    end, true)
    self.Restore.Visible = false
    self.Restore.TextSize = 24
    self.DragLabel = text(self.Root, "", UDim2.new(), UDim2.fromOffset(180, 30), palette.Accent)
    self.DragLabel.BackgroundColor3, self.DragLabel.BackgroundTransparency = palette.Selected, 0.05
    self.DragLabel.Visible, self.DragLabel.ZIndex = false, 90
    corner(self.DragLabel, 5)
    self:_connect(UIS.InputChanged, function(event)
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
        SuppressClickUntil = 0,
    }, Designer)
    local ok, err = pcall(function()
        self:_buildUI(options.Parent)
        self:Render()
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
