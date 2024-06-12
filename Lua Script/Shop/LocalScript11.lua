script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent:TweenPosition(
		UDim2.new(0.205, 0,1.1, 0),
		"Out",
		"Quad",
		0.5	
	)
end)