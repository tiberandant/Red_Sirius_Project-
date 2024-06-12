game.ReplicatedStorage.ItemBuy.OnServerEvent:Connect(function(plr, item, Price)
	if plr.leaderstats.Bolt.Value >= Price then
		local clo = game.ReplicatedStorage[item]:Clone() 

		plr.leaderstats.Bolt.Value = plr.leaderstats.Bolt.Value - Price
		clo.Parent = plr.Backpack
	end
end)