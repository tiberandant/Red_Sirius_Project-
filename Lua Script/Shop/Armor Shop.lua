local Armored1 = game.ReplicatedStorage:WaitForChild("Armored2")
local Armored2 = game.ReplicatedStorage:WaitForChild("Armored1")

script.Parent.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		Armored2:FireClient(player)
	end
end)

script.Parent.TouchEnded:Connect(function(hit)
	local player2 = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player2 then
		Armored1:FireClient(player2)
	end
end)