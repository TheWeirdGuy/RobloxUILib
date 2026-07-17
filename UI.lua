--!strict
-- Aurelia UI - premium, dependency-free Roblox interface library.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local info = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Theme = {
	Background = Color3.fromRGB(7, 10, 15), Sidebar = Color3.fromRGB(13, 18, 25),
	Surface = Color3.fromRGB(16, 22, 30), Hover = Color3.fromRGB(22, 30, 40),
	Raised = Color3.fromRGB(25, 33, 44), Border = Color3.fromRGB(40, 53, 68),
	Accent = Color3.fromRGB(39, 201, 255), AccentDark = Color3.fromRGB(11, 101, 138),
	Text = Color3.fromRGB(240, 247, 255), Muted = Color3.fromRGB(133, 151, 171),
	Success = Color3.fromRGB(72, 219, 154), Danger = Color3.fromRGB(255, 98, 122),
}

local ThemePresets = {
	Cyan = {},
	Violet = { Accent = Color3.fromRGB(155, 112, 255), AccentDark = Color3.fromRGB(82, 54, 153) },
	Rose = { Accent = Color3.fromRGB(255, 91, 139), AccentDark = Color3.fromRGB(142, 43, 79) },
	Emerald = { Accent = Color3.fromRGB(67, 222, 157), AccentDark = Color3.fromRGB(30, 125, 86) },
}

local function new(class, properties)
	local object = Instance.new(class)
	for key, value in properties or {} do if key ~= "Parent" then object[key] = value end end
	if properties and properties.Parent then object.Parent = properties.Parent end
	return object
end

local function round(parent, radius) new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent }) end
local function outline(parent, transparency)
	new("UIStroke", { Color = Theme.Border, Transparency = transparency or 0, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end
local function pad(parent, amount)
	new("UIPadding", { PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount), PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount), Parent = parent })
end
local function animate(object, properties) TweenService:Create(object, info, properties):Play() end
local function label(parent, value, size, color, weight)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 8), Text = value,
		TextColor3 = color or Theme.Text, TextSize = size, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", weight or Enum.FontWeight.Medium), Parent = parent,
	})
end
local function callback(fn, value)
	if fn then task.spawn(function() local ok, err = pcall(fn, value); if not ok then warn("[Aurelia]", err) end end) end
end
local function hover(button, base, over)
	button.MouseEnter:Connect(function() animate(button, { BackgroundColor3 = over }) end)
	button.MouseLeave:Connect(function() animate(button, { BackgroundColor3 = base }) end)
end

local Aurelia = { Palette = Theme }
local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

