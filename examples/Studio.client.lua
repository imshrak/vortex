local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vortex = ReplicatedStorage:WaitForChild("Vortex")
local Library = require(Vortex)
local ThemeManager = require(Vortex.addons.ThemeManager)

local Window = Library:CreateWindow({
    Title = "vortex",
    Subtitle = "by shrak.",
    Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
})
local Main = Window:AddTab("Main", "rocket")
local Settings = Window:AddTab("Settings", "gear")
local General = Main:AddGroupbox("General")
General:AddToggle("Enabled", { Text = "Enabled", Default = true })
General:AddSlider("Volume", { Text = "Volume", Min = 0, Max = 1, Default = 0.5, Rounding = 2 })
General:AddInput("Name", { Text = "Name", Default = "Vortex" })
General:AddDropdown("Mode", { Text = "Mode", Values = { "Light", "Balanced", "Full" }, Default = 2 })
ThemeManager:SetLibrary(Library):ApplyToTab(Settings)
