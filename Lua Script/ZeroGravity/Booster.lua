local UserInputService = game:GetService("UserInputService")
local Camera = game.Workspace.CurrentCamera
local ZeroGravity = game.Workspace:WaitForChild("ZeroGravity") 

local bodyVelocity
local boosterActive = false

local function activateBooster()
	if not bodyVelocity and inZeroGravityZone then
		local character = game.Players.LocalPlayer.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and character.PrimaryPart then
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Camera.CFrame.LookVector * 10
			bodyVelocity.MaxForce = Vector3.new(20000, 20000, 20000)
			bodyVelocity.P = 12500
			bodyVelocity.Parent = character.PrimaryPart
		end
	end
end

local function deactivateBooster()
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
end

ZeroGravity.Touched:Connect(function(part)
	if part.Parent:FindFirstChildOfClass("Humanoid") then
		inZeroGravityZone = true
		print("Entered ZeroGravity zone")
	end
end)

ZeroGravity.TouchEnded:Connect(function(part)
	if part.Parent:FindFirstChildOfClass("Humanoid") then
		inZeroGravityZone = false
		print("Exited ZeroGravity zone")
		deactivateBooster()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
		activateBooster()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
		deactivateBooster()
	end
end)