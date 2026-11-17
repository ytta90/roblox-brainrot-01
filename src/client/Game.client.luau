-- Brainrot Bay: client. Cash/income HUD, base lock button, notifications,
-- slap (F) and lock (L) keybinds, and a how-to-play panel.
-- The 3D camera is Roblox's default third-person camera; this script only
-- adds the 2D HUD on top of the 3D world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local ToggleLockRemote = remotes:WaitForChild("ToggleLock")
local SlapRemote = remotes:WaitForChild("Slap")
local NotifyRemote = remotes:WaitForChild("Notify")
local LockUpdateRemote = remotes:WaitForChild("LockUpdate")

local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local brainrotsValue = leaderstats:WaitForChild("Brainrots")

----------------------------------------------------------------------
-- HUD
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function formatCash(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 10000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

-- Top-left cash panel.
local cashPanel = Instance.new("Frame")
cashPanel.Name = "CashPanel"
cashPanel.AnchorPoint = Vector2.new(0, 0)
cashPanel.Position = UDim2.fromOffset(16, 16)
cashPanel.Size = UDim2.fromOffset(240, 96)
cashPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
cashPanel.BackgroundTransparency = 0.15
cashPanel.BorderSizePixel = 0
cashPanel.Parent = gui
local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 12)
cashCorner.Parent = cashPanel

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Position = UDim2.fromOffset(14, 8)
cashLabel.Size = UDim2.new(1, -28, 0, 44)
cashLabel.BackgroundTransparency = 1
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.Parent = cashPanel

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Income"
incomeLabel.Position = UDim2.fromOffset(14, 52)
incomeLabel.Size = UDim2.new(1, -28, 0, 34)
incomeLabel.BackgroundTransparency = 1
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
incomeLabel.TextScaled = true
incomeLabel.Font = Enum.Font.FredokaOne
incomeLabel.Parent = cashPanel

local function refreshCash()
	cashLabel.Text = "💰 " .. formatCash(cashValue.Value)
	incomeLabel.Text = "+" .. formatCash(incomeValue.Value) .. "/s  •  🧠 " .. tostring(brainrotsValue.Value) .. " brainrots"
end
cashValue:GetPropertyChangedSignal("Value"):Connect(refreshCash)
incomeValue:GetPropertyChangedSignal("Value"):Connect(refreshCash)
brainrotsValue:GetPropertyChangedSignal("Value"):Connect(refreshCash)
refreshCash()

-- Notification banner (center top).
local notifyLabel = Instance.new("TextLabel")
notifyLabel.Name = "Notify"
notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
notifyLabel.Position = UDim2.new(0.5, 0, 0, 130)
notifyLabel.Size = UDim2.new(0.7, 0, 0, 44)
notifyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
notifyLabel.BackgroundTransparency = 0.15
notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifyLabel.TextScaled = true
notifyLabel.Font = Enum.Font.FredokaOne
notifyLabel.TextTransparency = 1
notifyLabel.BackgroundTransparency = 1
notifyLabel.Parent = gui
local notifyCorner = Instance.new("UICorner")
notifyCorner.CornerRadius = UDim.new(0, 12)
notifyCorner.Parent = notifyLabel

local notifyTween = nil
local function showNotification(message)
	notifyLabel.Text = message
	if notifyTween then
		notifyTween:Cancel()
	end
	notifyLabel.TextTransparency = 0
	notifyLabel.BackgroundTransparency = 0.15
	notifyTween = TweenService:Create(notifyLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2.6), {
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
	notifyTween:Play()
end
NotifyRemote.OnClientEvent:Connect(showNotification)

-- Base lock button (bottom right).
local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.AnchorPoint = Vector2.new(1, 1)
lockButton.Position = UDim2.new(1, -16, 1, -16)
lockButton.Size = UDim2.fromOffset(220, 56)
lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextScaled = true
lockButton.Font = Enum.Font.FredokaOne
lockButton.Text = "🔒 Lock Base (L)"
lockButton.Parent = gui
local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 12)
lockCorner.Parent = lockButton

