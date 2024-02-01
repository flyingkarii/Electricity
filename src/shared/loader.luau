local loader = {}
local priorities: { [string]: number } = {}

function loader.load_modules(parent: Instance, deep: boolean, ...)
	local load_queue: { ModuleScript } = {}
	local children: { Instance } = if deep
		then parent:GetDescendants()
		else parent:GetChildren()

	for _, child: Instance in children do
		if not child:IsA "ModuleScript" then continue end
		local priority_str: string? = child.Name:match "%d+"

		if priority_str and tonumber(priority_str) then
			priorities[child.Name] = tonumber(priority_str) :: number
		else
			priorities[child.Name] = 100
		end

		table.insert(load_queue, child :: ModuleScript)
	end

	table.sort(load_queue, function(a: ModuleScript, b: ModuleScript)
		local a_priority: number = priorities[a.Name]
		local b_priority: number = priorities[b.Name]

		return a_priority < b_priority
	end)

	for _, moduleInstance: ModuleScript in load_queue do
		local module = require(moduleInstance) :: any

		if typeof(module) == "function" then
			task.spawn(module, ...)
		elseif module.on_start then
			task.spawn(module.on_start, ...)
		end
	end
end

return loader
