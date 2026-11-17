-- Brainrot Bay: builds a cute 3D brainrot character model out of parts.
-- The model origin is the ground point under the character (feet at y = 0).

local BrainrotData = require(script.Parent.BrainrotData)

local CharacterFactory = {}

local function makePart(name, size, color, cframe, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function buildAccessory(kind, color, scale, model)
	local s = scale
	if kind == "pepperoni" then
		-- a pepperoni slice on top of the head
		local disc = makePart("Pepperoni", Vector3.new(1.0 * s, 0.25 * s, 1.0 * s), color, CFrame.new(0, 3.7 * s, 0), model)
		disc.Shape = Enum.PartType.Cylinder
		disc.CFrame = CFrame.new(0, 3.7 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif kind == "bat" then
		-- a wooden bat held upright beside the head
		local bat = makePart("Bat", Vector3.new(0.35 * s, 2.2 * s, 0.35 * s), color, CFrame.new(1.1 * s, 2.6 * s, 0.3 * s), model)
		bat.CFrame = CFrame.new(1.1 * s, 2.6 * s, 0.3 * s) * CFrame.Angles(0, 0, math.rad(-18))
	elseif kind == "fin" then
		-- a shark fin on the head
		local fin = makePart("Fin", Vector3.new(0.3 * s, 1.1 * s, 1.0 * s), color, CFrame.new(0, 3.9 * s, -0.1 * s), model)
		fin.CFrame = CFrame.new(0, 3.9 * s, -0.1 * s) * CFrame.Angles(math.rad(-25), 0, 0)
	elseif kind == "banana" then
		-- a banana held up like a trophy
		local banana = makePart("Banana", Vector3.new(0.4 * s, 1.4 * s, 0.4 * s), color, CFrame.new(1.0 * s, 3.6 * s, 0.2 * s), model)
		banana.CFrame = CFrame.new(1.0 * s, 3.6 * s, 0.2 * s) * CFrame.Angles(0, 0, math.rad(35))
	elseif kind == "wing" then
		-- little plane wings on the back
		for _, side in ipairs({ -1, 1 }) do
			local wing = makePart("Wing", Vector3.new(1.6 * s, 0.2 * s, 0.9 * s), color, CFrame.new(side * 1.5 * s, 1.5 * s, -0.4 * s), model)
			wing.CFrame = CFrame.new(side * 1.5 * s, 1.5 * s, -0.4 * s) * CFrame.Angles(0, 0, math.rad(side * -12))
		end
	elseif kind == "cactus" then
		-- a mini cactus sprouting from the head
		makePart("Cactus", Vector3.new(0.4 * s, 0.9 * s, 0.4 * s), color, CFrame.new(0, 4.0 * s, 0), model)
		for _, side in ipairs({ -1, 1 }) do
			makePart("CactusArm", Vector3.new(0.7 * s, 0.3 * s, 0.3 * s), color, CFrame.new(side * 0.45 * s, 3.9 * s, 0), model)
		end
	elseif kind == "tutu" then
		-- a ballerina tutu skirt around the waist
		local tutu = makePart("Tutu", Vector3.new(3.0 * s, 0.25 * s, 3.0 * s), color, CFrame.new(0, 0.6 * s, 0), model)
		tutu.Shape = Enum.PartType.Cylinder
		tutu.CFrame = CFrame.new(0, 0.6 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
		-- a coffee cup on the head
		makePart("Cup", Vector3.new(0.6 * s, 0.7 * s, 0.6 * s), Color3.fromRGB(255, 245, 230), CFrame.new(0, 3.9 * s, 0), model)
	elseif kind == "fridge" then
		-- a tiny fridge strapped to the back
		makePart("Fridge", Vector3.new(1.2 * s, 1.8 * s, 0.7 * s), color, CFrame.new(0, 1.6 * s, -1.2 * s), model)
		makePart("FridgeDoor", Vector3.new(0.9 * s, 0.7 * s, 0.1 * s), Color3.fromRGB(140, 150, 160), CFrame.new(0, 1.9 * s, -1.6 * s), model)
	elseif kind == "ring" then
		-- a Saturn ring around the body
		local ring = makePart("Ring", Vector3.new(4.2 * s, 0.2 * s, 4.2 * s), color, CFrame.new(0, 1.4 * s, 0), model)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(0, 1.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif kind == "crown" then
		-- a golden crown
		makePart("Crown", Vector3.new(1.2 * s, 0.5 * s, 1.2 * s), color, CFrame.new(0, 3.8 * s, 0), model)
		for _, dx in ipairs({ -0.45, 0, 0.45 }) do
			makePart("CrownSpike", Vector3.new(0.25 * s, 0.5 * s, 0.25 * s), color, CFrame.new(dx * s, 4.1 * s, 0), model)
		end
	elseif kind == "tentacles" then
		-- jellyfish tentacles dangling under the body
		for i = 1, 5 do
			local angle = (i - 3) * 0.35
			local tent = makePart("Tentacle", Vector3.new(0.25 * s, 1.1 * s, 0.25 * s), color, CFrame.new(angle * s, -0.4 * s, 0.3 * s), model)
			tent.CFrame = CFrame.new(angle * s, -0.4 * s, 0.3 * s) * CFrame.Angles(0, 0, math.rad(angle * 18))
		end
	elseif kind == "bowtie" then
		makePart("Bowtie", Vector3.new(0.9 * s, 0.35 * s, 0.2 * s), color, CFrame.new(0, 2.1 * s, 1.05 * s), model)
	end
end

-- Builds the model. Origin = ground point under the character, facing +Z.
function CharacterFactory.build(data)
	local s = data.scale or 1
	local model = Instance.new("Model")
	model.Name = data.name

	-- body
	local body = makePart("Body", Vector3.new(2 * s, 2 * s, 1.8 * s), data.bodyColor, CFrame.new(0, 1.0 * s, 0), model)
	body.CanQuery = true
	body.CanTouch = true

	-- head
	makePart("Head", Vector3.new(1.6 * s, 1.5 * s, 1.5 * s), data.headColor, CFrame.new(0, 2.75 * s, 0), model)

	-- goofy eyes on the front (+Z) of the head
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.3 * s, 0.45 * s, 0.15 * s), Color3.fromRGB(20, 20, 20), CFrame.new(side * 0.4 * s, 2.85 * s, 0.78 * s), model)
		eye.Shape = Enum.PartType.Ball
		-- a big friendly smile
		if side == -1 then
			local smile = makePart("Smile", Vector3.new(0.8 * s, 0.15 * s, 0.1 * s), Color3.fromRGB(20, 20, 20), CFrame.new(0, 2.3 * s, 0.78 * s), model)
			smile.Shape = Enum.PartType.Ball
		end
	end

	-- little feet
	for _, side in ipairs({ -1, 1 }) do
		makePart("Foot", Vector3.new(0.7 * s, 0.3 * s, 1.0 * s), data.headColor, CFrame.new(side * 0.55 * s, 0.15 * s, 0.1 * s), model)
	end

	-- arms
	for _, side in ipairs({ -1, 1 }) do
		makePart("Arm", Vector3.new(0.4 * s, 1.2 * s, 0.4 * s), data.headColor, CFrame.new(side * 1.15 * s, 1.1 * s, 0), model)
	end

	buildAccessory(data.accessory.kind, data.accessory.color, s, model)

	-- floating name + income label
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(170, 56)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.6 * s, 0)
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Income"
	incomeLabel.Position = UDim2.new(0, 0, 0.55, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.45, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = BrainrotData.formatCash(data.income) .. "/s  |  " .. data.rarity
	incomeLabel.TextColor3 = BrainrotData.RARITY_COLORS[data.rarity] or Color3.fromRGB(255, 255, 255)
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.FredokaOne
	incomeLabel.Parent = billboard

	model.PrimaryPart = body
	return model
end

-- Sets every part in the model anchored/unanchored (for carry vs. placed).
function CharacterFactory.setAnchored(model, anchored)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.Massless = not anchored
		end
	end
end

return CharacterFactory
