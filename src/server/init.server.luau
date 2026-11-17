-- Brainrot Bay: server. Builds the 3D world, runs the conveyor, the
-- base economy, stealing/carrying, base locks and slapping.
-- Players buy brainrot characters off a central conveyor; the characters
-- walk to the buyer's base and earn cash every second. Other players can
-- steal characters out of an unlocked base and carry them home.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(script.Parent.BrainrotData)
local CharacterFactory = require(script.Parent.CharacterFactory)

local GROUND_Y = 0.4 -- top surface of plot floors and the conveyor belt
local PLOT_X = { -63, -21, 21, 63 }
local PLOT_Z = { -48, 48 }
local PLOT_COLORS = {
	Color3.fromRGB(255, 170, 170),
	Color3.fromRGB(170, 220, 255),
	Color3.fromRGB(180, 255, 170),
	Color3.fromRGB(255, 230, 150),
	Color3.fromRGB(220, 180, 255),
	Color3.fromRGB(255, 200, 150),
	Color3.fromRGB(160, 255, 230),
	Color3.fromRGB(255, 170, 220),
}
local SLOT_OFFSETS = {
	{ -5, -4 }, { 0, -4 }, { 5, -4 },
	{ -5, 4 }, { 0, 4 }, { 5, 4 },
}

----------------------------------------------------------------------
-- Remotes
----------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local ToggleLockRemote = makeRemote("ToggleLock")
local SlapRemote = makeRemote("Slap")
local NotifyRemote = makeRemote("Notify")
local LockUpdateRemote = makeRemote("LockUpdate")

local function notify(player, message)
	if player and player.Parent then
		NotifyRemote:FireClient(player, message)
	end
end

----------------------------------------------------------------------
-- World
----------------------------------------------------------------------
local world = Instance.new("Folder")
world.Name = "BrainrotWorld"
world.Parent = workspace

