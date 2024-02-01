local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local _ct = require(ReplicatedStorage.ct)
local controls = require(ReplicatedStorage.libraries.controls)
local gorp = require(ReplicatedStorage.packages.gorp)

local client = ReplicatedStorage.client
local loop = require(client.loop)

RunService.Heartbeat:Connect(loop.loop)
task.spawn(loop.startup)
task.wait(0.1) -- todo: what the fuck

gorp.get_client().gorp_selector()
gorp.get_client().enabled(true)

controls.load {}
