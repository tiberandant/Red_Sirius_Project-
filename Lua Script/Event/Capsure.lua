-- Capsure �𵨰� �÷��̾ �����ɴϴ�
local capsure = script.Parent
local primaryPart = capsure:FindFirstChild("Circle") -- Circle�� PrimaryPart�� ����մϴ�
local destroyed = false -- ���� �̹� �ı��Ǿ����� ���θ� �����ϴ� ����
local replicatedStorage = game:GetService("ReplicatedStorage") -- ReplicatedStorage ���� ��������
local meleeTemplate = replicatedStorage:FindFirstChild("Melee") -- Melee ������ ��������

-- �� ���� ���� �Ÿ��� ����ϴ� �Լ�
local function getDistance(pos1, pos2)
	return (pos1 - pos2).magnitude
end

-- �ı� ���� ó���ϴ� �Լ�
local function checkPlayerProximity()
	if destroyed then return end -- ���� �̹� �ı��� ��� �Լ��� �����մϴ�

	local players = game:GetService("Players"):GetPlayers()
	for _, player in ipairs(players) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local playerPosition = character.HumanoidRootPart.Position
			local capsurePosition = primaryPart.Position -- PrimaryPart�� ��ġ�� ����մϴ�

			-- �ʿ信 ���� �Ÿ� �Ӱ谪�� �����մϴ�
			local destroyDistance = 30

			if getDistance(playerPosition, capsurePosition) < destroyDistance then
				destroyed = true -- ���� �ı����� ǥ���մϴ�

				-- ���� ȿ�� ����
				local explosion = Instance.new("Explosion")
				explosion.Position = primaryPart.Position
				explosion.BlastRadius = 10 -- ���� �ݰ�
				explosion.BlastPressure = 50000 -- ���� �з�
				explosion.DestroyJointRadiusPercent = 0 -- ��Ʈ�� �ı����� ����
				explosion.Parent = workspace

				-- ��Ʈ ������� �ϱ�
				for _, part in ipairs(capsure:GetChildren()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false -- ��Ʈ���� �ݶ��̴� ����
						part:BreakJoints()
						local bodyVelocity = Instance.new("BodyVelocity")
						bodyVelocity.Velocity = Vector3.new(math.random(-50, 50), math.random(20, 50), math.random(-50, 50))
						bodyVelocity.P = 5000
						bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
						bodyVelocity.Parent = part
						-- 1�� �Ŀ� BodyVelocity ����
						game:GetService("Debris"):AddItem(bodyVelocity, 1)
					end
				end

				-- ����� ����
				explosion.Hit:Connect(function(hit)
					local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(0)
					end
				end)

				-- ��� ���� �ı��մϴ�
				capsure:Destroy()

				-- Melee ������ ����
				if meleeTemplate then
					local meleeClone = meleeTemplate:Clone()
					meleeClone.Parent = workspace

					-- Melee ���� �ֿ� ��Ʈ�� ã�� ��ġ�� �����մϴ�
					local meleePrimaryPart = meleeClone:FindFirstChildWhichIsA("BasePart") or meleeClone.PrimaryPart
					if meleePrimaryPart then
						-- Capsure ���� ���ʰ� ���� ���͸� ����Ͽ� Melee �������� ��ġ ����
						local forwardVector = primaryPart.CFrame.LookVector
						local upVector = primaryPart.CFrame.UpVector
						local offset = forwardVector * 8 + upVector * 3 -- �ʿ信 ���� �Ÿ��� �����մϴ�
						meleePrimaryPart.CFrame = primaryPart.CFrame + offset
					end
				end

				break
			end
		end
	end
end

-- checkPlayerProximity �Լ��� �ֱ������� �����մϴ�
while true do
	checkPlayerProximity()
	wait(1) -- �� 1�ʸ��� üũ
end