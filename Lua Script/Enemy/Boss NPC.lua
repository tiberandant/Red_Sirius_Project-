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
local HITBOX_SIZE = Vector3.new(8, 4, 6)
local SEARCH_DELAY = 1
local ATTACK_RANGE = 50
local ATTACK_DELAY = 2
local ATTACK_MIN_WALKSPEED = 100
local ATTACK_MAX_WALKSPEED = 100
local RANGED_ATTACK_COOLDOWN = 2 -- ���Ÿ� ���� ��Ÿ��
local RANGED_ATTACK_RANGE = 50 -- ���Ÿ� ���� ��Ÿ�

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
local lastRangedAttackTime = 0 -- ������ ���Ÿ� ���� �ð�

local worldAttachment = Instance.new("Attachment")
worldAttachment.Name = "SoldierWorldAttachment"
worldAttachment.Parent = Workspace.Terrain

maid.worldAttachment = worldAttachment
maid.humanoidRootPart.AlignOrientation.Attachment1 = worldAttachment

local attackAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations.AttackAnimation)
attackAnimation.Looped = false
attackAnimation.Priority = Enum.AnimationPriority.Action
maid.attackAnimation = attackAnimation

local shootAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations.ShootAnimation)
shootAnimation.Looped = false
shootAnimation.Priority = Enum.AnimationPriority.Action
maid.shootAnimation = shootAnimation

local missileAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations:FindFirstChild("MissileAnimation"))
missileAnimation.Looped = false
missileAnimation.Priority = Enum.AnimationPriority.Action
maid.missileAnimation = missileAnimation

local dashAnimation = maid.humanoid:LoadAnimation(maid.instance.Animations.DashAnimation)
dashAnimation.Looped = false
dashAnimation.Priority = Enum.AnimationPriority.Action
maid.dashAnimation = dashAnimation

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

local function performRangedAttack()
	-- NPC�� ��ǥ���� �ٶ󺸵��� ���� ����
	if not target or not target.Position then
		return
	end

	maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)

	-- ���Ÿ� ���� �ִϸ��̼� ���
	maid.shootAnimation:Play()

	-- ���Ÿ� ���� ���� ����
	local function createProjectile()
		if not target or not target.Position then
			return
		end

		local projectile = Instance.new("Part")
		projectile.Size = Vector3.new(0.3, 0.3, 0.3)
		projectile.BrickColor = BrickColor.new("Bright red")
		projectile.Material = Enum.Material.Neon
		projectile.Anchored = false
		projectile.CanCollide = false
		projectile.Position = maid.humanoidRootPart.Position + Vector3.new(0, 2, 0)
		projectile.Velocity = (target.Position - maid.humanoidRootPart.Position).Unit * 200 -- ����ü �ӵ� ����

		projectile.Parent = Workspace

		-- �浹 �� ���� ó��
		projectile.Touched:Connect(function(hit)
			local hitHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if hitHumanoid and hit.Parent ~= maid.instance then
				hitHumanoid:TakeDamage(ATTACK_DAMAGE / 10) 
			end
		end)

		-- ���� �ð� �� ����ü ����
		game:GetService("Debris"):AddItem(projectile, 10)
	end

	-- 5�� �������� �߻�
	for i = 1, 5 do
		createProjectile()
		wait(0.1) -- �߻� ���� ª�� ���� �ð��� �߰�
	end

	-- ���Ÿ� ���� �ִϸ��̼� ����
	maid.shootAnimation:Stop()
end

local function trackTarget(missile, target, missileSpeed, stopTrackingDistance, initialDirection)
	local connection
	local tracking = true
	connection = RunService.Stepped:Connect(function()
		if missile and missile.Parent then
			if target and target.Parent then
				local distance = (target.Position - missile.Position).Magnitude

				if distance > stopTrackingDistance and tracking then
					initialDirection = (target.Position - missile.Position).Unit
					missile.CFrame = CFrame.new(missile.Position, target.Position)
				else
					tracking = false
				end

				missile.Position = missile.Position + initialDirection * missileSpeed * RunService.Heartbeat:Wait()
			else
				connection:Disconnect()
				missile:Destroy() -- ��ǥ�� ���� ��� �̻��� ����
			end
		else
			connection:Disconnect()
		end
	end)
end

local function createExplosion(position)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 5
	explosion.BlastPressure = 0
	explosion.Parent = Workspace

	-- �ð��� ȿ�� �߰�
	local explosionEffect = Instance.new("Part")
	explosionEffect.Size = Vector3.new(5, 5, 5)
	explosionEffect.BrickColor = BrickColor.new("Bright yellow")
	explosionEffect.Material = Enum.Material.Neon
	explosionEffect.Shape = Enum.PartType.Ball
	explosionEffect.Transparency = 0.5
	explosionEffect.Anchored = true
	explosionEffect.CanCollide = false
	explosionEffect.Position = position
	explosionEffect.Parent = Workspace

	game:GetService("Debris"):AddItem(explosionEffect, 0.5)
end

