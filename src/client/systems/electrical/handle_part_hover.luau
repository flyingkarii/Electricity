local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local ct = require(ReplicatedStorage.ct)
local tst = require(ReplicatedStorage.tst)

local function is_occupied(world: tst.Registry, io: Part): boolean
	local component = io.Parent :: Model
	local id = tonumber(component.Name)
	if not id then return false end

	for _, part in world:get(id, ct.occupied) do
		if part == io then return true end
	end

	return false
end

return function(world: tst.Registry)
	local character = Players.LocalPlayer.Character

	if not character then return end

	local camera = workspace.CurrentCamera
	local mouse_loc = UserInputService:GetMouseLocation()
	local point = camera:ViewportPointToRay(mouse_loc.X, mouse_loc.Y)
	local result = workspace:Raycast(point.Origin, point.Direction * 50)
	local last_hovering = world:context():try_get(ct.io_hovering)

	if result == nil then
		if last_hovering then
			local was_selected = is_occupied(world, last_hovering)
			if was_selected then return end

			last_hovering.BrickColor = BrickColor.new "Institutional white"
			last_hovering.Transparency = 0.7
		end

		return
	end

	if
		not result.Instance:HasTag "Input"
		and not result.Instance:HasTag "Output"
	then
		return
	end

	local was_selected = is_occupied(world, result.Instance)
	if was_selected then return end

	result.Instance.BrickColor = BrickColor.new "Gold"
	result.Instance.Transparency = 0.2
	world:context():set(ct.io_hovering, result.Instance)
end
