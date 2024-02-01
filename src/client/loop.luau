local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)
local loader = require(ReplicatedStorage.loader)

local gorp = require(ReplicatedStorage.packages.gorp)
local loop_setup = require(ReplicatedStorage.loop_setup)

local client = ReplicatedStorage.client

local world = gorp.hook_world(ecr.registry(), "client")
world:context()

return {
	startup = function()
		loader.load_modules(script.Parent.startup, true, world)
	end,
	loop = loop_setup(
		world,
		client.systems,

		{ interval = 1 },
		"electrical/handle_part_hover"
	),
}
