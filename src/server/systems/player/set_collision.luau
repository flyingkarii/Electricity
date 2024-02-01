local Players = game:GetService "Players"

return function()
	for _, player in Players:GetPlayers() do
		if not player.Character then continue end
		for _, part in player.Character:GetDescendants() do
			if part:IsA "BasePart" then part.CollisionGroup = "player" end
		end
	end
end
