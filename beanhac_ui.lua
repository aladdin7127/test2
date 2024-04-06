local library = {
	style = {
		window = {
			backgroundcolour = Color3.new(),
			outlinecolour = Color3.fromRGB(48,48,48)
		},

		maincolour = Color3.fromRGB(19,19,19),
		backgroundcolour = Color3.fromRGB(12,12,12),
		outlinecolour = Color3.fromRGB(51,51,51),

		accentcolour = Color3.fromRGB(170,85,235),

		otherfontcolour = Color3.fromRGB(140,140,140),
		objectcolour = Color3.fromRGB(120,120,120),
		fontcolour = Color3.fromRGB(205,205,205),
		infocolour = Color3.fromRGB(180,180,180),

		gradientstartcolour = Color3.fromRGB(41,41,41),
		gradientendcolour = Color3.fromRGB(16,16,16),

		riskycolour = Color3.fromRGB(255,125,55),
		font = Font.fromId(12187362578, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	},

	flags = {},
	opened = {},
	connections = {},
	timer = tick(),
	
	unloading = false,
	togglebind = Enum.KeyCode.Delete,

	white = Color3.new(1,1,1),
}

pcall(game.Destroy, game.Players.LocalPlayer.PlayerGui:FindFirstChild("beanhac_ui"))

local camera = workspace.CurrentCamera
local userinputservice = game:GetService("UserInputService")
local textservice = game:GetService("TextService")
local runservice = game:GetService("RunService")
local stats = game:GetService("Stats")
local mouse = game:GetService("Players").LocalPlayer:GetMouse()
local tweenservice = game:GetService("TweenService")
local coregui = game.CoreGui
local contentprovider = game:GetService("ContentProvider")

local defaultcallback = function() end
local gui = Instance.new("ScreenGui")

if runservice:IsStudio() then
	gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
else
	if gethui then
		gui.Parent = gethui()
	elseif syn and syn.protect_gui then 
		syn.protect_gui(gui)
		gui.Parent = coregui
	elseif coregui:FindFirstChild("RobloxGui") then
		gui.Parent = coregui:FindFirstChild("RobloxGui")
	else
		gui.Parent = coregui
	end
end

function library:create(class, properties)
	local object = class

	if type(class) == "string" then
		object = Instance.new(class)
	end

	for p, v in properties do
		local success = pcall(function()
			object[p] = v
		end)

		if not success then
			warn(`failed to set {p} = {v} for {object}`)
		end
	end

	return object
end

function library:sectoms(v)
	return math.floor(v*1000)
end

function library:getdarkercolour(colour, amount)
	local h, s, v = colour:ToHSV()
	return Color3.fromHSV(h, s, v / (amount or 1.5))
end

function library:updateaccent(colour)
	library.events.updateaccent:Fire(colour)
end

function library:highlight(h_instance, instance, properties, d_properties, ignore)
	ignore = ignore or function()
		return false
	end
	
	h_instance.MouseEnter:Connect(function()
		for property, value in properties do
			if ignore() then
				continue
			end
			
			instance[property] = value
		end
	end)
	
	h_instance.MouseLeave:Connect(function()
		for property, value in d_properties do
			if ignore() then
				continue
			end
			
			instance[property] = value
		end
	end)
end

library.style.darkeraccentcolour = library:getdarkercolour(library.style.accentcolour)
library.style.gradientaccentcolour = library:getdarkercolour(library.style.accentcolour, 2)

function library:createlabel(properties)
	local object = library:create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = library.style.font,
		TextColor3 = library.style.fontcolour,
		TextSize = 15,
		--TextStrokeTransparency = 0,
	})

	return library:create(object, properties)
end

function library:isoveropened()
	for frame, _ in next, library.opened do
		local pos, size = frame.AbsolutePosition, frame.AbsoluteSize

		if mouse.X >= pos.X
			and mouse.X <= pos.X + size.X
			and mouse.Y >= pos.Y 
			and mouse.Y <= pos.Y + size.Y then
			
			return true
		end
	end
end

function library.textbounds(text, size, width)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = library.style.font
	params.Size = size
	params.Width = width

	return textservice:GetTextBoundsAsync(params)
end

function library.vector2_udim2(vector)
	return UDim2.fromOffset(vector.X, vector.Y)
end

function mapvalue(value, mina, maxa, minb, maxb)
	return (1 - ((value - mina) / (maxa - mina))) * minb + ((value - mina) / (maxa - mina)) * maxb
end

function library:unload()
	library.unloading = true

	for _, c in library.connections do
		c:Disconnect()
	end

	gui:Destroy()
end

local fps_timer = tick()
local fps_counter = 0
library.fps = 60

table.insert(library.connections, runservice.RenderStepped:Connect(function(delta)
	library.delta = delta
	fps_counter += 1

	if (tick() - fps_timer) >= 1 then
		library.fps = fps_counter
		fps_counter = 0
		fps_timer = tick()
	end

	--library.ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
end))

function library:makedraggable(instance, height)
	instance.Active = true

	instance.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local position = Vector2.new(mouse.X - instance.AbsolutePosition.X, mouse.Y - instance.AbsolutePosition.Y)

			if position.Y > (height or 40) then
				return
			end

			while userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				if library.unloading then
					break
				end
				
				instance.Position = UDim2.fromOffset(mouse.X - position.X + (instance.Size.X.Offset * instance.AnchorPoint.X), mouse.Y - (gui.IgnoreGuiInset and -36 or 0) - position.Y + (instance.Size.Y.Offset * instance.AnchorPoint.Y))
				task.wait()
			end
		end
	end)
end

local baseaddons = {}

