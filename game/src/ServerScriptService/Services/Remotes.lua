--[[
	Remotes: creates ReplicatedStorage.Remotes. The client only ever sends intents; the
	server checks everything (Systems and Scripts: "the server decides everything").

	  Notify         RemoteEvent     server -> client   (text, kind)   kind = "info" | "good" | "bad"
	  TreadmillStep  RemoteEvent     server -> client   (gain, spurMultiplier)
	  Shop           RemoteFunction  client -> server   (action, arg) -> ok, message
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local DEFINITIONS = {
	Notify = "RemoteEvent",
	TreadmillStep = "RemoteEvent",
	Shop = "RemoteFunction",
}

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

for name, className in pairs(DEFINITIONS) do
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end
	Remotes[name] = remote
end

function Remotes.notify(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

return Remotes
