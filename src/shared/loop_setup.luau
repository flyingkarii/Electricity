local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)
local gorp = require(ReplicatedStorage.packages.gorp)
local tst = require(ReplicatedStorage.tst)

type System = {
	name: string,
	interval: number,
	dt: number,
	type: "stateless",
	fn: (world: ecr.Registry, dt: number) -> (),
} | {
	name: string,
	interval: number,
	dt: number,
	type: "stateful",
	fn: (dt: number) -> (),
}

local function loop_setup(
	world: ecr.Registry,
	systems_path: Instance,
	...: string | { interval: number }
): (dt: number) -> ()
	local modules = {} :: { [string]: ModuleScript? }
	local unregistered = {} :: { [string]: true }
	local scheduled = {} :: { System }

	local function recurse_systems_path(
		dir_name: string,
		dir_instance: Instance
	)
		for _, module in dir_instance:GetChildren() do
			if module:IsA "Folder" then
				recurse_systems_path(`{dir_name}{module.Name}{"/"}`, module)
			else
				assert(module:IsA "ModuleScript")
				local name = dir_name .. module.Name
				assert(
					modules[name] == nil,
					`system already exists with the name {name}`
				)
				modules[name] = module
				unregistered[name] = true
			end
		end
	end

	recurse_systems_path("", systems_path)

	local interval: number?

	for i, v in { ... } do
		if type(v) == "table" then
			interval = v.interval
			continue
		end

		assert(interval, `no interval defined`)

		local module = modules[v]

		if not module then
			warn(`system "{v}" does not exist`)
			continue
		end

		unregistered[v] = nil

		-- get system function
		local fn = (require :: any)(module) :: tst.System
		-- run system initially, check if a secondary function is returned
		local fn2 = fn(world, 0)

		local system: System = fn2
				and {
					name = v,
					interval = interval,
					dt = 0,
					type = "stateful" :: "stateful",
					fn = fn2,
				}
			or {
				name = v,
				interval = interval,
				dt = 0,
				type = "stateless" :: "stateless",
				fn = fn,
			}

		table.insert(scheduled, system)
	end

	for name in unregistered do
		warn(
			`system "{name}" is unregistered. did you forget to register "{name}"?`
		)
	end

	local scheduler = gorp.scheduler "main"

	local frame_count = 0

	local function run(dt: number)
		frame_count += 1

		for _, system in scheduled do
			local name = system.name

			system.dt += dt

			if frame_count % system.interval > 0 then
				scheduler:skip(name)
				continue
			end

			if system.type == "stateful" then
				scheduler:system(name, system.fn, system.dt)
				--system.fn(system.dt)
			else
				scheduler:system(name, system.fn, world, system.dt)
				--system.fn(world, system.dt)
			end

			(system :: any).dt = 0
		end

		scheduler:finish()
	end

	return run
end

return loop_setup
