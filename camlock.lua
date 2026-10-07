local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove an old copy if one exists
local old = playerGui:FindFirstChild("IvorysCamlock")
if old then
	old:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "IvorysCamlock"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = playerGui

-- Main frame
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(180, 150)
main.Position = UDim2.new(1, -200, 0.5, -75)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 35)
title.Position = UDim2.fromOffset(5, 5)
title.BackgroundTransparency = 1
title.Text = "Ivory's Camlock"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = main

-- Camlock button
local camlock = Instance.new("TextButton")
camlock.Size = UDim2.new(1, -20, 0, 32)
camlock.Position = UDim2.fromOffset(10, 45)
camlock.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
camlock.Text = "CAMLOCK  •  OFF"
camlock.TextColor3 = Color3.fromRGB(240, 240, 240)
camlock.Font = Enum.Font.GothamSemibold
camlock.TextSize = 13
camlock.Parent = main

local camCorner = Instance.new("UICorner")
camCorner.CornerRadius = UDim.new(0, 9)
camCorner.Parent = camlock

-- Tracer button
local tracer = Instance.new("TextButton")
tracer.Size = UDim2.new(1, -20, 0, 32)
tracer.Position = UDim2.fromOffset(10, 82)
tracer.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
tracer.Text = "TRACER  •  OFF"
tracer.TextColor3 = Color3.fromRGB(240, 240, 240)
tracer.Font = Enum.Font.GothamSemibold
tracer.TextSize = 13
tracer.Parent = main

local tracerCorner = Instance.new("UICorner")
tracerCorner.CornerRadius = UDim.new(0, 9)
tracerCorner.Parent = tracer

-- Status
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 120)
status.BackgroundTransparency = 1
status.Text = "READY"
status.TextColor3 = Color3.fromRGB(170, 170, 175)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = main

local camlockEnabled = false
local tracerEnabled = false

camlock.Activated:Connect(function()
	camlockEnabled = not camlockEnabled

	if camlockEnabled then
		camlock.Text = "CAMLOCK  •  ON"
		camlock.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		status.Text = "CAMLOCK READY"
	else
		camlock.Text = "CAMLOCK  •  OFF"
		camlock.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		status.Text = "READY"
	end
end)

tracer.Activated:Connect(function()
	if not camlockEnabled then
		return
	end

	tracerEnabled = not tracerEnabled

	if tracerEnabled then
		tracer.Text = "TRACER  •  ON"
		tracer.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	else
		tracer.Text = "TRACER  •  OFF"
		tracer.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	end
end)
