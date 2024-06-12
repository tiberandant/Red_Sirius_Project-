local replicatedStorage = game.ReplicatedStorage

local weaponSystem = replicatedStorage:WaitForChild("WeaponsSystem")
local weaponModule = require(weaponSystem:WaitForChild("WeaponsSystem"))

local camera = workspace.Camera
local player = game.Players.LocalPlayer

--Camera
script.Parent.Equipped:Connect(function()
	weaponModule.camera:setEnabled(true)
	weaponModule.camera.rotateCharacterWithCamera = true
end)
script.Parent.Unequipped:Connect(function()
	weaponModule.camera:setEnabled(false)
	weaponModule.camera.rotateCharacterWithCamera = false

	camera.CameraSubject = player.Character
	weaponModule.normalOffset = Vector3.new(0,0,0)
end)

--AmmoUI 
local isEquipped = false
local CurrentAmmo = script.Parent:WaitForChild("CurrentAmmo")

script.Parent.Equipped:Connect(function()
	if not game.Players.LocalPlayer.PlayerGui:FindFirstChild("AmmoUI") then
		AmmoUI = script.Parent.AmmoUI:Clone()
		AmmoUI.Parent = game.Players.LocalPlayer.PlayerGui
	end
	isEquipped = true
end)
script.Parent.Unequipped:Connect(function()
	AmmoUI:Destroy()
	isEquipped = false
end)

while true do wait()
	repeat wait() until player.PlayerGui:FindFirstChild("AmmoUI")
	
	if player.PlayerGui:FindFirstChild("AmmoUI") and isEquipped == true then		
		player.PlayerGui:FindFirstChild("AmmoUI").AmmoText.Text = CurrentAmmo.Value.."/"..script.Parent.Configuration.ReservedAmmo.Value
	end
end