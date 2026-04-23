local player = game.Players.LocalPlayer
local Lighting = game:GetService("Lighting")

-- STATE
local recording = false
local playing = false
local path = {}
local recordInterval = 0.15
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

-- RECORD
local function startRecord()
	path = {}
	task.spawn(function()
		while recording do
			local _, _, hrp = getChar()
			table.insert(path, hrp.Position)
			task.wait(recordInterval)
		end
	end)
end

-- WALK
local function walkTo(pos)
	local _, hum = getChar()
	hum:MoveTo(pos)
	hum.MoveToFinished:Wait()
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
frame.Size = UDim2.new(0,420,0,320)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

-- ICON (MINIMIZE)
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
closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
closeBtn.TextColor3 = Color3.new(1,1,1)

-- TOGGLE GUI
local function hideGUI()
	frame.Visible = false
	icon.Visible = true
end

local function showGUI()
	frame.Visible = true
	icon.Visible = false
end

closeBtn.MouseButton1Click:Connect(hideGUI)
icon.MouseButton1Click:Connect(showGUI)

-- BUTTONS
local function btn(txt,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = txt
	b.BackgroundColor3 = Color3.fromRGB(70,70,70)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local recBtn = btn("RECORD",10)
local playBtn = btn("PLAY",50)
local delBtn = btn("DELETE",90)

-- RECORD
recBtn.MouseButton1Click:Connect(function()
	recording = not recording
	recBtn.Text = recording and "STOP" or "RECORD"
	if recording then startRecord() end
end)

-- PLAY
playBtn.MouseButton1Click:Connect(function()
	playing = not playing
	playBtn.Text = playing and "STOP" or "PLAY"

	if playing then
		task.spawn(function()
			while playing do

				for _,pos in ipairs(path) do
					if not playing then break end
					walkTo(pos)
					detectAndHold()
				end

				if tpEnabled then
					for _,pos in ipairs(tpPoints) do
						if not playing then break end
						tp(pos)
						task.wait(1)
					end

					if checkpoint then
						tp(checkpoint)
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
	path = {}
	recBtn.Text = "RECORD"
	playBtn.Text = "PLAY"
end)

-- PASSIVE
task.spawn(function()
	while true do
		detectAndHold()
		task.wait(0.3)
	end
end)
