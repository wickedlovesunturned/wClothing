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
 *  Version  : 1.0.1
 *  Built    : 2026
 * ─────────────────────────────────────────────
 *  © Wicked Development — All Rights Reserved
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")

local player         = Players.LocalPlayer
local Remotes        = ReplicatedStorage:WaitForChild("ClothingRemotes", 15)
local ToggleClothing = Remotes:WaitForChild("ToggleClothing", 10)
local SyncClothing   = Remotes:WaitForChild("SyncClothing", 10)

SyncClothing.OnClientEvent:Connect(function(_) end)

local COMMANDS = {
	["/hat"]   = "hat",
	["/hair"]  = "hair",
	["/back"]  = "back",
	["/waist"] = "waist",
	["/shirt"] = "shirt",
	["/pants"] = "pants",
}

local lastFired = {}
local DEBOUNCE  = 0.5

local function onChat(message)
	local cmd = message:lower():match("^(/[%a]+)")
	if not cmd then return end
	local slot = COMMANDS[cmd]
	if not slot then return end
	local now = tick()
	if lastFired[slot] and (now - lastFired[slot]) < DEBOUNCE then return end
	lastFired[slot] = now
	ToggleClothing:FireServer(slot)
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.SendingMessage:Connect(function(msg)
		onChat(msg.Text)
	end)
else
	player.Chatted:Connect(onChat)
end

-- — Built by Wicked Development | github.com/wickedlovesunturned