function Aurelia.new(options)
	options = options or {}
	assert(player, "Aurelia must run from a LocalScript")
	local self = setmetatable({ _tabs = {}, _connections = {}, _visible = true, _minimized = false }, Window)
	self.Flags = {}
	self._theme = table.clone(Theme)
	self._key = options.ToggleKey or Enum.KeyCode.RightShift
	self._targetSize = options.Size or UDim2.fromOffset(840, 520)
	self._menuId = options.MenuId or "AureliaUI"
	assert(type(self._menuId) == "string" and self._menuId ~= "", "MenuId must be a non-empty string")

	local screenParent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
	local existing = screenParent:FindFirstChild(self._menuId)
	if existing then
		local cleanup = existing:FindFirstChild("AureliaCleanup")
		if cleanup and cleanup:IsA("BindableEvent") then cleanup:Fire() else existing:Destroy() end
	end

	local screen = new("ScreenGui", { Name = self._menuId, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	self._screen = screen
	screen.Parent = screenParent
	local cleanup = new("BindableEvent", { Name = "AureliaCleanup", Parent = screen })
	table.insert(self._connections, cleanup.Event:Connect(function() self:Destroy() end))
	local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.42, BorderSizePixel = 0, Parent = screen })
	local root = new("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = self._targetSize, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = dim })
	self._root = root; round(root, 14); outline(root, 0.1)
	self._sizeConstraint = new("UISizeConstraint", { MinSize = Vector2.new(580, 390), MaxSize = Vector2.new(1000, 650), Parent = root })
	local accent = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = root })
	new("UIGradient", { Name = "AccentGradient", Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 134, 255)), ColorSequenceKeypoint.new(0.5, Theme.Accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 84, 255)) }), Parent = accent })

	local sidebar = new("Frame", { Size = UDim2.new(0, 210, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = root }); self._sidebar = sidebar
	new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = sidebar })
	local brand = new("Frame", { Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 58), BackgroundTransparency = 1, Parent = sidebar })
	local brandTitle = label(brand, options.Title or "AURELIA", 19, Theme.Text, Enum.FontWeight.Bold); brandTitle.Size = UDim2.new(1, 0, 0, 25)
	local brandSub = label(brand, options.Subtitle or "PREMIUM INTERFACE", 9, Theme.Accent, Enum.FontWeight.SemiBold); brandSub.Position = UDim2.fromOffset(0, 28)
	local nav = new("ScrollingFrame", { Position = UDim2.fromOffset(12, 88), Size = UDim2.new(1, -24, 1, -158), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = sidebar })
	self._nav = nav; new("UIListLayout", { Padding = UDim.new(0, 6), Parent = nav })

	local profile = new("Frame", { Position = UDim2.new(0, 12, 1, -58), Size = UDim2.new(1, -24, 0, 46), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = sidebar }); round(profile, 10); outline(profile, 0.4)
	local avatar = new("ImageLabel", { Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=100&h=100", Parent = profile }); round(avatar, 8)
	local name = label(profile, player.DisplayName, 11, Theme.Text, Enum.FontWeight.SemiBold); name.Position = UDim2.fromOffset(48, 6); name.Size = UDim2.new(1, -56, 0, 17)
	local status = label(profile, "●  Connected", 9, Theme.Success); status.Position = UDim2.fromOffset(48, 23)

	local top = new("Frame", { Position = UDim2.fromOffset(210, 0), Size = UDim2.new(1, -210, 0, 76), BackgroundTransparency = 1, Parent = root }); self._top = top
	local pageTitle = label(top, "Dashboard", 18, Theme.Text, Enum.FontWeight.Bold); pageTitle.Position = UDim2.fromOffset(24, 18); pageTitle.Size = UDim2.new(1, -340, 0, 24); self._pageTitle = pageTitle
	local pageSub = label(top, "Configure your experience", 10, Theme.Muted); pageSub.Position = UDim2.fromOffset(24, 43); self._pageSub = pageSub
	local search = new("TextBox", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -186, 0, 24), Size = UDim2.fromOffset(140, 28), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Search controls...", PlaceholderColor3 = Theme.Muted, Text = "", TextColor3 = Theme.Text, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Parent = top }); round(search, 7); outline(search, 0.35); self._search = search
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = search })
	local settings = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -104, 0, 24), Size = UDim2.fromOffset(72, 28), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "Settings", TextColor3 = Theme.Muted, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), Parent = top }); round(settings, 7); outline(settings, 0.35); self._settings = settings
	settings.MouseEnter:Connect(function() animate(settings, { BackgroundColor3 = Theme.Hover, TextColor3 = Theme.Text }) end); settings.MouseLeave:Connect(function() animate(settings, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Muted }) end)
	settings.Activated:Connect(function() self:OpenThemeSettings() end)
	local minimize = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 22), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "-", TextColor3 = Theme.Muted, TextSize = 15, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), Parent = top }); round(minimize, 8); outline(minimize, 0.35)
	minimize.MouseEnter:Connect(function() animate(minimize, { BackgroundColor3 = Theme.Hover, TextColor3 = Theme.Text }) end); minimize.MouseLeave:Connect(function() animate(minimize, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Muted }) end)
	minimize.Activated:Connect(function() self:Minimize(not self._minimized) end)
	local close = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 22), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "X", TextColor3 = Theme.Muted, TextSize = 12, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), Parent = top }); round(close, 8); outline(close, 0.35)
	close.MouseEnter:Connect(function() animate(close, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Text }) end)
	close.MouseLeave:Connect(function() animate(close, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Muted }) end)
	close.Activated:Connect(function() self:Close() end)
	self._content = new("Frame", { Position = UDim2.fromOffset(210, 76), Size = UDim2.new(1, -210, 1, -76), BackgroundTransparency = 1, ClipsDescendants = true, Parent = root })
	self._notifications = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(290, 300), BackgroundTransparency = 1, Parent = screen })
	new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = self._notifications })
	local tooltip = new("Frame", { Size = UDim2.fromOffset(180, 30), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, Visible = false, ZIndex = 100, Parent = screen }); round(tooltip, 7); outline(tooltip, 0.2); self._tooltip = tooltip
	local tooltipText = label(tooltip, "", 9, Theme.Text, Enum.FontWeight.Medium); tooltipText.Position = UDim2.fromOffset(8, 4); tooltipText.Size = UDim2.new(1, -16, 1, -8); tooltipText.TextWrapped = true; tooltipText.TextTruncate = Enum.TextTruncate.None; tooltipText.ZIndex = 101; self._tooltipText = tooltipText
	self:_AttachTooltip(settings, "Open the built-in theme settings")
	self:_AttachTooltip(minimize, "Minimize or restore this menu")
	self:_AttachTooltip(close, "Close and clean up this menu")

	local dragging, dragStart, startPosition = false, Vector3.zero, root.Position
	table.insert(self._connections, top.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging, dragStart, startPosition = true, input.Position, root.Position end end))
	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart; root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + d.X, startPosition.Y.Scale, startPosition.Y.Offset + d.Y) end end))
	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == self._key then self:SetVisible(not self._visible) end end))
	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) if self._tooltip.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local point = UserInputService:GetMouseLocation(); self._tooltip.Position = UDim2.fromOffset(point.X + 14, point.Y + 14) end end))
	search:GetPropertyChangedSignal("Text"):Connect(function() self:_ApplySearch(search.Text) end)
	root.Size = UDim2.fromOffset(760, 460); root.BackgroundTransparency = 1; animate(root, { Size = self._targetSize, BackgroundTransparency = 0 })
	return self
