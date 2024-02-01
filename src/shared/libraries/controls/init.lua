--[[

This file handles keybinding and actions.

shut up harry i will reimplement CAS if i want to

TODO: consider case:
	Action begins - No signal fire
	Listener connected
	Action ends - Fires signal

	Listener may make assumption that the signal always will have fired for begin before it fires for end.
	This will cause an error in the case that the listener depends on some initialization done on action begin.

TODO: add check for if 2 actions with same keybind are enabled at the same priority (uh oh)

]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"

local default_keybinds = require(script.default_keybinds)
local enum_serializer = require(ReplicatedStorage.libraries.enum_serializer)
local tst = require(ReplicatedStorage.tst)

local deserialize_enum = enum_serializer.deserialize

type ActionAndKeybind = {
	Action: tst.ActionType,
	Keybind: tst.Keybind,
}

type InputData = {
	Type: "begin" | "hold" | "end",
	Input: tst.Input,
}

--- map action to a priority (nil if it is disabled) (larger number = higher priority)
local priorities: { [tst.ActionType]: number } = {}
--- map action to a keybind
local action_keybinds: { [tst.ActionType]: tst.Keybind } = {}
--- all raw inputs currently held
local held_inputs: { [tst.RawInput]: true } = {}
--- all actions that were started and triggering input not yet released
local held_actions: { [tst.RawInput]: { tst.ActionType } } = {}
--- maps raw input to an array of keybinds with same triggers
--- keybinds are primary sorted by `RequiredHeld` array size and secondary sorted by priority
--- recomputed each time an action is enabled or disabled
local input_map: { [tst.RawInput]: { ActionAndKeybind } } = {}
--- maps action type to a input. this is more easy to work with for ecs systems.
local held: { [tst.ActionType]: InputData } = {}

local function get_raw_input(input: InputObject): tst.RawInput
	return input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType
		or input.KeyCode
end

-- loads and registers a map of action to serialized keybind
-- any action defined in `defaultKeybinds` that is not specified here
-- is automatically included
local function load_serialized_keybinds(data: {
	[tst.ActionType]: tst.SerializedKeybind,
})
	-- maps a trigger to all keybinds using the same trigger
	local keybinds = {} :: { [tst.ActionType]: tst.Keybind }

	local function deserialize_keybind(
		serialized_keybind: tst.SerializedKeybind
	): tst.Keybind
		local trigger = deserialize_enum(serialized_keybind.Trigger)

		local required_held = {}
		for i, serialized_enum in serialized_keybind.RequiredHeld do
			required_held[i] = deserialize_enum(serialized_enum)
		end

		return {
			Trigger = trigger,
			RequiredHeld = required_held,
		}
	end

	-- TODO: dont load keybinds that do not have a default?

	-- deserialize all keybinds and add to map
	for action: tst.ActionType, serializedKeybind in data do
		keybinds[action] = deserialize_keybind(serializedKeybind)
	end

	-- add all default keybinds that were not specified in data
	for action: tst.ActionType, keybind in default_keybinds do
		if not data[action] then
			assert(not keybinds[action])
			keybinds[action] = keybind
		end
	end

	action_keybinds = keybinds
end

-- computes an input map from raw input to an array of matching actions and keybinds
-- using data from loaded keybinds
local function compute_input_map()
	-- maps a trigger to all keybinds using the same trigger
	debug.profilebegin "Recompute Input Map"
	local map = {} :: { [tst.RawInput]: { ActionAndKeybind } }

	for action: tst.ActionType, keybind in action_keybinds do
		if not priorities[action] then continue end

		local trigger = keybind.Trigger
		local keybinds = map[trigger]

		if not keybinds then
			keybinds = {}
			map[trigger] = keybinds
		end

		table.insert(keybinds, {
			Action = action :: tst.ActionType,
			Keybind = keybind,
		})
	end

	--[[

	Each keybinds array is sorted with:
		- Primary order of `RequiredHeld` size
		- Secondary order of action priority

	We do this so that more complicated keybinds like [CTRL + CLICK] is parsed before just [CLICK]
	and also for different actions with the same keybind, higher priority actions are parsed before
	lower priority actions.

	[CTRL + CLICK] will be parsed before [CLICK] even if the latter has a higher priority if they are bound to two
	different actions.

	]]

	for _, keybinds in map do
		table.sort(keybinds, function(a, b)
			local priority_a = priorities[a.Action]
			local priority_b = priorities[b.Action]
			assert(
				priority_a and priority_b,
				"error while sorting, no priority for action"
			)

			return if #a.Keybind.RequiredHeld == #b.Keybind.RequiredHeld
				then priority_a > priority_b
				else #a.Keybind.RequiredHeld > #b.Keybind.RequiredHeld
		end)
	end

	-- update current held actions
	-- handles case where an action begins and keybindings are changed while an action is held
	local updated_held_actions = {} :: { [tst.RawInput]: { tst.ActionType } }
	for trigger, actions in held_actions do
		updated_held_actions[trigger] = actions
	end

	held_actions = updated_held_actions
	input_map = map
	debug.profileend()
end

local function process_raw_input_began(input: InputObject, gs)
	if gs then return end

	local raw_input = get_raw_input(input)
	held_inputs[raw_input] = true

	local action_and_keybinds = input_map[raw_input]
	if not action_and_keybinds then return end

	local matched_actions_and_keybinds: {
		{
			Action: tst.ActionType,
			Keybind: tst.Keybind,
		}
	} =
		{}

	-- check all keybinds and try find first that matches criteria
	local min_extras = 0
	for _, action_and_keybind in action_and_keybinds do
		local all_held = true
		if #action_and_keybind.Keybind.RequiredHeld < min_extras then
			continue
		end

		for _, required_held in action_and_keybind.Keybind.RequiredHeld do
			if not held_inputs[required_held] then
				all_held = false
				break
			end
		end

		if all_held then
			min_extras =
				math.max(min_extras, #action_and_keybind.Keybind.RequiredHeld)
			table.insert(matched_actions_and_keybinds, action_and_keybind)
		end
	end

	if #matched_actions_and_keybinds == 0 then return end

	held_actions[raw_input] = {}
	for _, matched_action_and_keybind in matched_actions_and_keybinds do
		if #matched_action_and_keybind.Keybind.RequiredHeld < min_extras then
			continue
		end
		local action: tst.ActionType = matched_action_and_keybind.Action
		table.insert(held_actions[raw_input], action)

		local value = {
			Input = {
				Action = action,
				Begin = true,
				End = nil,
				Object = input,
			},
			Type = "begin",
		} :: any
		held[action] = value

		RunService.RenderStepped:Once(function()
			RunService.RenderStepped:Wait()
			value.Type = "hold"
			value.Input.Begin = nil
		end)
	end
end

local function process_raw_input_ended(input: InputObject, gameprocessed)
	if gameprocessed then return end
	local raw_input = get_raw_input(input)

	held_inputs[raw_input] = nil

	if held_actions[raw_input] == nil then return end
	for _, action: tst.ActionType in held_actions[raw_input] do
		if not action then return end

		held[action] = {
			Input = {
				Action = action,
				Begin = nil,
				End = true,
				Object = input,
			},
			Type = "end",
		}

		RunService.RenderStepped:Once(function()
			RunService.RenderStepped:Wait()
			held[action] = nil
		end)
	end

	held_actions[raw_input] = nil
end

UserInputService.InputBegan:Connect(process_raw_input_began)
UserInputService.InputEnded:Connect(process_raw_input_ended)

local controls = {}

function controls.load(keybinds: { [tst.ActionType]: tst.SerializedKeybind })
	load_serialized_keybinds(keybinds)
	compute_input_map()
end

function controls.enable(action: tst.ActionType, priority: number?)
	if priorities[action] == (priority or 1) then return controls end
	priorities[action] = priority or 1
	compute_input_map()
	return controls
end

function controls.disable(action: tst.ActionType)
	if priorities[action] == nil then return controls end
	priorities[action] = nil
	compute_input_map()
	return controls
end

function controls.get_state(
	action: tst.ActionType
): (("begin" | "hold" | "end")?, tst.Input?)
	if held[action] == nil then return nil, nil end

	return held[action].Type, held[action].Input
end

function controls.get_keybind(action: tst.ActionType)
	return action_keybinds[action]
end

function controls.meets_requirement(
	required_held: { tst.RawInput },
	key_code: tst.RawInput
)
	if held_inputs[key_code] == nil then return false end

	local all_held = true
	for _, key in required_held do
		if not held_inputs[key] then
			all_held = false
			break
		end
	end

	return all_held
end

return controls