do
	local objects = {}
	
	function objects:colourpicker(flag, options)
		assert(flag, "colourpicker must have a set flag!") 
		assert(options.default, "colourpicker must have a set default value!")
		
		local mainlabel = self.label
		local groupbox = self.groupbox
		
		local colourpicker = {
			value = options.default,
			text = options.text or "colourpicker",
			callback = options.callback or defaultcallback,
			transparency = options.transparency or 0,
		}
		
		library.flags[flag] = colourpicker
		
		function colourpicker:sethsv(colour)
			local h,s,v = colour:ToHSV()
			
			colourpicker.hue = h
			colourpicker.sat = s
			colourpicker.vib = v
		end
		
		colourpicker:sethsv(colourpicker.value)
		
		local displayouter = library:create("Frame", {
			BackgroundColor3 = library.style.backgroundcolour,
			BorderColor3 = Color3.new(),
			--Position = UDim2.new(1, -30, 0, 2.5),
			Size = UDim2.new(0, 18, 0, 10),
			ZIndex = 8,
			Parent = mainlabel
		})
		
		local displayinner = library:create("Frame", {
			BackgroundColor3 = library.white,
			BorderColor3 = Color3.new(),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 9,
			Parent = displayouter
		})
		
		local displaygradient = library:create("UIGradient", {
			Rotation = 90,
			Parent = displayinner,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colourpicker.value),
				ColorSequenceKeypoint.new(1, library:getdarkercolour(colourpicker.value)),
			})
		})
		
		local pickerouter = library:create("Frame", {
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			Position = UDim2.fromOffset(displayinner.AbsolutePosition.X, displayinner.AbsolutePosition.Y + 18),
			Visible = false,
			ZIndex = 25,
			Size = UDim2.fromOffset(options.transparency and 245 or 225, 200),
			Name = "colourpicker",
			Parent = gui,
		})
		
		displayinner:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			pickerouter.Position = UDim2.fromOffset(displayinner.AbsolutePosition.X, displayinner.AbsolutePosition.Y + 18)
		end)
		
		local pickerinner = library:create("Frame", {
			BackgroundColor3 = library.style.maincolour,
			BorderColor3 = library.style.outlinecolour,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 25,
			Parent = pickerouter,
		})
		
		local satmapouter = library:create("Frame", {
			BorderColor3 = Color3.new(),
			BackgroundColor3 = Color3.new(),
			Position = UDim2.new(0, 4, 0, 5),
			Size = UDim2.new(0, 190, 0, 190),
			ZIndex = 26,
			Parent = pickerinner,
		})
		
		local satmapinner = library:create("Frame", {
			BorderColor3 = library.style.outlinecolour,
			BackgroundColor3 = library.style.maincolour,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 27,
			Parent = satmapouter,
		})
		
		local satmap = library:create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 28,
			Image = "rbxassetid://4155801252",
			Parent = satmapinner,
		})
		
		local satmap = library:create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 28,
			Image = "rbxassetid://4155801252",
			Parent = satmapinner,
		})
		
		--[[local cursorouter = library:create("ImageLabel", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 25, 0, 25),
			ZIndex = 29,
			Image = "rbxassetid://15931665651",
			Parent = satmap,
		})]]
		
		local cursorouter = library:create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 3, 0, 3),
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			ZIndex = 29,
			Parent = satmap,
		})

		local cursorinner = library:create("Frame", {
			Size = UDim2.new(1 ,0, 1, 0),
			--Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = library.white,
			BorderSizePixel = 0,
			ZIndex = 30,
			Parent = cursorouter,
		})
		
		local hueouter = library:create("Frame", {
			BorderColor3 = Color3.new(),
			BackgroundColor3 = Color3.new(),
			Size = UDim2.new(0, 18, 1, -10),
			Position = UDim2.new(0,202,0,5),
			ZIndex = 26,
			Parent = pickerinner,
		})
		
		local hueinner = library:create("Frame", {
			BackgroundColor3 = library.white,
			BorderColor3 = library.style.outlinecolour,
			Size = UDim2.new(1,0,1,0),
			ZIndex = 27,
			Parent = hueouter,
		})
		
		local huecursor = library:create("Frame", { 
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 28,
			Parent = hueinner,
		})
		
		local sequence = {}
		
		for hue = 0, 1, 0.1 do
			table.insert(sequence, ColorSequenceKeypoint.new(hue, Color3.fromHSV(hue, 1, 1)))
		end
		
		local huegradient = library:create("UIGradient", {
			Color = ColorSequence.new(sequence),
			Rotation = 90,
			Parent = hueinner,
		})
		
		local transparencyouter, transparencyinner, transparencycursor, transparencygradient

		if options.transparency then
			transparencyouter = library:create("Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(0, 18, 1, -10),
				Position = UDim2.new(0,224,0,5),
				ZIndex = 29,
				Parent = pickerinner,
			})

			transparencyinner = library:create("Frame", {
				BackgroundColor3 = library.white,
				BorderColor3 = library.style.outlinecolour,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 29,
				Parent = transparencyouter,
			})
			
			transparencygradient = library:create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, library.style.maincolour),
					ColorSequenceKeypoint.new(1, colourpicker.value),
				}),
				Parent = transparencyinner
			})

			transparencycursor = library:create("Frame", { 
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0, 0.5),
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 0, 1),
				ZIndex = 31,
				Parent = transparencyinner,
			})
		end
		
		function colourpicker:update()
			colourpicker.value = Color3.fromHSV(colourpicker.hue, colourpicker.sat, colourpicker.vib)
			satmap.BackgroundColor3 = Color3.fromHSV(colourpicker.hue, 1, 1)

			displaygradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colourpicker.value),
				ColorSequenceKeypoint.new(1, library:getdarkercolour(colourpicker.value)),
			})
			displayinner.BackgroundTransparency = colourpicker.transparency

			if transparencyinner then
				transparencycursor.Position = UDim2.new(0, 0, 1-colourpicker.transparency, 0)
				transparencygradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, library.style.maincolour),
					ColorSequenceKeypoint.new(1, colourpicker.value),
				})
			end

			cursorouter.Position = UDim2.new(colourpicker.sat, 0, 1 - colourpicker.vib, 0)
			huecursor.Position = UDim2.new(0, 0, colourpicker.hue, 0)
			
			if colourpicker.callback then
				colourpicker.callback(colourpicker)
			end
			
			library.flags[flag] = colourpicker
		end
		
		function colourpicker:open()
			for frame, _ in library.opened do
				if frame.Name == "colourpicker" then
					frame.Visible = false
					library.opened[frame] = nil
				end
			end
			
			pickerouter.Visible = true
			library.opened[pickerouter] = true
		end
		
		function colourpicker:close()
			pickerouter.Visible = false
			library.opened[pickerouter] = nil
		end
		
		function colourpicker:setfromhsv(hsv, t)
			colourpicker.transparency = t or 0
			colourpicker:sethsv(Color3.fromHSV(table.unpack(hsv)))
			colourpicker:update()
		end
		
		satmap.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				while userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local min_x = satmap.AbsolutePosition.X
					local max_x = min_x + satmap.AbsoluteSize.X
					local x = math.clamp(mouse.X, min_x, max_x)

					local min_y = satmap.AbsolutePosition.Y
					local max_y = min_y + satmap.AbsoluteSize.Y
					local y = math.clamp(mouse.Y, min_y, max_y)

					colourpicker.sat = (x - min_x) / (max_x - min_x)
					colourpicker.vib = 1 - ((y - min_y) / (max_y - min_y))
					colourpicker:update()

					task.wait()
				end
			end
		end)

		hueinner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				while userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local min = hueinner.AbsolutePosition.Y
					local max = min + hueinner.AbsoluteSize.Y
					local y = math.clamp(mouse.Y, min, max)

					colourpicker.hue = ((y - min) / (max - min))
					colourpicker:update()

					task.wait()
				end
			end
		end)
		
		displayinner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:isoveropened() then
				if pickerouter.Visible then
					colourpicker:close()
				else
					colourpicker:open()
				end
			end
		end)
		
		if transparencyinner then
			transparencyinner.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					while userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						local min = transparencyinner.AbsolutePosition.Y
						local max = min + transparencyinner.AbsoluteSize.Y
						local y = math.clamp(mouse.Y, min, max)

						colourpicker.transparency = 1 - ((y - min) / (max - min))
						colourpicker:update()

						task.wait()
					end
				end
			end)
		end
		
		colourpicker:update()
		colourpicker.display = displayinner
		
		if self.type ~= "toggle" then
			groupbox:addblank(6)
		end

		groupbox:resize()
		
		return colourpicker
	end
	
	function objects:keypicker(flag, options)
		assert(flag, "keypicker must have a set flag!")
		assert(options.default, "keypicker must have a set default value!")
		
		local mainlabel = self.label
		local groupbox = self.groupbox

		local keypicker = {
			value = options.default,
			mode = options.mode or "hold",
			callback = options.callback or defaultcallback,
			toggled = false,
		}
		
		library.flags[flag] = keypicker
		
		local keyouter = library:create("Frame", {
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			BorderSizePixel = 2,
			Position = UDim2.new(1, -36, 0, 0),
			Size = UDim2.new(0, 24, 0, 10),
			ZIndex = 8,
			
			Parent = mainlabel,
		})
		
		local keyinner = library:create("Frame", {
			BackgroundColor3 = library.style.backgroundcolour,
			BorderColor3 = library.style.outlinecolour,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 8,

			Parent = keyouter,
		})
		
		local displaylabel = library:createlabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 12,
			Text = string.upper(keypicker.value),
			ZIndex = 9,
			Parent = keyinner,
		})
		
		local modeouter = library:create("Frame", {
			Name = "keypicker",
			BorderColor3 = Color3.new(),
			BackgroundColor3 = Color3.new(),
			BorderSizePixel = 2,
			Position = UDim2.fromOffset(mainlabel.AbsolutePosition.X + mainlabel.AbsoluteSize.X + 4, mainlabel.AbsolutePosition.Y + 1),
			Size = UDim2.new(0, 60, 0, 45 + 2),
			Visible = false,
			ZIndex = 50,
			Parent = gui,
		})
		
		local modeinner = library:create("Frame", {
			BackgroundColor3 = library.style.backgroundcolour,
			BorderColor3 = library.style.outlinecolour,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 51,
			Parent = modeouter
		})
		
		library:create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = modeinner,
		})
		
		local buttons = {}
		
		for index, mode in {"always", "toggle", "hold"} do
			local button = {}
			
			local label = library:createlabel({
				Active = false,
				Size = UDim2.new(1,0,0,15),
				TextColor3 = library.style.objectcolour,
				TextSize = 12,
				Text = mode,
				ZIndex = 52,
				Parent = modeinner,
			})
			
			function button:select()
				for _, v in buttons do
					v:deselect()
				end
				
				keypicker.mode = mode
				
				label.TextColor3 = library.style.accentcolour
				modeouter.Visible = false
			end
			
			function button:deselect()
				keypicker.mode = nil
				
				label.TextColor3 = library.style.objectcolour
			end
			
			label.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					button:select()
				end
			end)
			
			if mode == keypicker.mode then
				button:select()
			end
			
			buttons[mode] = button
		end
		
		local picking  = false
		
		keyouter.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:isoveropened() then
				picking = true

				displaylabel.Text = "..."

				task.wait(0.2)

				local c
				c = userinputservice.InputBegan:Connect(function(input)
					local key

					if input.UserInputType == Enum.UserInputType.Keyboard then
						key = input.KeyCode.Name
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
						key = "MB1"
					elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
						key = "MB2"
					elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
						key = "MB3"
					end

					picking = false

					displaylabel.Text = key
					keypicker.value = key

					if keypicker.callback then
						keypicker.callback(keypicker)
					end
					
					library.flags[flag] = keypicker
					
					c:Disconnect()
				end)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not library:isoveropened() then
				modeouter.Visible = not modeouter.Visible
			end
		end)
		
		function keypicker:getstate()
			if keypicker.mode == "always" then
				return true
			elseif keypicker.mode == "hold" then
				if keypicker.value == "none" then
					return false
				end

				local key = keypicker.value

				if key == "MB1" or key == "MB2" then
					return
						key == "MB1" and userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
						key == "MB2" and userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or 
						key == "MB3" and userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
				else
					return userinputservice:IsKeyDown(Enum.KeyCode[keypicker.value])
				end
			else
				return keypicker.toggled
			end
		end
		
		table.insert(library.connections, userinputservice.InputBegan:Connect(function(input, gp)
			if not picking and not gp then
				if keypicker.mode == "toggle" then
					keypicker.toggled = not keypicker.toggled
				end
			end
		end))
		
		if self.type == "toggle" then
			groupbox:addblank(0)
		else
			groupbox:addblank(16)
		end
		
		groupbox:resize()

		return keypicker
	end
	
	baseaddons.__index = objects
	baseaddons.__namecall = function(t, k, ...)
		return objects[k](...)
	end