end

function Window:SetVisible(visible)
	self._visible = visible
	local target = self._minimized and UDim2.fromOffset(420, 64) or self._targetSize
	local compact = UDim2.new(target.X.Scale, target.X.Offset - 50, target.Y.Scale, target.Y.Offset - 20)
	if visible then self._screen.Enabled = true; self._root.Size = compact; animate(self._root, { Size = target, BackgroundTransparency = 0 })
	else animate(self._root, { Size = compact, BackgroundTransparency = 0.2 }); task.delay(0.18, function() if not self._visible and self._screen.Parent then self._screen.Enabled = false end end) end
end

function Window:Minimize(minimized)
	if self._destroyed or self._minimized == minimized then return end
	self._minimized = minimized
	if minimized then
		self._sizeConstraint.MinSize = Vector2.new(320, 64)
		self._sidebar.Visible = false; self._content.Visible = false; self._search.Visible = false; self._settings.Visible = false; self._pageSub.Visible = false
		self._top.Position = UDim2.fromOffset(0, 0); self._top.Size = UDim2.new(1, 0, 0, 64); self._pageTitle.Size = UDim2.new(1, -120, 0, 24)
		animate(self._root, { Size = UDim2.fromOffset(420, 64) })
	else
		self._sidebar.Visible = true; self._content.Visible = true; self._search.Visible = true; self._settings.Visible = true; self._pageSub.Visible = true
		self._top.Position = UDim2.fromOffset(210, 0); self._top.Size = UDim2.new(1, -210, 0, 76); self._pageTitle.Size = UDim2.new(1, -340, 0, 24)
		animate(self._root, { Size = self._targetSize })
		task.delay(0.18, function() if not self._minimized then self._sizeConstraint.MinSize = Vector2.new(580, 390) end end)
	end
end

function Window:_AttachTooltip(gui, value)
	if not value or value == "" then return end
	gui.MouseEnter:Connect(function()
		if self._destroyed then return end
		self._tooltipText.Text = tostring(value)
		self._tooltip.Size = UDim2.fromOffset(200, math.max(30, 18 + math.ceil(#tostring(value) / 34) * 12))
		local point = UserInputService:GetMouseLocation(); self._tooltip.Position = UDim2.fromOffset(point.X + 14, point.Y + 14); self._tooltip.Visible = true
	end)
	gui.MouseLeave:Connect(function() self._tooltip.Visible = false end)
end

function Window:_ApplySearch(value)
	if not self._active then return end
	local query = string.lower(value or "")
	for _, card in self._active._page:GetChildren() do
		if card:IsA("Frame") and card:GetAttribute("AureliaSection") then
			local sectionMatch = query == "" or string.find(card:GetAttribute("AureliaSection"), query, 1, true) ~= nil
			local anyMatch = false
			for _, control in card:GetChildren() do
				local searchable = control:GetAttribute("AureliaSearch")
				if searchable then local visible = sectionMatch or string.find(searchable, query, 1, true) ~= nil; control.Visible = visible; anyMatch = anyMatch or visible end
			end
			card.Visible = query == "" or anyMatch
		end
	end
end

function Window:SetTheme(theme)
	local overrides = type(theme) == "string" and ThemePresets[theme] or theme
	assert(type(overrides) == "table", "SetTheme expects a preset name or theme table")
	local old = table.clone(Theme); local updated = table.clone(Theme)
	if type(theme) == "string" and theme == "Cyan" then updated.Accent, updated.AccentDark = Color3.fromRGB(39, 201, 255), Color3.fromRGB(11, 101, 138) end
	for key, color in overrides do if Theme[key] and typeof(color) == "Color3" then updated[key] = color end end
	local properties = { "BackgroundColor3", "TextColor3", "ImageColor3", "ScrollBarImageColor3" }
	for _, object in self._screen:GetDescendants() do
		if not object:GetAttribute("AureliaIgnoreTheme") then for role, oldColor in old do
			for _, property in properties do pcall(function() if object[property] == oldColor then object[property] = updated[role] end end) end
			if object:IsA("UIStroke") and object.Color == oldColor then object.Color = updated[role] end
		end end
		if object:IsA("UIGradient") and object.Name == "AccentGradient" then object.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, updated.Accent:Lerp(Color3.fromRGB(74, 134, 255), 0.35)), ColorSequenceKeypoint.new(0.5, updated.Accent), ColorSequenceKeypoint.new(1, updated.Accent:Lerp(Color3.fromRGB(129, 84, 255), 0.35)) }) end
	end
	for key, color in updated do Theme[key] = color end
	self._theme = table.clone(updated)
