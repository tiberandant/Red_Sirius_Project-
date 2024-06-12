local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local meteorTemplate = ServerStorage:FindFirstChild("Meteor")
local dropZone = Workspace:FindFirstChild("DropZone")
local zeroGravity = Workspace:FindFirstChild("ZeroGravity")

local function getRandomPositionWithinDropZone()
	local size = dropZone.Size
	local position = dropZone.Position
	local x = position.X - size.X / 2 + math.random() * size.X
	local z = position.Z - size.Z / 2 + math.random() * size.Z
	return Vector3.new(x, position.Y - 10 , z)
end

local function dropMeteor()
	local meteor = meteorTemplate:Clone()
	meteor:SetPrimaryPartCFrame(CFrame.new(getRandomPositionWithinDropZone()))
	meteor.Parent = Workspace
	meteor.PrimaryPart.Anchored = false

	-- 중력 효과 적용
	if meteor.PrimaryPart then
		local gravityForce = Instance.new("BodyForce")
		gravityForce.Force = Vector3.new(0, meteor.PrimaryPart:GetMass() * -10.0, 0)
		gravityForce.Parent = meteor.PrimaryPart

		-- 회전 효과 추가
		local angularVelocity = Instance.new("BodyAngularVelocity")
		angularVelocity.AngularVelocity = Vector3.new(0, 10, 0)  -- Y축 주위로 회전
		angularVelocity.MaxTorque = Vector3.new(0, 1000000, 0)  -- 필요한 경우 토크 값을 조정하여 회전 강도 조절
		angularVelocity.Parent = meteor.PrimaryPart
	else
		error("Meteor model does not have a PrimaryPart set.")
	end
end

while true do
	dropMeteor()
	wait(3)
end