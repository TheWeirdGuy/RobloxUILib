--!strict
-- Aurelia UI - a dependency-free, premium Roblox interface library.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer
local TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Palette = {
	Background = Color3.fromRGB(7, 10, 15),
	Sidebar = Color3.fromRGB(13, 18, 25),
	Surface = Color3.fromRGB(16, 22, 30),
	SurfaceHover = Color3.fromRGB(21, 29, 39),
	Elevated = Color3.fromRGB(24, 32, 43),
	Border = Color3.fromRGB(39, 51, 66),
	Accent = Color3.fromRGB(39, 201, 255),
	AccentDark = Color3.fromRGB(11, 101, 138),
	Text = Color3.fromRGB(240, 247, 255),
	Muted = Color3.fromRGB(133, 151, 171),
	Success = Color3.fromRGB(72, 219, 154),
	Danger = Color3.fromRGB(255, 98, 122),
}

local function create(className: string, props: {[string]: any}?): Instance
	local instance = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function corner(parent: Instance, radius: number)
	create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent: Instance, color: Color3?, transparency: number?)
	create("UIStroke", {
		Color = color or Palette.Border,
		Transparency = transparency or 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent: Instance, left: number, right: number?, top: number?, bottom: number?)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right or left),
		PaddingTop = UDim.new(0, top or left),
		PaddingBottom = UDim.new(0, bottom or top or left),
		Parent = parent,
	})
end

local function tween(instance: Instance, properties: {[string]: any})
	TweenService:Create(instance, TWEEN, properties):Play()
end

local function text(parent: Instance, value: string, size: number, color: Color3?, weight: Enum.FontWeight?): TextLabel
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size + 8),
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", weight or Enum.FontWeight.Medium),
		Text = value,
		TextColor3 = color or Palette.Text,
		TextSize = size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	}) :: TextLabel
end

local function bindHover(button: GuiButton, target: GuiObject, base: Color3, hover: Color3)
	button.MouseEnter:Connect(function() tween(target, { BackgroundColor3 = hover }) end)
	button.MouseLeave:Connect(function() tween(target, { BackgroundColor3 = base }) end)
end

local function safeCall(callback: ((any) -> ())?, value: any)
	if callback then
		task.spawn(function()
			local ok, message = pcall(callback, value)
			if not ok then warn("[Aurelia UI] Callback error:", message) end
		end)
	end
end

local Aurelia = {}
Aurelia.__index = Aurelia

