local Event = game.ReplicatedStorage:WaitForChild("ArmorBuy")

Event.OnServerEvent:Connect(function(plr, itemName, price)
	local leaderstats = plr:FindFirstChild("leaderstats")
	local points = leaderstats and leaderstats:FindFirstChild("Bolt")

	if points and points.Value >= price then
		points.Value = points.Value - price

		-- ReplicatedStorage에서 아이템 가져오기
		local item = game.ReplicatedStorage:FindFirstChild(itemName)

		if item then
			-- 플레이어의 캐릭터에 아이템 복사 및 장착
			local character = plr.Character or plr.CharacterAdded:Wait()
			local newItem = item:Clone()

			-- 앵커 해제 함수
			local function unanchorParts(model)
				for _, part in pairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
					end
				end
			end

			-- 아이템이 액세서리인 경우
			if newItem:IsA("Accessory") then
				character.Humanoid:AddAccessory(newItem)
			else
				-- 아이템이 모델인 경우, 모든 파트의 앵커를 해제하고 PrimaryPart를 찾아 CFrame 설정
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
					-- 아이템이 단일 파트인 경우
					newItem.Anchored = false
					newItem.CFrame = character.HumanoidRootPart.CFrame
				end

				newItem.Parent = character
			end
		end
	else
		print("구매 실패: 포인트가 부족합니다.")
	end
end)