local environment = type(getgenv) == "function" and getgenv() or _G
local previous = environment.VortexDesigner
if type(previous) == "table" and type(previous.Destroy) == "function" then
    previous:Destroy()
end

local Designer = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/vortex/main/Designer.lua"))()
local editor = Designer:Create()
environment.VortexDesigner = editor
return editor
