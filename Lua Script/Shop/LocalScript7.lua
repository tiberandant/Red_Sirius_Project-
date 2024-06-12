game.ReplicatedStorage.Touched.OnClientEvent:Connect(function()
	script.Parent:TweenPosition(
		UDim2.new(0.205, 0,0.195, 0),
		"Out",
		"Bounce",
		1
	)
end)