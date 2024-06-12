local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local ZeroGravity1 = game.Workspace:WaitForChild("ZeroGravity1")

local bodyVelocity
local inZeroGravityZone = false
local boosterActive = false
local lastDeactivationTime = 0
local deactivationCooldown = 1 -- 쿨다운 기간 (초 단위)
local alreadyInZone = false -- 새로운 플래그 추가

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
			humanoid:SetAttribute("BoosterActive", true)
			boosterActive = true
		end
	end
end

local function deactivateBooster()
	if bodyVelocity and boosterActive then
		local character = game.Players.LocalPlayer.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetAttribute("BoosterActive", false)
		end
		bodyVelocity:Destroy()
		bodyVelocity = nil
		boosterActive = false
	end
end

local function isCharacterInZeroGravity(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local humanPosition = rootPart.Position
		local partPosition = ZeroGravity1.Position
		local halfSize = ZeroGravity1.Size / 2
		return (math.abs(humanPosition.X - partPosition.X) <= halfSize.X) and
			(math.abs(humanPosition.Y - partPosition.Y) <= halfSize.Y) and
			(math.abs(humanPosition.Z - partPosition.Z) <= halfSize.Z)
	end
	return false
end

ZeroGravity1.Touched:Connect(function(part)
	if part and part.Parent then
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not alreadyInZone then
			inZeroGravityZone = true
			alreadyInZone = true -- 무중력 구역에 들어갔음을 표시
			print("Entered ZeroGravity zone")
		end
	end
end)

ZeroGravity1.TouchEnded:Connect(function(part)
	if part and part.Parent then
		local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			wait(0.1)
			if not isCharacterInZeroGravity(game.Players.LocalPlayer.Character) then
				if inZeroGravityZone then -- 추가된 체크
					inZeroGravityZone = false
					alreadyInZone = false -- 무중력 구역에서 나왔음을 표시
					print("Exited ZeroGravity zone")
					deactivateBooster()
				end
			end
		end
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

local function onCharacterCollision(part)
	local character = game.Players.LocalPlayer.Character
	if part and part.Parent == character and bodyVelocity then
		bodyVelocity.Parent = nil
		bodyVelocity.Parent = character.PrimaryPart
	end
end

local function connectCollisionEvents()
	local character = game.Players.LocalPlayer.Character
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onCharacterCollision)
		end
	end
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart")
	connectCollisionEvents()
end)

if game.Players.LocalPlayer.Character then
	connectCollisionEvents()
end

RunService.Stepped:Connect(function()
	local character = game.Players.LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and inZeroGravityZone and not isCharacterInZeroGravity(character) then
			local currentTime = tick()
			if currentTime - lastDeactivationTime >= deactivationCooldown then
				if inZeroGravityZone then -- 추가된 체크
					inZeroGravityZone = false
					alreadyInZone = false -- 무중력 구역에서 나왔음을 표시
					print("Exited ZeroGravity zone (RunService check)")
					deactivateBooster()
					lastDeactivationTime = currentTime
				end
			end
		end
	end
end)