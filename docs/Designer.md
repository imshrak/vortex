# Vortex Designer

Build menus visually and export comment-free Lua.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/vortex/main/examples/Designer.lua"))()
```

For Studio, sync [designer.project.json](../designer.project.json) with Rojo and start Play. HTTP loading and file access are optional; the Studio launcher uses ModuleScripts.

## Editing

- Select a window, tab, group, or control in the outline. Click controls on the canvas to select them.
- Add tabs and groups with the outline buttons. Use Insert to add controls to the selected group.
- Edit labels, IDs, defaults, options, and layout in Properties. Use Theme and Style for colors, typography, spacing, and corners.
- Drag outline items to reorder them. Drop controls onto groups or groups onto tabs to move them. Move up/down buttons also work on touch.
- Preview enables control interaction. Switch back with Editing. Reset view restores the preview without changing the project.

The preview renders with Vortex itself. Control interactions do not overwrite project defaults. Window dragging, resizing, and the launcher are reserved for the exported menu; edit dimensions in Properties.

## Saving and export

Save opens the Project export. Copy the JSON or save a `.vortex.json` file, then use Open to load it later. File access saves to `VortexUI/Designer` inside your runtime's file sandbox. Without clipboard access, Copy selects the text for manual copying.

Export offers Lua with the HTTP loader, Studio with a ModuleScript loader, or editable Project JSON. Exported Lua contains the window, palette, style, tabs, groups, and controls. Add your behavior through callbacks after exporting; buttons start with empty callbacks.

## Shortcuts

| Keys | Action |
| --- | --- |
| Ctrl+Z | Undo |
| Ctrl+Shift+Z / Ctrl+Y | Redo |
| Ctrl+D | Duplicate selection |
| Delete | Delete selection |
| Ctrl+S | Save project |

History stores the last 60 edits. Shortcuts pause while typing. Minimize restores through the V button; close cleans up the editor and preview.

## Custom loader

```lua
local editor = Designer:Create({
    ProjectModule = Project,
    LoadLibrary = function() return loadstring(librarySource)() end,
})

local json = editor:ExportJSON()
local source = editor:ExportLua("Studio")
local ok, err = editor:ImportJSON(json)
```

`LoadLibrary` must return a fresh library instance each time. `Data` optionally supplies a validated project table. `Parent` optionally supplies a GUI container. `Destroy()` closes without confirmation; the editor's Close button asks before discarding unsaved work.
