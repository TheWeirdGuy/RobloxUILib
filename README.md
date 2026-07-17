Aurelia UI

Aurelia is a premium dark Roblox UI library with animated navigation and reusable controls. It can be used as a normal ModuleScript in Roblox Studio or loaded from GitHub in environments that support `game:HttpGet()` and `loadstring()`.

## Supported widgets

- Tabs and sections
- Buttons
- Toggles
- Sliders
- Dropdowns
- Multi-select dropdowns
- Text inputs
- Color pickers
- Keybind pickers
- Labels
- Toast notifications
- Modal dialogs and message boxes
- Search, tooltips, widget flags, and theme presets

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
window:Minimize(true)
window:Minimize(false)
window:Close() -- animated close followed by cleanup
window:Destroy()
print(window:GetFlag("WalkSpeed"))
```

### Duplicate menu protection

Before creating a window, Aurelia checks `PlayerGui` for another menu with the same `MenuId`. If one exists, Aurelia tells it to disconnect its input listeners and destroy itself before creating the replacement. This prevents duplicate interfaces when a script is run more than once.

Use a different `MenuId` for menus that should exist at the same time:

```lua
local combatWindow = Aurelia.new({ MenuId = "CombatMenu", Title = "COMBAT" })
local adminWindow = Aurelia.new({ MenuId = "AdminMenu", Title = "ADMIN" })
```

Running another window with `MenuId = "CombatMenu"` replaces only `combatWindow`; `adminWindow` remains open. Every window also includes an **X** button in its top-right corner. Pressing it animates the window closed, disconnects global input listeners, and removes the interface.

The **-** button directly left of X toggles a compact title-bar view. It preserves all tabs, flags, and widget values while the menu is minimized.

## Search bar

Every window includes a search field in its top bar. Aurelia automatically indexes section names and widget `Name` values. Typing filters the controls in the currently selected tab; clearing the search restores everything. No additional setup is required.

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
    Flag = "PlayerOutlines",
    Tooltip = "Draw an outline around each visible player.",
    Callback = function(enabled)
        print("Enabled:", enabled)
    end,
})

toggle:Set(true)
print(toggle:Get())
```

The callback receives a boolean.

All stateful widgets accept an optional `Flag`. All widgets accept an optional `Tooltip` unless their API only accepts plain text.

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

## Multi-select dropdown

```lua
local details = section:AddMultiDropdown({
    Name = "ESP details",
    Options = { "Names", "Distance", "Health", "Tool" },
    Default = { "Names", "Distance" },
    Flag = "EspDetails",
    Tooltip = "Choose all details displayed above players.",
    Callback = function(selected)
        for _, option in selected do
            print(option)
        end
    end,
})

details:Set({ "Names", "Health" })
local selected = details:Get()
details:Close()
```

The callback and `Get` return an array in the same order as `Options`. Users can keep the list open while selecting multiple entries.

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

## Keybind picker

```lua
local keybind = section:AddKeybind({
    Name = "Open utility",
    Description = "Press the assigned key to activate",
    Default = Enum.KeyCode.K,
    Flag = "UtilityKey",
    Tooltip = "Click the key field and press a new key.",
    Changed = function(newKey)
        print("New binding:", newKey.Name)
    end,
    Callback = function(key)
        print("Activated with:", key.Name)
    end,
})

keybind:Set(Enum.KeyCode.L)
print(keybind:Get())
```

Click the key field and press any keyboard key to rebind it. Press Escape while listening to cancel. `Changed` runs when the binding changes; `Callback` runs when the bound key is pressed.

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

## Modal dialogs and message boxes

```lua
window:Dialog({
    Title = "Delete profile?",
    Content = "This action cannot be undone.",
    Buttons = {
        { Name = "Cancel" },
        {
            Name = "Delete",
            Color = Aurelia.Palette.Danger,
            Callback = function()
                print("Deleted")
            end,
        },
    },
})
```

`window:ShowDialog(options)` is an alias for `window:Dialog(options)`. The returned controller has a `Close()` method for programmatic dismissal. Each button supports `Name`, optional `Color`, and optional `Callback`.

## Tooltips

Add `Tooltip` to a widget definition:

```lua
section:AddButton({
    Name = "Reset settings",
    Tooltip = "Restores every option to its default value.",
    Callback = resetSettings,
})
```

The tooltip follows the mouse and disappears when the pointer leaves the widget. The built-in Settings, minimize, and close buttons also have tooltips.

## Widget flags

Flags collect state from controls in one window-level table. Supported stateful controls are toggles, sliders, dropdowns, multi-select dropdowns, text inputs, color pickers, and keybinds.

```lua
section:AddSlider({
    Name = "Walk speed",
    Min = 16,
    Max = 100,
    Default = 24,
    Flag = "WalkSpeed",
})

print(window.Flags.WalkSpeed)
print(window:GetFlag("WalkSpeed"))

for name, value in window.Flags do
    print(name, value)
end
```

Flag values update when users interact with a widget and when its `Set` method is called. Use unique flag names within a window.

## Settings and themes

Every window has a built-in **Settings** button. It opens a modal containing Cyan, Violet, and Rose theme choices. Emerald is also available through the API:

```lua
window:SetTheme("Violet")
window:SetTheme("Rose")
window:SetTheme("Emerald")
window:SetTheme("Cyan")
```

Custom theme overrides are supported:

```lua
window:SetTheme({
    Accent = Color3.fromRGB(255, 170, 40),
    AccentDark = Color3.fromRGB(140, 80, 15),
    Background = Color3.fromRGB(8, 8, 10),
})
```

Only supplied keys are changed. Existing controls update immediately.

## Theme colors

The built-in palette is exposed through `Aurelia.Palette`:

```lua
local accent = Aurelia.Palette.Accent
local success = Aurelia.Palette.Success
local danger = Aurelia.Palette.Danger
```

Available keys are `Background`, `Sidebar`, `Surface`, `Hover`, `Raised`, `Border`, `Accent`, `AccentDark`, `Text`, `Muted`, `Success`, and `Danger`.