-- Lock state: server sends remaining seconds; the client counts down locally.
local lockEndsAt = 0
local cooldownEndsAt = 0

local function refreshLockButton()
	local now = tick()
	if now < lockEndsAt then
		lockButton.Text = "🔒 Locked (" .. math.ceil(lockEndsAt - now) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	elseif now < cooldownEndsAt then
		lockButton.Text = "⏳ Lock ready in " .. math.ceil(cooldownEndsAt - now) .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	else
		lockButton.Text = "🔒 Lock Base (L)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
	end
end

LockUpdateRemote.OnClientEvent:Connect(function(lockRemaining, cooldownRemaining)
	local now = tick()
	lockEndsAt = now + (lockRemaining or 0)
	cooldownEndsAt = now + (cooldownRemaining or 0)
	refreshLockButton()
end)

lockButton.MouseButton1Click:Connect(function()
	ToggleLockRemote:FireServer()
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		refreshLockButton()
	end
end)

-- Bottom-left hint.
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "Hint"
hintLabel.AnchorPoint = Vector2.new(0, 1)
hintLabel.Position = UDim2.new(0, 16, 1, -16)
hintLabel.Size = UDim2.fromOffset(360, 30)
hintLabel.BackgroundTransparency = 1
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Text = "E — buy / steal  •  F — slap  •  L — lock base"
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hintLabel.TextStrokeTransparency = 0.4
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.FredokaOne
hintLabel.Parent = gui

-- How-to-play panel (shown once at join).
local helpFrame = Instance.new("Frame")
helpFrame.Name = "Help"
helpFrame.AnchorPoint = Vector2.new(0.5, 0.5)
helpFrame.Position = UDim2.fromScale(0.5, 0.5)
helpFrame.Size = UDim2.fromOffset(460, 330)
helpFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
helpFrame.BackgroundTransparency = 0.05
helpFrame.BorderSizePixel = 0
helpFrame.Parent = gui
local helpCorner = Instance.new("UICorner")
helpCorner.CornerRadius = UDim.new(0, 16)
helpCorner.Parent = helpFrame

local helpTitle = Instance.new("TextLabel")
helpTitle.Position = UDim2.fromOffset(0, 14)
helpTitle.Size = UDim2.new(1, 0, 0, 44)
helpTitle.BackgroundTransparency = 1
helpTitle.Text = "🧠 BRAINROT BAY"
helpTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
helpTitle.TextScaled = true
helpTitle.Font = Enum.Font.FredokaOne
helpTitle.Parent = helpFrame

local helpBody = Instance.new("TextLabel")
helpBody.Position = UDim2.fromOffset(24, 64)
helpBody.Size = UDim2.new(1, -48, 0, 200)
helpBody.BackgroundTransparency = 1
helpBody.TextXAlignment = Enum.TextXAlignment.Left
helpBody.TextYAlignment = Enum.TextYAlignment.Top
helpBody.TextWrapped = true
helpBody.TextColor3 = Color3.fromRGB(240, 240, 240)
helpBody.TextSize = 18
helpBody.Font = Enum.Font.SourceSans
helpBody.Text = "1. Brainrots walk down the middle conveyor.\n"
	.. "Walk up and press E to BUY one — it walks to your base and earns cash every second.\n\n"
	.. "2. Press E on a brainrot in someone else's UNLOCKED base to STEAL it. Carry it home!\n\n"
	.. "3. Lock your base (L) for 30s so nobody can steal from you. Slap thieves with F!\n\n"
	.. "4. Rare brainrots earn way more. First to get rich wins the leaderboard!"
helpBody.Parent = helpFrame

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(0.5, -70, 1, -58)
closeButton.Size = UDim2.fromOffset(140, 44)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "Let's go!"
closeButton.TextScaled = true
closeButton.Font = Enum.Font.FredokaOne
closeButton.Parent = helpFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton
closeButton.MouseButton1Click:Connect(function()
	helpFrame.Visible = false
end)

----------------------------------------------------------------------
-- Keybinds
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		SlapRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.L then
		ToggleLockRemote:FireServer()
	end
end)
