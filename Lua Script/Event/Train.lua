local s = script
local g = game.Workspace

local Model = s.Parent.Parent -- 모델 객체
local Train = Model.Train
local Train2 = Model.Train2
local Spark1 = Model.Spark1
local Spark2 = Model.Spark2
local Spark3 = Model.Spark3
local Spark4 = Model.Spark4
local Door = Model.Door -- Door 객체 추가
local Fire1 = Model.Fire1 -- Fire1 객체 추가
local Fire2 = Model.Fire2 -- Fire2 객체 추가
local Fire3 = Model.Fire3 -- Fire3 객체 추가
local Fire4 = Model.Fire4 -- Fire4 객체 추가

-- BodyVelocity 객체 생성 및 추가
local function addBodyVelocity(part)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5) -- 적절한 힘 설정
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = part
end

addBodyVelocity(Train)
addBodyVelocity(Train2)

local function createExplosion(position, damage)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 100
	explosion.BlastPressure = 50000
	explosion.DestroyJointRadiusPercent = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters

	explosion.Hit:Connect(function(part, distance)
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(damage)
		end
	end)

	explosion.Parent = g
end

local function onProximityTriggered()
	local initialVelocity = 0
	local acceleration = 0.5 -- 초기 가속도 값
	local maxVelocity = 15 -- 초기 최대 속도 (반으로 줄임)
	local duration = 80 -- 총 지속 시간 
	local speedIncreaseTime = 10 -- 속도를 증가시킬 시간 
	local sparkTime = 40 -- 스파크가 발생할 시간 
	local fireTime = 30 -- 불이 나타날 시간
	local doorDestructionTime = 50 -- Door 파트가 파괴될 시간
	local meleeAppearanceTime = 10 -- 첫 번째 Melee가 나타날 시간
	local destructionTime = 60 -- 첫 번째 파트가 파괴될 시간
	local finalDestructionTime = 80 -- 모델이 파괴될 시간
	local startTime = tick() -- 현재 시간을 기록
	local totalDistance = 0 -- 총 이동 거리 초기화
	local timeStep = 0.1 -- 업데이트 주기 (더 자주 업데이트)
	local sparkGenerated = false -- 스파크 발생 여부 체크
	local fireGenerated = false -- 불 발생 여부 체크
	local doorDestroyed = false -- Door 파트 파괴 여부 체크
	local partsDestroyed = false -- 첫 번째 파트 파괴 여부 체크

	-- 카메라 설정
	local camera = game.Workspace.CurrentCamera
	local originalCameraSubject = camera.CameraSubject
	local originalCameraType = camera.CameraType
	camera.CameraSubject = Train2
	camera.CameraType = Enum.CameraType.Track

	while tick() - startTime < duration do

		if tick() - startTime >= speedIncreaseTime then
			acceleration = 1 -- 새로운 가속도 값
			maxVelocity = 60 -- 새로운 최대 속도 (반으로 줄임)
		end

		if not sparkGenerated and tick() - startTime >= sparkTime then
			Spark1.ParticleEmitter.Enabled = true
			Spark2.ParticleEmitter.Enabled = true
			Spark3.ParticleEmitter.Enabled = true
			Spark4.ParticleEmitter.Enabled = true
			sparkGenerated = true -- 스파크 발생 표시
		end

		if not fireGenerated and tick() - startTime >= fireTime then
			Fire1.Fire.Enabled = true
			Fire2.Fire.Enabled = true
			Fire3.Fire.Enabled = true
			Fire4.Fire.Enabled = true
			fireGenerated = true -- 불 발생 표시
		end

		if not doorDestroyed and tick() - startTime >= doorDestructionTime then
			if Door then Door:Destroy() end
			doorDestroyed = true -- Door 파트 파괴 표시
		end

		if not partsDestroyed and tick() - startTime >= destructionTime then
			createExplosion(Train.Position, 50) -- Train 파트의 위치에서 폭발 생성 및 50 대미지
			if Train then Train:Destroy() end
			if Spark1 then Spark1:Destroy() end
			if Spark2 then Spark2:Destroy() end
			partsDestroyed = true -- 첫 번째 파트 파괴 표시
		end

		if initialVelocity < maxVelocity then
			initialVelocity = initialVelocity + acceleration
			if initialVelocity > maxVelocity then
				initialVelocity = maxVelocity
			end
		end

		-- 이동 거리 계산
		totalDistance = totalDistance + initialVelocity * timeStep

		-- 작은 흔들림을 추가
		local shakeMagnitude = 0.2 -- 흔들림의 크기
		local shakeX = (math.random() - 0.5) * shakeMagnitude
		local shakeY = (math.random() - 0.5) * shakeMagnitude

		local velocity = Vector3.new(shakeX, shakeY, initialVelocity) -- Y축 속도를 0으로 설정

		if not partsDestroyed and Train:FindFirstChild("BodyVelocity") then
			Train.BodyVelocity.Velocity = velocity
		end
		if Train2:FindFirstChild("BodyVelocity") then
			Train2.BodyVelocity.Velocity = velocity
		end

		wait(timeStep) -- 업데이트 주기, 너무 짧으면 프레임 드랍이 발생할 수 있음
	end

	-- 속도를 0으로 설정하여 기차를 멈춤
	if Train2:FindFirstChild("BodyVelocity") then
		Train2.BodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Y축 속도를 0으로 설정
	end

	-- 모델 파괴
	if Model then Model:Destroy() end

	-- 카메라 원래대로 복구
	camera.CameraSubject = originalCameraSubject
	camera.CameraType = originalCameraType

	-- 총 이동 거리 출력
	print("Total Distance Travelled: " .. totalDistance .. " studs")

end

script.Parent.ProximityPrompt.Triggered:Connect(onProximityTriggered)