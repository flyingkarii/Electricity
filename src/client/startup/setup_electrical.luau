local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.ct)
local tst = require(ReplicatedStorage.tst)

local circuit_id = 0

local function setup_io(world: tst.Registry, io_instance: Part)
	local id = world:create()
	world:set(id, ct.circuit_id, circuit_id)
	world:set(id, ct.occupied, {})
	world:set(id, ct.charge, 0)

	if io_instance.Parent == nil then return end

	io_instance.Parent.Name = tostring(id)
	circuit_id += 1
end

local function setup_component(world: tst.Registry, component: Model)
	for _, child in component:GetChildren() do
		if not child:IsA "Part" then continue end
		if child:HasTag "Input" or child:HasTag "Output" then
			setup_io(world, child)
		end
	end
end

return function(world: tst.Registry)
	Players.LocalPlayer.CharacterAdded:Wait()

	for _, child in workspace.Electrical:GetChildren() do
		setup_component(world, child)
	end
end
