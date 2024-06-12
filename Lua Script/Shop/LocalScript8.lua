local Price = 500
local Item = script.Parent.Parent.Parent.ItemName.Text

local Event = game.ReplicatedStorage:WaitForChild("ItemBuy")

script.Parent.MouseButton1Click:Connect(function()
	Event:FireServer(Item, Price)
	script.Parent.Parent.Visible = false
end)