function onTouched(hit)
	if hit.Parent then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		local rightArm1Exists = hit.Parent:FindFirstChild("RightArm1")
		local sourceRightArm1 = script.Parent.Parent:FindFirstChild("RightArm1")

		if humanoid and not rightArm1Exists and sourceRightArm1 then
			local g = sourceRightArm1:Clone()
			g.Parent = hit.Parent
			local C = g:GetChildren()
			for i = 1, #C do
				if C[i].ClassName == "Part" or C[i].ClassName == "UnionOperation" or C[i].ClassName == "WedgePart" or C[i].ClassName == "MeshPart" then
					local W = Instance.new("Weld")
					W.Part0 = g.Middle
					W.Part1 = C[i]
					local CJ = CFrame.new(g.Middle.Position)
					local C0 = g.Middle.CFrame:Inverse() * CJ
					local C1 = C[i].CFrame:Inverse() * CJ
					W.C0 = C0
					W.C1 = C1
					W.Parent = g.Middle
				end
			end

			local rightUpperArm = hit.Parent:FindFirstChild("RightUpperArm")
			if rightUpperArm then
				local Y = Instance.new("Weld")
				Y.Part0 = rightUpperArm
				Y.Part1 = g.Middle
				Y.C0 = CFrame.new(0, 0, 0)
				Y.Parent = Y.Part0
			end

			local h = g:GetChildren()
			for i = 1, #h do
				if h[i].ClassName == "Part" or h[i].ClassName == "UnionOperation" or h[i].ClassName == "WedgePart" or h[i].ClassName == "MeshPart" then
					h[i].Anchored = false
					h[i].CanCollide = false
				end
			end

			-- 기존 캐릭터의 오른팔을 투명하게 처리
			local rightArmParts = {"RightUpperArm", "RightLowerArm", "RightHand"}
			for _, partName in ipairs(rightArmParts) do
				local part = hit.Parent:FindFirstChild(partName)
				if part then
					part.Transparency = 1
					for _, decal in ipairs(part:GetDescendants()) do
						if decal:IsA("Decal") then
							decal.Transparency = 1
						end
					end
				end
			end
		else
			if not sourceRightArm1 then
				print("RightArm1 not found in source object.")
			end
		end
	end
end

script.Parent.Touched:Connect(onTouched)