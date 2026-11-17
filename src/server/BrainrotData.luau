-- Brainrot Bay: character roster and game tuning.
-- Every character here was invented for this game.

local BrainrotData = {}

BrainrotData.START_CASH = 100
BrainrotData.PLOT_COUNT = 8
BrainrotData.PLOT_SIZE = 20
BrainrotData.MAX_SLOTS = 6
BrainrotData.CONVEYOR_MAX = 6
BrainrotData.SPAWN_INTERVAL = 3.5
BrainrotData.CONVEYOR_LENGTH = 156 -- studs, from x=-78 to x=+78
BrainrotData.CONVEYOR_SPEED = 4 -- studs per second
BrainrotData.BELT_Y = 0.4 -- top surface of the conveyor belt
BrainrotData.LOCK_SECONDS = 30
BrainrotData.LOCK_COOLDOWN = 45
BrainrotData.SLAP_RANGE = 9
BrainrotData.SLAP_COOLDOWN = 3
BrainrotData.SLAP_STUN = 1.2

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(120, 200, 90),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(170, 90, 230),
	Legendary = Color3.fromRGB(255, 170, 30),
	Mythic = Color3.fromRGB(255, 70, 110),
	["Brainrot God"] = Color3.fromRGB(255, 60, 220),
	Secret = Color3.fromRGB(30, 30, 30),
}

-- accessory kinds understood by CharacterFactory:
-- "pepperoni", "bat", "fin", "banana", "wing", "cactus", "tutu",
-- "fridge", "ring", "crown", "tentacles", "bowtie", "none"
BrainrotData.CHARACTERS = {
	{
		name = "Noobini Pizzanini",
		rarity = "Common",
		cost = 25,
		income = 1,
		weight = 22,
		scale = 1.0,
		bodyColor = Color3.fromRGB(255, 210, 80),
		headColor = Color3.fromRGB(255, 190, 60),
		accessory = { kind = "pepperoni", color = Color3.fromRGB(220, 60, 60) },
	},
	{
		name = "Tung Tung Sahur",
		rarity = "Common",
		cost = 50,
		income = 2,
		weight = 18,
		scale = 1.1,
		bodyColor = Color3.fromRGB(150, 100, 55),
		headColor = Color3.fromRGB(170, 120, 70),
		accessory = { kind = "bat", color = Color3.fromRGB(120, 80, 40) },
	},
	{
		name = "Tralalero Tralala",
		rarity = "Rare",
		cost = 150,
		income = 5,
		weight = 15,
		scale = 1.1,
		bodyColor = Color3.fromRGB(70, 140, 255),
		headColor = Color3.fromRGB(90, 160, 255),
		accessory = { kind = "fin", color = Color3.fromRGB(40, 90, 200) },
	},
	{
		name = "Chimpanzini Bananini",
		rarity = "Rare",
		cost = 300,
		income = 10,
		weight = 12,
		scale = 1.0,
		bodyColor = Color3.fromRGB(140, 95, 55),
		headColor = Color3.fromRGB(160, 115, 70),
		accessory = { kind = "banana", color = Color3.fromRGB(255, 230, 60) },
	},
	{
		name = "Bombardiro Crocodilo",
		rarity = "Epic",
		cost = 750,
		income = 20,
		weight = 9,
		scale = 1.2,
		bodyColor = Color3.fromRGB(60, 170, 80),
		headColor = Color3.fromRGB(80, 190, 100),
		accessory = { kind = "wing", color = Color3.fromRGB(230, 230, 230) },
	},
	{
		name = "Lirili Larila",
		rarity = "Epic",
		cost = 1500,
		income = 40,
		weight = 7,
		scale = 1.2,
		bodyColor = Color3.fromRGB(230, 200, 140),
		headColor = Color3.fromRGB(240, 215, 160),
		accessory = { kind = "cactus", color = Color3.fromRGB(60, 180, 90) },
	},
	{
		name = "Ballerina Cappuccina",
		rarity = "Legendary",
		cost = 3000,
		income = 80,
		weight = 5,
		scale = 1.0,
		bodyColor = Color3.fromRGB(255, 180, 210),
		headColor = Color3.fromRGB(255, 220, 230),
		accessory = { kind = "tutu", color = Color3.fromRGB(255, 140, 190) },
	},
	{
		name = "Frigo Camelo",
		rarity = "Legendary",
		cost = 6000,
		income = 150,
		weight = 4,
		scale = 1.3,
		bodyColor = Color3.fromRGB(120, 190, 235),
		headColor = Color3.fromRGB(150, 205, 245),
		accessory = { kind = "fridge", color = Color3.fromRGB(200, 210, 220) },
	},
	{
		name = "La Vaca Saturno Saturnita",
		rarity = "Mythic",
		cost = 12000,
		income = 300,
		weight = 3,
		scale = 1.3,
		bodyColor = Color3.fromRGB(190, 130, 230),
		headColor = Color3.fromRGB(210, 160, 245),
		accessory = { kind = "ring", color = Color3.fromRGB(255, 215, 90) },
	},
	{
		name = "Giraffa Celeste",
		rarity = "Mythic",
		cost = 25000,
		income = 600,
		weight = 2.5,
		scale = 1.5,
		bodyColor = Color3.fromRGB(120, 200, 255),
		headColor = Color3.fromRGB(150, 215, 255),
		accessory = { kind = "crown", color = Color3.fromRGB(255, 215, 90) },
	},
	{
		name = "Los Tralaleritos",
		rarity = "Brainrot God",
		cost = 50000,
		income = 1200,
		weight = 1.2,
		scale = 1.4,
		bodyColor = Color3.fromRGB(60, 120, 255),
		headColor = Color3.fromRGB(90, 150, 255),
		accessory = { kind = "fin", color = Color3.fromRGB(255, 220, 60) },
	},
	{
		name = "Graipuss Medussi",
		rarity = "Secret",
		cost = 100000,
		income = 2500,
		weight = 0.8,
		scale = 1.4,
		bodyColor = Color3.fromRGB(150, 80, 200),
		headColor = Color3.fromRGB(180, 110, 220),
		accessory = { kind = "tentacles", color = Color3.fromRGB(120, 60, 170) },
	},
}

function BrainrotData.pickRandom()
	local total = 0
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		total = total + char.weight
	end
	local roll = math.random() * total
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		roll = roll - char.weight
		if roll <= 0 then
			return char
		end
	end
	return BrainrotData.CHARACTERS[1]
end

function BrainrotData.formatCash(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 10000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

return BrainrotData
