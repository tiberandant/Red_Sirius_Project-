local ZeroGravity = script.Parent

local gravidadeNormal = workspace.Gravity
local gravidadeAntigravidade = 0.1

local function alterarGravidade(part)
	local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:SetAttribute("gravidadeOriginal", humanoid.WalkSpeed)
		humanoid.WalkSpeed = 16  
		workspace.Gravity = gravidadeAntigravidade
	end
end

local function restaurarGravidade(part)
	local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid:GetAttribute("gravidadeOriginal") then
		humanoid.WalkSpeed = humanoid:GetAttribute("gravidadeOriginal")
		workspace.Gravity = gravidadeNormal
	end
end

ZeroGravity.Touched:Connect(alterarGravidade)
ZeroGravity.TouchEnded:Connect(restaurarGravidade)