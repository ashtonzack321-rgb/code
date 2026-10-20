--[[
	Main (client): starts the UI controllers in ./Controllers.
]]

local Controllers = script.Parent:WaitForChild("Controllers")

local HUDController = require(Controllers:WaitForChild("HUDController"))
local ShopController = require(Controllers:WaitForChild("ShopController"))

HUDController.start()
ShopController.start(HUDController)
