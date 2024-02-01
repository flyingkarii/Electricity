--[[

This file contains all game-related type definitions.

]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)

export type System = (world: ecr.Registry, dt: number) -> ...(number) -> ()
export type entity = ecr.entity
export type Registry = ecr.Registry

export type ActionType =
	"select_single"
	| "select_toggle"
	| "select_drag"
	| "deselect_all"
	| "interact"

export type SerializedEnum = {
	Type: string,
	Name: string,
}

export type RawInput = Enum.KeyCode | Enum.UserInputType

-- InputObject wrapper
export type Input = {
	Action: ActionType, -- the action being committed
	Begin: true?, -- true if the input is pressed
	End: true?, -- true if the input is released
	Object: InputObject,
}

export type Keybind<T = RawInput> = {
	Trigger: T, -- input that triggers the action
	DefaultPriority: number?, -- the default priority, default is 1
	RequiredHeld: { T }, -- will not trigger unless all are held
}

export type SerializedKeybind = Keybind<SerializedEnum>

export type Unit = {

	name: string,
	display_name: string,
	type: string,

	height: number,

	components: { [string]: unknown },
}

export type Building = {

	name: string,
	display_name: string,
	type: string,

	components: { [string]: unknown },
}

return nil
