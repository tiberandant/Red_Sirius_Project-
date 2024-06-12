local Prompt = script.Parent
local Configuration = Prompt.Parent.Configuration
local AvailableAmmo = Configuration.AvailableAmmo
local AmmoType = Configuration.AmmoType

local isGiven = false

Prompt.ObjectText = "Text: "..AmmoType.Value

local function onTool()
	if Prompt.Parent.ClassName == "Tool" then
		wait()
		Prompt.Parent.Parent:Destroy()
	else
		wait()
		Prompt.Parent:Destroy()
	end
end

Prompt.Triggered:Connect(function(player)
	local char = player.Character
	local backpack = player.Backpack
	--Character
	if char:FindFirstChildWhichIsA("Tool") then
		local weapon = char:FindFirstChildWhichIsA("Tool")
		if weapon:FindFirstChild("AmmoType") then
			if weapon.AmmoType.Value == AmmoType.Value and isGiven == false then
				local availableAmmo = weapon.Configuration.ReservedAmmo
				local ammoCapacity = weapon.Configuration.AmmoCapacity
				availableAmmo.Value += AvailableAmmo.Value
				ammoCapacity.Value = ammoCapacity.DefaultAmmoCapacity.Value
				isGiven = true
				onTool()
			end
		end
		--Loot
	else
		local Tool = Instance.new("Tool", player.Backpack)
		Tool.Name = AmmoType.Value.."Ammo"

		Prompt.Parent.Name = "Handle"
		Prompt.Parent.Anchored = false
		Prompt.Parent.CanCollide = false

		for _, v in pairs(Prompt.Parent:GetChildren()) do
			if v:IsA("BasePart") or v:IsA("MeshPart") then
				v.Anchored = false
				v.CanCollide = false
			end
		end
		Prompt.Parent.Parent = Tool
	end
	--Backpack
	for i, tool in pairs(backpack:GetChildren()) do
		if tool:FindFirstChild("AmmoType") then
			if tool.AmmoType.Value == AmmoType.Value and isGiven == false then
				local availableAmmo = tool.Configuration.ReservedAmmo
				local ammoCapacity = tool.Configuration.AmmoCapacity
				availableAmmo.Value += AvailableAmmo.Value
				ammoCapacity.Value = ammoCapacity.DefaultAmmoCapacity.Value
				isGiven = true
				onTool()
			end
		end
	end
end)