local function performMissileAttack()
	-- NPC�� ��ǥ���� �ٶ󺸵��� ���� ����
	if not target or not target.Position then
		return
	end

	if not maid.humanoidRootPart then
		return
	end

	maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)

	-- �̻��� ���� ���� ����
	local function createMissile(offset)
		if not target or not target.Position then
			return
		end

		if not maid.humanoidRootPart then
			return
		end

		local missile = game.ReplicatedStorage:FindFirstChild("MissileObject"):Clone()
		local initialDirection = (target.Position - maid.humanoidRootPart.Position).Unit
		missile.Position = maid.humanoidRootPart.Position + offset
		missile.Anchored = true -- �̻����� �����Ͽ� �߷��� ������ ���� �ʰ� ����
		missile.CanCollide = false
		missile.Parent = Workspace

		local missileSpeed = 20 -- �̻��� �ӵ��� ������ ����
		local stopTrackingDistance = 5 -- ���� ����� ���� �Ÿ� ����

		-- �浹 �� ���� ó��
		missile.Touched:Connect(function(hit)
			local hitHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if hitHumanoid and hit.Parent ~= maid.instance then
				hitHumanoid:TakeDamage(ATTACK_DAMAGE / 6) -- ������� 1/6�� ����
				createExplosion(missile.Position) -- ���� ȿ�� �߰�
				missile:Destroy() -- �浹 �� �̻��� ����
			end
		end)

		-- ���� �ð� �� �̻��� ����
		game:GetService("Debris"):AddItem(missile, 20)

		-- ������ �ο��� ���� �Լ� ����
		trackTarget(missile, target, missileSpeed, stopTrackingDistance, initialDirection)
	end

	local offsetPositions = {
		Vector3.new(-5, 8, 5),
		Vector3.new(5, 8, 5),
		Vector3.new(-5, 1, -5),
		Vector3.new(5, 1, -5)
	}

	for _, offset in ipairs(offsetPositions) do
		createMissile(offset)
	end

	-- �̻��� �ִϸ��̼� ���
	if maid.missileAnimation then
		maid.missileAnimation:Play()
	else
		warn("MissileAnimation is nil")
	end

	-- NPC�� �ڷ� õõ�� �̵���Ű�� ���� ����
	local function moveBackward()
		local backwardDirection = (maid.humanoidRootPart.Position - target.Position).Unit
		local targetPosition = maid.humanoidRootPart.Position + backwardDirection * 20 -- ��ǥ ��ġ ����
		local moveDuration = 2 -- �̵��� �ɸ��� �ð� (��)

		local startTime = tick()
		while tick() - startTime < moveDuration do
			if not maid.humanoidRootPart or not target or not target.Position then
				return
			end

			local elapsed = tick() - startTime
			local alpha = elapsed / moveDuration
			maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position:Lerp(targetPosition, alpha), target.Position)
			RunService.Heartbeat:Wait()
		end

		if target and target.Position then
			maid.humanoidRootPart.CFrame = CFrame.new(targetPosition, target.Position) -- ���� ��ġ�� ����
		end
	end

	-- NPC�� �ڷ� �̵���Ű��
	moveBackward()

	-- �̻��� �ִϸ��̼� ����
	if maid.missileAnimation then
		maid.missileAnimation:Stop()
	else
		warn("MissileAnimation is nil")
	end
end

local function attack()
	attacking = true
	lastAttackTime = tick()

	local attackType = random:NextInteger(1, 3)

	if attackType == 1 then
		-- ���� ����
		local originalWalkSpeed = maid.humanoid.WalkSpeed

		-- ��ǥ������ ����
		if not target or not target.Position then
			attacking = false
			return
		end

		local targetPosition = target.Position + (target.Position - maid.humanoidRootPart.Position).Unit * -1 -- ��ǥ�� �ٷ� �տ� ���ߵ��� ����
		maid.humanoid.WalkSpeed = random:NextInteger(ATTACK_MIN_WALKSPEED, ATTACK_MAX_WALKSPEED) -- ���� �ӵ� ����
		maid.humanoid:MoveTo(targetPosition)

		-- DashAnimation ���
		maid.dashAnimation:Play()

		-- AlignOrientation ��Ȱ��ȭ
		maid.alignOrientation.Enabled = false

		-- ��ǥ������ ������ ������ ���
		maid.humanoid.MoveToFinished:Wait()

		-- ���� �ִϸ��̼� ���
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

		local attackedHumanoids = {}
		for _, part in pairs(hitTouchingParts) do
			local parentModel = part:FindFirstAncestorOfClass("Model")
			if isInstaceAttackable(part) and not attackedHumanoids[parentModel] then
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
		maid.dashAnimation:Stop() -- DashAnimation ����
		maid.alignOrientation.Enabled = true -- AlignOrientation ��Ȱ��ȭ

	elseif attackType == 2 then
		-- ���Ÿ� ����
		if tick() - lastRangedAttackTime > RANGED_ATTACK_COOLDOWN then
			performRangedAttack()
			lastRangedAttackTime = tick()
		end
	else
		-- �̻��� ����
		performMissileAttack()
	end

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