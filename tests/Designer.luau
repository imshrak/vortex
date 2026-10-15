local designerChecks = 0
local function verify(value, message)
    designerChecks += 1
    assert(value, message)
end

local project = Project.new()
verify(project:Get("n3").Id == "Enabled", "Starter project should contain editable controls")
verify(project:Update("window", "Title", "My menu"), "Window properties should be editable")
verify(project:Undo() and project.Data.Window.Title == "vortex", "Undo should restore window settings")
verify(project:Redo() and project.Data.Window.Title == "My menu", "Redo should restore the edit")
local before = Project.Clone(project.Data)
verify(not project:Update("n3", "Id", "Amount"), "Duplicate IDs should be rejected")
verify(project:Get("n3").Id == "Enabled", "Failed edits must leave the project unchanged")
verify(not project:Update("window", "Width", 200), "Invalid dimensions should be rejected")
verify(not project:Update("window", "Title", 4), "Invalid property types should be rejected")
verify(not project:Update("window", "Nothing", "value"), "Unknown properties should be rejected")
verify(not project:Update("window", "Unknown", "FFFFFF", "Theme"), "Unknown theme roles should be rejected")
verify(not project:Update("window", "ControlRadius", 50, "Style"), "Styles should respect library bounds")
verify(not project:Update("window", "ToggleKey", "InvalidKey"), "Invalid menu keys should be rejected")
verify(project:Update("window", "Accent", "AABBCC", "Theme"), "Theme edits should be stored")
verify(project:Update("window", "TextSize", 15, "Style"), "Style edits should be stored")
verify(project:Duplicate("n3"), "Controls should duplicate")
local duplicate = project:Get(project.Selection)
verify(duplicate.Id ~= "Enabled" and duplicate.Kind == "Toggle", "Duplicates need distinct IDs")
verify(project:Remove(duplicate.Key), "Controls should delete")
verify(project:Undo() and project:Get(duplicate.Key), "Undo should restore deleted controls")
verify(project:Redo() and not project:Get(duplicate.Key), "Redo should remove the restored control")

project.Selection = "n2"
verify(project:Add("Group"), "Adding groups should resolve the selected tab")
local otherGroup = project.Selection
verify(project:Move("n3", otherGroup), "Controls should move between groups")
local _, _, _, newParent = project:Get("n3")
verify(newParent.Key == otherGroup, "Moved controls should use the destination group")
verify(project:Move("n4", "n3"), "Controls should reorder across groups")
verify(project:Get(otherGroup).Controls[1].Key == "n4", "Dropped controls should precede their target")
verify(not project:Move("n3", "window"), "Invalid drops should be rejected")
verify(project:Add("Tab"), "Tabs should be insertable")
local secondTab = project.Selection
verify(not project:Add("Toggle"), "Empty selected tabs should require a group instead of inserting elsewhere")
verify(project:Move(otherGroup, secondTab), "Groups should move between tabs")
verify(project:Move(secondTab, "n1"), "Tabs should reorder")
verify(project.Data.Tabs[1].Key == secondTab, "Tab order should match the move")
verify(project:Duplicate(secondTab), "Tabs should duplicate their contents")
local duplicatedTab = project:Get(project.Selection)
verify(
    duplicatedTab.Name ~= project:Get(secondTab).Name and #duplicatedTab.Groups == 1,
    "Duplicated tabs should have unique names and children"
)
verify(not project:Update(duplicatedTab.Key, "Name", project:Get(secondTab).Name), "Tab names must remain unique")

local complete = Project.new()
for _, kind in ipairs(Project.Kinds) do
    complete.Selection = "n2"
    verify(complete:Add(kind), "Each control kind should be insertable: " .. kind)
end
local dropdown, inputControl, paragraph
for _, node in ipairs(complete:Get("n2").Controls) do
    if node.Kind == "Dropdown" then
        dropdown = node
    end
    if node.Kind == "Input" then
        inputControl = node
    end
    if node.Kind == "Paragraph" then
        paragraph = node
    end
end
verify(complete:Update(dropdown.Key, "Values", { "Fresh", "Other" }), "Dropdown choices should update")
verify(complete:Get(dropdown.Key).Default == "Fresh", "Changing choices should normalize the default")
verify(not complete:Update(dropdown.Key, "Values", { "Repeat", "Repeat" }), "Duplicate choices should be rejected")
verify(complete:Update(dropdown.Key, "Multi", true), "Multi dropdowns should be supported")
verify(complete:Update(inputControl.Key, "Multiline", true), "Multiline inputs should be supported")
verify(
    complete:Update(paragraph.Key, "Content", 'First line\nSecond line "quoted" \\ literal'),
    "Multiline content should retain quotes and slashes"
)
verify(complete:Update("window", "Title", 'Quote " \\ -- literal'), "Text should permit literal code-like characters")

