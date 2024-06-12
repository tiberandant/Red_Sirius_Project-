local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(script:WaitForChild("Maid"))

local function getValueFromConfig(name)
	local configuration = script.Parent:WaitForChild("Configuration")
	local valueObject = configuration and configuration:FindFirstChild(name)
	return valueObject and valueObject.Value
end

local DESTROY_ON_DEATH = getValueFromConfig("DestroyOnDeath")
local DEATH_DESTROY_DELAY = 10
local SEARCH_DELAY = 1
local ATTACK_RADIUS = getValueFromConfig("AttackRadius")
local MAX_PARTS_PER_HEARTBEAT = 50
local HOVER_HEIGHT = 100
local MISSILE_STOP_DISTANCE = 20

local maid = Maid.new()
maid.instance = script.Parent
maid.humanoid = maid.instance:WaitForChild("mob")
maid.humanoidRootPart = maid.instance:WaitForChild("HumanoidRootPart")

local startPosition = maid.instance.PrimaryPart.Position + Vector3.new(0, HOVER_HEIGHT, 0)

-- BodyPosition to keep the mob hovering
local bodyPosition = Instance.new("BodyPosition")
bodyPosition.Position = startPosition
bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
bodyPosition.Parent = maid.humanoidRootPart
maid:give(bodyPosition) -- Add to maid

local worldAttachment = Instance.new("Attachment")
worldAttachment.Name = "SoldierWorldAttachment"
worldAttachment.Parent = Workspace.Terrain
maid:give(worldAttachment) -- Add to maid

local humanoidAttachment = Instance.new("Attachment")
humanoidAttachment.Position = Vector3.new(0, 0, 0)
humanoidAttachment.Parent = maid.humanoidRootPart
maid:give(humanoidAttachment) -- Add to maid

local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Attachment0 = humanoidAttachment
alignOrientation.Attachment1 = worldAttachment
alignOrientation.RigidityEnabled = false
alignOrientation.ReactionTorqueEnabled = true
alignOrientation.MaxTorque = 10000
alignOrientation.Responsiveness = 50
alignOrientation.Parent = maid.humanoidRootPart
maid:give(alignOrientation) -- Add to maid

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
bodyGyro.P = 3000
bodyGyro.Parent = maid.humanoidRootPart
maid:give(bodyGyro) -- Add to maid

local searchingForTargets = false
local target = nil
local newTarget = nil
local newTargetDistance = nil
local searchIndex = 0
local timeSearchEnded = 0
local searchRegion = nil
local searchParts = nil

local state = {
	lastMissileTime = 0
}

local function isAlive()
	return maid.humanoid.Health > 0 and maid.humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

local function destroy()
	print("Destroy called")
	maid:clean()
end

local function releaseWeldConstraints()
	local welds = maid.instance:GetDescendants()
	for _, weld in ipairs(welds) do
		if weld:IsA("WeldConstraint") then
			weld:Destroy()
		end
	end
end

local function died()
	print("Died called")
	maid.humanoidRootPart.Anchored = true
	releaseWeldConstraints()
	wait(DEATH_DESTROY_DELAY)
	destroy()
end

local function isInstanceAttackable(targetInstance)
	local targetHumanoid = targetInstance and targetInstance.Parent and targetInstance.Parent:FindFirstChild("Humanoid")
	if not targetHumanoid then
		return false
	end

	local isAttackable = false
	local distance = (maid.humanoidRootPart.Position - targetInstance.Position).Magnitude

	if distance <= ATTACK_RADIUS then
		local ray = Ray.new(
			maid.humanoidRootPart.Position,
			(targetInstance.Parent.HumanoidRootPart.Position - maid.humanoidRootPart.Position).Unit * distance
		)

		local part = Workspace:FindPartOnRayWithIgnoreList(ray, {
			targetInstance.Parent, maid.instance,
		}, false, true)

		if
			targetInstance ~= maid.instance and
			targetInstance:IsDescendantOf(Workspace) and
			targetHumanoid.Health > 0 and
			targetHumanoid:GetState() ~= Enum.HumanoidStateType.Dead and
			not CollectionService:HasTag(targetInstance.Parent, "ZombieFriend") and
			not part
		then
			isAttackable = true
		end
	end

	return isAttackable
end