local function makePart(name, size, color, cframe, parent, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CFrame = cframe
	part.Parent = parent or world
	return part
end

local function makeTextLabel(parent, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return label
end

-- Big title sign at the back of the map.
do
	local sign = makePart("TitleSign", Vector3.new(46, 9, 1), Color3.fromRGB(40, 40, 60), CFrame.new(0, 8, -78))
	makeTextLabel(sign, "BRAINROT BAY\nSteal brainrots - Get rich - Lock your base", Color3.fromRGB(255, 220, 60))
end

-- Trees, clouds and lamps for a lively 3D scene.
local function makeTree(x, z)
	local trunk = makePart("Trunk", Vector3.new(1.2, 5, 1.2), Color3.fromRGB(140, 95, 55), CFrame.new(x, 2.5, z))
	trunk.Shape = Enum.PartType.Cylinder
	trunk.CFrame = CFrame.new(x, 2.5, z) * CFrame.Angles(0, 0, math.rad(90))
	local leaves = makePart("Leaves", Vector3.new(5, 5, 5), Color3.fromRGB(70, 180, 90), CFrame.new(x, 7, z))
	leaves.Shape = Enum.PartType.Ball
end

for _, pos in ipairs({
	{ -95, -70 }, { 95, -70 }, { -95, 70 }, { 95, 70 },
	{ -100, 0 }, { 100, 0 }, { -40, 78 }, { 40, 78 },
	{ -88, 25 }, { 88, -25 }, { 0, 82 }, { -70, -78 }, { 70, -78 },
}) do
	makeTree(pos[1], pos[2])
end

for _, pos in ipairs({
	{ -60, 38, -60 }, { 30, 44, 55 }, { 70, 36, -30 },
	{ -20, 42, 70 }, { 85, 40, 40 },
}) do
	local cloud = makePart("Cloud", Vector3.new(12, 4, 7), Color3.fromRGB(255, 255, 255), CFrame.new(pos[1], pos[2], pos[3]))
	cloud.Shape = Enum.PartType.Ball
	cloud.Material = Enum.Material.Neon
end

for _, x in ipairs({ -40, 40 }) do
	for _, z in ipairs({ -9, 9 }) do
		makePart("LampPole", Vector3.new(0.5, 6, 0.5), Color3.fromRGB(60, 60, 70), CFrame.new(x, 3, z))
		local lamp = makePart("LampHead", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(255, 230, 130), CFrame.new(x, 6.4, z), world, Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
	end
end

----------------------------------------------------------------------
-- Conveyor belt (brainrots walk along it, players buy them)
----------------------------------------------------------------------
makePart("Belt", Vector3.new(156, 0.4, 8), Color3.fromRGB(50, 50, 60), CFrame.new(0, 0.2, 0))
for _, z in ipairs({ -4.2, 4.2 }) do
	makePart("BeltRail", Vector3.new(156, 0.7, 0.6), Color3.fromRGB(255, 200, 40), CFrame.new(0, 0.55, z))
end

local stripes = {}
for i = 1, 12 do
	local stripe = makePart("Stripe", Vector3.new(2, 0.12, 6.5), Color3.fromRGB(255, 220, 60), CFrame.new(-78 + (i - 1) * 13, 0.45, 0), world, Enum.Material.Neon)
	table.insert(stripes, stripe)
end

-- Start arch and end portal.
for _, x in ipairs({ -80, 80 }) do
	for _, z in ipairs({ -4.5, 4.5 }) do
		makePart("ArchPost", Vector3.new(1, 6, 1), Color3.fromRGB(255, 120, 60), CFrame.new(x, 3, z))
	end
	makePart("ArchTop", Vector3.new(1, 1, 10), Color3.fromRGB(255, 120, 60), CFrame.new(x, 6.2, 0))
end

----------------------------------------------------------------------
-- Plots (player bases)
----------------------------------------------------------------------
local plots = {}

local function refreshPlotSign(plot)
	local label = plot.signLabel
	if plot.owner then
		label.Text = plot.owner.DisplayName .. "'s BASE"
	else
		label.Text = "FREE PLOT\nJoin to claim!"
	end
end

local function buildPlot(index, x, z)
	local side = 1
	if z < 0 then
		side = -1
	end
	local color = PLOT_COLORS[((index - 1) % #PLOT_COLORS) + 1]
	local floor = makePart("PlotFloor", Vector3.new(20, 0.4, 20), color, CFrame.new(x, 0.2, z))
	floor.CanCollide = true
	-- back wall and side walls (entrance stays open toward the conveyor)
	local backZ = z + side * 9.5
	makePart("BackWall", Vector3.new(20, 3, 1), color, CFrame.new(x, 1.5, backZ)).CanCollide = true
	for _, dx in ipairs({ -9.5, 9.5 }) do
		makePart("SideWall", Vector3.new(1, 3, 20), color, CFrame.new(x + dx, 1.5, z)).CanCollide = true
	end
	-- owner sign on the back wall
	local signPart = makePart("PlotSign", Vector3.new(11, 2.6, 0.5), Color3.fromRGB(35, 35, 50), CFrame.new(x, 3.4, z + side * 8.9))
	local signGui = Instance.new("SurfaceGui")
	if side < 0 then
		signGui.Face = Enum.NormalId.Back
	else
		signGui.Face = Enum.NormalId.Front
	end
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 20
	signGui.Parent = signPart
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.TextScaled = true
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.Parent = signGui
	-- spawn pad near the entrance
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlotSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Color = Color3.fromRGB(120, 255, 140)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CFrame = CFrame.new(x, 0.5, z - side * 6)
	spawn.Parent = world
	-- lock gate across the entrance (visual only; the lock is enforced by the steal check)
	local gate = makePart("LockGate", Vector3.new(18, 4.5, 0.8), Color3.fromRGB(255, 60, 60), CFrame.new(x, 2.4, z - side * 9.5), world, Enum.Material.Neon)
	gate.Transparency = 1
	local gateGui = Instance.new("BillboardGui")
	gateGui.Name = "LockLabel"
	gateGui.Size = UDim2.fromOffset(180, 50)
	gateGui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gateGui.Enabled = false
	gateGui.Parent = gate
	local gateLabel = Instance.new("TextLabel")
	gateLabel.Size = UDim2.fromScale(1, 1)
	gateLabel.BackgroundTransparency = 1
	gateLabel.Text = "🔒 LOCKED"
	gateLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	gateLabel.TextStrokeTransparency = 0.1
	gateLabel.TextScaled = true
	gateLabel.Font = Enum.Font.FredokaOne
	gateLabel.Parent = gateGui

	local facingYaw = 0
	if z > 0 then
		facingYaw = math.pi
	end
	local plot = {
		index = index,
		center = Vector3.new(x, 0, z),
		facingYaw = facingYaw,
		owner = nil,
		slots = {},
		lockedUntil = 0,
		cooldownUntil = 0,
		signLabel = signLabel,
		gate = gate,
		gateGui = gateGui,
		spawnLoc = spawn,
	}
	for i = 1, BrainrotData.MAX_SLOTS do
		plot.slots[i] = nil
	end
	refreshPlotSign(plot)
	plots[index] = plot
	return plot
end

do
	local index = 0
	for _, z in ipairs(PLOT_Z) do
		for _, x in ipairs(PLOT_X) do
			index = index + 1
			buildPlot(index, x, z)
		end
	end
end

local function plotOf(player)
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

local function freeSlot(plot)
	for i = 1, BrainrotData.MAX_SLOTS do
		if plot.slots[i] == nil then
			return i
		end
	end
	return nil
end

local function slotCFrame(plot, slotIndex)
	local offset = SLOT_OFFSETS[slotIndex]
	local pos = Vector3.new(plot.center.X + offset[1], GROUND_Y, plot.center.Z + offset[2])
	return CFrame.new(pos) * CFrame.Angles(0, plot.facingYaw, 0)
end

----------------------------------------------------------------------
-- Characters
----------------------------------------------------------------------
local characters = {}
local conveyorChars = {}

local function removeFromList(list, value)
	for i = #list, 1, -1 do
		if list[i] == value then
			table.remove(list, i)
			return
		end
	end
end

local function tweenModelTo(char, targetCFrame, duration, onDone)
	if char.tween then
		char.tween:Cancel()
	end
	if char.moveConn then
		char.moveConn:Disconnect()
		char.moveConn = nil
	end
	if char.cfValue then
		char.cfValue:Destroy()
		char.cfValue = nil
	end
	local cfValue = Instance.new("CFrameValue")
	cfValue.Value = char.model:GetPivot()
	char.cfValue = cfValue
	char.moveConn = cfValue.Changed:Connect(function(value)
		if char.model.Parent ~= nil then
			char.model:PivotTo(value)
		end
	end)
	local tween = TweenService:Create(cfValue, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = targetCFrame })
	char.tween = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and onDone then
			onDone()
		end
	end)
	tween:Play()
end

local function despawnCharacter(char)
	removeFromList(characters, char)
	removeFromList(conveyorChars, char)
	if char.tween then
		char.tween:Cancel()
	end
	if char.moveConn then
		char.moveConn:Disconnect()
	end
	if char.cfValue then
		char.cfValue:Destroy()
	end
	if char.weld then
		char.weld:Destroy()
	end
	if char.model.Parent ~= nil then
		char.model:Destroy()
	end
end

local function getCash(player)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	if cash then
		return cash.Value
	end
	return 0
end

local function setCash(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	if cash then
		cash.Value = math.max(0, math.floor(amount))
	end
end

local function setIncome(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local income = stats and stats:FindFirstChild("Income")
	if income then
		income.Value = math.floor(amount)
	end
end

local function updateBrainrotCount(player)
	if not player then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local count = stats and stats:FindFirstChild("Brainrots")
	if not count then
		return
	end
	local n = 0
	for _, char in ipairs(characters) do
		if char.state == "owned" and char.owner == player then
			n = n + 1
		end
	end
	count.Value = n
end

local function refreshPrompt(char)
	local prompt = char.prompt
	if not prompt or prompt.Parent == nil then
		return
	end
	if char.state == "conveyor" then
		prompt.Enabled = true
		prompt.ActionText = "Buy  " .. BrainrotData.formatCash(char.data.cost)
		prompt.ObjectText = char.data.name
	elseif char.state == "owned" then
		local plot = char.plot
		local locked = plot and tick() < plot.lockedUntil
		if locked then
			prompt.Enabled = false
			prompt.ActionText = "Locked"
		else
			prompt.Enabled = true
			prompt.ActionText = "Steal!"
			prompt.ObjectText = char.data.name .. " (" .. (char.owner and char.owner.DisplayName or "?") .. ")"
		end
	else
		prompt.Enabled = false
	end
end

local function isCarrying(player)
	for _, char in ipairs(characters) do
		if char.state == "carried" and char.carrier == player then
			return true
		end
	end
	return false
end

local function setLockVisual(plot)
	local locked = tick() < plot.lockedUntil
	if locked then
		plot.gate.Transparency = 0.55
		plot.gateGui.Enabled = true
	else
		plot.gate.Transparency = 1
		plot.gateGui.Enabled = false
	end
	for _, char in ipairs(characters) do
		if char.state == "owned" and char.plot == plot then
			refreshPrompt(char)
		end
	end
end

local function returnCharacter(char)
	local plot = char.plot
	local owner = char.originalOwner or char.owner
	char.state = "owned"
	char.owner = owner
	char.carrier = nil
	char.originalOwner = nil
	if char.weld then
		char.weld:Destroy()
		char.weld = nil
	end
	if plot and char.slot then
		tweenModelTo(char, slotCFrame(plot, char.slot), 1.0)
	end
	refreshPrompt(char)
	updateBrainrotCount(owner)
	if owner then
		notify(owner, char.data.name .. " is safe back in your base.")
	end
end

local function completeSteal(char)
	local carrier = char.carrier
	if not carrier then
		return
	end
	local myPlot = plotOf(carrier)
	if not myPlot then
		returnCharacter(char)
		return
	end
	local slot = freeSlot(myPlot)
	if not slot then
		notify(carrier, "Your base is full! The brainrot slipped away.")
		returnCharacter(char)
		return
	end
	local oldPlot = char.plot
	local oldOwner = char.originalOwner or char.owner
	if oldPlot and char.slot then
		oldPlot.slots[char.slot] = nil
	end
	char.owner = carrier
	char.plot = myPlot
	char.slot = slot
	myPlot.slots[slot] = char
	char.state = "owned"
	char.carrier = nil
	char.originalOwner = nil
	if char.weld then
		char.weld:Destroy()
		char.weld = nil
	end
	tweenModelTo(char, slotCFrame(myPlot, slot), 1.0)
	refreshPrompt(char)
	updateBrainrotCount(oldOwner)
	updateBrainrotCount(carrier)
	notify(carrier, "You stole " .. char.data.name .. "! It now earns cash for YOU.")
	if oldOwner and oldOwner ~= carrier then
		notify(oldOwner, carrier.DisplayName .. " stole your " .. char.data.name .. "!")
	end
end

local function tryBuy(player, char)
	if char.state ~= "conveyor" then
		return
	end
	local plot = plotOf(player)
	if not plot then
		notify(player, "You don't own a base yet!")
		return
	end
	if getCash(player) < char.data.cost then
		notify(player, "Not enough cash! " .. char.data.name .. " costs " .. BrainrotData.formatCash(char.data.cost) .. ".")
		return
	end
	local slot = freeSlot(plot)
	if not slot then
		notify(player, "Your base is full (6 brainrots max)!")
		return
	end
	if isCarrying(player) then
		notify(player, "Put down what you're carrying first!")
		return
	end
	setCash(player, getCash(player) - char.data.cost)
	char.state = "owned"
	char.owner = player
	char.plot = plot
	char.slot = slot
	plot.slots[slot] = char
	removeFromList(conveyorChars, char)
	refreshPrompt(char)
	updateBrainrotCount(player)
	tweenModelTo(char, slotCFrame(plot, slot), 1.2)
	notify(player, "You bought " .. char.data.name .. " for " .. BrainrotData.formatCash(char.data.cost) .. "! It earns " .. BrainrotData.formatCash(char.data.income) .. "/s.")
end

local function trySteal(player, char)
	if char.state ~= "owned" then
		return
	end
	if char.owner == player then
		notify(player, "That's your brainrot!")
		return
	end
	local victimPlot = char.plot
	if not victimPlot then
		return
	end
	if tick() < victimPlot.lockedUntil then
		notify(player, "That base is LOCKED! Come back when the lock runs out.")
		return
	end
	local myPlot = plotOf(player)
	if not myPlot then
		notify(player, "You don't own a base yet!")
		return
	end
	if not freeSlot(myPlot) then
		notify(player, "Your base is full (6 brainrots max)!")
		return
	end
	if isCarrying(player) then
		notify(player, "You're already carrying a brainrot!")
		return
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	char.state = "carried"
	char.carrier = player
	char.originalOwner = char.owner
	if char.tween then
		char.tween:Cancel()
	end
	refreshPrompt(char)
	notify(player, "You stole " .. char.data.name .. "! Carry it back to YOUR base!")
	if char.originalOwner then
		notify(char.originalOwner, "⚠️ " .. player.DisplayName .. " is stealing your " .. char.data.name .. "! Slap them (F) or lock your base (L)!")
	end
end

local function onPrompt(player, char)
	if char.state == "conveyor" then
		tryBuy(player, char)
	elseif char.state == "owned" then
		trySteal(player, char)
	end
end

local function spawnConveyorCharacter()
	local data = BrainrotData.pickRandom()
	local model = CharacterFactory.build(data)
	model.Parent = world
	local startCFrame = CFrame.new(-78, GROUND_Y, 0) * CFrame.Angles(0, math.rad(90), 0)
	model:PivotTo(startCFrame)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = data.name
	prompt.ActionText = "Buy  " .. BrainrotData.formatCash(data.cost)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	local char = {
		model = model,
		data = data,
		state = "conveyor",
		owner = nil,
		plot = nil,
		slot = nil,
		prompt = prompt,
		tween = nil,
		cfValue = nil,
		moveConn = nil,
		weld = nil,
		carrier = nil,
		originalOwner = nil,
	}
	table.insert(characters, char)
	table.insert(conveyorChars, char)
	prompt.Triggered:Connect(function(player)
		onPrompt(player, char)
	end)
	local endCFrame = CFrame.new(78, GROUND_Y, 0) * CFrame.Angles(0, math.rad(90), 0)
	local duration = BrainrotData.CONVEYOR_LENGTH / BrainrotData.CONVEYOR_SPEED
	tweenModelTo(char, endCFrame, duration, function()
		if char.state == "conveyor" then
			despawnCharacter(char)
		end
	end)
end

-- Conveyor spawner.
task.spawn(function()
	while true do
		task.wait(BrainrotData.SPAWN_INTERVAL)
		if #conveyorChars < BrainrotData.CONVEYOR_MAX then
			spawnConveyorCharacter()
		end
	end
end)

-- Income tick: every owned brainrot pays its owner once a second.
task.spawn(function()
	while true do
		task.wait(1)
		for _, plot in ipairs(plots) do
			local owner = plot.owner
			if owner then
				local income = 0
				for _, char in ipairs(characters) do
					if char.state == "owned" and char.owner == owner then
						income = income + char.data.income
					end
				end
				if income > 0 then
					setCash(owner, getCash(owner) + income)
				end
				setIncome(owner, income)
			end
		end
	end
end)

-- Heartbeat: carried characters follow their carrier, steal completion,
-- lock expiry, and conveyor stripe animation.
local heartbeatAccum = 0
RunService.Heartbeat:Connect(function(dt)
	heartbeatAccum = heartbeatAccum + dt
	for _, stripe in ipairs(stripes) do
		local pos = stripe.CFrame.Position
		local x = pos.X + BrainrotData.CONVEYOR_SPEED * dt
		if x > 78 then
			x = -78
		end
		stripe.CFrame = CFrame.new(x, pos.Y, pos.Z)
	end
	if heartbeatAccum < 0.15 then
		return
	end
	heartbeatAccum = 0
	local now = tick()
	for _, plot in ipairs(plots) do
		if plot.owner and plot.lockedUntil > 0 and now >= plot.lockedUntil then
			plot.lockedUntil = 0
			setLockVisual(plot)
		end
	end
	for _, char in ipairs(characters) do
		if char.state == "carried" then
			local carrier = char.carrier
			local character = carrier and carrier.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not hrp or not humanoid or humanoid.Health <= 0 then
				returnCharacter(char)
			else
				char.model:PivotTo(hrp.CFrame * CFrame.new(0, 3.5, 0))
				local myPlot = plotOf(carrier)
				if myPlot then
					local c = myPlot.center
					if math.abs(hrp.Position.X - c.X) <= 10 and math.abs(hrp.Position.Z - c.Z) <= 10 then
						completeSteal(char)
					end
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- Base lock
----------------------------------------------------------------------
ToggleLockRemote.OnServerEvent:Connect(function(player)
	local plot = plotOf(player)
	if not plot then
		notify(player, "You don't own a base!")
		return
	end
	local now = tick()
	if now < plot.lockedUntil then
		-- unlock early
		plot.lockedUntil = 0
		setLockVisual(plot)
		LockUpdateRemote:FireClient(player, 0, math.max(0, plot.cooldownUntil - now))
		notify(player, "Base unlocked.")
		return
	end
	if now < plot.cooldownUntil then
		notify(player, "Lock recharging! Ready in " .. math.ceil(plot.cooldownUntil - now) .. "s.")
		LockUpdateRemote:FireClient(player, 0, plot.cooldownUntil - now)
		return
	end
	plot.lockedUntil = now + BrainrotData.LOCK_SECONDS
	plot.cooldownUntil = now + BrainrotData.LOCK_SECONDS + BrainrotData.LOCK_COOLDOWN
	setLockVisual(plot)
	LockUpdateRemote:FireClient(player, BrainrotData.LOCK_SECONDS, BrainrotData.LOCK_COOLDOWN + BrainrotData.LOCK_SECONDS)
	notify(player, "🔒 Base locked for " .. BrainrotData.LOCK_SECONDS .. "s! No one can steal from you.")
end)

----------------------------------------------------------------------
-- Slap: knock a carried brainrot out of a nearby player's hands.
----------------------------------------------------------------------
local slapCooldowns = {}

local function spawnSlapEffect(character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local boom = Instance.new("Part")
	boom.Name = "SlapEffect"
	boom.Size = Vector3.new(1, 1, 1)
	boom.Transparency = 1
	boom.Anchored = true
	boom.CanCollide = false
	boom.CFrame = hrp.CFrame * CFrame.new(0, 2.5, 0)
	boom.Parent = world
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 60)
	gui.AlwaysOnTop = true
	gui.Parent = boom
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "💥 SLAP!"
	label.TextColor3 = Color3.fromRGB(255, 220, 60)
	label.TextStrokeTransparency = 0.1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	task.delay(0.7, function()
		if boom.Parent ~= nil then
			boom:Destroy()
		end
	end)
end

SlapRemote.OnServerEvent:Connect(function(player)
	local now = tick()
	if slapCooldowns[player] and now - slapCooldowns[player] < BrainrotData.SLAP_COOLDOWN then
		return
	end
	slapCooldowns[player] = now
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local best = nil
	local bestDist = BrainrotData.SLAP_RANGE
	for _, char in ipairs(characters) do
		if char.state == "carried" and char.carrier ~= player then
			local cChar = char.carrier.Character
			local cHrp = cChar and cChar:FindFirstChild("HumanoidRootPart")
			if cHrp then
				local d = (cHrp.Position - hrp.Position).Magnitude
				if d < bestDist then
					best = char
					bestDist = d
				end
			end
		end
	end
	if not best then
		notify(player, "No one nearby is carrying a brainrot!")
		return
	end
	local victim = best.carrier
	local vChar = victim.Character
	local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
	if vHum then
		vHum.WalkSpeed = 0
		task.delay(BrainrotData.SLAP_STUN, function()
			if vHum.Parent ~= nil then
				vHum.WalkSpeed = 16
			end
		end)
	end
	spawnSlapEffect(vChar)
	returnCharacter(best)
	notify(player, "SLAP! You knocked the brainrot out of " .. victim.DisplayName .. "'s hands!")
	notify(victim, "💥 " .. player.DisplayName .. " slapped you! Your stolen brainrot dropped!")
end)

----------------------------------------------------------------------
-- Players
----------------------------------------------------------------------
local function onCharacterAdded(player, character)
	local plot = plotOf(player)
	if plot then
		player.RespawnLocation = plot.spawnLoc
	end
end

local function onCharacterRemoving(player, _character)
	for _, char in ipairs(characters) do
		if char.state == "carried" and char.carrier == player then
			returnCharacter(char)
		end
	end
	task.delay(3, function()
		if player.Parent ~= nil then
			player:LoadCharacter()
		end
	end)
end

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = BrainrotData.START_CASH
	cash.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	local count = Instance.new("IntValue")
	count.Name = "Brainrots"
	count.Value = 0
	count.Parent = leaderstats
	leaderstats.Parent = player

	local plot = nil
	for _, p in ipairs(plots) do
		if p.owner == nil then
			plot = p
			break
		end
	end
	if plot then
		plot.owner = player
		player.RespawnLocation = plot.spawnLoc
		refreshPlotSign(plot)
		notify(player, "Welcome to Brainrot Bay! This is YOUR base. Buy brainrots off the conveyor (E) and lock your base (L)!")
	else
		notify(player, "All 8 bases are taken! Hang around — a base frees up when someone leaves.")
	end
	LockUpdateRemote:FireClient(player, 0, 0)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterRemoving:Connect(function(character)
		onCharacterRemoving(player, character)
	end)
	player:LoadCharacter()
end

local function onPlayerRemoving(player)
	for _, char in ipairs(characters) do
		if char.state == "carried" and char.carrier == player then
			returnCharacter(char)
		end
	end
	local plot = plotOf(player)
	if plot then
		for i = #characters, 1, -1 do
			local char = characters[i]
			if char.owner == player and char.state == "owned" then
				despawnCharacter(char)
			end
		end
		plot.owner = nil
		plot.lockedUntil = 0
		plot.cooldownUntil = 0
		for i = 1, BrainrotData.MAX_SLOTS do
			plot.slots[i] = nil
		end
		setLockVisual(plot)
		refreshPlotSign(plot)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("Brainrot Bay server ready: " .. #plots .. " plots, conveyor running.")