end

local basegroupbox = {}

do
	local objects = {}

	function objects:toggle(flag, options)
		assert(flag, "toggle must have a set flag!")
		options = options or {}

		local toggle = {
			value = options.default or false,
			callback = options.callback or defaultcallback,
			risky = options.risky or false,
			text = options.text or "toggle",
		}

		library.flags[flag] = toggle

		local groupbox = self
		local container = groupbox.container

		local toggleouter = library:create("Frame", {
			Size = UDim2.new(0,6,0,6),
			ZIndex = 7,
			Parent = container,

			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
		})

		local toggleinner = library:create("Frame", {
			Size = UDim2.new(1,0,1,0),
			ZIndex = 7,
			Parent = toggleouter,
			BorderSizePixel = 0,

			BackgroundColor3 = library.white,
		})

		local togglegradient = library:create("UIGradient", {
			Parent = toggleinner,
			Rotation = 90,

			Color = toggle.value and ColorSequence.new({
				ColorSequenceKeypoint.new(0, library.style.accentcolour),
				ColorSequenceKeypoint.new(1, library.style.gradientaccentcolour),
			}) or ColorSequence.new({
				ColorSequenceKeypoint.new(0, library:getdarkercolour(library.style.gradientstartcolour, 0.75)),
				ColorSequenceKeypoint.new(1, library.style.gradientendcolour),
			})
		})

		local togglelabel = library:createlabel({
			Size = UDim2.new(0,210,1,0),
			Position = UDim2.new(1,6,0,0),
			Text = toggle.text,
			TextSize = 13,
			Parent = toggleinner,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 7,
		})
		
		library:create("UIListLayout", {
			Padding = UDim.new(0, 4),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = togglelabel,
		})
		
		local width = library.textbounds(toggle.text, 13, camera.ViewportSize.X).X
		local togglearea = library:create("Frame", {
			Parent = toggleouter,
			BackgroundTransparency = 1,
			Size = UDim2.new(0,20 + width,1,8),
			Position = UDim2.new(0,-4,0,-4),
			ZIndex = 8,
		})

		function toggle:display()
			togglegradient.Color = toggle.value and ColorSequence.new({
				ColorSequenceKeypoint.new(0, library.style.accentcolour),
				ColorSequenceKeypoint.new(1, library.style.gradientaccentcolour),
			}) or ColorSequence.new({
				ColorSequenceKeypoint.new(0, library:getdarkercolour(library.style.gradientstartcolour, 0.75)),
				ColorSequenceKeypoint.new(1, library.style.gradientendcolour),
			})
		end

		function toggle:set(value)
			toggle.value = value
			library.flags[flag] = toggle
			toggle:display()

			if toggle.callback then
				toggle.callback(toggle)
			end
		end
		
		library:highlight(togglearea, toggleouter, {BorderColor3 = library.style.darkeraccentcolour}, {BorderColor3 = Color3.new()})

		togglearea.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:isoveropened() then
				toggle:set(not toggle.value)
			end
		end)
		
		setmetatable(toggle, baseaddons)

		groupbox:addblank(8)
		groupbox:resize()
		
		toggle.groupbox = groupbox
		toggle.label = togglelabel
		toggle.type = "toggle"

		return toggle
	end

	function objects:slider(flag, options)
		assert(flag, "slider must have a set flag!")
		assert(options.default, "slider must have a set default value!")
		assert(options.min, "slider must have a set min value!")
		assert(options.max, "slider must have a set max value!")
		assert(options.rounding, "slider must have a set rounding value!")

		local slider = {
			text = options.text,
			value = options.default,
			rounding = options.rounding,
			min = options.min,
			max = options.max,
			suffix = options.suffix or "",
			prefix = options.prefix or "",
			callback = options.callback or defaultcallback,
			maxsize = 180,
			allownull = options.allownull or true,
		}

		library.flags[flag] = slider

		local groupbox = self
		local container = groupbox.container
		
		local offset = library:create("Frame", {
			Parent = container,
			Size = UDim2.new(1,0,0,(if slider.text == nil then 10 else 20)),
			BackgroundTransparency = 1,
			ZIndex = 99
		})
		
		local sliderlabel = library:createlabel({
			Text = slider.text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 8,
			Size = UDim2.new(1,0,0,8),
			Position = UDim2.new(0,13,0,0),
			Visible = not (slider.text == nil),
			Parent = offset,
		})

		local sliderouter = library:create("Frame", {
			Parent = offset,
			ZIndex = 7,
			Position = UDim2.new(0,13,0,(if slider.text == nil then 0 else 12)),
			Size = UDim2.new(1,-45,0,6),

			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
		})

		local sliderinner = library:create("Frame", {
			Parent = sliderouter,
			ZIndex = 7,
			Size = UDim2.new(1,0,1,0),
			BorderSizePixel = 0,

			BackgroundColor3 = library.white,
			BorderColor3 = Color3.new(),
		})

		local sliderfill = library:create("Frame", {
			Parent = sliderinner,
			ZIndex = 7,
			Size = UDim2.new(1,0,1,0),
			BorderSizePixel = 0,

			BackgroundColor3 = library.white
		})

		local slidergradient = library:create("UIGradient", {
			Parent = sliderfill,
			Rotation = 90,
			Offset = Vector2.new(0,-0.1),

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, library.style.accentcolour),
				ColorSequenceKeypoint.new(1, library.style.gradientaccentcolour),
			})
		})

		local slideroutergradient = library:create("UIGradient", {
			Parent = sliderinner,
			Rotation = 90,
			Offset = Vector2.new(0,-0.1),

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, library.white),
				ColorSequenceKeypoint.new(0.1, library.style.gradientstartcolour),
				ColorSequenceKeypoint.new(1, library.style.gradientendcolour),
			})
		})
		
		local width = library.textbounds(slider.max, 13, camera.ViewportSize.X)

		local displaylabel = library:createlabel({
			Size = UDim2.new(0,width,1,0),
			TextSize = 13,
			Text = "inf",
			ZIndex = 8,
			Parent = sliderinner,
			Position = UDim2.new(0,0,0.5,0),

			TextColor3 = library.style.objectcolour,
		})
		
		local slidertween = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		function slider:update()
			local value = if slider.rounding == 0 then slider.value else string.format(`%.{slider.rounding}f`, slider.value)
			displaylabel.Text = `{slider.prefix}{value}{slider.suffix}`

			local x = (mapvalue(slider.value, slider.min, slider.max, 0, slider.maxsize))
			--sliderfill.Size = UDim2.new(0,x,1,0)
			--dispalylabel.Position = UDim2.new(0,x,0.5,0)
			
			tweenservice:Create(displaylabel, slidertween, {Position = UDim2.new(0,x,0.5,0)}):Play()
			tweenservice:Create(sliderfill, slidertween, {Size = UDim2.new(0,x,1,0)}):Play()
		end
		
		function slider:set(value)
			slider.value = value		
			slider:update()
		end

		local function rounding(value)
			if slider.rounding == 0 then
				return math.floor(value)
			end

			return tonumber(string.format(`%.{slider.rounding}f`, value))
		end

		function slider:valuefromoffset(x)
			return rounding(mapvalue(x, 0, slider.maxsize, slider.min, slider.max))
		end
		
		library:highlight(sliderouter, sliderouter, {BorderColor3 = library.style.darkeraccentcolour}, {BorderColor3 = Color3.new()})

		sliderinner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:isoveropened() then
				local mousepos = mouse.X
				local sliderpos = sliderfill.Size.X.Offset
				local diff = mousepos - (sliderfill.AbsolutePosition.X + sliderpos)

				while userinputservice:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					sliderouter.BorderColor3 = library.style.darkeraccentcolour
					displaylabel.TextColor3 = library.style.fontcolour

					local newmousepos = mouse.X
					local newx = math.clamp(sliderpos + (newmousepos - mousepos) + diff, 0, slider.maxsize)

					local value = slider:valuefromoffset(newx)
					local oldvalue = slider.value
					slider.value = value

					slider:update()

					if value ~= oldvalue then
						slider.callback(slider)
						library.flags[flag] = slider
					end

					task.wait()
				end

				sliderouter.BorderColor3 = Color3.new()
				displaylabel.TextColor3 = library.style.objectcolour
			end
		end)

		slider:update()
		
		if slider.text ~= nil then
			groupbox:addblank(3)
		end
		
		groupbox:resize()

		return slider
	end
	
	function objects:dropdown(flag, options)
		assert(flag, "dropdown must have a set flag!")
		assert(options.values, "dropdown must have a set of values!")
		
		local dropdown = {
			text = options.text,
			values = options.values,
			default = options.default or {},
			value = options.multi and {},
			multi = options.multi or false,
			callback = options.callback or defaultcallback,
			maxitems = 8,
		}
		
		local groupbox = self
		local container = groupbox.container
		
		local y_offset = 0
		
		local offset = library:create("Frame", {
			Parent = container,
			Size = UDim2.new(1,0,0,if dropdown.text == nil then 10 else 20),
			BackgroundTransparency = 1,
			ZIndex = 99
		})
		
		local dropdownlabel = library:createlabel({
			Size = UDim2.new(1,0,0,10),
			Position = UDim2.new(0,13,0,0),
			TextSize = 13,
			Text = dropdown.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			ZIndex = 7,
			Visible = not (dropdown.text == nil),
			Parent = offset
		})
		
		local dropdownouter = library:create("Frame", {
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			Size = UDim2.new(1,-45,0,20),
			ZIndex = 7,
			Position = UDim2.new(0,13,0,(if dropdown.text == nil then 2 else 12)),
			
			Parent = offset
		})
		
		local dropdowninner = library:create("Frame", {
			BackgroundColor3 = library.style.maincolour,
			BorderColor3 = library.style.outlinecolour,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 7,
			
			Parent = dropdownouter,
		})
		library:highlight(dropdownouter, dropdowninner, {BorderColor3 = library.style.darkeraccentcolour}, {BorderColor3 = library.style.outlinecolour})
		
		local dropdownarrow = library:create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -16, 0.5, 0),
			ImageColor3 = library.style.objectcolour,
			Size = UDim2.new(0, 8, 0, 8),
			Image = "http://www.roblox.com/asset/?id=6282522798",
			ZIndex = 8,
			Parent = dropdowninner,
		}) -- pasted from linoria 8)
		
		local dropdownvalue = library:createlabel({
			Position = UDim2.new(0,5,0,0),
			Size = UDim2.new(1,-5,1,0),
			TextSize = 13,
			TextColor3 = library.style.infocolour,
			Text = "...",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			ZIndex = 7,
			
			Parent = dropdowninner,
		})
		
		local listouter = library:create("Frame", {
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			ZIndex = 15,
			Visible = false,
			Name = "dropdown",
			
			Parent = gui,
		})
		
		local function listpos()
			listouter.Position = UDim2.fromOffset(dropdownouter.AbsolutePosition.X, dropdownouter.AbsolutePosition.Y + dropdownouter.Size.Y.Offset + 1)
		end
		
		local function listsize(ysize)
			listouter.Size = UDim2.fromOffset(dropdownouter.AbsoluteSize.X, ysize or (dropdown.maxitems * 20 + 2))
		end
		
		listpos()
		listsize()
		
		dropdownouter:GetPropertyChangedSignal("AbsolutePosition"):Connect(listpos)
		
		local listinner = library:create("Frame", {
			BackgroundColor3 = library.style.maincolour,
			BorderColor3 = library.style.outlinecolour,
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 16,
			
			Parent = listouter,
		})
		
		local listscrolling = library:create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 0,
			ZIndex = 16,
			
			Parent = listinner,
		})
		
		library:create("UIListLayout", {
			Padding = UDim.new(),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = listscrolling,
		})
		
		function dropdown:update()
			local values = dropdown.values
			local values_string = ""
			
			if dropdown.multi then
				for index, value in values do
					if dropdown.value[value] then
						values_string = `{values_string}{value}, `
					end
				end
				
				values_string = values_string:sub(1, #values_string - 2)
			else
				values_string = dropdown.value or ""
			end
			
			dropdownvalue.Text = (values_string == "" and "..." or values_string)
		end
		
		function dropdown:getvalues()
			if dropdown.multi then
				local valuestable = {}
				
				for value, _ in dropdown.value do
					table.insert(valuestable, value)
				end
				
				return valuestable
			else
				return dropdown.value and 1 or 0
			end
		end
		
		function dropdown:updatelist()
			local values = dropdown.values
			local buttons = {}
			
			for _, object in listscrolling:GetChildren() do
				if not object:IsA("UIListLayout") then
					object:Destroy()
				end
			end
			
			local count = 0
			
			for  index, value in values do
				local tbl = {}
				
				count += 1
				
				local button = library:create("Frame", {
					BackgroundColor3 = library.style.maincolour,
					--BorderColor3 = library.style.outlinecolour,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -1, 0, 20),
					ZIndex = 20,
					Active = true,
					Parent = listscrolling,
				})
				
				local buttonlabel = library:createlabel({
					Active = false,
					BackgroundColor3 = library.style.maincolour,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -6, 1, 0),
					Position = UDim2.new(0, 6, 0 ,0),
					TextSize = 13,
					Text = value,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 25,
					
					Parent = button,
				})
				
				local selected
				
				if dropdown.multi then
					selected = dropdown.value[value]
				else
					selected = dropdown.value == value
				end
				
				function tbl:update()
					if dropdown.multi then
						selected = dropdown.value[value]
					else
						selected = dropdown.value == value
					end

					buttonlabel.TextColor3 = selected and library.style.accentcolour or library.style.objectcolour
				end
				
				library:highlight(buttonlabel, buttonlabel, {TextColor3 = library:getdarkercolour(library.style.accentcolour, 0.9)}, {TextColor3 = library.style.objectcolour}, function()
					if buttonlabel.TextColor3 == library.style.accentcolour then
						return true
					end
					
					return false
				end)
				
				buttonlabel.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local newvalue = not selected
						
						if not (dropdown:getvalues() == 1 and (not newvalue)) then
							if dropdown.multi then
								selected = newvalue
								
								if selected then
									dropdown.value[value] = true
								else
									dropdown.value[value] = nil
								end
							else
								selected = newvalue
								
								if selected then
									dropdown.value = value
								else
									dropdown.value = nil
								end
								
								for _, other in buttons do
									other:update()
								end
							end
							
							tbl:update()
							dropdown:update()
							
							library.flags[flag] = dropdown
							dropdown.callback(dropdown)
						end
					end
				end)
				
				tbl:update()
				dropdown:update()
				
				buttons[button] = tbl
			end
			
			listscrolling.CanvasSize = UDim2.fromOffset(0, (count * 20) + 1)
			listsize(math.clamp(count * 20, 0, dropdown.maxitems * 20) + 1)
		end
		
		function dropdown:setvalues(new)
			if new then
				dropdown.values = new
			end
			
			dropdown:updatelist()
		end
		
		function dropdown:open()
			listouter.Visible = true
			library.opened[listouter] = true
			dropdownarrow.Rotation = 180
		end
		
		function dropdown:close()
			listouter.Visible = false
			library.opened[listouter] = nil
			dropdownarrow.Rotation = 0
		end
		
		function dropdown:setvalue(value)
			if dropdown.multi then
				local tbl = {}
				
				for value, bool in value do
					if table.find(dropdown.values, value) then
						tbl[value] = true
					end
				end
				
				dropdown.value = tbl
			else
				if (not value) then
					dropdown.value = nil
				elseif table.find(dropdown.values, value) then
					dropdown.value = value
				end
			end
			
			dropdown:updatelist()
			
			library.flags[flag] = dropdown
			dropdown.callback(dropdown)
		end
		
		dropdownouter.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:isoveropened() then
				if listouter.Visible then
					dropdown:close()
				else
					dropdown:open()
				end
			end
		end)
		
		userinputservice.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos, size = listouter.AbsolutePosition, listouter.AbsoluteSize
				
				if mouse.X < pos.X
					or mouse.X > pos.X + size.X
					or mouse.Y < (pos.Y - 21)
					or mouse.Y > pos.Y + size.Y
				then
					dropdown:close()
				end
			end
		end)
		
		dropdown:updatelist()
		dropdown:update()
		
		local default = {}
		
		if typeof(dropdown.default) == "string" then
			local index = table.find(dropdown.values, dropdown.default)
			if index then
				table.insert(default, index)
			end
		elseif typeof(dropdown.default) == "table" then
			for _, value in dropdown.default do
				local index = table.find(dropdown.values, value)
				if index then
					table.insert(default, index)
				end
			end
		elseif typeof(dropdown.default) == "number" and dropdown.values[dropdown.default] ~= nil then
			table.insert(default, dropdown.default)
		end
		
		if next(default) then
			for i = 1, #default do
				local index = default[i]
				if dropdown.multi then
					dropdown.value[dropdown.values[index]] = true
				else
					dropdown.value = dropdown.values[index]
				end
				
				if (not dropdown.multi) then
					break 
				end
			end
			
			dropdown:updatelist()
			dropdown:update()
		end
		
		groupbox:addblank(16)
		groupbox:resize()
		
		return dropdown
	end
	
	function objects:label(text, wrap)
		local label = {}
		
		local groupbox = self
		local container = groupbox.container
		
		local offset = library:create("Frame", {
			Parent = container,
			Size = UDim2.new(1,0,0,0),
			BackgroundTransparency = 1,
			ZIndex = 99
		})
		
		local textlabel = library:createlabel({
			Size = UDim2.new(1, -16, 0, 10),
			Position = UDim2.new(0,13,0,0),
			TextSize = 13,
			Text = text,
			TextWrapped = wrap or false,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 7,
			Parent = offset,
		})
		
		if wrap then
			local y = library.textbounds(text, 13, textlabel.AbsoluteSize.X).Y
			offset.Size = UDim2.new(1,0,0,y)
			textlabel.Size = UDim2.new(1, -4, 0, y)
		else
			library:create("UIListLayout", {
				Padding = UDim.new(0, 4),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = textlabel,
			})
		end
		
		function label:set(text)
			if wrap then
				local y = library.textbounds(text, 13, textlabel.AbsoluteSize.X).Y
				offset.Size = UDim2.new(1,0,0,y)
				textlabel.Size = UDim2.new(1, -4, 0, y)
			end
			
			groupbox:resize()
		end
		
		label.groupbox = groupbox
		label.label = textlabel
		label.type = "label"
		
		if not wrap then
			setmetatable(label, baseaddons)
		end
		
		groupbox:addblank(1)
		groupbox:resize()
		
		return label
	end
	
	function objects:button(options)
		assert(options.callback, "button must have a set callback!")
		
		local groupbox = self
		local container = groupbox.container
		
		local outer = library:create("Frame", {
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.new(),
			BorderSizePixel = 2,
			Size = UDim2.new(1, -4, 0, 20),
			ZIndex = 8,
			Parent = container,
		})
		
		local inner = library:create("Frame", {
			BackgroundColor3 = library.style.maincolour,
			BorderColor3 = library.style.outlinecolour,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 8,
			Parent = outer
		})
		
		local label = library:createlabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 13,
			Text = options.text or "button",
			ZIndex = 9,
			Parent = inner
		})
		
		library:highlight(inner, inner, {BorderColor3 = library.style.darkeraccentcolour}, {BorderColor3 = library.style.outlinecolour})
		
		outer.InputBegan:Connect(function(input, gp)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gp and not library:isoveropened() then
				options.callback()
			end
		end)
		
		groupbox:resize()
	end

	basegroupbox.__index = objects
	basegroupbox.__namecall = function(t, k, ...)
		return objects[k](...)
	end