local function findTargets()
	if not searchingForTargets and tick() - timeSearchEnded >= SEARCH_DELAY then
		searchingForTargets = true

		local centerPosition = maid.humanoidRootPart.Position
		local topCornerPosition = centerPosition + Vector3.new(ATTACK_RADIUS, ATTACK_RADIUS, ATTACK_RADIUS)
		local bottomCornerPosition = centerPosition + Vector3.new(-ATTACK_RADIUS, -ATTACK_RADIUS, -ATTACK_RADIUS)

		searchRegion = Region3.new(bottomCornerPosition, topCornerPosition)
		searchParts = Workspace:FindPartsInRegion3(searchRegion, maid.instance, math.huge)

		newTarget = nil
		newTargetDistance = nil

		searchIndex = 1
	end

	if searchingForTargets then
		local checkedParts = 0
		while searchingForTargets and searchIndex <= #searchParts and checkedParts < MAX_PARTS_PER_HEARTBEAT do
			local currentPart = searchParts[searchIndex]
			if currentPart and isInstanceAttackable(currentPart) then
				local character = currentPart.Parent
				local distance = (character.HumanoidRootPart.Position - maid.humanoidRootPart.Position).Magnitude

				if not newTargetDistance or distance < newTargetDistance then
					newTarget = character.HumanoidRootPart
					newTargetDistance = distance
				end
			end

			searchIndex = searchIndex + 1
			checkedParts = checkedParts + 1
		end

		if searchIndex >= #searchParts then
			target = newTarget
			searchingForTargets = false
			timeSearchEnded = tick()
		end
	end
end

local function createMissiles(target)
	if not isAlive() then return end

	local missileTemplate = ReplicatedStorage:WaitForChild("Missile")
	local offsets = {
		Vector3.new(-70, 70, 0),  -- 왼쪽 위
		Vector3.new(70, 70, 0),   -- 오른쪽 위
		Vector3.new(-70, -70, 0), -- 왼쪽 아래
		Vector3.new(70, -70, 0)   -- 오른쪽 아래
	}

	for _, offset in ipairs(offsets) do
		local missile = missileTemplate:Clone()

		-- 미사일 위치를 조정합니다.
		missile.CFrame = CFrame.new(maid.humanoidRootPart.Position + Vector3.new(0, 70, 0) + offset, target.Position)
		missile.Anchored = false
		missile.CanCollide = false
		missile.Parent = Workspace

		local bodyVelocity = missile:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
		bodyVelocity.Velocity = (target.Position - missile.Position).Unit * 50
		bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		bodyVelocity.Parent = missile
		maid:give(bodyVelocity) -- Add to maid

		local bodyGyro = missile:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
		bodyGyro.P = 3000
		bodyGyro.CFrame = CFrame.new(missile.Position, target.Position)
		bodyGyro.Parent = missile
		maid:give(bodyGyro) -- Add to maid

		local function updateMissile()
			if missile.Parent and target.Parent then
				local distance = (target.Position - missile.Position).Magnitude
				if distance > MISSILE_STOP_DISTANCE then
					bodyGyro.CFrame = CFrame.new(missile.Position, target.Position)
					bodyVelocity.Velocity = (target.Position - missile.Position).Unit * 50
				else
					bodyGyro:Destroy()
					bodyVelocity.Velocity = missile.CFrame.LookVector * 50
				end
			else
				missile:Destroy()
			end
		end

		local updateConnection = RunService.Heartbeat:Connect(updateMissile)
		maid:give(updateConnection) -- Add to maid
		game.Debris:AddItem(missile, 8)

		missile.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character:FindFirstChild("Humanoid")

			if humanoid and character ~= maid.instance then
				if missile.Parent then
					local damage = 10
					local hitPartName = hit.Name:lower()
					if hitPartName:find("head") then
						damage = 20
					elseif hitPartName:find("torso") or hitPartName:find("upper") or hitPartName:find("lower") then
						damage = 10
					end

					humanoid:TakeDamage(damage)

					local explosion = Instance.new("Explosion")
					explosion.Position = missile.Position
					explosion.BlastRadius = 0
					explosion.BlastPressure = 0
					explosion.Parent = Workspace

					missile:Destroy()
					updateConnection:Disconnect()
				end
			end
		end)
	end
end

local function onHeartbeat()
	if not isAlive() then
		if maid.alignOrientation then
			maid.alignOrientation.Enabled = false
		end
		return
	end

	if target then
		if maid.alignOrientation then
			maid.alignOrientation.Enabled = true
			maid.alignOrientation.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)
		end
		local targetPosition = target.Position
		if maid.worldAttachment then
			maid.worldAttachment.WorldCFrame = CFrame.new(maid.humanoidRootPart.Position, targetPosition)
		end
		if maid.bodyGyro then
			maid.bodyGyro.CFrame = CFrame.new(maid.humanoidRootPart.Position, targetPosition)
		end

		if tick() - state.lastMissileTime >= 8 then
			createMissiles(target) -- 4개의 미사일을 발사합니다.
			state.lastMissileTime = tick()
		end
	else
		if maid.alignOrientation then
			maid.alignOrientation.Enabled = false
		end
		if maid.bodyGyro then
			maid.bodyGyro.CFrame = maid.humanoidRootPart.CFrame
		end
	end

	if not target or not isInstanceAttackable(target) then
		findTargets()
	end
end

maid.heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
maid:give(maid.heartbeatConnection) -- Add to maid

maid.diedConnection = maid.humanoid.Died:Connect(died)
maid:give(maid.diedConnection) -- Add to maid

RunService.Heartbeat:Wait()
onHeartbeat()