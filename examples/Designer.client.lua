local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LibraryModule = ReplicatedStorage:WaitForChild("Vortex")
local DesignerModule = ReplicatedStorage:WaitForChild("VortexDesigner")
local Designer = require(DesignerModule)

Designer:Create({
    Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
    ProjectModule = require(DesignerModule.Project),
    LoadLibrary = function()
        local module = LibraryModule:Clone()
        module.Parent = ReplicatedStorage
        local library = require(module)
        module:Destroy()
        return library
    end,
})
