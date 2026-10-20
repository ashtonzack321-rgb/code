--[[
	Main (client): starts the UI controllers in ./Controllers.
]]

local Controllers = script.Parent:WaitForChild("Controllers")

local HUDController = require(Controllers:WaitForChild("HUDController"))
local ShopController = require(Controllers:WaitForChild("ShopController"))
local IncomePops = require(Controllers:WaitForChild("IncomePops"))

HUDController.start()
ShopController.start(HUDController)
IncomePops.start()
