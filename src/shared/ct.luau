--!nolint FunctionUnused
--[[

This file is used to contain all the components that are being used in the game

]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)
local gorp = require(ReplicatedStorage.packages.gorp)

--- Helper function to create a component which always returns a certain value
local function primitive<T>(value: T): T
	return ecr.component(function()
		return value
	end)
end

--- Helper function to create a component which clones the given input table
local function struct<T>(value: T): T
	return ecr.component(function()
		return table.clone(value :: any) :: any
	end)
end

local cts = gorp.names(ecr.name {
	-- * General Components

	model = ecr.component() :: Model,
	transform = ecr.component() :: CFrame,

	-- * Model Components

	-- * Player Components

	player = ecr.component() :: Player,

	-- * Controller Components
	-- These components dictate how a unit behaves

	owner = ecr.component() :: Player,

	-- * Electrical Components

	io_hovering = ecr.component() :: Part?,
	occupied = ecr.component() :: { Part },

	circuit_id = ecr.component() :: number,
	charge = ecr.component() :: number,
	input = ecr.component() :: number,
	outputs = ecr.component() :: number,

	-- Electrical component types
	test_generator = ecr.tag(),
	switch = ecr.tag(),
	simple_light = ecr.tag(),
})

return cts