export type WindowOptions = {
	Title: string?,
	Subtitle: string?,
	ToggleKey: Enum.KeyCode?,
	Size: UDim2?,
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function Aurelia.new(options: WindowOptions?)
	options = options or {}
	assert(LOCAL_PLAYER, "Aurelia UI must be required from a LocalScript")

	local self = setmetatable({}, Window)
	self._connections = {}
	self._tabs = {}
	self._activeTab = nil
	self._visible = true
	self._toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	self._targetSize = options.Size or UDim2.fromOffset(840, 520)

	local screen = create("ScreenGui", {
		Name = "AureliaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 50,
	}) :: ScreenGui
	self._screen = screen
	local parent = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui") or LOCAL_PLAYER:WaitForChild("PlayerGui")
	screen.Parent = parent

	local dim = create("Frame", {
		Name = "Dim",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = screen,
	}) :: Frame

	local root = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self._targetSize,
		BackgroundColor3 = Palette.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = dim,
	}) :: Frame
	self._root = root
	corner(root, 14)
	stroke(root, Color3.fromRGB(54, 73, 92), 0.1)
	create("UISizeConstraint", {
		MinSize = Vector2.new(580, 390),
		MaxSize = Vector2.new(1000, 650),
		Parent = root,
	})

	local accentLine = create("Frame", {
		BackgroundColor3 = Palette.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 5,
		Parent = root,
	})
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 134, 255)),
			ColorSequenceKeypoint.new(0.5, Palette.Accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 84, 255)),
		}),
		Parent = accentLine,
	})

	local sidebar = create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Palette.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 210, 1, 0),
		Parent = root,
	}) :: Frame
	self._sidebar = sidebar
	create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Palette.Border,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = sidebar,
	})

	local brand = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 18),
		Size = UDim2.new(1, -40, 0, 58),
		Parent = sidebar,
	})
	local brandTitle = text(brand, options.Title or "AURELIA", 19, Palette.Text, Enum.FontWeight.Bold)
	brandTitle.Size = UDim2.new(1, 0, 0, 25)
	local brandSub = text(brand, options.Subtitle or "PREMIUM INTERFACE", 9, Palette.Accent, Enum.FontWeight.SemiBold)
	brandSub.Position = UDim2.fromOffset(0, 28)
	brandSub.Size = UDim2.new(1, 0, 0, 16)
	brandSub.TextTransparency = 0.08

	local nav = create("ScrollingFrame", {
		Name = "Navigation",
		Position = UDim2.fromOffset(12, 88),
		Size = UDim2.new(1, -24, 1, -158),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	}) :: ScrollingFrame
	self._nav = nav
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = nav })

	local profile = create("Frame", {
		Position = UDim2.new(0, 12, 1, -58),
		Size = UDim2.new(1, -24, 0, 46),
		BackgroundColor3 = Palette.Surface,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	corner(profile, 10)
	stroke(profile, Palette.Border, 0.4)
	local avatar = create("ImageLabel", {
		Position = UDim2.fromOffset(7, 7),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Palette.Elevated,
		BorderSizePixel = 0,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. LOCAL_PLAYER.UserId .. "&w=100&h=100",
		Parent = profile,
	})
	corner(avatar, 8)
	local username = text(profile, LOCAL_PLAYER.DisplayName, 11, Palette.Text, Enum.FontWeight.SemiBold)
	username.Position = UDim2.fromOffset(48, 6)
	username.Size = UDim2.new(1, -56, 0, 17)
	local status = text(profile, "●  Connected", 9, Palette.Success, Enum.FontWeight.Medium)
	status.Position = UDim2.fromOffset(48, 23)
	status.Size = UDim2.new(1, -56, 0, 15)

	local topbar = create("Frame", {
		Name = "Topbar",
		Position = UDim2.fromOffset(210, 0),
		Size = UDim2.new(1, -210, 0, 76),
		BackgroundTransparency = 1,
		Parent = root,
	}) :: Frame
	self._topbar = topbar
	local pageTitle = text(topbar, "Dashboard", 18, Palette.Text, Enum.FontWeight.Bold)
	pageTitle.Position = UDim2.fromOffset(24, 18)
	pageTitle.Size = UDim2.new(1, -110, 0, 24)
	self._pageTitle = pageTitle
	local pageSub = text(topbar, "Configure your experience", 10, Palette.Muted)
	pageSub.Position = UDim2.fromOffset(24, 43)
	pageSub.Size = UDim2.new(1, -110, 0, 17)
	self._pageSubtitle = pageSub

	local keyBadge = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 24),
		Size = UDim2.fromOffset(72, 28),
		BackgroundColor3 = Palette.Surface,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		Text = self._toggleKey.Name,
		TextColor3 = Palette.Muted,
		TextSize = 9,
		Parent = topbar,
	})
	corner(keyBadge, 7)
	stroke(keyBadge, Palette.Border, 0.35)

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(210, 76),
		Size = UDim2.new(1, -210, 1, -76),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
	}) :: Frame
	self._content = content

	local notifications = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(290, 300),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	self._notifications = notifications
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifications,
	})

	-- Dragging is restricted to the top bar to avoid interfering with controls.
	local dragging = false
	local dragStart = Vector2.zero
	local startPosition = root.Position
	table.insert(self._connections, topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = root.Position
		end
	end))
	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end))
	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self._toggleKey then self:SetVisible(not self._visible) end
	end))

	root.Size = UDim2.fromOffset(760, 460)
	root.BackgroundTransparency = 1
	tween(root, { Size = self._targetSize, BackgroundTransparency = 0 })
	return self
end

function Window:SetVisible(visible: boolean)
	self._visible = visible
	local target = self._targetSize
	local compact = UDim2.new(target.X.Scale, target.X.Offset - 50, target.Y.Scale, target.Y.Offset - 40)
	if visible then
		self._screen.Enabled = true
		self._root.Size = compact
		self._root.BackgroundTransparency = 0.15
		tween(self._root, { Size = target, BackgroundTransparency = 0 })
	else
		tween(self._root, { Size = compact, BackgroundTransparency = 0.2 })
		task.delay(0.18, function()
			if not self._visible and self._screen.Parent then self._screen.Enabled = false end
		end)
	end
