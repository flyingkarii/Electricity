--[[

Convetst enums to serialized formats and vice-versa.

]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local tst = require(ReplicatedStorage.tst)

return table.freeze {
	serialize = function(enum: Enum.KeyCode | Enum.UserInputType)
		return table.freeze { Type = tostring(enum.EnumType), Name = enum.Name }
	end,

	deserialize = function(data: tst.SerializedEnum)
		return assert((Enum :: any)[data.Type][data.Name], "invalid data")
	end,
}
