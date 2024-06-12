local ZeroGravity1 = script.Parent

local touchingHumanoids = {}
local RunService = game:GetService("RunService")

local function calcularMassa(modelo)
	local massaTotal = 0
	for _, parte in ipairs(modelo:GetDescendants()) do
		if parte:IsA("BasePart") then
			massaTotal = massaTotal + parte:GetMass()
		end
	end
	return massaTotal
end

local function aplicarAntigravidade(humanoid)
	local rootPart = humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if rootPart and not rootPart:FindFirstChild("AntiGravity") then
		local vectorForce = Instance.new("VectorForce")
		vectorForce.Name = "AntiGravity"
		local attachment = Instance.new("Attachment", rootPart)
		vectorForce.Attachment0 = attachment
		vectorForce.Force = Vector3.new(0, calcularMassa(humanoid.Parent) * workspace.Gravity, 0)
		vectorForce.Parent = rootPart
	end
end

local function removerAntigravidade(humanoid)
	if humanoid.Parent then
		local rootPart = humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local vectorForce = rootPart:FindFirstChild("AntiGravity")
			if vectorForce then
				vectorForce:Destroy()
			end
		end
	end
end

local function alterarGravidade(part)
	if part and part.Parent then
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not touchingHumanoids[humanoid] then
			humanoid:SetAttribute("gravidadeOriginal", humanoid.WalkSpeed)
			humanoid.WalkSpeed = 16
			aplicarAntigravidade(humanoid)
			touchingHumanoids[humanoid] = true
		end
	end
end

local function restaurarGravidade(humanoid)
	if humanoid and humanoid.Parent and not humanoid:GetAttribute("BoosterActive") then
		humanoid.WalkSpeed = humanoid:GetAttribute("gravidadeOriginal")
		removerAntigravidade(humanoid)
		touchingHumanoids[humanoid] = nil
	end
end

local function isHumanoidInZeroGravity(humanoid)
	local rootPart = humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local humanPosition = rootPart.Position
		local partPosition = ZeroGravity1.Position
		local halfSize = ZeroGravity1.Size / 2
		return (math.abs(humanPosition.X - partPosition.X) <= halfSize.X) and
			(math.abs(humanPosition.Y - partPosition.Y) <= halfSize.Y) and
			(math.abs(humanPosition.Z - partPosition.Z) <= halfSize.Z)
	end
	return false
end

ZeroGravity1.Touched:Connect(function(part)
	if part and part.Parent then
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			alterarGravidade(part)
		end
	end
end)

ZeroGravity1.TouchEnded:Connect(function(part)
	if part and part.Parent then
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			wait(0.1)
			if not isHumanoidInZeroGravity(humanoid) then
				restaurarGravidade(humanoid)
			end
		end
	end
end)

RunService.Stepped:Connect(function()
	for humanoid, _ in pairs(touchingHumanoids) do
		if humanoid.Parent == nil or not humanoid.Parent:IsDescendantOf(workspace) then
			removerAntigravidade(humanoid)
			touchingHumanoids[humanoid] = nil
		elseif not isHumanoidInZeroGravity(humanoid) then
			restaurarGravidade(humanoid)
		end
	end
end)