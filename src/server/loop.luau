local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ct = require(ReplicatedStorage.ct)
local ecr = require(ReplicatedStorage.packages.ecr)
local gorp = require(ReplicatedStorage.packages.gorp)
local loader = require(ReplicatedStorage.loader)
local loop_setup = require(ReplicatedStorage.loop_setup)

local world = gorp.hook_world(ecr.registry(), "server")
world:context()

return {
	startup = function()
		loader.load_modules(script.Parent.startup, true, world)
	end,
	loop = loop_setup(world, ServerStorage.systems),
}
