local function verifyAppearance(library, window, group, toggle, slider, input, dropdown, key)
    local checks = 0
    local function expect(value, message)
        checks += 1
        assert(value, message)
    end
    local function position(object, xScale, xOffset, yScale, yOffset)
        local p = object.Position
        return math.abs(p.X.Scale - xScale) < 0.0001
            and p.X.Offset == xOffset
            and math.abs(p.Y.Scale - yScale) < 0.0001
            and p.Y.Offset == yOffset
    end
    expect(window.Size.X == 580 and window.Size.Y == 460, "Default window dimensions must remain 580 by 460")
    expect(position(window.Title, 0, 22, 0, 11), "Title must use the reference header inset")
    expect(window.Title.TextSize == 20 and window.Title.TextTransparency == 0.2, "Title typography must match")
    expect(position(window.Subtitle, 0, 124, 0, 8), "Subtitle must use the reference header inset")
    expect(position(window.Navigation, 0, 16, 0, 57), "Navigation must start at the reference position")
    expect(window.Navigation.Size.Y.Offset == 34, "Navigation must be 34 pixels tall")
    expect(window.Tabs.Main.Button.Size.X.Offset == 64, "Main tab must retain its reference width")
    expect(
        window.Tabs.Main.Label.TextSize == 14 and window.Tabs.Main.Label.TextTransparency == 0.4,
        "Tab typography must match"
    )
    expect(position(window.Tabs.Main.Frame, 0, 16, 0, 102), "Page viewport must use the reference inset")
    expect(window.Tabs.Main.Frame.ScrollBarThickness == 1, "Page scrollbar must retain its original thickness")
    expect(
        group.Frame.Size.X.Offset == 540 and group.Content.Size.X.Offset == 508,
        "Card and content widths must match"
    )
    expect(position(group.Content, 0, 16, 0, 12), "Card content inset must match")
    expect(
        group.MinimumHeight == 288 and not group.ShowTitle,
        "Default cards must preserve the unheaded 288-pixel minimum"
    )
    expect(
        toggle.Pill.ClassName == "ImageButton" and toggle.Pill.Image == "rbxassetid://18772190202",
        "Toggle must use the original pill asset"
    )
    expect(toggle.Knob.Image == "rbxassetid://18772309008", "Toggle must use the original knob asset")
    expect(position(toggle.Pill, 1, -41, 0, 6), "Toggle pill placement must match")
    expect(toggle.Label.TextTransparency == 0.4, "Control labels must use the original text opacity")
    expect(slider.Frame:GetAttribute("BaseHeight") == 47.52, "Sliders must retain their fractional row height")
    expect(
        slider.Track.Size.X.Scale == 290 / 508 and slider.Track.Size.Y.Offset == 3,
        "Slider track proportions must match"
    )
    expect(position(slider.Track, 160 / 508, 0, 19.8 / 47.52, 0), "Slider track must sit alongside its label")
    expect(slider.Box.Size.X.Offset == 41 and slider.Box.Size.Y.Offset == 21, "Slider value box dimensions must match")
    expect(slider.Head.Size.X.Offset == 12 and slider.Head.Size.Y.Offset == 12, "Slider knob dimensions must match")
    expect(position(input.Box, 1, -58, 0.5, -10.5), "Inputs must use compact right-aligned fields by default")
    expect(dropdown.Frame.BackgroundTransparency == 0.985, "Dropdown background opacity must match")
    expect(
        dropdown.Label.Position.X.Offset == 15 and dropdown.Label.TextTransparency == 0.4,
        "Dropdown label styling must match"
    )
    expect(
        key.Button.Size.Y.Offset == 21 and key.Button.Position.Y.Offset == 6,
        "Keybind fields must retain their compact height and inset"
    )
    expect(
        window.GlobalSettings.Size.X.Offset == 158 and window.GlobalSettings.Size.Y.Offset == 93,
        "Header settings popup dimensions must match"
    )
    expect(
        window.Toast.Position.X.Offset == 220 and window.Toast.TextTransparency == 0.15,
        "Notifications must use the footer toast"
    )
    expect(
        window.Launcher.Parent == window.LauncherGui and window.LauncherGui ~= window.Gui,
        "Launcher must have an independent GUI"
    )
    expect(
        library.Theme.Background:ToHex() == "0f0f0f" and library.Theme.Text:ToHex() == "ffffff",
        "Default colors must match the original palette"
    )
    return checks
end