end

function Window:Dialog(options)
	options = options or {}
	local overlay = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.35, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 40, Parent = self._root })
	local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(390, 210), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 41, Parent = overlay }); round(card, 12); outline(card, 0.15)
	local title = label(card, options.Title or "Message", 15, Theme.Text, Enum.FontWeight.Bold); title.Position = UDim2.fromOffset(20, 18); title.Size = UDim2.new(1, -40, 0, 24); title.ZIndex = 42
	local content = label(card, options.Content or "", 10, Theme.Muted); content.Position = UDim2.fromOffset(20, 54); content.Size = UDim2.new(1, -40, 0, 82); content.TextWrapped = true; content.TextTruncate = Enum.TextTruncate.None; content.TextYAlignment = Enum.TextYAlignment.Top; content.ZIndex = 42
	local actions = new("Frame", { Position = UDim2.new(0, 20, 1, -54), Size = UDim2.new(1, -40, 0, 34), BackgroundTransparency = 1, ZIndex = 42, Parent = card }); new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), Parent = actions })
	local closed = false; local function closeDialog() if closed then return end; closed = true; animate(card, { Size = UDim2.fromOffset(350, 185) }); animate(overlay, { BackgroundTransparency = 1 }); task.delay(0.18, function() if overlay.Parent then overlay:Destroy() end end) end
	local buttons = options.Buttons or { { Name = "Okay" } }
	for _, action in buttons do
		local actionButton = new("TextButton", { Size = UDim2.fromOffset(92, 34), BackgroundColor3 = action.Color or Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = action.Name or "Okay", TextColor3 = Theme.Text, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), ZIndex = 43, Parent = actions }); if action.Color then actionButton:SetAttribute("AureliaIgnoreTheme", true) end; round(actionButton, 7); outline(actionButton, 0.35); hover(actionButton, action.Color or Theme.Raised, Theme.Hover)
		actionButton.Activated:Connect(function() closeDialog(); callback(action.Callback, action.Name) end)
	end
	card.Size = UDim2.fromOffset(350, 185); overlay.BackgroundTransparency = 1; animate(card, { Size = UDim2.fromOffset(390, 210) }); animate(overlay, { BackgroundTransparency = 0.35 })
	return { Close = closeDialog }
end

Window.ShowDialog = Window.Dialog

function Window:OpenThemeSettings()
	self:Dialog({ Title = "Theme settings", Content = "Choose an accent preset. Existing controls update immediately.", Buttons = {
		{ Name = "Cyan", Callback = function() self:SetTheme("Cyan") end },
		{ Name = "Violet", Color = Color3.fromRGB(82, 54, 153), Callback = function() self:SetTheme("Violet") end },
		{ Name = "Rose", Color = Color3.fromRGB(142, 43, 79), Callback = function() self:SetTheme("Rose") end },
	} })
end

function Window:Close()
	if self._destroyed then return end
	self._visible = false
	local target = self._minimized and UDim2.fromOffset(420, 64) or self._targetSize
	animate(self._root, { Size = UDim2.new(target.X.Scale, target.X.Offset - 40, target.Y.Scale, target.Y.Offset - 20), BackgroundTransparency = 0.25 })
	task.delay(0.18, function() self:Destroy() end)
end

function Window:GetFlag(name) return self.Flags[name] end

