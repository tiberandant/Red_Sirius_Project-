local Touched = game.ReplicatedStorage:WaitForChild("Touched2")
local Touched2 = game.ReplicatedStorage:WaitForChild("Touched")

script.Parent.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		Touched2:FireClient(player)
	end
end)

script.Parent.TouchEnded:Connect(function(hit)
	local player2 = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player2 then
		Touched:FireClient(player2)
	end
end)