local function verifyCustomization(Library, Window, SaveManager, ThemeManager)
    local checks = 0
    local function expect(value, message)
        checks += 1
        assert(value, message)
    end
    local function rejects(callback, message)
        expect(not pcall(callback), message)
    end
    local test = Window:AddTab({ Name = "Customization", Icon = "grid", Width = 128 })
    local hidden = Window:AddTab({ Name = "Hidden", Visible = false })
    expect(
        not hidden.Button.Visible and test.Button.Size.X.Offset == 128,
        "Tab options should control width and visibility"
    )
    test:SetName("Advanced"):SetWidth(120):Select()
    expect(
        Window.SelectedTab == "Advanced" and Window.Tabs.Advanced == test and not Window.Tabs.Customization,
        "Renaming a selected tab must keep its identity consistent"
    )
    test.Button.Activated:Fire()
    expect(Window.SelectedTab == "Advanced", "Renamed tab buttons must still select the tab")
    test:SetVisible(false)
    expect(
        Window.SelectedTab == "Main" and not test.Frame.Visible,
        "Hiding a selected tab should choose another visible tab"
    )
    test:SetVisible(true)

    local group = test:AddGroupbox({
        Name = "Advanced",
        ShowTitle = true,
        Description = "Customize controls",
        Collapsible = true,
        MinHeight = 42,
    })
    local toggle =
        group:AddToggle("CustomEnabled", { Text = "Enabled", Default = false, Tooltip = "Enable the controls" })
    local checkbox = group:AddCheckbox("CustomCheckbox", { Text = "Checkbox", Default = true })
    expect(
        checkbox.Type == "Toggle" and checkbox.Kind == "Checkbox",
        "Checkboxes should share toggle configuration semantics"
    )
    checkbox:SetValue(false)
    checkbox:Reset(true)
    expect(checkbox.Value, "Reset should restore the initial checkbox value")
    local dependent = group:AddInput("CustomInput", { Text = "Dependent", Default = "ready", Width = 160 })
    dependent:DependsOn({ { toggle, true } })
    expect(not dependent.Frame.Visible, "Unmet dependencies should hide a row")
    toggle:SetValue(true, true)
    expect(dependent.Frame.Visible, "Silent source changes must refresh dependent visibility")
    dependent:SetVisible(false)
    toggle:SetValue(false, true)
    toggle:SetValue(true, true)
    expect(not dependent.Frame.Visible, "Dependencies must preserve manual visibility")
    dependent:SetVisible(true):DependsOn({ { toggle, true } }, "Disabled")
    toggle:SetValue(false, true)
    expect(
        dependent.Frame.Visible and dependent.Disabled and not dependent.Box.TextEditable,
        "Disabled dependencies should preserve layout and prevent editing"
    )
    dependent:DependsOn({})
    expect(not dependent.Disabled, "Clearing dependencies should restore normal state")
    local before = #toggle._observers
    dependent:DependsOn({ { toggle, true } })
    dependent:Destroy()
    expect(
        not Library.Options.CustomInput and #toggle._observers == before,
        "Destroy should unregister a control and its dependency subscriptions"
    )

    local slider = group:AddSlider(
        "CustomSlider",
        { Text = "Stepped", Min = 0, Max = 10, Step = 0.25, Rounding = 2, Suffix = "x", Default = 1.5 }
    )
    slider:SetValue(1.62)
    expect(slider.Value == 1.5 and slider.Box.Text == "1.5x", "Sliders should quantize steps and show a suffix")
    slider:SetValue(1.9)
    expect(slider.Value == 2, "Stepped sliders should choose the nearest step")
    slider:SetRange(0, 1):SetSuffix(" units")
    expect(slider.Value == 1 and slider.Box.Text == "1 units", "Changing range should clamp and update the display")
    slider.Box.Text = "0.5 units"
    slider.Box.FocusLost:Fire()
    expect(slider.Value == 0.5, "Numeric entry should accept the configured suffix")
    local inferred = group:AddSlider("CustomInferred", { Min = 0, Max = 2, Step = 0.25, Default = 1.75 })
    expect(inferred.Value == 1.75 and inferred.Rounding == 2, "Fractional steps should infer decimal precision")
    rejects(function()
        group:AddSlider("BadStep", { Step = 0 })
    end, "Zero slider steps must be rejected")

    local input = group:AddInput("CustomValidated", {
        Text = "Validated",
        Default = "okay",
        Validator = function(value)
            return #value >= 3
        end,
        Multiline = true,
    })
    expect(not input:SetValue("x") and input.Value == "okay", "Input validators must reject invalid assignments")
    input:SetPlaceholder("Write a note")
    local boundedNumber = group:AddInput("CustomBoundedNumber", { Numeric = true, MaxLength = 1, Default = "1" })
    expect(
        not boundedNumber:SetValue("-2") and boundedNumber.Value == "1",
        "Length limits must not produce an invalid numeric value"
    )
    expect(
        input.Box.MultiLine
            and input.Box.PlaceholderText == "Write a note"
            and input.Frame:GetAttribute("BaseHeight") == 104,
        "Multiline options must configure the full-width editor"
    )

    local dictionary = group:AddDropdown("CustomDictionary", {
        Text = "Quality",
        Values = { low = "Low quality", high = "High quality" },
        Default = "low",
        AllowNull = false,
        DisabledValues = { "high" },
        Searchable = true,
        FormatDisplayValue = function(_, label)
            return label:upper()
        end,
    })
    expect(
        dictionary.Value == "low" and dictionary.Label.Text:find("LOW QUALITY", 1, true),
        "Dictionary choices should preserve IDs while formatting labels"
    )
    expect(not dictionary:SetValue(nil), "Required dropdowns should reject nil")
    local requiredMulti =
        group:AddDropdown("CustomRequiredMulti", { Values = { "A", "B" }, Multi = true, AllowNull = false })
    expect(
        not requiredMulti:SetValue({ A = false }),
        "Required multi dropdowns must reject a dictionary without selected entries"
    )
    dictionary:SetOpen(true)
    dictionary.Search.Text = "high"
    for _, row in ipairs(dictionary.OptionsFrame:GetChildren()) do
        if row:IsA("TextButton") then
            row.Activated:Fire()
        end
    end
    expect(dictionary.Value == "low", "Disabled dropdown entries must ignore user activation")
    dictionary:SetDisabledValues({})
    for _, row in ipairs(dictionary.OptionsFrame:GetChildren()) do
        if row:IsA("TextButton") then
            row.Activated:Fire()
        end
    end
    expect(dictionary.Value == "high", "Enabled dictionary entries should select their backend ID")
    local currentValues = { "First" }
    local dynamic = group:AddDropdown("CustomDynamic", {
        Values = function()
            return currentValues
        end,
        Default = "First",
    })
    currentValues = { "Second" }
    dynamic:SetOpen(true)
    expect(
        dynamic.Values[1] == "Second" and dynamic.Value == nil,
        "Dynamic dropdown providers should refresh on opening"
    )
    dynamic:SetOpen(false)

    local pressed = 0
    local button = group:AddButton({
        Text = "Confirm",
        DoubleClick = true,
        Func = function()
            pressed += 1
        end,
    })
    expect(not button:Press() and pressed == 0, "Double-click buttons must arm without invoking the action")
    expect(
        button:Press() and pressed == 1 and button.Label.Text == "Confirm",
        "The second click should invoke the action and restore text"
    )
    local paragraph = group:AddParagraph({ Title = "About", Content = "An explanation." })
    paragraph:SetTitle("Details"):SetContent("Updated explanation")
    expect(
        paragraph.Label.Text == "Details" and paragraph.Body.Text == "Updated explanation",
        "Paragraphs should expose title and content setters"
    )
    local image = group:AddImage({ Image = 123, Height = 100 })
    image:SetImage(456)
    expect(image.Image.Image == "rbxassetid://456", "Images should normalize numeric asset IDs")

    local expandedHeight = group.Height
    group:SetCollapsed(true)
    expect(group.Height < expandedHeight and not group.Content.Visible, "Collapsing should remove body height")
    group:SetCollapsed(false):SetDescription("Updated description")
    expect(
        group.Content.Visible and group.DescriptionLabel.Text == "Updated description",
        "Expanding and description changes should reflow the card"
    )
    group:Hide()
    expect(not group.Frame.Visible, "Group visibility should be mutable")
    group:Show()

    local nested = test:AddGroupbox({ Name = "Nested", MinHeight = 42 })
    local tabs = nested:AddTabbox({ TabWidth = 100 })
    local first = tabs:AddTab("First")
    first:AddToggle("CustomNested", { Text = "Nested toggle" })
    local second = tabs:AddTab("Second")
    second:AddLabel("Second page")
    tabs:SelectTab("Second")
    expect(
        not first.Content.Visible and second.Content.Visible and tabs.Host.Frame:GetAttribute("BaseHeight") == 62,
        "Tabboxes must size to their selected page"
    )
    first:Select()
    expect(first.Content.Visible and not second.Content.Visible, "Tabbox pages should expose Select")
    local box = nested:AddDependencyBox()
    box:AddInput("CustomBoxInput", { Text = "Only when enabled", Default = "test" })
    box:SetupDependencies({ { toggle, true } })
    expect(not box.Frame.Visible, "Dependency boxes should hide all their child controls together")
    toggle:SetValue(true, true)
    expect(box.Frame.Visible, "Dependency boxes should update on silent changes")

    toggle.Frame.MouseEnter:Fire()
    expect(
        Library._tooltip.Visible and Library._tooltipText.Text == "Enable the controls",
        "Hover should show tooltip text"
    )
    toggle.Frame.MouseLeave:Fire()
    expect(not Library._tooltip.Visible, "Leaving should hide tooltips")

    local resizeCount, toggleCount = 0, 0
    Window:OnResize(function()
        resizeCount += 1
    end):OnToggle(function()
        toggleCount += 1
    end)
    Window:SetSize(Vector2.new(700, 520))
    expect(
        Window.Size.X == 700 and Window.Frame.Size.X.Offset == 700 and resizeCount == 1,
        "Size changes should update layout and emit callbacks"
    )
    Window:SetSize(Vector2.new(1, 1))
    expect(Window.Size.X == 400 and Window.Size.Y == 300, "Window resizing must respect bounds")
    Window:SetPosition(UDim2.fromOffset(200, 200)):Center():SetScale(0.8):SetTransparency(0.1):SetSubtitle("Custom")
    expect(
        Window.Frame.Position.X.Scale == 0.5 and Window.MaxScale == 0.8 and Window.Subtitle.Text == "Custom",
        "Runtime window customization should update state"
    )
    Window:SetVisible(false):SetVisible(true)
    expect(toggleCount == 2, "Window visibility callbacks should run")
    Window:SetVisible(true)
    expect(toggleCount == 2, "Visibility callbacks should ignore unchanged state")
    Window:SetHeaderButtons({ Minimize = false })
    expect(
        not Window.MinimizeButton.Visible and Window.SettingsButton.Position.X.Offset == -72,
        "Hidden header actions should leave no gap"
    )
    Window:SetHeaderButtons({ Minimize = true }):SetResizable(true)
    expect(Window.ResizeHandle.Visible, "Resize handle should be opt-in and mutable")
    Library:SetTheme({ Track = Color3.fromRGB(80, 90, 110) })
    expect(
        slider.Track.BackgroundColor3 == Color3.fromRGB(80, 90, 110),
        "Track palette changes should update existing sliders"
    )

    local initialStyle = Library:GetStyle()
    Library:SetStyle({ RowSpacing = 9, TextSize = 14, ControlRadius = 9 })
    expect(
        slider.Label.TextSize == 14 and group.Content:FindFirstChildOfClass("UIListLayout").Padding.Offset == 9,
        "Style changes should repaint and reflow existing controls"
    )
    local snapshot = Library:GetStyle()
    snapshot.RowSpacing = 100
    expect(Library.Style.RowSpacing == 9, "Style snapshots must not mutate live settings")
    rejects(function()
        Library:SetStyle({ RowSpacing = 4, BadRole = 1 })
    end, "Invalid styles must reject atomically")
    expect(Library.Style.RowSpacing == 9, "Invalid styles must not partially apply")
    Library:SetStyle(initialStyle)

    local chosen = false
    local dialog = Library:Dialog({
        Title = "Confirm",
        Content = "Continue?",
        Buttons = {
            {
                Text = "Continue",
                Callback = function()
                    chosen = true
                end,
            },
            { Text = "Cancel" },
        },
    })
    dialog.Buttons[1].Activated:Fire()
    expect(dialog.Closed and chosen and not Library._dialog, "Dialog actions should close and invoke their callbacks")
    local firstDialog = Library:Dialog({})
    local secondDialog = Library:Dialog({})
    expect(firstDialog.Closed and not secondDialog.Closed, "Opening another dialog should dismiss the previous one")
    secondDialog:Close()
    rejects(function()
        Library:Dialog({ Buttons = { { Text = "Bad", Callback = true } } })
    end, "Invalid dialog callbacks must be rejected before opening")
    expect(not Library._dialog, "Rejected dialog options must not leave a blocking overlay")
    local escapeDialog = Library:Dialog({ Width = 320, Height = 180 })
    UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape }, false)
    expect(escapeDialog.Closed, "Escape should dismiss dialogs")
    Library:SetWatermark("Vortex test")
    Library:SetKeybindsVisible(true, { Width = 230, Position = UDim2.fromOffset(20, 200) })
    expect(Library._watermark.Visible and Library._keybindMenu.Visible, "Optional overlays should be available")
    expect(
        Library.KeybindFrame.Size.X.Offset == 230 and Library.KeybindFrame.Position.X.Offset == 20,
        "Overlay placement and width should be configurable"
    )
    Library:SetWatermark(nil)
    Library:SetKeybindsVisible(false)

    local transient = group:AddToggle("CustomTransient", { Default = true, Save = false })
    local exported, json = SaveManager:Export()
    expect(exported and type(json) == "string", "Config export should work without writing a file")
    toggle:SetValue(false, true)
    transient:SetValue(false, true)
    expect(
        SaveManager:Import(json) and toggle.Value and not transient.Value,
        "Import should restore included controls and ignore Save=false controls"
    )
    expect(not SaveManager:Import("invalid"), "Invalid config imports must return an error")
    local invalidNormalized = HttpService:JSONEncode({
        Version = 1,
        Objects = {
            CustomEnabled = { Type = "Toggle", Value = false },
            CustomBoundedNumber = { Type = "Input", Value = "-2" },
        },
    })
    expect(
        not SaveManager:Import(invalidNormalized) and toggle.Value,
        "Imports must validate normalized input before applying other controls"
    )
    expect(
        table.find(ThemeManager:GetThemeNames(), "Graphite") and ThemeManager:GetTheme("Graphite").Background ~= nil,
        "Theme discovery should return available palettes"
    )

    Window:SetSize(Vector2.new(580, 460)):SetScale(1):SetTransparency(0):SetResizable(false)
    Window:SelectTab("Main")
    return checks
end
