function onTouched(hit)
	if hit.Parent then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		local hairExists = hit.Parent:FindFirstChild("Hair")
		local sourceHair = script.Parent.Parent:FindFirstChild("Hair")

		if humanoid and not hairExists and sourceHair then
			local g = sourceHair:Clone()
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

			local head = hit.Parent:FindFirstChild("Head")
			if head then
				local Y = Instance.new("Weld")
				Y.Part0 = head
				Y.Part1 = g.Middle
				Y.C0 = CFrame.new(0, 0, 0)
				Y.Parent = Y.Part0

				local h = g:GetChildren()
				for i = 1, #h do
					if h[i].ClassName == "Part" or h[i].ClassName == "UnionOperation" or h[i].ClassName == "WedgePart" or h[i].ClassName == "MeshPart" then
						h[i].Anchored = false
						h[i].CanCollide = false
					end
				end

				-- 기존 캐릭터의 머리카락을 투명하게 처리
				for _, accessory in ipairs(hit.Parent:GetChildren()) do
					if accessory:IsA("Accessory") and accessory.Name == "Hair" then
						accessory.Handle.Transparency = 1
						for _, decal in ipairs(accessory.Handle:GetDescendants()) do
							if decal:IsA("Decal") then
								decal.Transparency = 1
							end
						end
					end
				end
			else
				print("Head not found in character.")
			end
		else
			if not sourceHair then
				print("Hair not found in source object.")
			end
		end
	end
end

script.Parent.Touched:Connect(onTouched)
