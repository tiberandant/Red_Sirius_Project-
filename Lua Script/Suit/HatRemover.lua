function onTouched(hit) 
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Accessory") and child.Name ~= "NewItemName" then -- NewItemName�� ���� ������ �̸����� ����
				child:Destroy()
			end
		end
	end
end 

script.Parent.Touched:connect(onTouched)