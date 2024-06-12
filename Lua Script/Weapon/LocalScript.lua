local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponsSystem = ReplicatedStorage:WaitForChild("WeaponsSystem")
local weaponModule = require(WeaponsSystem:WaitForChild("WeaponsSystem"))
local camera = workspace.Camera
local player = game:GetService("Players").LocalPlayer

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
