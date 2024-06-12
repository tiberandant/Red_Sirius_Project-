function onTouched(part)
	local humanoid = part.Parent:findFirstChild("Humanoid")
	if humanoid ~= nil then
		local player = game.Players:FindFirstChild(humanoid.Parent.Name)
		if player ~= nil then
			local stats = player:FindFirstChild("leaderstats")
			if stats ~= nil then
				local score = stats:FindFirstChild("Bolt")
				if score ~= nil then
					-- ·£´ý °ª ¼³Á¤
					local randomAmount = math.random(3)
					local amounts = {100, 150, 200}
					score.Value = score.Value + amounts[randomAmount]
				end
			end
		end
		script.Parent:remove()
	end
end

script.Parent.Touched:Connect(onTouched)