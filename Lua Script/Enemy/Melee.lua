local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Ragdoll = require(script:WaitForChild("Ragdoll"))
local Maid = require(script:WaitForChild("Maid"))

local function getValueFromConfig(name)
	local configuration = script.Parent:WaitForChild("Configuration")
	local valueObject = configuration and configuration:FindFirstChild(name)
	return valueObject and valueObject.Value
end

local ATTACK_DAMAGE = getValueFromConfig("AttackDamage")
local ATTACK_RADIUS = getValueFromConfig("AttackRadius")

local PATROL_ENABLED = getValueFromConfig("PatrolEnabled")
local PATROL_RADIUS = getValueFromConfig("PatrolRadius")

local DESTROY_ON_DEATH = getValueFromConfig("DestroyOnDeath")
local RAGDOLL_ENABLED = getValueFromConfig("RagdollEnabled")

local DEATH_DESTROY_DELAY = 30
local PATROL_WALKSPEED = 16
local MIN_REPOSITION_TIME = 2
local MAX_REPOSITION_TIME = 10
local MAX_PARTS_PER_HEARTBEAT = 50
local ATTACK_STAND_TIME = 1
local HITBOX_SIZE = Vector3.new(5, 3, 4)
local SEARCH_DELAY = 1
local ATTACK_RANGE = 3
local ATTACK_DELAY = 1
local ATTACK_MIN_WALKSPEED = 15
local ATTACK_MAX_WALKSPEED = 15

local maid = Maid.new()
maid.instance = script.Parent

maid.humanoid = maid.instance:WaitForChild("mob")
maid.head = maid.instance:WaitForChild("Head")
maid.humanoidRootPart = maid.instance:FindFirstChild("HumanoidRootPart")
maid.alignOrientation = maid.humanoidRootPart:FindFirstChild("AlignOrientation")

local startPosition = maid.instance.PrimaryPart.Position

local attacking = false
local searchingForTargets = false


local target = nil
local newTarget = nil
local newTargetDistance = nil
local searchIndex = 0
local timeSearchEnded = 0
local searchRegion = nil
local searchParts = nil
local movingToAttack = false
local lastAttackTime = 0

local worldAttachment = Instance.new("Attachment")
worldAttachment.Name = "SoldierWorldAttachment"
worldAttachment.Parent = Workspace.Terrain

maid.worldAttachment = worldAttachment
maid.humanoidRootPart.AlignOrientation.Attachment1 = worldAttachment

local attackAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations.AttackAnimation)
attackAnimation.Looped = false
attackAnimation.Priority = Enum.AnimationPriority.Action
maid.attackAnimation = attackAnimation

local deathAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations.DeathAnimation)
deathAnimation.Looped = false
deathAnimation.Priority = Enum.AnimationPriority.Action
maid.deathAnimation = deathAnimation

local random = Random.new()

local function getRandomPointInCircle(centerPosition, circleRadius)
	local radius = math.sqrt(random:NextNumber()) * circleRadius
	local angle = random:NextNumber(0, math.pi * 2)
	local x = centerPosition.X + radius * math.cos(angle)
	local z = centerPosition.Z + radius * math.sin(angle)

	local position = Vector3.new(x, centerPosition.Y, z)

	return position
end

local function isAlive()
	return maid.humanoid.Health > 0 and maid.humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

local function destroy()
	maid:destroy()
end

local function patrol()
	while isAlive() do
		if not attacking then
			local position = getRandomPointInCircle(startPosition, PATROL_RADIUS)
			maid.humanoid.WalkSpeed = PATROL_WALKSPEED
			maid.humanoid:MoveTo(position)
		end

		wait(random:NextInteger(MIN_REPOSITION_TIME, MAX_REPOSITION_TIME))
	end
end

local function isInstaceAttackable(targetInstance)
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

		-- Create a new region
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
			if currentPart and isInstaceAttackable(currentPart) then
				local character = currentPart.Parent
				local distance = (character.HumanoidRootPart.Position - maid.humanoidRootPart.Position).magnitude

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

