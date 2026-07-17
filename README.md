Aurelia UI

Aurelia is a premium dark Roblox UI library with animated navigation and reusable controls. It can be used as a normal ModuleScript in Roblox Studio or loaded from GitHub in environments that support `game:HttpGet()` and `loadstring()`.

## Supported widgets

- Tabs and sections
- Buttons
- Toggles
- Sliders
- Dropdowns
- Text inputs
- Color pickers
- Labels
- Toast notifications

## Installation

### Roblox Studio with Rojo

Sync `default.project.json`. Rojo places the library at `ReplicatedStorage.AureliaUI` and the demonstration at `StarterPlayerScripts.AureliaDemo`.

```lua
local Aurelia = require(game.ReplicatedStorage:WaitForChild("AureliaUI"))
```

### GitHub loadstring

The library file can be loaded directly:

```lua
local Aurelia = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/TheWeirdGuy/RobloxUILib/main/UI.lua"
))()
```

To run the included Home tab and respawn-button example after uploading `loader.lua`:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/TheWeirdGuy/RobloxUILib/main/loader.lua"
))()
```

`loadstring` and `game:HttpGet()` are not available to ordinary Roblox LocalScripts. Use the ModuleScript installation for a normal Roblox experience.

## Creating a window

```lua
local window = Aurelia.new({
    MenuId = "MyHub",
    Title = "MY HUB",
    Subtitle = "PREMIUM SUITE",
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(840, 520), -- optional
})
```

| Option | Type | Default | Purpose |
| --- | --- | --- | --- |
| `MenuId` | string | `"AureliaUI"` | Unique identity used for duplicate protection |
| `Title` | string | `"AURELIA"` | Brand name in the sidebar |
| `Subtitle` | string | `"PREMIUM INTERFACE"` | Small text below the title |
| `ToggleKey` | Enum.KeyCode | `RightShift` | Shows or hides the interface |
| `Size` | UDim2 | `840 x 520` | Window dimensions |

Window methods:

```lua
window:SetVisible(false)
window:SetVisible(true)
window:Close() -- animated close followed by cleanup
window:Destroy()
```

### Duplicate menu protection

Before creating a window, Aurelia checks `PlayerGui` for another menu with the same `MenuId`. If one exists, Aurelia tells it to disconnect its input listeners and destroy itself before creating the replacement. This prevents duplicate interfaces when a script is run more than once.

Use a different `MenuId` for menus that should exist at the same time:

```lua
local combatWindow = Aurelia.new({ MenuId = "CombatMenu", Title = "COMBAT" })
local adminWindow = Aurelia.new({ MenuId = "AdminMenu", Title = "ADMIN" })
```

Running another window with `MenuId = "CombatMenu"` replaces only `combatWindow`; `adminWindow` remains open. Every window also includes an **X** button in its top-right corner. Pressing it animates the window closed, disconnects global input listeners, and removes the interface.

## Creating a tab

Tabs appear in the left sidebar. The first tab is selected automatically.

```lua
local homeTab = window:AddTab({
    Name = "Home",
    Icon = "H",
    Description = "General actions and information",
})
```

`Name` is the sidebar label, `Icon` is the short symbol displayed beside it, and `Description` appears underneath the page heading.

## Creating a section

Sections group related widgets into cards inside a tab.

```lua
local playerSection = homeTab:AddSection({
    Name = "Player",
    Description = "Actions for your character",
})
```

The description is optional. A short form is also supported:

```lua
local section = homeTab:AddSection("Player")
```

## Button

```lua
section:AddButton({
    Name = "Respawn character",
    Callback = function()
        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end,
})
```

The callback runs whenever the button is pressed.

## Toggle

```lua
local toggle = section:AddToggle({
    Name = "Player outlines",
    Description = "Draw outlines around players",
    Default = false,
    Callback = function(enabled)
        print("Enabled:", enabled)
    end,
})

toggle:Set(true)
print(toggle:Get())
```

The callback receives a boolean.

## Slider

```lua
local slider = section:AddSlider({
    Name = "Walk speed",
    Min = 16,
    Max = 100,
    Default = 24,
    Increment = 1,
    Suffix = " studs",
    Callback = function(value)
        print("Speed:", value)
    end,
})

slider:Set(32)
print(slider:Get())
```

`Increment` controls the step size. `Suffix` is only display text.

## Dropdown

```lua
local dropdown = section:AddDropdown({
    Name = "Target bone",
    Options = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(option)
        print("Selected:", option)
    end,
})

dropdown:Set("UpperTorso")
print(dropdown:Get())
```

The callback receives the selected option.

## Text input

```lua
local input = section:AddInput({
    Name = "Profile name",
    Placeholder = "Enter a name...",
    Default = "Default",
    SubmitOnEnter = true,
    Callback = function(text)
        print("Submitted:", text)
    end,
})

input:Set("Competitive")
print(input:Get())
```

When `SubmitOnEnter` is true, the callback runs after Enter is pressed. Otherwise it runs whenever the field loses focus.

## Color picker

```lua
local picker = section:AddColorPicker({
    Name = "Outline color",
    Default = Color3.fromRGB(39, 201, 255),
    Callback = function(color)
        print("Selected color:", color)
    end,
})

picker:Set(Color3.fromRGB(255, 80, 120))
print(picker:Get())
```

The picker provides a full hue bar, saturation/brightness field, RGB values, and a hex preview. Its callback receives a `Color3`. `Set` also requires a `Color3`.

## Label

```lua
local label = section:AddLabel("Press RightShift to hide or show the UI.")
label.Text = "Updated information"
```

`AddLabel` returns the Roblox `TextLabel` instance.

## Notifications

```lua
window:Notify({
    Title = "Profile saved",
    Content = "Your configuration is ready.",
    Duration = 4,
    Color = Aurelia.Palette.Success,
})
```

You can also send a title-only notification:

```lua
window:Notify("Welcome back")
```

## Theme colors

The built-in palette is exposed through `Aurelia.Palette`:

```lua
local accent = Aurelia.Palette.Accent
local success = Aurelia.Palette.Success
local danger = Aurelia.Palette.Danger
```

Available keys are `Background`, `Sidebar`, `Surface`, `Hover`, `Raised`, `Border`, `Accent`, `AccentDark`, `Text`, `Muted`, `Success`, and `Danger`.
