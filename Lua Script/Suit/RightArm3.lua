function onTouched(hit)
	if hit.Parent then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		local rightArm3Exists = hit.Parent:FindFirstChild("RightArm3")
		local sourceRightArm3 = script.Parent.Parent:FindFirstChild("RightArm3")

		if humanoid and not rightArm3Exists and sourceRightArm3 then
			local g = sourceRightArm3:Clone()
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

			local rightHand = hit.Parent:FindFirstChild("RightHand")
			if rightHand then
				local Y = Instance.new("Weld")
				Y.Part0 = rightHand
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
		else
			if not sourceRightArm3 then
				print("RightArm3 not found in source object.")
			end
		end
	end
end

script.Parent.Touched:Connect(onTouched)