function Window:AddTab(options)
	if type(options) == "string" then options = { Name = options } end
	local tab = setmetatable({ _window = self, _name = options.Name or "Tab", _description = options.Description or "Manage this category" }, Tab)
	local button = new("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = self._nav }); round(button, 9)
	local indicator = new("Frame", { Position = UDim2.fromOffset(0, 9), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = button }); round(indicator, 2)
	local icon = label(button, options.Icon or "◇", 14, Theme.Muted, Enum.FontWeight.Bold); icon.Position = UDim2.fromOffset(14, 7); icon.Size = UDim2.fromOffset(22, 26); icon.TextXAlignment = Enum.TextXAlignment.Center
	local title = label(button, tab._name, 11, Theme.Muted, Enum.FontWeight.SemiBold); title.Position = UDim2.fromOffset(44, 7); title.Size = UDim2.new(1, -52, 0, 26)
	local page = new("ScrollingFrame", { Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -44, 1, -18), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, Parent = self._content })
	new("UIListLayout", { Padding = UDim.new(0, 12), Parent = page }); new("UIPadding", { PaddingBottom = UDim.new(0, 16), Parent = page })
	tab._button, tab._indicator, tab._icon, tab._title, tab._page = button, indicator, icon, title, page; table.insert(self._tabs, tab)
	button.MouseEnter:Connect(function() if self._active ~= tab then animate(button, { BackgroundTransparency = 0.55 }) end end)
	button.MouseLeave:Connect(function() if self._active ~= tab then animate(button, { BackgroundTransparency = 1 }) end end)
	button.Activated:Connect(function() self:SelectTab(tab) end)
	if not self._active then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(selected)
	for _, tab in self._tabs do local active = tab == selected; tab._page.Visible = active; animate(tab._button, { BackgroundTransparency = active and 0 or 1 }); animate(tab._indicator, { BackgroundTransparency = active and 0 or 1 }); animate(tab._title, { TextColor3 = active and Theme.Text or Theme.Muted }); animate(tab._icon, { TextColor3 = active and Theme.Accent or Theme.Muted }) end
	self._active = selected; self._pageTitle.Text = selected._name; self._pageSub.Text = selected._description; self:_ApplySearch(self._search.Text)
end

function Window:Notify(options)
	if type(options) == "string" then options = { Title = options } end
	local toast = new("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = self._notifications }); round(toast, 11); outline(toast, 0.25)
	local bar = new("Frame", { Position = UDim2.fromOffset(10, 16), Size = UDim2.fromOffset(3, 38), BackgroundColor3 = options.Color or Theme.Accent, BorderSizePixel = 0, Parent = toast }); round(bar, 2)
	local title = label(toast, options.Title or "Notification", 11, Theme.Text, Enum.FontWeight.Bold); title.Position = UDim2.fromOffset(24, 12); title.Size = UDim2.new(1, -36, 0, 20)
	local body = label(toast, options.Content or "", 9, Theme.Muted); body.Position = UDim2.fromOffset(24, 34); body.Size = UDim2.new(1, -36, 0, 22); body.TextWrapped = true; body.TextTruncate = Enum.TextTruncate.None
	animate(toast, { BackgroundTransparency = 0 }); task.delay(options.Duration or 4, function() if toast.Parent then animate(toast, { BackgroundTransparency = 1 }); task.delay(0.2, function() toast:Destroy() end) end end)
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in self._connections do connection:Disconnect() end
	if self._screen and self._screen.Parent then self._screen:Destroy() end
end

function Tab:AddSection(options)
	if type(options) == "string" then options = { Name = options } end
	local section = setmetatable({ _tab = self }, Section)
	local card = new("Frame", { Size = UDim2.new(1, -4, 0, 58), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = self._page }); card:SetAttribute("AureliaSection", string.lower(options.Name or "Section")); round(card, 12); outline(card, 0.35); pad(card, 16); new("UIListLayout", { Padding = UDim.new(0, 9), Parent = card })
	local heading = label(card, options.Name or "Section", 12, Theme.Text, Enum.FontWeight.Bold); heading.Size = UDim2.new(1, 0, 0, 18)
	if options.Description then local desc = label(card, options.Description, 9, Theme.Muted); desc.Size = UDim2.new(1, 0, 0, 16) end
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = card }); section._card = card; return section
end
function Section:_row(height) return new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, Parent = self._card }) end
function Section:_Register(control, options)
	control:SetAttribute("AureliaSearch", string.lower(options.Name or "Control"))
	self._tab._window:_AttachTooltip(control, options.Tooltip)
	return control
end
function Section:_SetFlag(options, value) if options.Flag then self._tab._window.Flags[options.Flag] = value end end

