local thickness = 1
local color = BrickColor.new("Bright red")
local material = Enum.Material.Neon
local transparency = 0
local cancollide = false
local damageAmount = 100 -- 입히고자 하는 대미지 값
local cooldownTime = 3 -- 대미지를 받지 않는 시간 (초)

local block = script.Parent
local CollectionService = game:GetService("CollectionService")
local tagName = "RecentlyDamaged"

local function applyDamage(hit)
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid and not CollectionService:HasTag(humanoid, tagName) then
		humanoid:TakeDamage(damageAmount)
		CollectionService:AddTag(humanoid, tagName)
		task.delay(cooldownTime, function()
			CollectionService:RemoveTag(humanoid, tagName)
		end)
	end
end

local function laser()
	if block:FindFirstChild("Part") then
		block.Part:Destroy()
	end
	local raycast = workspace:Raycast(block.Position, block.CFrame.LookVector * 5000)
	local distance = raycast and (block.Position - raycast.Position).Magnitude
	local part = Instance.new("Part", block)
	part.Anchored = true
	part.BrickColor = color
	part.Material = material
	part.Transparency = transparency
	part.CanCollide = cancollide

	if raycast and distance <= 2048 then
		local middle = (block.Position + raycast.Position) / 2
		part.Size = Vector3.new(thickness, thickness, distance)
		part.CFrame = CFrame.lookAt(middle, raycast.Position)
		applyDamage(raycast.Instance) -- 레이저가 닿은 위치에 대미지 적용
	else
		part.Size = Vector3.new(thickness, thickness, 2048)
		part.CFrame = block.CFrame * CFrame.new(0, 0, -1024)
	end
end

while wait() do
	laser()
end