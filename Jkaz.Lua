local player = game.Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- STATE
local recording = false
local playing = false
local path = {}

local tpEnabled = true
local lowPower = false
local checkpoint = nil

-- CHARACTER
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	return char, hum, hrp
end

-- DETECT
local function detectAndHold()
	local _, _, hrp = getChar()
	for _, p in pairs(workspace:GetDescendants()) do
		if p:IsA("ProximityPrompt") then
			local part = p.Parent
			if part and part:IsA("BasePart") then
				if (part.Position - hrp.Position).Magnitude < 10 then
					fireproximityprompt(p, p.HoldDuration)
				end
			end
		end
	end
end

-- 🔥 RECORD (FRAME PERFECT)
local function startRecord()
	path = {}

	local lastTime = tick()

	RunService:BindToRenderStep("REC", Enum.RenderPriority.Character.Value + 1, function()
		if not recording then return end

		local _, hum = getChar()

		local now = tick()
		local dt = now - lastTime
		lastTime = now

		table.insert(path, {
			dir = hum.MoveDirection,
			dt = dt
		})
	end)
end

local function stopRecord()
	RunService:UnbindFromRenderStep("REC")
end

-- 🔥 REPLAY (AKURAT)
local function replay()
	local _, hum = getChar()

	for _,step in ipairs(path) do
		if not playing then break end

		hum:Move(step.dir, true)
		detectAndHold()

		task.wait(step.dt)
	end

	hum:Move(Vector3.zero, true)
end

-- TP
local function tp(pos)
	local _, _, hrp = getChar()
	hrp.CFrame = CFrame.new(pos)
end

-- TP POINTS
local tpPoints = {
	Vector3.new(-197.9, 17.4, -235.0),
	Vector3.new(-134.6, 12.8, -233.0),
	Vector3.new(-257.6, 14.5, -236.9),
	Vector3.new(-57.8, 3.3, 428.4)
}

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,450,0,360)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

-- ICON
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,40,0,40)
icon.Position = UDim2.new(0,20,0,100)
icon.Text = "◉"
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)
icon.Visible = false
icon.Active = true
icon.Draggable = true

-- CLOSE
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

-- BUTTON
local function btn(txt,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = txt
	b.BackgroundColor3 = Color3.fromRGB(70,70,70)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local recBtn = btn("RECORD",40)
local playBtn = btn("PLAY",80)
local delBtn = btn("DELETE",120)
local tpBtn = btn("TP ON/OFF",160)
local cpSetBtn = btn("SET CHECKPOINT",200)
local cpDelBtn = btn("DELETE CHECKPOINT",240)
local batBtn = btn("HEMAT OFF",280)

-- RECORD
recBtn.MouseButton1Click:Connect(function()
	recording = not recording
	recBtn.Text = recording and "STOP" or "RECORD"

	if recording then
		startRecord()
	else
		stopRecord()
	end
end)

-- PLAY
playBtn.MouseButton1Click:Connect(function()
	playing = not playing
	playBtn.Text = playing and "STOP" or "PLAY"

	if playing then
		task.spawn(function()
			while playing do
				replay()

				if tpEnabled then
					for _,pos in ipairs(tpPoints) do
						if not playing then break end
						tp(pos)
						task.wait(0.8)
					end

					if checkpoint then
						tp(checkpoint)
						task.wait(1)
					end
				end
			end
		end)
	end
end)

-- DELETE
delBtn.MouseButton1Click:Connect(function()
	recording = false
	playing = false
	stopRecord()
	path = {}
	recBtn.Text = "RECORD"
	playBtn.Text = "PLAY"
end)

-- TP TOGGLE
tpBtn.MouseButton1Click:Connect(function()
	tpEnabled = not tpEnabled
	tpBtn.Text = tpEnabled and "TP ON" or "TP OFF"
end)

-- CHECKPOINT
cpSetBtn.MouseButton1Click:Connect(function()
	local _, _, hrp = getChar()
	checkpoint = hrp.Position
	cpSetBtn.Text = "CHECKPOINT SET"
end)

cpDelBtn.MouseButton1Click:Connect(function()
	checkpoint = nil
	cpSetBtn.Text = "SET CHECKPOINT"
end)

-- HEMAT
batBtn.MouseButton1Click:Connect(function()
	lowPower = not lowPower
	batBtn.Text = lowPower and "HEMAT ON" or "HEMAT OFF"

	if lowPower then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 100
	else
		Lighting.GlobalShadows = true
		Lighting.FogEnd = 100000
	end
end)

-- PASSIVE
task.spawn(function()
	while true do
		detectAndHold()
		task.wait(0.3)
	end
end)