function Section:AddToggle(options)
	local row = self:_Register(self:_row(42), options); local title = label(row, options.Name or "Toggle", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, -58, 0, 19)
	local desc = label(row, options.Description or "", 8, Theme.Muted); desc.Position = UDim2.fromOffset(0, 20); desc.Size = UDim2.new(1, -58, 0, 16)
	local button = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 23), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = row }); round(button, 12)
	local knob = new("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = button }); round(knob, 9)
	local value = options.Default == true; self:_SetFlag(options, value)
	local function render() animate(button, { BackgroundColor3 = value and Theme.AccentDark or Theme.Raised }); animate(knob, { Position = value and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = value and Theme.Accent or Theme.Muted }) end
	render(); button.Activated:Connect(function() value = not value; self:_SetFlag(options, value); render(); callback(options.Callback, value) end)
	return { Set = function(_, v) value = v == true; self:_SetFlag(options, value); render(); callback(options.Callback, value) end, Get = function() return value end }
end

function Section:AddSlider(options)
	local min, max, step = options.Min or 0, options.Max or 100, options.Increment or 1; local value = math.clamp(options.Default or min, min, max)
	local row = self:_Register(self:_row(55), options); local title = label(row, options.Name or "Slider", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, -70, 0, 18)
	local readout = label(row, "", 9, Theme.Accent, Enum.FontWeight.Bold); readout.AnchorPoint = Vector2.new(1, 0); readout.Position = UDim2.fromScale(1, 0); readout.Size = UDim2.fromOffset(66, 18); readout.TextXAlignment = Enum.TextXAlignment.Right
	local track = new("TextButton", { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = row }); round(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track }); round(fill, 3)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(13, 13), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = track }); round(knob, 7); outline(knob)
	local function set(v, call) value = math.clamp(math.round(v / step) * step, min, max); self:_SetFlag(options, value); local alpha = (value - min) / (max - min); fill.Size = UDim2.fromScale(alpha, 1); knob.Position = UDim2.fromScale(alpha, 0.5); readout.Text = tostring(value) .. (options.Suffix or ""); if call then callback(options.Callback, value) end end
	local dragging = false; local function input(i) set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), true) end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; input(i) end end)
	table.insert(self._tab._window._connections, UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then input(i) end end))
	table.insert(self._tab._window._connections, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)); set(value)
	return { Set = function(_, v) set(v, true) end, Get = function() return value end }
end

function Section:AddButton(options)
	if type(options) == "string" then options = { Name = options } end
	local button = self:_Register(new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = options.Name or "Button", TextColor3 = Theme.Text, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), Parent = self._card }), options); round(button, 8); outline(button, 0.4); hover(button, Theme.Raised, Theme.Hover)
	button.Activated:Connect(function() animate(button, { BackgroundColor3 = Theme.AccentDark }); task.delay(0.12, function() if button.Parent then animate(button, { BackgroundColor3 = Theme.Raised }) end end); callback(options.Callback) end); return button
end

function Section:AddInput(options)
	local row = self:_Register(self:_row(58), options); local title = label(row, options.Name or "Input", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, 0, 0, 18)
	local box = new("TextBox", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = options.Placeholder or "Type here...", PlaceholderColor3 = Theme.Muted, Text = options.Default or "", TextColor3 = Theme.Text, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Parent = row }); round(box, 7); outline(box, 0.4); pad(box, 10)
	self:_SetFlag(options, box.Text); box.Focused:Connect(function() animate(box, { BackgroundColor3 = Theme.Hover }) end); box.FocusLost:Connect(function(enter) animate(box, { BackgroundColor3 = Theme.Raised }); self:_SetFlag(options, box.Text); if enter or not options.SubmitOnEnter then callback(options.Callback, box.Text) end end)
	return { Set = function(_, v) box.Text = tostring(v); self:_SetFlag(options, box.Text); callback(options.Callback, box.Text) end, Get = function() return box.Text end }
end