end

function Window:AddTab(options)
	if type(options) == "string" then options = { Name = options } end
	local tab = setmetatable({}, Tab)
	tab._window = self
	tab._name = options.Name or "Tab"
	tab._description = options.Description or "Manage " .. string.lower(tab._name)

	local button = create("TextButton", {
		Name = tab._name,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Palette.Sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self._nav,
	}) :: TextButton
	corner(button, 9)
	local indicator = create("Frame", {
		Position = UDim2.fromOffset(0, 9),
		Size = UDim2.fromOffset(3, 22),
		BackgroundColor3 = Palette.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	})
	corner(indicator, 2)
	local icon = text(button, options.Icon or "◇", 14, Palette.Muted, Enum.FontWeight.Bold)
	icon.Position = UDim2.fromOffset(14, 7)
	icon.Size = UDim2.fromOffset(22, 26)
	icon.TextXAlignment = Enum.TextXAlignment.Center
	local label = text(button, tab._name, 11, Palette.Muted, Enum.FontWeight.SemiBold)
	label.Position = UDim2.fromOffset(44, 7)
	label.Size = UDim2.new(1, -52, 0, 26)

	local page = create("ScrollingFrame", {
		Name = tab._name .. "Page",
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -44, 1, -18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Palette.Accent,
		ScrollBarImageTransparency = 0.15,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self._content,
	}) :: ScrollingFrame
	create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
	create("UIPadding", { PaddingBottom = UDim.new(0, 16), Parent = page })

	tab._button = button
	tab._indicator = indicator
	tab._label = label
	tab._icon = icon
	tab._page = page
	table.insert(self._tabs, tab)

	button.MouseEnter:Connect(function()
		if self._activeTab ~= tab then tween(button, { BackgroundTransparency = 0.55, BackgroundColor3 = Palette.Surface }) end
	end)
	button.MouseLeave:Connect(function()
		if self._activeTab ~= tab then tween(button, { BackgroundTransparency = 1 }) end
	end)
	button.Activated:Connect(function() self:SelectTab(tab) end)
	if not self._activeTab then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(selected)
	for _, tab in self._tabs do
		local active = tab == selected
		tab._page.Visible = active
		tween(tab._button, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = Palette.Surface })
		tween(tab._indicator, { BackgroundTransparency = active and 0 or 1 })
		tween(tab._label, { TextColor3 = active and Palette.Text or Palette.Muted })
		tween(tab._icon, { TextColor3 = active and Palette.Accent or Palette.Muted })
	end
	self._activeTab = selected
	self._pageTitle.Text = selected._name
	self._pageSubtitle.Text = selected._description
end

function Window:Notify(options)
	if type(options) == "string" then options = { Title = options } end
	local toast = create("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = Palette.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self._notifications,
	})
	corner(toast, 11)
	stroke(toast, Palette.Border, 0.25)
	local bar = create("Frame", { Size = UDim2.fromOffset(3, 38), Position = UDim2.fromOffset(10, 16), BackgroundColor3 = options.Color or Palette.Accent, BorderSizePixel = 0, Parent = toast })
	corner(bar, 2)
	local title = text(toast, options.Title or "Notification", 11, Palette.Text, Enum.FontWeight.Bold)
	title.Position = UDim2.fromOffset(24, 12)
	title.Size = UDim2.new(1, -36, 0, 20)
	local body = text(toast, options.Content or "", 9, Palette.Muted)
	body.Position = UDim2.fromOffset(24, 34)
	body.Size = UDim2.new(1, -36, 0, 22)
	body.TextWrapped = true
	body.TextTruncate = Enum.TextTruncate.None
	tween(toast, { BackgroundTransparency = 0 })
	task.delay(options.Duration or 4, function()
		if toast.Parent then
			tween(toast, { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 0) })
			task.delay(0.2, function() toast:Destroy() end)
		end
	end)
end

function Window:Destroy()
	for _, connection in self._connections do connection:Disconnect() end
	self._screen:Destroy()
end

