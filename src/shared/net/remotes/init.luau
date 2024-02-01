local RunService = game:GetService "RunService"

type Server = typeof(require(script.server))
type Client = typeof(require(script.client))

return if RunService:IsServer()
	then require(script.server) :: Server & Client
	else require(script.client) :: Server & Client
