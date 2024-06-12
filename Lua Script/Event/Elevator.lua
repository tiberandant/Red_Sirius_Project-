s = script
g = game.Workspace
Elevator = s.Parent.Parent.Elevator
-------------------------
function onClicked()
	-- 15초 동안 올라가기
	Elevator.BodyVelocity.velocity = Vector3.new(0, 5, 0)
	wait(15)

	-- 8초 동안 멈추기
	Elevator.BodyVelocity.velocity = Vector3.new(0, 0, 0)
	wait(11)

	-- 다시 15초 동안 올라가기
	Elevator.BodyVelocity.velocity = Vector3.new(0, 5, 0)
	wait(15)

	-- 완전히 멈추기
	Elevator.BodyVelocity.velocity = Vector3.new(0, 0, 0)
end

script.Parent.ClickDetector.MouseClick:connect(onClicked)
