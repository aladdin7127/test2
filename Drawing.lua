local Drawing = {
	List = {},
	Handle = nil,
	Root = nil,
	Connection = nil,
}

local RunService = game:GetService("RunService")

Drawing.Root = Instance.new("Part", script)
Drawing.Root.Size = Vector3.one

function Drawing.new(Type: string, Properties: {})
	if Drawing.Connection == nil then
		return warn("Drawing hasn't been initialised...")
	end
	
	assert(Type, "TYPE IS REQUIRED")
	Properties = Properties or {}
	
	local DrawingObject = {}
	
	
	function DrawingObject:Remove()
		local Index = table.find(Drawing.List, DrawingObject)
		if Index then
			Drawing.List[Index] = nil
		end
	end
	
	DrawingObject.Type = Type
	
	DrawingObject.Colour = Properties.Colour or Color3.new()
	DrawingObject.Transparency = Properties.Transparency or 0
	DrawingObject.Visible = Properties.Visible or true
	
	if DrawingObject.Type == "Line" then
		DrawingObject.From = Properties.From or Vector3.zero
		DrawingObject.To = Properties.To or Vector3.zero
	elseif DrawingObject.Type == "Quad" then
		DrawingObject.Points = Properties.Points or {Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero}
		
		if #DrawingObject.Points ~= 4 then
			return warn("Quad requires 4 points.")
		end
	end

	table.insert(Drawing.List, DrawingObject)
	return DrawingObject
end

function Drawing:Initialise()
	Drawing.Handle = Instance.new("WireframeHandleAdornment", workspace.CurrentCamera)
	Drawing.Handle.AlwaysOnTop = true
	Drawing.Handle.Color3 = Color3.new()
	Drawing.Handle.Adornee = Drawing.Root
	
	Drawing.Connection = RunService.RenderStepped:Connect(function(Delta)
		Drawing.Handle:Clear()
		
		for _, NEW_DRAWING in Drawing.List do
			if not NEW_DRAWING.Visible then
				continue
			end
			
			if NEW_DRAWING.Type == "Line" then
				Drawing.Handle.Color3 = NEW_DRAWING.Colour
				Drawing.Handle.Transparency =  NEW_DRAWING.Transparency
				
				Drawing.Handle:AddLine(NEW_DRAWING.From, NEW_DRAWING.To)
			elseif NEW_DRAWING.Type == "Quad" then
				Drawing.Handle.Color3 = NEW_DRAWING.Colour
				Drawing.Handle.Transparency =  NEW_DRAWING.Transparency
				
				for Index = 1, 4 do
					Drawing.Handle:AddLine(NEW_DRAWING.Points[Index], NEW_DRAWING.Points[if Index == 4 then 1 else Index + 1])
				end
			end
		end
	end)
end

function Drawing:Terminate()
	if Drawing.Connection then
		Drawing.Connection:Disconnect()
		Drawing.Connection = nil
	else
		warn("Drawing hasn't been initialised")
	end
end

return Drawing