function Tab:AddSection(options)
	if type(options) == "string" then options = { Name = options } end
	local section = setmetatable({}, Section)
	section._tab = self

	local card = create("Frame", {
		Name = options.Name or "Section",
		Size = UDim2.new(1, -4, 0, 58),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Palette.Surface,
		BorderSizePixel = 0,
		Parent = self._page,
	})
	corner(card, 12)
	stroke(card, Palette.Border, 0.35)
	padding(card, 16, 16, 14, 16)
	local layout = create("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	local heading = text(card, options.Name or "Section", 12, Palette.Text, Enum.FontWeight.Bold)
	heading.Size = UDim2.new(1, 0, 0, 18)
	if options.Description then
		local description = text(card, options.Description, 9, Palette.Muted)
		description.Size = UDim2.new(1, 0, 0, 16)
	end
	local divider = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Palette.Border, BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = card })
	section._card = card
	section._layout = layout
	section._divider = divider
	return section
end

function Section:_row(height: number)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Palette.Surface,
		BorderSizePixel = 0,
		Parent = self._card,
	})
	return row
end

function Section:AddToggle(options)
	local row = self:_row(42)
	local title = text(row, options.Name or "Toggle", 10, Palette.Text, Enum.FontWeight.SemiBold)
	title.Size = UDim2.new(1, -58, 0, 19)
	local description = text(row, options.Description or "", 8, Palette.Muted)
	description.Position = UDim2.fromOffset(0, 20)
	description.Size = UDim2.new(1, -58, 0, 16)

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(42, 23),
		BackgroundColor3 = Palette.Elevated,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}) :: TextButton
	corner(button, 12)
	local knob = create("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = Palette.Muted, BorderSizePixel = 0, Parent = button })
	corner(knob, 9)

	local value = options.Default == true
	local function render(instant: boolean?)
		local buttonProps = { BackgroundColor3 = value and Palette.AccentDark or Palette.Elevated }
		local knobProps = { Position = value and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = value and Palette.Accent or Palette.Muted }
		if instant then
			for key, property in buttonProps do (button :: any)[key] = property end
			for key, property in knobProps do (knob :: any)[key] = property end
		else
			tween(button, buttonProps); tween(knob, knobProps)
		end
	end
	render(true)
	button.Activated:Connect(function() value = not value; render(); safeCall(options.Callback, value) end)
	return {
		Set = function(_, newValue) value = newValue == true; render(); safeCall(options.Callback, value) end,
		Get = function() return value end,
	}
end

function Section:AddSlider(options)
	local minimum = options.Min or 0
	local maximum = options.Max or 100
	local increment = options.Increment or 1
	local value = math.clamp(options.Default or minimum, minimum, maximum)
	local row = self:_row(55)
	local title = text(row, options.Name or "Slider", 10, Palette.Text, Enum.FontWeight.SemiBold)
	title.Size = UDim2.new(1, -70, 0, 18)
	local readout = text(row, tostring(value) .. (options.Suffix or ""), 9, Palette.Accent, Enum.FontWeight.Bold)
	readout.AnchorPoint = Vector2.new(1, 0)
	readout.Position = UDim2.fromScale(1, 0)
	readout.Size = UDim2.fromOffset(66, 18)
	readout.TextXAlignment = Enum.TextXAlignment.Right
	local track = create("TextButton", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Palette.Elevated,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}) :: TextButton
	corner(track, 3)
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Palette.Accent, BorderSizePixel = 0, Parent = track })
	corner(fill, 3)
	local knob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(13, 13), BackgroundColor3 = Palette.Text, BorderSizePixel = 0, Parent = track })
	corner(knob, 7)
	stroke(knob, Palette.Accent, 0)

	local dragging = false
	local function set(newValue, call: boolean?)
		value = math.clamp(math.round(newValue / increment) * increment, minimum, maximum)
		local alpha = (value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		readout.Text = tostring(value) .. (options.Suffix or "")
		if call then safeCall(options.Callback, value) end
	end
	local function fromInput(input)
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		set(minimum + (maximum - minimum) * alpha, true)
	end
	track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; fromInput(input) end end)
	table.insert(self._tab._window._connections, UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromInput(input) end end))
	table.insert(self._tab._window._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
	set(value)
	return { Set = function(_, newValue) set(newValue, true) end, Get = function() return value end }
end

function Section:AddButton(options)
	if type(options) == "string" then options = { Name = options } end
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Palette.Elevated,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		Text = options.Name or "Button",
		TextColor3 = Palette.Text,
		TextSize = 10,
		Parent = self._card,
	}) :: TextButton
	corner(button, 8)
	stroke(button, Palette.Border, 0.4)
	bindHover(button, button, Palette.Elevated, Palette.SurfaceHover)
	button.Activated:Connect(function()
		tween(button, { BackgroundColor3 = Palette.AccentDark })
		task.delay(0.12, function() if button.Parent then tween(button, { BackgroundColor3 = Palette.Elevated }) end end)
		safeCall(options.Callback, nil)
	end)
	return button
