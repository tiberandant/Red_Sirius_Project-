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
local RANGED_ATTACK_COOLDOWN = 2 -- 원거리 공격 쿨타임
local RANGED_ATTACK_RANGE = 50 -- 원거리 공격 사거리

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
local lastRangedAttackTime = 0 -- 마지막 원거리 공격 시간

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
	-- NPC가 목표물을 바라보도록 방향 설정
	if not target or not target.Position then
		return
	end

	maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)

	-- 원거리 공격 애니메이션 재생
	maid.shootAnimation:Play()

	-- 원거리 공격 로직 구현
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
		projectile.Velocity = (target.Position - maid.humanoidRootPart.Position).Unit * 200 -- 투사체 속도 증가

		projectile.Parent = Workspace

		-- 충돌 및 피해 처리
		projectile.Touched:Connect(function(hit)
			local hitHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if hitHumanoid and hit.Parent ~= maid.instance then
				hitHumanoid:TakeDamage(ATTACK_DAMAGE / 10) 
			end
		end)

		-- 일정 시간 후 투사체 제거
		game:GetService("Debris"):AddItem(projectile, 10)
	end

	-- 5발 연속으로 발사
	for i = 1, 5 do
		createProjectile()
		wait(0.1) -- 발사 간의 짧은 지연 시간을 추가
	end

	-- 원거리 공격 애니메이션 중지
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
				missile:Destroy() -- 목표가 없을 경우 미사일 제거
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

	-- 시각적 효과 추가
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
	-- NPC가 목표물을 바라보도록 방향 설정
	if not target or not target.Position then
		return
	end

	if not maid.humanoidRootPart then
		return
	end

	maid.humanoidRootPart.CFrame = CFrame.new(maid.humanoidRootPart.Position, target.Position)

	-- 미사일 공격 로직 구현
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
		missile.Anchored = true -- 미사일을 고정하여 중력의 영향을 받지 않게 설정
		missile.CanCollide = false
		missile.Parent = Workspace

		local missileSpeed = 20 -- 미사일 속도를 느리게 설정
		local stopTrackingDistance = 5 -- 유도 기능을 멈출 거리 설정

		-- 충돌 및 피해 처리
		missile.Touched:Connect(function(hit)
			local hitHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if hitHumanoid and hit.Parent ~= maid.instance then
				hitHumanoid:TakeDamage(ATTACK_DAMAGE / 6) -- 대미지를 1/6로 감소
				createExplosion(missile.Position) -- 폭발 효과 추가
				missile:Destroy() -- 충돌 시 미사일 제거
			end
		end)

		-- 일정 시간 후 미사일 제거
		game:GetService("Debris"):AddItem(missile, 20)

		-- 유도성 부여를 위한 함수 실행
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

	-- 미사일 애니메이션 재생
	if maid.missileAnimation then
		maid.missileAnimation:Play()
	else
		warn("MissileAnimation is nil")
	end

	-- NPC를 뒤로 천천히 이동시키기 위한 로직
	local function moveBackward()
		local backwardDirection = (maid.humanoidRootPart.Position - target.Position).Unit
		local targetPosition = maid.humanoidRootPart.Position + backwardDirection * 20 -- 목표 위치 설정
		local moveDuration = 2 -- 이동에 걸리는 시간 (초)

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
			maid.humanoidRootPart.CFrame = CFrame.new(targetPosition, target.Position) -- 최종 위치로 설정
		end
	end

	-- NPC를 뒤로 이동시키기
	moveBackward()

	-- 미사일 애니메이션 중지
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
		-- 근접 공격
		local originalWalkSpeed = maid.humanoid.WalkSpeed

		-- 목표물에게 돌진
		if not target or not target.Position then
			attacking = false
			return
		end

		local targetPosition = target.Position + (target.Position - maid.humanoidRootPart.Position).Unit * -1 -- 목표물 바로 앞에 멈추도록 조정
		maid.humanoid.WalkSpeed = random:NextInteger(ATTACK_MIN_WALKSPEED, ATTACK_MAX_WALKSPEED) -- 돌진 속도 설정
		maid.humanoid:MoveTo(targetPosition)

		-- DashAnimation 재생
		maid.dashAnimation:Play()

		-- AlignOrientation 비활성화
		maid.alignOrientation.Enabled = false

		-- 목표물에게 도달할 때까지 대기
		maid.humanoid.MoveToFinished:Wait()

		-- 공격 애니메이션 재생
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
		maid.dashAnimation:Stop() -- DashAnimation 중지
		maid.alignOrientation.Enabled = true -- AlignOrientation 재활성화

	elseif attackType == 2 then
		-- 원거리 공격
		if tick() - lastRangedAttackTime > RANGED_ATTACK_COOLDOWN then
			performRangedAttack()
			lastRangedAttackTime = tick()
		end
	else
		-- 미사일 공격
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