-- Capsure 모델과 플레이어를 가져옵니다
local capsure = script.Parent
local primaryPart = capsure:FindFirstChild("Circle") -- Circle을 PrimaryPart로 사용합니다
local destroyed = false -- 모델이 이미 파괴되었는지 여부를 추적하는 변수
local replicatedStorage = game:GetService("ReplicatedStorage") -- ReplicatedStorage 서비스 가져오기
local meleeTemplate = replicatedStorage:FindFirstChild("Melee") -- Melee 아이템 가져오기

-- 두 벡터 간의 거리를 계산하는 함수
local function getDistance(pos1, pos2)
	return (pos1 - pos2).magnitude
end

-- 파괴 논리를 처리하는 함수
local function checkPlayerProximity()
	if destroyed then return end -- 모델이 이미 파괴된 경우 함수를 종료합니다

	local players = game:GetService("Players"):GetPlayers()
	for _, player in ipairs(players) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local playerPosition = character.HumanoidRootPart.Position
			local capsurePosition = primaryPart.Position -- PrimaryPart의 위치를 사용합니다

			-- 필요에 따라 거리 임계값을 변경합니다
			local destroyDistance = 30

			if getDistance(playerPosition, capsurePosition) < destroyDistance then
				destroyed = true -- 모델이 파괴됨을 표시합니다

				-- 폭발 효과 생성
				local explosion = Instance.new("Explosion")
				explosion.Position = primaryPart.Position
				explosion.BlastRadius = 10 -- 폭발 반경
				explosion.BlastPressure = 50000 -- 폭발 압력
				explosion.DestroyJointRadiusPercent = 0 -- 파트를 파괴하지 않음
				explosion.Parent = workspace

				-- 파트 흩어지게 하기
				for _, part in ipairs(capsure:GetChildren()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false -- 파트들의 콜라이더 제거
						part:BreakJoints()
						local bodyVelocity = Instance.new("BodyVelocity")
						bodyVelocity.Velocity = Vector3.new(math.random(-50, 50), math.random(20, 50), math.random(-50, 50))
						bodyVelocity.P = 5000
						bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
						bodyVelocity.Parent = part
						-- 1초 후에 BodyVelocity 제거
						game:GetService("Debris"):AddItem(bodyVelocity, 1)
					end
				end

				-- 대미지 제거
				explosion.Hit:Connect(function(hit)
					local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(0)
					end
				end)

				-- 즉시 모델을 파괴합니다
				capsure:Destroy()

				-- Melee 아이템 생성
				if meleeTemplate then
					local meleeClone = meleeTemplate:Clone()
					meleeClone.Parent = workspace

					-- Melee 모델의 주요 파트를 찾아 위치를 설정합니다
					local meleePrimaryPart = meleeClone:FindFirstChildWhichIsA("BasePart") or meleeClone.PrimaryPart
					if meleePrimaryPart then
						-- Capsure 모델의 앞쪽과 위쪽 벡터를 계산하여 Melee 아이템의 위치 설정
						local forwardVector = primaryPart.CFrame.LookVector
						local upVector = primaryPart.CFrame.UpVector
						local offset = forwardVector * 8 + upVector * 3 -- 필요에 따라 거리를 조정합니다
						meleePrimaryPart.CFrame = primaryPart.CFrame + offset
					end
				end

				break
			end
		end
	end
end

-- checkPlayerProximity 함수를 주기적으로 실행합니다
while true do
	checkPlayerProximity()
	wait(1) -- 매 1초마다 체크
end