--[[

This file stores a map of all default keybinds.

]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local tst = require(ReplicatedStorage.tst)

return {
	select_single = {
		Trigger = Enum.UserInputType.MouseButton1,
		RequiredHeld = {},
	},

	select_toggle = {
		Trigger = Enum.UserInputType.MouseButton1,
		RequiredHeld = { Enum.KeyCode.LeftControl },
	},

	select_drag = {
		Trigger = Enum.UserInputType.MouseButton1,
		RequiredHeld = {},
	},

	deselect_all = {
		Trigger = Enum.KeyCode.C,
		RequiredHeld = {},
	},

	interact = {
		Trigger = Enum.KeyCode.E,
		RequiredHeld = {},
	},
} :: { [tst.ActionType]: tst.Keybind }
