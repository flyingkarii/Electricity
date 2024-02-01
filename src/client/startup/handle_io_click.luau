local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local ct = require(ReplicatedStorage.ct)
local remotes = require(ReplicatedStorage.net.remotes)
local tst = require(ReplicatedStorage.tst)

local selected_input: Part? = nil
local selected_output: Part? = nil

local function is_occupied(world: tst.Registry, io: Part): boolean
	local component = io.Parent :: Model
	local id = tonumber(component.Name)
	if not id then return false end

	for _, part in world:get(id, ct.occupied) do
		if part == io then return true end
	end

	return false
end

local function handle_existing_io(changing_io: Part, occupied)
	changing_io.BrickColor = BrickColor.new "Institutional white"
	changing_io.Transparency = 0.7

	for i, part: Part in occupied do
		if part == selected_input then table.remove(occupied, i) end
	end

	return occupied
end

local function io_selected(io_instance: Part, is_first: boolean)
	if is_first then
		io_instance.Transparency = 0.1
		return
	end

	if selected_input == nil and selected_output == nil then return end

	local current_input = selected_input :: Part
	local current_output = selected_output :: Part
	local ios = { current_input, current_output }

	for _, part: Part in ios do
		part.Transparency = 0.7
		part.BrickColor = BrickColor.new "Institutional white"
	end
end

local function on_io_click(world: tst.Registry, io_instance: Part)
	local model = io_instance.Parent
	if not model or not model:IsA "Model" then return end

	local id = tonumber(model.Name)

	if not id then
		warn "Has an input, but isn't named after an id...?!"
		return
	end

	local io_type = if io_instance:HasTag "Input"
		then "input"
		elseif io_instance:HasTag "Output" then "output"
		else nil

	if io_type == nil then
		warn "invalid I/O type"
		return
	end

	local occupied = world:get(id, ct.occupied)

	if io_type == "input" and selected_input ~= nil then
		occupied = handle_existing_io(selected_input, occupied)
	end

	if io_type == "output" and selected_output ~= nil then
		occupied = handle_existing_io(selected_output, occupied)
	end

	if is_occupied(world, io_instance) then return end

	if io_type == "output" then
		table.insert(occupied, io_instance)
		world:set(id, ct.occupied, occupied)
		selected_output = io_instance
	else
		table.insert(occupied, io_instance)
		world:set(id, ct.occupied, occupied)
		selected_input = io_instance
	end

	-- if output or input don't already have an opposite input or output,
	-- this is the first selection, so return.
	if
		(io_type == "output" and selected_input == nil)
		or (io_type == "input" and selected_output == nil)
	then
		io_selected(io_instance, true)
		return
	end

	if
		io_type == "input" and selected_output
		or io_type == "output" and selected_input
	then
		io_selected(io_instance, false)
		remotes.try_wire.fire(id)
	end
end

local function on_try_click(world: tst.Registry, input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local mouse_loc = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(mouse_loc.X, mouse_loc.Y)
	local raycast_result = workspace:Raycast(ray.Origin, ray.Direction * 50)
	if not raycast_result then return end

	local instance = raycast_result.Instance

	if not instance:HasTag "Input" and not instance:HasTag "Output" then
		return
	end

	on_io_click(world, instance)
end

return function(world: tst.Registry)
	UserInputService.InputEnded:Connect(function(input, processed)
		on_try_click(world, input, processed)
	end)
end
