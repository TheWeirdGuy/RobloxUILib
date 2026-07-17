local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Aurelia = require(ReplicatedStorage:WaitForChild("AureliaUI"))

local window = Aurelia.new({
	MenuId = "AureliaDemo",
	Title = "AURELIA",
	Subtitle = "PREMIUM SUITE",
	ToggleKey = Enum.KeyCode.RightShift,
})

local combat = window:AddTab({
	Name = "Combat",
	Icon = "◈",
	Description = "Fine-tune combat assistance",
})

local aim = combat:AddSection({
	Name = "Silent Aim",
	Description = "Precision targeting controls",
})

aim:AddToggle({
	Name = "Enable silent aim",
	Description = "Activates the targeting system",
	Default = true,
	Callback = function(enabled)
		print("Silent aim:", enabled)
	end,
})

aim:AddToggle({
	Name = "Visibility check",
	Description = "Ignore targets behind geometry",
	Default = true,
})

aim:AddSlider({
	Name = "Field of view",
	Min = 20,
	Max = 300,
	Default = 120,
	Increment = 5,
	Suffix = "°",
})

aim:AddDropdown({
	Name = "Target bone",
	Options = { "Head", "UpperTorso", "HumanoidRootPart" },
	Default = "Head",
})

local weapon = combat:AddSection({ Name = "Weapon", Description = "Weapon behavior and feedback" })
weapon:AddSlider({ Name = "Hit chance", Min = 0, Max = 100, Default = 82, Suffix = "%" })
weapon:AddButton({
	Name = "Apply configuration",
	Callback = function()
		window:Notify({ Title = "Configuration saved", Content = "Your combat profile is now active." })
	end,
})

local visuals = window:AddTab({ Name = "Visuals", Icon = "◉", Description = "World and player rendering" })
local players = visuals:AddSection({ Name = "Player ESP", Description = "Clear, customizable player information" })
players:AddToggle({ Name = "Player outlines", Description = "Draw an outline around visible players" })
players:AddToggle({ Name = "Name tags", Description = "Show display names and distance", Default = true })
players:AddDropdown({ Name = "Outline style", Options = { "Glow", "Solid", "Minimal" }, Default = "Glow" })
players:AddColorPicker({
	Name = "Outline color",
	Default = Color3.fromRGB(39, 201, 255),
	Callback = function(color)
		print("Outline color:", color)
	end,
})

local world = visuals:AddSection({ Name = "World", Description = "Atmosphere and lighting" })
world:AddSlider({ Name = "Brightness", Min = 0, Max = 10, Default = 3, Increment = 0.5 })
world:AddToggle({ Name = "Remove fog", Description = "Improves visibility at long range" })

local utility = window:AddTab({ Name = "Utility", Icon = "✦", Description = "Quality-of-life utilities" })
local movement = utility:AddSection({ Name = "Movement", Description = "Responsive movement adjustments" })
movement:AddSlider({ Name = "Walk speed", Min = 16, Max = 100, Default = 24 })
movement:AddToggle({ Name = "Infinite jump", Description = "Jump again while airborne" })

local settings = window:AddTab({ Name = "Settings", Icon = "⚙", Description = "Interface preferences and profiles" })
local profiles = settings:AddSection({ Name = "Profiles", Description = "Save and switch configurations" })
profiles:AddInput({ Name = "Profile name", Placeholder = "Enter a profile name", SubmitOnEnter = true })
profiles:AddDropdown({ Name = "Active profile", Options = { "Default", "Competitive", "Legit" }, Default = "Default" })
profiles:AddButton({ Name = "Save current profile", Callback = function() window:Notify("Profile saved") end })
profiles:AddLabel("Press RightShift at any time to hide or show the interface.")

window:Notify({
	Title = "Welcome to Aurelia",
	Content = "Your premium interface is ready.",
	Duration = 5,
})
