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

local DEATH_DESTROY_DELAY = 5
local PATROL_WALKSPEED = 16
local MIN_REPOSITION_TIME = 2
local MAX_REPOSITION_TIME = 10
local MAX_PARTS_PER_HEARTBEAT = 50
local ATTACK_STAND_TIME = 1
local HITBOX_SIZE = Vector3.new(5, 3, 4)
local SEARCH_DELAY = 1
local ATTACK_RANGE = 50 
local ATTACK_DELAY = 1
local ATTACK_MIN_WALKSPEED = 15
local ATTACK_MAX_WALKSPEED = 15

local PROJECTILE_SPEED = 100
local PROJECTILE_LIFETIME = 10
local PROJECTILE_DAMAGE = ATTACK_DAMAGE / 10

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

local function createProjectile(targetPosition)
	-- ��ȿ�� �˻� �߰�
	if not target or not target.Parent or not target.Parent.HumanoidRootPart then
		print("Target is not valid.")
		return
	end
	
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(0.3, 0.3, 0.3)  -- ������Ÿ�� ũ��
	projectile.Material = Enum.Material.Neon
	projectile.BrickColor = BrickColor.new("Bright yellow")

	local startPosition = maid.humanoidRootPart.Position + maid.humanoidRootPart.CFrame.LookVector * 2
	local futureTargetPosition = targetPosition + target.Parent.HumanoidRootPart.Velocity * (startPosition - targetPosition).Magnitude / PROJECTILE_SPEED
	projectile.CFrame = CFrame.new(startPosition, futureTargetPosition)
	projectile.Velocity = (futureTargetPosition - startPosition).Unit * PROJECTILE_SPEED
	projectile.CanCollide = false
	projectile.Parent = Workspace

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = projectile.Velocity
	bodyVelocity.MaxForce = Vector3.new(1e4, 1e4, 1e4)
	bodyVelocity.Parent = projectile

	projectile.Touched:Connect(function(hit)
		local targetHumanoid = hit.Parent:FindFirstChild("Humanoid")
		if targetHumanoid and (targetHumanoid.RootPart.Position - hit.Position).Magnitude <= 20 then  -- �ǰ� ���� Ȯ��
			targetHumanoid:TakeDamage(PROJECTILE_DAMAGE)
		end
	end)

	game:GetService("Debris"):AddItem(projectile, PROJECTILE_LIFETIME)
end

local function attack()
	attacking = true
	lastAttackTime = tick()

	-- ��ǥ ������ HumanoidRootPart�� �����Ͽ� �߽� ���� ����
	local direction = (target.Position - maid.humanoidRootPart.Position).Unit
	maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position, maid.humanoidRootPart.Position + direction)

	maid.humanoid.WalkSpeed = 0
	maid.attackAnimation:Play()

	-- ��ǥ ������ HumanoidRootPart�� ����
	local targetPosition = target.Position + Vector3.new(0, target.Size.Y * 0.5, 0)

	coroutine.wrap(function()
		for i = 1, 5 do
			createProjectile(targetPosition)
			wait(0.1)  -- ���� �� �� �ð� �������� �����Ͽ� ������Ÿ�� �߻� ������ ����
		end
	end)()

	
	wait(ATTACK_STAND_TIME)

	maid.humanoid.WalkSpeed = ATTACK_MIN_WALKSPEED  -- ���� �� �̵� �ӵ� ����

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
		local distanceToTarget = (target.Position - maid.humanoidRootPart.Position).magnitude
		local inAttackRange = distanceToTarget <= ATTACK_RANGE

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


local hasDied = false -- ��� ó���� �̹� �Ǿ������� �����ϴ� ����

local function died()
	if hasDied then return end -- �̹� ��� ó���� �Ǿ��ٸ� �Լ� ���� ����
	hasDied = true -- ��� ó���� ���۵��� ǥ��

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

	-- Bolt ��ǰ ���� �ڵ�
	local boltPart = game.ReplicatedStorage.Items:FindFirstChild("Bolt")
	if boltPart then
		local clonedBolt = boltPart:Clone()
		clonedBolt.Position = maid.humanoidRootPart.Position + Vector3.new(0, 5, 0)  -- NPC�� ����� ��ġ ���� 5 ����
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