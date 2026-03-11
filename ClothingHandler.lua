--[[
 * ██╗    ██╗██╗ ██████╗██╗  ██╗███████╗██████╗
 * ██║    ██║██║██╔════╝██║ ██╔╝██╔════╝██╔══██╗
 * ██║ █╗ ██║██║██║     █████╔╝ █████╗  ██║  ██║
 * ██║███╗██║██║██║     ██╔═██╗ ██╔══╝  ██║  ██║
 * ╚███╔███╔╝██║╚██████╗██║  ██╗███████╗██████╔╝
 *  ╚══╝╚══╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝
 *
 *  W I C K E D   D E V E L O P M E N T
 * ─────────────────────────────────────────────
 *  Project  : Clothing Strip System
 *  Author   : Wicked
 *  Version  : 1.0.0
 *  Built    : 2026
 * ─────────────────────────────────────────────
 *  © Wicked Development — All Rights Reserved
--]]

-- ClothingHandler (Script — ServerScriptService) 

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:FindFirstChild("ClothingRemotes") or Instance.new("Folder")
Remotes.Name   = "ClothingRemotes"
Remotes.Parent = ReplicatedStorage

local function getRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name, r.Parent = name, Remotes
	end
	return r
end

local ToggleClothing = getRemote("ToggleClothing")
local SyncClothing   = getRemote("SyncClothing")

local playerData = {}

local function getData(player)
	playerData[player.UserId] = playerData[player.UserId] or { state = {}, originalDesc = nil }
	return playerData[player.UserId]
end

local ACC_TYPES = {
	hat   = { Enum.AccessoryType.Hat },
	hair  = { Enum.AccessoryType.Hair },
	back  = { Enum.AccessoryType.Back },
	waist = { Enum.AccessoryType.Waist },
}

local function buildDesc(originalDesc, state)
	local desc = originalDesc:Clone()

	if state.shirt then
		desc.Shirt = 0
		desc.GraphicTShirt = 0
	end
	if state.pants then
		desc.Pants = 0
	end

	local removedTypes = {}
	for slot, removed in pairs(state) do
		if removed and ACC_TYPES[slot] then
			for _, t in ipairs(ACC_TYPES[slot]) do
				removedTypes[t] = true
			end
		end
	end

	if next(removedTypes) then
		local filtered = {}
		for _, acc in ipairs(desc:GetAccessories(false)) do
			if not removedTypes[acc.AccessoryType] then
				table.insert(filtered, acc)
			end
		end
		desc:SetAccessories(filtered, false)
	end

	return desc
end

local function applyToPlayer(player)
	local data = getData(player)
	if not data.originalDesc then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:ApplyDescription(buildDesc(data.originalDesc, data.state))
	SyncClothing:FireClient(player, data.state)
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local data = getData(player)

	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)

	data.originalDesc = (ok and desc) or humanoid:GetAppliedDescription()

	local hasAny = false
	for _, v in pairs(data.state) do if v then hasAny = true; break end end
	if hasAny then
		task.wait(0.5)
		applyToPlayer(player)
	end
end

local VALID_SLOTS = { hat=true, hair=true, back=true, waist=true, shirt=true, pants=true }

ToggleClothing.OnServerEvent:Connect(function(player, slot)
	slot = tostring(slot):lower()
	if not VALID_SLOTS[slot] then return end

	local data = getData(player)
	data.state[slot] = not data.state[slot]

	applyToPlayer(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- — Built by Wicked Development | github.com/wickedlovesunturned
