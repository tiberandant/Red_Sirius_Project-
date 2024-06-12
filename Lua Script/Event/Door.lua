local L = script.Parent.Left
local LPos = Vector3.new(108.321, -99.92, 6536.25)
local LOpenPos = {["CFrame"] = L.CFrame - (L.Position - LPos)} -- ���� ����
local LClosePos = {["CFrame"] = L.CFrame} -- ���� ����

local R = script.Parent.Right
local RPos = Vector3.new(122.03, -99.923, 6536.25)
local ROpenPos = {["CFrame"] = R.CFrame - (R.Position - RPos)} -- ������ ����
local RClosePos = {["CFrame"] = R.CFrame} -- ������ ����

local tweenservice = game:GetService("TweenService")

local Info = TweenInfo.new( -- �¿� ����
	1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)


local LOpenTween = tweenservice:Create(L, Info, LOpenPos)
local LCloseTween = tweenservice:Create(L, Info, LClosePos)

local ROpenTween = tweenservice:Create(R, Info, ROpenPos)
local RCloseTween = tweenservice:Create(R, Info, RClosePos)



local IsClosing = false
local IsOpening = false
RCloseTween.Completed:Connect(function(PlaybackState) 
	-- ���� �Ϸ�� ������ �������θ� Ȯ����
	if PlaybackState == Enum.PlaybackState.Completed then
		IsClosing = false
	end
end)

function CloseDoor()
	IsClosing = true
	LCloseTween:Play()
	RCloseTween:Play()
end

function PauseClose()
	LCloseTween:Pause()
	RCloseTween:Pause()
	IsClosing = false
end

ROpenTween.Completed:Connect(function(PlaybackState)
	--���� �Ϸᵵ ������ �������θ� Ȯ��
	wait(1) -- ���� ���� 1�� ����
	IsOpening = false
	CloseDoor()
end)

function OpenDoor()
	IsOpening = true
	LOpenTween:Play()
	ROpenTween:Play()
end

local sensor = script.Parent.sensor
sensor.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildOfClass("Humanoid") then
		if IsClosing then
			PauseClose()
		end
		if not IsOpening then
			OpenDoor()
		end
	end
end)