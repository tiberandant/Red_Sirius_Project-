local s = script
local g = game.Workspace

local Model = s.Parent.Parent -- �� ��ü
local Train = Model.Train
local Train2 = Model.Train2
local Spark1 = Model.Spark1
local Spark2 = Model.Spark2
local Spark3 = Model.Spark3
local Spark4 = Model.Spark4
local Door = Model.Door -- Door ��ü �߰�
local Fire1 = Model.Fire1 -- Fire1 ��ü �߰�
local Fire2 = Model.Fire2 -- Fire2 ��ü �߰�
local Fire3 = Model.Fire3 -- Fire3 ��ü �߰�
local Fire4 = Model.Fire4 -- Fire4 ��ü �߰�

-- BodyVelocity ��ü ���� �� �߰�
local function addBodyVelocity(part)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5) -- ������ �� ����
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
	local acceleration = 0.5 -- �ʱ� ���ӵ� ��
	local maxVelocity = 15 -- �ʱ� �ִ� �ӵ� (������ ����)
	local duration = 80 -- �� ���� �ð� 
	local speedIncreaseTime = 10 -- �ӵ��� ������ų �ð� 
	local sparkTime = 40 -- ����ũ�� �߻��� �ð� 
	local fireTime = 30 -- ���� ��Ÿ�� �ð�
	local doorDestructionTime = 50 -- Door ��Ʈ�� �ı��� �ð�
	local meleeAppearanceTime = 10 -- ù ��° Melee�� ��Ÿ�� �ð�
	local destructionTime = 60 -- ù ��° ��Ʈ�� �ı��� �ð�
	local finalDestructionTime = 80 -- ���� �ı��� �ð�
	local startTime = tick() -- ���� �ð��� ���
	local totalDistance = 0 -- �� �̵� �Ÿ� �ʱ�ȭ
	local timeStep = 0.1 -- ������Ʈ �ֱ� (�� ���� ������Ʈ)
	local sparkGenerated = false -- ����ũ �߻� ���� üũ
	local fireGenerated = false -- �� �߻� ���� üũ
	local doorDestroyed = false -- Door ��Ʈ �ı� ���� üũ
	local partsDestroyed = false -- ù ��° ��Ʈ �ı� ���� üũ

	-- ī�޶� ����
	local camera = game.Workspace.CurrentCamera
	local originalCameraSubject = camera.CameraSubject
	local originalCameraType = camera.CameraType
	camera.CameraSubject = Train2
	camera.CameraType = Enum.CameraType.Track

	while tick() - startTime < duration do

		if tick() - startTime >= speedIncreaseTime then
			acceleration = 1 -- ���ο� ���ӵ� ��
			maxVelocity = 60 -- ���ο� �ִ� �ӵ� (������ ����)
		end

		if not sparkGenerated and tick() - startTime >= sparkTime then
			Spark1.ParticleEmitter.Enabled = true
			Spark2.ParticleEmitter.Enabled = true
			Spark3.ParticleEmitter.Enabled = true
			Spark4.ParticleEmitter.Enabled = true
			sparkGenerated = true -- ����ũ �߻� ǥ��
		end

		if not fireGenerated and tick() - startTime >= fireTime then
			Fire1.Fire.Enabled = true
			Fire2.Fire.Enabled = true
			Fire3.Fire.Enabled = true
			Fire4.Fire.Enabled = true
			fireGenerated = true -- �� �߻� ǥ��
		end

		if not doorDestroyed and tick() - startTime >= doorDestructionTime then
			if Door then Door:Destroy() end
			doorDestroyed = true -- Door ��Ʈ �ı� ǥ��
		end

		if not partsDestroyed and tick() - startTime >= destructionTime then
			createExplosion(Train.Position, 50) -- Train ��Ʈ�� ��ġ���� ���� ���� �� 50 �����
			if Train then Train:Destroy() end
			if Spark1 then Spark1:Destroy() end
			if Spark2 then Spark2:Destroy() end
			partsDestroyed = true -- ù ��° ��Ʈ �ı� ǥ��
		end

		if initialVelocity < maxVelocity then
			initialVelocity = initialVelocity + acceleration
			if initialVelocity > maxVelocity then
				initialVelocity = maxVelocity
			end
		end

		-- �̵� �Ÿ� ���
		totalDistance = totalDistance + initialVelocity * timeStep

		-- ���� ��鸲�� �߰�
		local shakeMagnitude = 0.2 -- ��鸲�� ũ��
		local shakeX = (math.random() - 0.5) * shakeMagnitude
		local shakeY = (math.random() - 0.5) * shakeMagnitude

		local velocity = Vector3.new(shakeX, shakeY, initialVelocity) -- Y�� �ӵ��� 0���� ����

		if not partsDestroyed and Train:FindFirstChild("BodyVelocity") then
			Train.BodyVelocity.Velocity = velocity
		end
		if Train2:FindFirstChild("BodyVelocity") then
			Train2.BodyVelocity.Velocity = velocity
		end

		wait(timeStep) -- ������Ʈ �ֱ�, �ʹ� ª���� ������ ����� �߻��� �� ����
	end

	-- �ӵ��� 0���� �����Ͽ� ������ ����
	if Train2:FindFirstChild("BodyVelocity") then
		Train2.BodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Y�� �ӵ��� 0���� ����
	end

	-- �� �ı�
	if Model then Model:Destroy() end

	-- ī�޶� ������� ����
	camera.CameraSubject = originalCameraSubject
	camera.CameraType = originalCameraType

	-- �� �̵� �Ÿ� ���
	print("Total Distance Travelled: " .. totalDistance .. " studs")

end

script.Parent.ProximityPrompt.Triggered:Connect(onProximityTriggered)