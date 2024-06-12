local Price = 200
local Item = script.Parent.Parent.Parent.ItemName.Text

local Event = game.ReplicatedStorage:WaitForChild("ArmorBuy")

script.Parent.MouseButton1Click:Connect(function()
	Event:FireServer(Item, Price)
	script.Parent.Parent.Visible = false
end)