local library = newLibrary()
local window, objects = complete:Build(library, { Parent = playerGui })
verify(window.Title.Text == complete.Data.Window.Title, "Preview should render the actual project title")
verify(objects[dropdown.Key].Value.Fresh == true, "Preview should build multi defaults correctly")
verify(objects[inputControl.Key].Value == "", "Preview should preserve input defaults")
verify(
    objects[paragraph.Key].Body.Text == complete:Get(paragraph.Key).Content,
    "Preview paragraphs should match the project"
)
verify(library.Theme.Accent:ToHex() == complete.Data.Theme.Accent:lower(), "Preview colors should match the project")
objects.n3:SetValue(true)
verify(complete:Get("n3").Default == false, "Preview interaction must not change design defaults")
library:Unload()

local source = complete:Generate()
verify(source:find("local Window = Library:CreateWindow", 1, true), "Lua export should construct a window")
verify(source:find("Multi = true", 1, true), "Lua export should retain dropdown options")
verify(
    not source:find("print(", 1, true) and not source:find("warn(", 1, true),
    "Exports should contain no debug output"
)
verify(
    complete:Generate("Studio"):find('require(game:GetService("ReplicatedStorage")', 1, true),
    "Studio export should use a ModuleScript"
)
verify(source == complete:Generate(), "Export should be deterministic")
local malformed = Project.Clone(complete.Data)
malformed.Tabs[1].Groups[1].Controls[1].Key = malformed.Tabs[1].Key
verify(not pcall(Project.new, malformed), "Imported keys must be unique")
malformed = Project.Clone(complete.Data)
malformed.Tabs[1].Groups[1].Controls[1].Kind = "Script"
verify(not pcall(Project.new, malformed), "Imported controls must use known kinds")
verify(not pcall(Project.new, { Version = 99 }), "Unsupported versions must be rejected")
verify(project:Replace(before), "Projects should replace atomically")
verify(project:Undo(), "Replacing a project should support undo")

local editor = Designer:Create({ ProjectModule = Project, LoadLibrary = newLibrary, Parent = playerGui })
verify(
    editor.Gui.Parent == playerGui and editor.PreviewWindow.Frame.Parent == editor.Stage,
    "Designer should embed its live preview"
)
editor:Select("n3")
editor.PropertyInputs.Text.Text = "Custom toggle"
editor.PropertyInputs.Text.FocusLost:Fire()
verify(editor.Model:Get("n3").Text == "Custom toggle", "Property fields should update the project")
verify(editor.PreviewObjects.n3.Label.Text == "Custom toggle", "Property edits should refresh the live preview")
local oldPreview, oldFrame = editor.PreviewLibrary, editor.PreviewWindow.Frame
editor:Add("Checkbox")
verify(oldPreview.Unloaded and oldFrame.Destroyed, "Refreshing should clean up the previous preview")
editor:Undo()
verify(editor.Model:Get("n3").Text == "Custom toggle", "Editor undo should preserve previous edits")
editor:SetTesting(true)
verify(
    editor.Testing and not editor.PreviewObjects.n3.Frame:FindFirstChild("DesignerSelect").Visible,
    "Preview mode should expose control interaction"
)
editor:SetTesting(false)
verify(
    editor.PreviewObjects.n3.Frame:FindFirstChild("DesignerSelect").Visible,
    "Editing mode should restore selection overlays"
)
local json = editor:ExportJSON()
verify(editor:ImportJSON(json), "Project JSON should round-trip")
verify(editor.Model:Get("n3").Text == "Custom toggle", "Project JSON should preserve labels")
verify(not editor:ImportJSON("bad"), "Malformed JSON should be rejected")
verify(not editor:ImportJSON(string.rep("x", 524289)), "Oversized projects should be rejected")
editor:ShowExport()
verify(editor.Modal ~= nil, "Export should open a dialog")
editor:_closeModal()
editor:ShowImport()
verify(editor.Modal ~= nil, "Import should open a dialog")
editor:_closeModal()
local editorConnections, previewConnections =
    table.clone(editor.Connections), table.clone(editor.PreviewLibrary._connections)
local previewFrame = editor.PreviewWindow.Frame
editor:Destroy()
editor:Destroy()
verify(editor.Gui.Destroyed and previewFrame.Destroyed, "Closing should destroy editor and preview")
for _, connection in ipairs(editorConnections) do
    verify(not connection.Connected, "Closing should disconnect editor listeners")
end
for _, connection in ipairs(previewConnections) do
    verify(not connection.Connected, "Closing should disconnect preview listeners")
end
verify(#callbackErrors == 0, "Designer callbacks must not produce hidden errors")
print("PASS: " .. designerChecks .. " Designer checks")
print("VORTEX_EXPORT_BEGIN")
print(source)
print("VORTEX_EXPORT_END")
