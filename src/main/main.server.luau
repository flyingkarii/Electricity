local PhysicsService = game:GetService "PhysicsService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local _ct = require(ReplicatedStorage.ct)
local loader = require(ReplicatedStorage.loader)
local remotes = require(ReplicatedStorage.net.remotes)

local loop = require(ServerStorage.loop)

PhysicsService:RegisterCollisionGroup "player"

--PhysicsService:CollisionGroupSetCollidable("unit", "building", false)

RunService.Heartbeat:Connect(loop.loop)
loop.startup()
