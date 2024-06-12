local L = script.Parent.Left
local LPos = Vector3.new(108.321, -99.92, 6536.25)
local LOpenPos = {["CFrame"] = L.CFrame - (L.Position - LPos)} -- 왼쪽 열림
local LClosePos = {["CFrame"] = L.CFrame} -- 왼쪽 닫힘

local R = script.Parent.Right
local RPos = Vector3.new(122.03, -99.923, 6536.25)
local ROpenPos = {["CFrame"] = R.CFrame - (R.Position - RPos)} -- 오른쪽 열림
local RClosePos = {["CFrame"] = R.CFrame} -- 오른쪽 닫힘

local tweenservice = game:GetService("TweenService")

local Info = TweenInfo.new( -- 좌우 통일
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
	-- 닫힘 완료는 오른쪽 기준으로만 확인함
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
	--열림 완료도 오른쪽 기준으로만 확인
	wait(1) -- 열린 상태 1초 유지
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