function onPlayerEntered(newPlayer)
	local stats = Instance.new("IntValue")
	stats.Name = "leaderstats"

	local Money = Instance.new("IntValue")
	Money.Name = "Bolt"
	Money.Value = 300

	Money.Parent = stats 
	stats.Parent = newPlayer

end

game.Players.ChildAdded:connect(onPlayerEntered)