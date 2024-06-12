local Event = game.ReplicatedStorage:WaitForChild("ArmorBuy")

Event.OnServerEvent:Connect(function(plr, itemName, price)
	local leaderstats = plr:FindFirstChild("leaderstats")
	local points = leaderstats and leaderstats:FindFirstChild("Bolt")

	if points and points.Value >= price then
		points.Value = points.Value - price

		-- ReplicatedStorage���� ������ ��������
		local item = game.ReplicatedStorage:FindFirstChild(itemName)

		if item then
			-- �÷��̾��� ĳ���Ϳ� ������ ���� �� ����
			local character = plr.Character or plr.CharacterAdded:Wait()
			local newItem = item:Clone()

			-- ��Ŀ ���� �Լ�
			local function unanchorParts(model)
				for _, part in pairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
					end
				end
			end

			-- �������� �׼������� ���
			if newItem:IsA("Accessory") then
				character.Humanoid:AddAccessory(newItem)
			else
				-- �������� ���� ���, ��� ��Ʈ�� ��Ŀ�� �����ϰ� PrimaryPart�� ã�� CFrame ����
				if newItem:IsA("Model") then
					unanchorParts(newItem)
					if newItem.PrimaryPart then
						newItem:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame)
					else
						for _, part in ipairs(newItem:GetChildren()) do
							if part:IsA("BasePart") then
								part.CFrame = character.HumanoidRootPart.CFrame
							end
						end
					end
				elseif newItem:IsA("BasePart") or newItem:IsA("MeshPart") then
					-- �������� ���� ��Ʈ�� ���
					newItem.Anchored = false
					newItem.CFrame = character.HumanoidRootPart.CFrame
				end

				newItem.Parent = character
			end
		end
	else
		print("���� ����: ����Ʈ�� �����մϴ�.")
	end
end)