local function runToTarget()
	local targetPosition = (maid.humanoidRootPart.Position - target.Position).Unit * ATTACK_RANGE + target.Position

	maid.humanoid:MoveTo(targetPosition)

	if not movingToAttack then
		maid.humanoid.WalkSpeed = random:NextInteger(ATTACK_MIN_WALKSPEED, ATTACK_MAX_WALKSPEED)
	end

	movingToAttack = true

	maid.attackAnimation:Stop()
end

local function attack()
	attacking = true
	lastAttackTime = tick()

	local originalWalkSpeed = maid.humanoid.WalkSpeed
	maid.humanoid.WalkSpeed = 0

	maid.attackAnimation:Play()

	local hitPart = Instance.new("Part")
	hitPart.Size = HITBOX_SIZE
	hitPart.Transparency = 1
	hitPart.CanCollide = true
	hitPart.Anchored = true
	hitPart.CFrame = maid.humanoidRootPart.CFrame * CFrame.new(0, -1, -3)
	hitPart.Parent = Workspace

	local hitTouchingParts = hitPart:GetTouchingParts()

	hitPart:Destroy()

	local attackedHumanoids	= {}
	for _, part in pairs(hitTouchingParts) do
		local parentModel = part:FindFirstAncestorOfClass("Model")
		if isInstaceAttackable(part) and not attackedHumanoids[parentModel]	then
			attackedHumanoids[parentModel.Humanoid] = true
		end
	end

	for humanoid in pairs(attackedHumanoids) do
		humanoid:TakeDamage(ATTACK_DAMAGE)
	end

	startPosition = maid.instance.PrimaryPart.Position

	wait(ATTACK_STAND_TIME)

	maid.humanoid.WalkSpeed = originalWalkSpeed

	maid.attackAnimation:Stop()

	attacking = false
end

local function onHeartbeat()
	if target then

		maid.alignOrientation.Enabled = true
		maid.worldAttachment.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)
	else
		maid.alignOrientation.Enabled = false
	end

	if target then
		local inAttackRange = (target.Position - maid.humanoidRootPart.Position).magnitude <= ATTACK_RANGE + 1

		if inAttackRange then
			if not attacking and tick() - lastAttackTime > ATTACK_DELAY then
				attack()
			end
		else
			runToTarget()
		end
	end

	if not target or not isInstaceAttackable(target) then
		findTargets()
	end
end

local hasDied = false -- 사망 처리가 이미 되었는지를 추적하는 변수

local function died()
	if hasDied then return end -- 이미 사망 처리가 되었다면 함수 실행 중지
	hasDied = true -- 사망 처리가 시작됨을 표시

	target = nil
	attacking = false
	newTarget = nil
	searchParts = nil
	searchingForTargets = false

	maid.heartbeatConnection:Disconnect()

	maid.humanoidRootPart.Anchored = true
	maid.deathAnimation:Play()

	wait(maid.deathAnimation.Length * 0.65)

	maid.deathAnimation:Stop()
	maid.humanoidRootPart.Anchored = false

	if RAGDOLL_ENABLED then
		Ragdoll(maid.instance, maid.humanoid)
	end

	-- Bolt 부품 생성 코드
	local boltPart = game.ReplicatedStorage.Items:FindFirstChild("Bolt")
	if boltPart then
		local clonedBolt = boltPart:Clone()
		clonedBolt.Position = maid.humanoidRootPart.Position + Vector3.new(0, 5, 0)  -- NPC가 사망한 위치 위로 5 미터
		clonedBolt.Parent = game.Workspace
	end

	if DESTROY_ON_DEATH then
		delay(DEATH_DESTROY_DELAY, function()
			destroy()
		end)
	end
end

maid.heartbeatConnection = RunService.Heartbeat:Connect(function()
	onHeartbeat()
end)

maid.diedConnection = maid.humanoid.Died:Connect(function()
	died()
end)

if PATROL_ENABLED then
	coroutine.wrap(function()
		patrol()
	end)()
end