function Section:AddDropdown(options)
	local values, selected = options.Options or {}, options.Default or (options.Options or {})[1]; local holder = self:_Register(self:_row(64), options); self:_SetFlag(options, selected)
	local title = label(holder, options.Name or "Dropdown", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, 0, 0, 18)
	local button = new("TextButton", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = tostring(selected or "Select..."), TextColor3 = Theme.Text, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Parent = holder }); round(button, 7); outline(button, 0.4); pad(button, 10)
	local list = new("Frame", { Position = UDim2.fromOffset(0, 63), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 10, Parent = holder }); round(list, 7); outline(list, 0.2); new("UIListLayout", { Parent = list })
	local open = false
	local function close() open = false; animate(list, { Size = UDim2.new(1, 0, 0, 0) }); animate(holder, { Size = UDim2.new(1, 0, 0, 64) }); task.delay(0.18, function() if not open then list.Visible = false end end) end
	for _, option in values do local choice = new("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = tostring(option), TextColor3 = Theme.Muted, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 11, Parent = list }); hover(choice, Theme.Raised, Theme.Hover); choice.Activated:Connect(function() selected = option; self:_SetFlag(options, selected); button.Text = tostring(option); close(); callback(options.Callback, option) end) end
	button.Activated:Connect(function() open = not open; if open then list.Visible = true; animate(list, { Size = UDim2.new(1, 0, 0, #values * 28) }); animate(holder, { Size = UDim2.new(1, 0, 0, 70 + #values * 28) }) else close() end end)
	return { Set = function(_, v) selected = v; self:_SetFlag(options, selected); button.Text = tostring(v); callback(options.Callback, v) end, Get = function() return selected end }
end

function Section:AddMultiDropdown(options)
	local values, selected = options.Options or {}, {}
	for _, item in options.Default or {} do selected[item] = true end
	local holder = self:_Register(self:_row(64), options)
	local title = label(holder, options.Name or "Multi dropdown", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, 0, 0, 18)
	local button = new("TextButton", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = "", TextColor3 = Theme.Text, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Parent = holder }); round(button, 7); outline(button, 0.4); new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = button })
	local list = new("Frame", { Position = UDim2.fromOffset(0, 63), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 10, Parent = holder }); round(list, 7); outline(list, 0.2); new("UIListLayout", { Parent = list })
	local choices, open = {}, false
	local function getValues() local result = {}; for _, item in values do if selected[item] then table.insert(result, item) end end; return result end
	local function refresh(call)
		local result = getValues(); button.Text = #result > 0 and table.concat(result, ", ") or "Select options..."
		for option, choice in choices do choice.Text = (selected[option] and "[x]  " or "[ ]  ") .. tostring(option); choice.TextColor3 = selected[option] and Theme.Accent or Theme.Muted end
		self:_SetFlag(options, table.clone(result)); if call then callback(options.Callback, table.clone(result)) end
	end
	local function close() open = false; animate(list, { Size = UDim2.new(1, 0, 0, 0) }); animate(holder, { Size = UDim2.new(1, 0, 0, 64) }); task.delay(0.18, function() if not open then list.Visible = false end end) end
	for _, option in values do
		local choice = new("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = "", TextColor3 = Theme.Muted, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 11, Parent = list }); new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = choice }); choices[option] = choice; hover(choice, Theme.Raised, Theme.Hover)
		choice.Activated:Connect(function() selected[option] = not selected[option] or nil; refresh(true) end)
	end
	button.Activated:Connect(function() open = not open; if open then list.Visible = true; animate(list, { Size = UDim2.new(1, 0, 0, #values * 28) }); animate(holder, { Size = UDim2.new(1, 0, 0, 70 + #values * 28) }) else close() end end)
	refresh(false)
	return { Set = function(_, items) selected = {}; for _, item in items do selected[item] = true end; refresh(true) end, Get = function() return getValues() end, Close = close }
end

function Section:AddKeybind(options)
	local row = self:_Register(self:_row(42), options); local title = label(row, options.Name or "Keybind", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, -110, 0, 19)
	local desc = label(row, options.Description or "Press the bound key to activate", 8, Theme.Muted); desc.Position = UDim2.fromOffset(0, 20); desc.Size = UDim2.new(1, -110, 0, 16)
	local value, listening = options.Default or Enum.KeyCode.Unknown, false
	local button = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(94, 30), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = value == Enum.KeyCode.Unknown and "Unbound" or value.Name, TextColor3 = Theme.Accent, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), Parent = row }); round(button, 7); outline(button, 0.35)
	self:_SetFlag(options, value); button.Activated:Connect(function() listening = true; button.Text = "Press a key..."; button.TextColor3 = Theme.Text end)
	table.insert(self._tab._window._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.KeyCode == Enum.KeyCode.Escape then listening = false; button.Text = value == Enum.KeyCode.Unknown and "Unbound" or value.Name; button.TextColor3 = Theme.Accent; return end
			if input.KeyCode ~= Enum.KeyCode.Unknown then value = input.KeyCode; listening = false; button.Text = value.Name; button.TextColor3 = Theme.Accent; self:_SetFlag(options, value); callback(options.Changed, value) end
		elseif not processed and value ~= Enum.KeyCode.Unknown and input.KeyCode == value then callback(options.Callback, value) end
	end))
	return { Set = function(_, key) assert(typeof(key) == "EnumItem", "Keybind:Set expects an Enum.KeyCode"); value = key; button.Text = key.Name; self:_SetFlag(options, value); callback(options.Changed, value) end, Get = function() return value end }
end

function Section:AddColorPicker(options)
	local value = options.Default or Color3.fromRGB(39, 201, 255)
	local hue, saturation, brightness = value:ToHSV()
	local holder = self:_Register(self:_row(64), options)
	local title = label(holder, options.Name or "Color picker", 10, Theme.Text, Enum.FontWeight.SemiBold); title.Size = UDim2.new(1, -140, 0, 18)
	local hex = label(holder, "", 9, Theme.Muted, Enum.FontWeight.SemiBold); hex.AnchorPoint = Vector2.new(1, 0); hex.Position = UDim2.fromScale(1, 0); hex.Size = UDim2.fromOffset(94, 18); hex.TextXAlignment = Enum.TextXAlignment.Right
	local button = new("TextButton", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = holder }); round(button, 7); outline(button, 0.4)
	local preview = new("Frame", { Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = value, BorderSizePixel = 0, Parent = button }); preview:SetAttribute("AureliaIgnoreTheme", true); round(preview, 5); outline(preview, 0.25)
	local buttonText = label(button, "Open color picker", 9, Theme.Text, Enum.FontWeight.Medium); buttonText.Position = UDim2.fromOffset(36, 3); buttonText.Size = UDim2.new(1, -48, 0, 26)

	local panel = new("Frame", { Position = UDim2.fromOffset(0, 65), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = holder }); round(panel, 8); outline(panel, 0.35)
	local sv = new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -48, 0, 130), BackgroundColor3 = Color3.fromHSV(hue, 1, 1), BorderSizePixel = 0, Parent = panel }); sv:SetAttribute("AureliaIgnoreTheme", true); round(sv, 6)
	local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv }); round(white, 6)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = white })
	local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv }); round(black, 6)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = black })
	local svInput = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = sv })
	local svCursor = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 5, Parent = sv }); round(svCursor, 5); outline(svCursor, 0)

	local hueBar = new("Frame", { Position = UDim2.new(1, -28, 0, 10), Size = UDim2.fromOffset(18, 130), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = panel }); round(hueBar, 6)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }), Parent = hueBar })
	local hueInput = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = hueBar })
	local hueCursor = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, hue), Size = UDim2.new(1, 6, 0, 3), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 5, Parent = hueBar }); round(hueCursor, 2); outline(hueCursor, 0.25)
	local rgb = label(panel, "", 9, Theme.Muted, Enum.FontWeight.Medium); rgb.Position = UDim2.fromOffset(10, 146); rgb.Size = UDim2.new(1, -20, 0, 20)

	local function update(call)
		value = Color3.fromHSV(hue, saturation, brightness)
		preview.BackgroundColor3 = value; sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		svCursor.Position = UDim2.fromScale(saturation, 1 - brightness); hueCursor.Position = UDim2.fromScale(0.5, hue)
		local r, g, b = math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5)
		hex.Text = string.format("#%02X%02X%02X", r, g, b); rgb.Text = string.format("RGB  %d, %d, %d", r, g, b)
		self:_SetFlag(options, value); if call then callback(options.Callback, value) end
	end
	local draggingSV, draggingHue = false, false
	local function setSV(input) saturation = math.clamp((input.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1); brightness = 1 - math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1); update(true) end
	local function setHue(input) hue = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1); update(true) end
	svInput.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = true; setSV(input) end end)
	hueInput.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHue = true; setHue(input) end end)
	table.insert(self._tab._window._connections, UserInputService.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then if draggingSV then setSV(input) elseif draggingHue then setHue(input) end end end))
	table.insert(self._tab._window._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV, draggingHue = false, false end end))
	local open = false
	button.Activated:Connect(function() open = not open; panel.Visible = true; buttonText.Text = open and "Close color picker" or "Open color picker"; animate(panel, { Size = UDim2.new(1, 0, 0, open and 176 or 0) }); animate(holder, { Size = UDim2.new(1, 0, 0, open and 247 or 64) }); if not open then task.delay(0.18, function() if not open then panel.Visible = false end end) end end)
	update(false)
	return { Set = function(_, color) if typeof(color) ~= "Color3" then error("ColorPicker:Set expects a Color3", 2) end; value = color; hue, saturation, brightness = color:ToHSV(); update(true) end, Get = function() return value end }
end

function Section:AddLabel(value)
	local item = label(self._card, value, 9, Theme.Muted); item:SetAttribute("AureliaSearch", string.lower(value)); item.Size = UDim2.new(1, 0, 0, 20); item.TextWrapped = true; item.TextTruncate = Enum.TextTruncate.None; item.AutomaticSize = Enum.AutomaticSize.Y; return item
end

return Aurelia
