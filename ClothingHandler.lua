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
 *  Project  : wClothing
 *  Author   : Wicked
 *  Version  : 1.0.0
 *  Built    : 2026
 * ─────────────────────────────────────────────
 *  © Wicked Development — All Rights Reserved
--]]

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

-- Method 1: AccessoryType (R15 / proper tagged accessories)
local ACCESSORY_TYPE_SLOTS = {
	hat   = { Enum.AccessoryType.Hat },
	hair  = { Enum.AccessoryType.Hair },
	back  = { Enum.AccessoryType.Back },
	waist = { Enum.AccessoryType.Waist },
}

-- Method 2: Attachment names inside Handle (R6 / ACS / untagged accessories)
local ATTACHMENT_SLOTS = {
	hat   = { "HatAttachment", "TopScaleAttachment", "FaceFrontAttachment", "FaceBackAttachment" },
	hair  = { "HairAttachment" },
	back  = { "BodyBackAttachment" },
	waist = { "WaistBackAttachment", "WaistFrontAttachment", "WaistCenterAttachment" },
}

-- Returns the slot name for an accessory using both methods
local function getAccessorySlot(accessory)
	-- Method 1: try AccessoryType first
	if accessory.AccessoryType ~= Enum.AccessoryType.Unknown then
		for slot, types in pairs(ACCESSORY_TYPE_SLOTS) do
			for _, t in ipairs(types) do
				if accessory.AccessoryType == t then
					return slot
				end
			end
		end
	end

	-- Method 2: fallback to attachment name inside Handle
	local handle = accessory:FindFirstChild("Handle")
	if handle then
		for slot, attachNames in pairs(ATTACHMENT_SLOTS) do
			for _, attachName in ipairs(attachNames) do
				if handle:FindFirstChild(attachName) then
					return slot
				end
			end
		end
	end

	return nil
end

local function buildDesc(originalDesc, state)
	local desc = originalDesc:Clone()

	if state.shirt then
		desc.Shirt         = 0
		desc.GraphicTShirt = 0
	end
	if state.pants then
		desc.Pants = 0
	end

	-- Strip toggled accessory slots via Method 1 (AccessoryType) on the description
	local removedTypes = {}
	for slot, removed in pairs(state) do
		if removed and ACCESSORY_TYPE_SLOTS[slot] then
			for _, t in ipairs(ACCESSORY_TYPE_SLOTS[slot]) do
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

	-- Apply modified description (Method 1 handles shirt/pants + tagged accessories)
	humanoid:ApplyDescription(buildDesc(data.originalDesc, data.state))

	-- After ApplyDescription re-adds accessories, sweep with Method 2
	-- to catch anything that slipped through (R6/ACS untagged accessories)
	task.defer(function()
		character = player.Character
		if not character then return end
		for _, obj in ipairs(character:GetChildren()) do
			if obj:IsA("Accessory") then
				local slot = getAccessorySlot(obj)
				if slot and data.state[slot] then
					obj:Destroy()
				end
			end
		end
	end)

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