end

function library:createwindow(options)
	local window = {
		tabs = {},
	}

	options.size = options.size or Vector2.new(500, 550)
	options.title = options.title or "window"
	options.autoshow = options.autoshow == nil and true or options.autoshow

	local outer = library:create("Frame", {
		AnchorPoint = Vector2.new(0.5,0.5),
		BorderSizePixel = 2,
		Position = UDim2.fromOffset(camera.ViewportSize.X/2, camera.ViewportSize.Y/2),
		Size = UDim2.fromOffset(options.size.X, options.size.Y),
		Visible = options.autoshow,
		Parent = gui,

		BackgroundColor3 = library.style.window.backgroundcolour,
		BorderColor3 = library.style.window.backgroundcolour,
	})
	library:makedraggable(outer, 20)
	
	table.insert(library.connections, userinputservice.InputBegan:Connect(function(input)
		if input.KeyCode == library.togglebind then
			outer.Visible = not outer.Visible
		end
	end))

	local inner = library:create("Frame", {
		BorderSizePixel = 1,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.fromOffset(options.size.X, options.size.Y),
		Parent = outer,

		BackgroundColor3 = library.style.backgroundcolour,
		BorderColor3 = library.style.window.outlinecolour,
	})

	local windowlabel = library:createlabel({
		Text = options.title,
		Size = UDim2.fromOffset(0,20),
		TextSize = 15,
		Position = UDim2.new(0, 8, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inner,

		TextColor3 = library.style.accentcolour,
	})
	
	local width = library.textbounds(options.title, 15, camera.ViewportSize.X)

	local otherlabel = library:createlabel({
		Text = options.other and ` | {options.other}` or "",
		Size = UDim2.fromOffset(0,20),
		TextSize = 15,
		Position = UDim2.new(0, 4+width.X, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inner,

		TextColor3 = library.style.otherfontcolour,
	})
	
	local gamelabel = library:createlabel({
		Text = ` [{options.gamename}]`,
		Size = UDim2.new(1,-4,0,20),
		TextSize = 15,
		Visible = options.gamename ~= nil,
		Position = UDim2.new(0, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = inner,

		TextColor3 = library.style.otherfontcolour,
	})

	local highlight = library:create("Frame", {
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0, 6, 0, 20),
		Parent = inner,
		BorderSizePixel = 0,

		BackgroundColor3 = library.style.accentcolour,
	})

	local mainouter = library:create("Frame", {
		BorderSizePixel = 2,
		Position = UDim2.new(0, 8, 0.125, 0),
		Size = UDim2.new(1, -16, 0.925, -33),
		Parent = inner,

		BackgroundColor3 = library.style.backgroundcolour,
		BorderColor3 = Color3.new(),
	})

	local maininner = library:create("Frame", {
		BorderMode = Enum.BorderMode.Inset,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = mainouter,

		BackgroundColor3 = library.style.backgroundcolour,
		BorderColor3 = library.style.outlinecolour,
	})

	local tabareaouter = library:create("Frame", {
		Position = UDim2.new(0, 9, 0.025, 12),
		Size = UDim2.new(1, -18, 0.025, 21),
		Parent = inner,
		BorderSizePixel = 2,

		BackgroundColor3 = Color3.new(),
		BorderColor3 = Color3.new(),
	})

	local tabareainner = library:create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Parent = tabareaouter,

		BackgroundColor3 = library.style.backgroundcolour,
		BorderColor3 = library.style.outlinecolour,
	})

	local tabarea = library:create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -4, 1, 0),
		Position = UDim2.new(0,2,0,0),
		Parent = tabareainner,
		ClipsDescendants = false,
	})

	local tablistlayout = library:create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = tabarea,
	})

	function window:tab(name)
		local tab = {
			groups = {}
		}

		local tabbutton = library:create("Frame", {
			Size = UDim2.new(1/#window.tabs, 0, 1, -4),
			Parent = tabarea,
			ZIndex = 2,

			BackgroundColor3 = library.white,
			BorderColor3 = library.style.outlinecolour,
		})

		local tablabel = library:createlabel({
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Text = name,
			Parent = tabbutton,
			ZIndex = 3,

			TextColor3 = library.style.otherfontcolour,
		})

		local tabgradient = library:create("UIGradient", {
			Parent = tabbutton,
			Rotation = 90,

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, library.style.gradientstartcolour),
				ColorSequenceKeypoint.new(1, library.style.gradientendcolour),
			})
		})

		local tabcontent = library:create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1,1),
			Visible = false,
			Parent = maininner,
			ZIndex = 1,
		})

		local leftside = library:create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0,6,0,0),
			Size = UDim2.new(0.5,-8,1,-8),
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 0,
			--ClipsDescendants = false,
			Parent = tabcontent,

			BackgroundColor3 = Color3.new(1,0,0),
		})

		local rightside = library:create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5,-8,1,-8),
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 0,
			Position = UDim2.new(0.5,2,0,0),
			--ClipsDescendants = false,
			Parent = tabcontent,

			BackgroundColor3 = Color3.new(0,0,1),
		})

		library:create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = leftside,
		})

		library:create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = rightside,
		})

		function tab:resize()   
			tabbutton.Size = UDim2.new(1/#window.tabs, 0, 1, -4)
		end

		function tab:show()
			for _, tab in window.tabs do
				tab:hide()
			end
			
			for _, frame in gui:GetChildren() do
				if frame.Name == "colourpicker" or frame.Name == "keypicker" then
					frame.Visible = false
					library.opened[frame] = nil
				end
			end

			tabgradient.Offset = Vector2.new(0, 0.1)
			tablabel.TextColor3 = library.style.accentcolour
			tabcontent.Visible = true
		end

		function tab:hide()
			tabgradient.Offset = Vector2.zero
			tablabel.TextColor3 = library.style.otherfontcolour
			tabcontent.Visible = false
		end

		library:create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,0,1),

			Parent = leftside,
		})

		library:create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,0,1),

			Parent = rightside,
		})
		
		library:highlight(tabbutton, tablabel, {TextColor3 = library:getdarkercolour(library.style.otherfontcolour, 0.75)}, {TextColor3 = library.style.otherfontcolour}, function()
			if tablabel.TextColor3 == library.style.accentcolour then
				return true
			end
			
			return false
		end)

		function tab:groupbox(options)
			local groupbox = {}

			local boxouter = library:create("Frame", {
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 0, 100),
				ZIndex = 2,
				Parent = options.side == 1 and leftside or rightside,

				BackgroundColor3 = Color3.new(),
				BorderColor3 = library.style.outlinecolour,
			})

			local boxinner = library:create("Frame", {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				ZIndex = 4,
				Parent = boxouter,

				BackgroundColor3 = library.style.maincolour,
				BorderColor3 = Color3.new(0, 0, 0),
			})

			local boxlabel = library:createlabel({
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 4, 0, -11),
				TextSize = 14,
				Text = options.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = boxinner,
			})

			local boxcontainer = library:create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 4, 0, 8),
				Size = UDim2.new(1, -4, 1, -8),
				ZIndex = 6,
				Parent = boxinner,

				BackgroundColor3 = Color3.new(1,0,0),
			})

			library:create("UIListLayout", {
				--Padding = UDim.new(0,2),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = boxcontainer,
			})

			function groupbox:addblank(size)
				library:create("Frame", {
					BackgroundTransparency = 1,
					ZIndex = 999,
					Size = UDim2.new(1,0,0,(size or 3)),

					Parent = boxcontainer,
				})
			end

			function groupbox:resize()
				local size = 0

				for _, obj in next, groupbox.container:GetChildren() do
					if obj:IsA("UIListLayout") or not obj.Visible then
						continue
					end

					size += obj.Size.Y.Offset
				end

				boxouter.Size = UDim2.new(1, 0, 0, 24 + size)
			end

			groupbox.container = boxcontainer
			setmetatable(groupbox, basegroupbox)

			groupbox:addblank(2)
			groupbox:resize()

			tab.groups[options.name] = groupbox

			return groupbox
		end

		tabbutton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				tab:show()
			end
		end)

		table.insert(window.tabs, tab)

		for _, tab in window.tabs do
			tab:resize()
		end

		window.tabs[1]:show()

		return tab
	end

	return window
