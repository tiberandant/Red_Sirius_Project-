s = script
g = game.Workspace
Elevator = s.Parent.Parent.Elevator
-------------------------
function onClicked()
	-- 15�� ���� �ö󰡱�
	Elevator.BodyVelocity.velocity = Vector3.new(0, 5, 0)
	wait(15)

	-- 8�� ���� ���߱�
	Elevator.BodyVelocity.velocity = Vector3.new(0, 0, 0)
	wait(11)

	-- �ٽ� 15�� ���� �ö󰡱�
	Elevator.BodyVelocity.velocity = Vector3.new(0, 5, 0)
	wait(15)

	-- ������ ���߱�
	Elevator.BodyVelocity.velocity = Vector3.new(0, 0, 0)
end

script.Parent.ClickDetector.MouseClick:connect(onClicked)