end

function Section:AddInput(options)
	local row = self:_row(58)
	local title = text(row, options.Name or "Input", 10, Palette.Text, Enum.FontWeight.SemiBold)
	title.Size = UDim2.new(1, 0, 0, 18)
	local box = create("TextBox", {
		Position = UDim2.fromOffset(0, 25),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Palette.Elevated,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		PlaceholderText = options.Placeholder or "Type here...",
		PlaceholderColor3 = Palette.Muted,
		Text = options.Default or "",
		TextColor3 = Palette.Text,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	}) :: TextBox
	corner(box, 7); stroke(box, Palette.Border, 0.4); padding(box, 10, 10, 0, 0)
	box.Focused:Connect(function() tween(box, { BackgroundColor3 = Palette.SurfaceHover }) end)
	box.FocusLost:Connect(function(enterPressed) tween(box, { BackgroundColor3 = Palette.Elevated }); if enterPressed or not options.SubmitOnEnter then safeCall(options.Callback, box.Text) end end)
	return { Set = function(_, value) box.Text = tostring(value) end, Get = function() return box.Text end }
end

function Section:AddDropdown(options)
	local values = options.Options or {}
	local selected = options.Default or values[1]
	local holder = self:_row(64)
	local title = text(holder, options.Name or "Dropdown", 10, Palette.Text, Enum.FontWeight.SemiBold)
	title.Size = UDim2.new(1, 0, 0, 18)
	local button = create("TextButton", {
		Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Palette.Elevated, BorderSizePixel = 0,
		AutoButtonColor = false, Text = tostring(selected or "Select..."), TextColor3 = Palette.Text, TextSize = 9,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
	}) :: TextButton
	corner(button, 7); stroke(button, Palette.Border, 0.4); padding(button, 10, 30, 0, 0)
	local arrow = text(button, "⌄", 13, Palette.Accent, Enum.FontWeight.Bold)
	arrow.AnchorPoint = Vector2.new(1, 0); arrow.Position = UDim2.new(1, 22, 0, 2); arrow.Size = UDim2.fromOffset(20, 26); arrow.TextXAlignment = Enum.TextXAlignment.Center
	local open = false
	local list = create("Frame", { Position = UDim2.fromOffset(0, 63), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Palette.Elevated, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 10, Parent = holder })
	corner(list, 7); stroke(list, Palette.Border, 0.2)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local optionButtons = {}
	for _, option in values do
		local optionButton = create("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Palette.Elevated, BorderSizePixel = 0, AutoButtonColor = false, Text = tostring(option), TextColor3 = Palette.Muted, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), ZIndex = 11, Parent = list }) :: TextButton
		bindHover(optionButton, optionButton, Palette.Elevated, Palette.SurfaceHover)
		optionButton.Activated:Connect(function()
			selected = option; button.Text = tostring(option); open = false
			tween(list, { Size = UDim2.new(1, 0, 0, 0) }); tween(holder, { Size = UDim2.new(1, 0, 0, 64) })
			task.delay(0.18, function() list.Visible = false end); safeCall(options.Callback, selected)
		end)
		table.insert(optionButtons, optionButton)
	end
	button.Activated:Connect(function()
		open = not open; list.Visible = true
		local listHeight = #values * 28
		tween(list, { Size = UDim2.new(1, 0, 0, open and listHeight or 0) })
		tween(holder, { Size = UDim2.new(1, 0, 0, open and 70 + listHeight or 64) })
		tween(arrow, { Rotation = open and 180 or 0 })
		if not open then task.delay(0.18, function() if not open then list.Visible = false end end) end
	end)
	return { Set = function(_, value) selected = value; button.Text = tostring(value); safeCall(options.Callback, value) end, Get = function() return selected end }
end

function Section:AddLabel(value: string)
	local label = text(self._card, value, 9, Palette.Muted)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.None
	label.AutomaticSize = Enum.AutomaticSize.Y
	return label
end

Aurelia.Palette = Palette
return Aurelia