end

do
	local infoarea = library:create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0,300,1,0),
		Position = UDim2.new(0,10,0,0),
		ZIndex = 999,
		Parent = gui,
	})
	
	library.infoarea = infoarea
	
	library:create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = infoarea,
	})
	
	function library:info(text, duration)
		local info = library:createlabel({
			Text = text or "info",
			Size = UDim2.new(1,0,0,15),
			TextStrokeTransparency = 0,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 1000,
			Parent = infoarea,
		})
		
		task.spawn(function()
			task.wait(duration or 5)
			info:Destroy()
		end)
	end
	
	local notificationarea = library:create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0,300,0,50),
		Position = UDim2.new(0,10,0,0),
		ZIndex = 999,
		Parent = gui,
	})
	
	
	function library:notify(text, duration)
		assert(text, "notification must have a set text value!")
		duration = duration or 5
		
		local size = library.textbounds(text, 15, camera.ViewportSize.X)

		local frame = library:create("Frame", {
			BorderColor3 = library.style.outlinecolour,
			BackgroundColor3 = library.white,
			BorderSizePixel = 2,
			Position = UDim2.new(0, -10, 0, 10),
			Size = UDim2.new(0, 0, 0, size.Y + 3),
			ClipsDescendants = true,
			ZIndex = 999,
			Parent = notificationarea,
		})
		
		library:create("UIGradient", {
			Rotation = 90,
			Parent = frame,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, library:getdarkercolour(library.style.maincolour, 0.6)),
				ColorSequenceKeypoint.new(1, library.style.backgroundcolour),
			})
		})
		
		local colour = library:create("Frame", {
			BackgroundColor3 = library.style.accentcolour,
			BorderSizePixel = 0,
			Position = UDim2.new(0,-1,0,-1),
			Size = UDim2.new(0, 3, 1, 2),
			ZIndex = 1000,
			Parent = frame,
		})
		
		local label = library:createlabel({
			Text = text,
			Size = UDim2.new(1,-4,1,0),
			Position = UDim2.new(0, 5, 0, 0),
			TextSize = 15,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 1002,
			Parent = frame,
		})
		
		tweenservice:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, size.X + 8,0, (size.Y + 3))}):Play()

		task.spawn(function()
			task.wait(duration or 5)
			
			tweenservice:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 0, 0, (size.Y + 3))}):Play()
			task.wait(0.4)
			frame:Destroy()
		end)
	end
end

return library
