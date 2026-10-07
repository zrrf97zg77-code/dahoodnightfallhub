--[[
    ╔══════════════════════════════════════════════════════════╗
    ║         IVORY CAMLOCK — DA HOOD EDITION                  ║
    ║         Delta Executor Build  (FIXED)                    ║
    ╠══════════════════════════════════════════════════════════╣
    ║  Fixes in this version:                                  ║
    ║   • CAMLOCK button now toggles on Delta mobile           ║
    ║   • ESP boxes scale with distance (shrink far / grow near)║
    ║   • Hitscan prediction for Da Hood                       ║
    ║   • Live PING_MULTIPLIER slider                          ║
    ╚══════════════════════════════════════════════════════════╝
--]]

if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv().IvoryCamlock then
    pcall(function() getgenv().IvoryCamlock:Destroy() end)
end

--========================================================--
-- SERVICES
--========================================================--

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- SETTINGS
--========================================================--

local HALF_FOV        = 90
local MAX_DISTANCE    = 1000
local AIM_SMOOTHNESS  = 0.20
local PING_MULTIPLIER = 1.0
local PING_EXTRA_MS   = 0.00

-- ESP box scaling
local BOX_NEAR_DIST   = 10     -- studs: closest  → box is biggest
local BOX_FAR_DIST    = 500    -- studs: farthest → box is smallest
local BOX_MAX_SIZE    = 90     -- pixel width at near distance
local BOX_MIN_SIZE    = 22     -- pixel width at far distance

--========================================================--
-- STATE
--========================================================--

local CamlockEnabled = false
local CurrentTarget  = nil

--========================================================--
-- SCREEN GUI
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "IvoryCamlock"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

getgenv().IvoryCamlock = ScreenGui

--========================================================--
-- MAIN PANEL
--========================================================--

local Main = Instance.new("Frame")
Main.Size             = UDim2.fromOffset(260, 210)
Main.Position         = UDim2.new(0.5, -130, 0.5, -105)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.Parent           = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color        = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness    = 1.2
MainStroke.Transparency = 0.65
MainStroke.Parent       = Main

-- Title
local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position               = UDim2.fromOffset(15, 10)
Title.Size                   = UDim2.new(1, -30, 0, 30)
Title.Text                   = "IVORY CAMLOCK"
Title.TextColor3             = Color3.fromRGB(255, 255, 255)
Title.TextSize               = 19
Title.Font                   = Enum.Font.GothamBold
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.Parent                 = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position               = UDim2.fromOffset(15, 38)
Subtitle.Size                   = UDim2.new(1, -30, 0, 20)
Subtitle.Text                   = "DA HOOD  •  HITSCAN  •  180°"
Subtitle.TextColor3             = Color3.fromRGB(145, 145, 145)
Subtitle.TextSize               = 10
Subtitle.Font                   = Enum.Font.Gotham
Subtitle.TextXAlignment         = Enum.TextXAlignment.Left
Subtitle.Parent                 = Main

-- Slider
local SliderLabel = Instance.new("TextLabel")
SliderLabel.BackgroundTransparency = 1
SliderLabel.Position               = UDim2.fromOffset(15, 62)
SliderLabel.Size                   = UDim2.new(1, -30, 0, 16)
SliderLabel.Text                   = "PREDICTION  •  1.00x"
SliderLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
SliderLabel.TextSize               = 10
SliderLabel.Font                   = Enum.Font.Gotham
SliderLabel.TextXAlignment         = Enum.TextXAlignment.Left
SliderLabel.Parent                 = Main

local SliderBG = Instance.new("Frame")
SliderBG.Position         = UDim2.fromOffset(15, 82)
SliderBG.Size             = UDim2.new(1, -30, 0, 8)
SliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SliderBG.BorderSizePixel  = 0
SliderBG.Parent           = Main
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size             = UDim2.fromScale(0.5, 1)
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderFill.BorderSizePixel  = 0
SliderFill.Parent           = SliderBG
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderKnob = Instance.new("Frame")
SliderKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
SliderKnob.Position         = UDim2.new(0.5, 0, 0.5, 0)
SliderKnob.Size             = UDim2.fromOffset(16, 16)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.BorderSizePixel  = 0
SliderKnob.ZIndex           = 3
SliderKnob.Parent           = SliderBG
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local SLIDER_MIN = 0.5
local SLIDER_MAX = 1.5

local function UpdateSliderVisual()
    local alpha = (PING_MULTIPLIER - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN)
    alpha = math.clamp(alpha, 0, 1)
    SliderFill.Size     = UDim2.fromScale(alpha, 1)
    SliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
    SliderLabel.Text    = string.format("PREDICTION  •  %.2fx", PING_MULTIPLIER)
end

-- GUI toggle
local GuiToggle = Instance.new("TextButton")
GuiToggle.Size             = UDim2.new(1, -30, 0, 38)
GuiToggle.Position         = UDim2.fromOffset(15, 100)
GuiToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GuiToggle.BorderSizePixel  = 0
GuiToggle.Text             = "HIDE GUI"
GuiToggle.TextColor3       = Color3.fromRGB(255, 255, 255)
GuiToggle.TextSize         = 12
GuiToggle.Font             = Enum.Font.GothamBold
GuiToggle.AutoButtonColor  = false
GuiToggle.Parent           = Main
Instance.new("UICorner", GuiToggle).CornerRadius = UDim.new(0, 8)

-- Status labels
local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position               = UDim2.fromOffset(15, 145)
StatusLabel.Size                   = UDim2.new(1, -30, 0, 16)
StatusLabel.Text                   = "STATUS  •  IDLE"
StatusLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize               = 10
StatusLabel.Font                   = Enum.Font.Gotham
StatusLabel.TextXAlignment         = Enum.TextXAlignment.Left
StatusLabel.Parent                 = Main

local TargetLabel = Instance.new("TextLabel")
TargetLabel.BackgroundTransparency = 1
TargetLabel.Position               = UDim2.fromOffset(15, 162)
TargetLabel.Size                   = UDim2.new(1, -30, 0, 16)
TargetLabel.Text                   = "TARGET  •  NONE"
TargetLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
TargetLabel.TextSize               = 10
TargetLabel.Font                   = Enum.Font.Gotham
TargetLabel.TextXAlignment         = Enum.TextXAlignment.Left
TargetLabel.Parent                 = Main

local PingLabel = Instance.new("TextLabel")
PingLabel.BackgroundTransparency = 1
PingLabel.Position               = UDim2.fromOffset(15, 179)
PingLabel.Size                   = UDim2.new(1, -30, 0, 16)
PingLabel.Text                   = "PING  •  0 ms"
PingLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
PingLabel.TextSize               = 10
PingLabel.Font                   = Enum.Font.Gotham
PingLabel.TextXAlignment         = Enum.TextXAlignment.Left
PingLabel.Parent                 = Main

--========================================================--
-- CAMLOCK BUTTON  (NO Draggable — that was blocking taps)
--========================================================--

local CamlockButton = Instance.new("TextButton")
CamlockButton.Size             = UDim2.fromOffset(150, 52)
CamlockButton.Position         = UDim2.new(0.5, -75, 0.85, 0)
CamlockButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
CamlockButton.BorderSizePixel  = 0
CamlockButton.Text             = "CAMLOCK • OFF"
CamlockButton.TextColor3       = Color3.fromRGB(255, 255, 255)
CamlockButton.TextSize         = 14
CamlockButton.Font             = Enum.Font.GothamBold
CamlockButton.AutoButtonColor  = false
CamlockButton.Active           = true
CamlockButton.Draggable        = false   -- 👈 KEY FIX
CamlockButton.Parent           = ScreenGui
Instance.new("UICorner", CamlockButton).CornerRadius = UDim.new(0, 12)

local CamlockStroke = Instance.new("UIStroke")
CamlockStroke.Color        = Color3.fromRGB(255, 255, 255)
CamlockStroke.Thickness    = 1.3
CamlockStroke.Transparency = 0.4
CamlockStroke.Parent       = CamlockButton

--========================================================--
-- ESP CONTAINER
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name   = "IvoryESP"
ESPFolder.Parent = ScreenGui

--========================================================--
-- TARGET BOX  (SizeOffset so it scales, we resize per-frame)
--========================================================--

local function CreatePlayerBox(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name           = player.Name .. "_Box"
    billboard.Size           = UDim2.fromOffset(BOX_MAX_SIZE, BOX_MAX_SIZE * 1.4)
    billboard.AlwaysOnTop    = true
    billboard.LightInfluence = 0
    billboard.Enabled        = false
    billboard.Parent         = ESPFolder

    local box = Instance.new("Frame")
    box.Size                   = UDim2.fromScale(1, 1)
    box.BackgroundTransparency = 1
    box.BorderSizePixel        = 0
    box.Parent                 = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Name      = "Outline"
    stroke.Color     = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Parent    = box

    return billboard
end

local function GetPlayerBox(player)
    local box = ESPFolder:FindFirstChild(player.Name .. "_Box")
    if not box then box = CreatePlayerBox(player) end
    return box
end

--========================================================--
-- TRACER
--========================================================--

local Tracer = Instance.new("Frame")
Tracer.AnchorPoint      = Vector2.new(0.5, 0.5)
Tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tracer.BorderSizePixel  = 0
Tracer.Visible          = false
Tracer.ZIndex           = 20
Tracer.Parent           = ScreenGui

--========================================================--
-- CHARACTER INFO
--========================================================--

local function GetCharacterInfo(player)
    if not player or player == LocalPlayer then return nil end
    local character = player.Character
    if not character then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root     = character:FindFirstChild("HumanoidRootPart")
    local head     = character:FindFirstChild("Head")

    if not humanoid or humanoid.Health <= 0 then return nil end
    if not root or not head then return nil end

    return character, humanoid, root, head
end

--========================================================--
-- TARGET SELECTION
--========================================================--

local function GetClosestTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local camPos  = camera.CFrame.Position
    local camLook = camera.CFrame.LookVector

    local bestPlayer, bestAngle = nil, HALF_FOV

    for _, player in ipairs(Players:GetPlayers()) do
        local character, humanoid, root, head = GetCharacterInfo(player)
        if character then
            local offset   = head.Position - camPos
            local distance = offset.Magnitude
            if distance > 0 and distance <= MAX_DISTANCE then
                local dot   = math.clamp(camLook:Dot(offset.Unit), -1, 1)
                local angle = math.deg(math.acos(dot))
                if angle < bestAngle then
                    bestAngle  = angle
                    bestPlayer = player
                end
            end
        end
    end
    return bestPlayer
end

--========================================================--
-- PING
--========================================================--

local cachedPing, pingTimer = 0.05, 0

local function GetPing()
    if tick() - pingTimer > 1 then
        pingTimer = tick()
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        if ok and typeof(ping) == "number" and ping > 0 then
            cachedPing = math.clamp(ping, 0, 0.4)
        end
    end
    return cachedPing
end

--========================================================--
-- HITSCAN PREDICTION
--========================================================--

local function GetPredictedPosition(player)
    local character, humanoid, root, head = GetCharacterInfo(player)
    if not character then return nil end

    local pingTime = (GetPing() * PING_MULTIPLIER) + PING_EXTRA_MS
    local velocity = root.AssemblyLinearVelocity

    return head.Position + (velocity * pingTime)
end

--========================================================--
-- TRACER UPDATE
--========================================================--

local function UpdateTracer(target)
    if not target then Tracer.Visible = false return end
    local character, humanoid, root, head = GetCharacterInfo(target)
    if not character then Tracer.Visible = false return end
    local camera = workspace.CurrentCamera
    if not camera then return end

    local position, visible = camera:WorldToViewportPoint(head.Position)
    if not visible then Tracer.Visible = false return end

    local viewport = camera.ViewportSize
    local start    = Vector2.new(viewport.X / 2, viewport.Y)
    local finish   = Vector2.new(position.X, position.Y)
    local diff     = finish - start
    local length   = diff.Magnitude

    if length < 1 then Tracer.Visible = false return end

    Tracer.Visible  = true
    Tracer.Position = UDim2.fromOffset((start.X + finish.X)/2, (start.Y + finish.Y)/2)
    Tracer.Size     = UDim2.fromOffset(length, 2)
    Tracer.Rotation = math.deg(math.atan2(diff.Y, diff.X))
end

--========================================================--
-- ESP UPDATE  (now resizes per frame based on distance)
--========================================================--

local function UpdateESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local billboard = GetPlayerBox(player)
            local character, humanoid, root, head = GetCharacterInfo(player)

            if character and head then
                billboard.Adornee = character
                billboard.Enabled = true

                -- Distance from camera to target
                local distance = (head.Position - camPos).Magnitude

                -- Map distance → box size (clamped)
                -- closer = bigger, farther = smaller
                local alpha = (distance - BOX_NEAR_DIST) / (BOX_FAR_DIST - BOX_NEAR_DIST)
                alpha = math.clamp(alpha, 0, 1)

                -- Lerp from MAX → MIN
                local boxW = BOX_MAX_SIZE + (BOX_MIN_SIZE - BOX_MAX_SIZE) * alpha
                local boxH = boxW * 1.4

                billboard.Size = UDim2.fromOffset(boxW, boxH)

                local box = billboard:FindFirstChild("Box")
                if box then
                    local outline = box:FindFirstChild("Outline")
                    if outline then
                        outline.Thickness = (player == CurrentTarget) and 2.5 or 1.5
                    end
                end
            else
                billboard.Enabled = false
            end
        end
    end
end

--========================================================--
-- CAMLOCK TOGGLE
--========================================================--

local function SetCamlock(enabled)
    CamlockEnabled = enabled
    if enabled then
        CamlockButton.Text             = "CAMLOCK • ON"
        CamlockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        CamlockStroke.Color            = Color3.fromRGB(120, 255, 120)
        StatusLabel.Text               = "STATUS  •  ACTIVE"
        StatusLabel.TextColor3         = Color3.fromRGB(120, 255, 120)
    else
        CamlockButton.Text             = "CAMLOCK • OFF"
        CamlockButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        CamlockStroke.Color            = Color3.fromRGB(255, 255, 255)
        StatusLabel.Text               = "STATUS  •  IDLE"
        StatusLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
        CurrentTarget                  = nil
    end
end

--========================================================--
-- BUTTON BINDING  (Delta mobile-safe)
--========================================================--

-- IMPORTANT: use only InputBegan. MouseButton1Click + InputBegan
-- both fire on PC → causes double-toggle → looks like "nothing happens".

local function BindButton(button, callback)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            callback()
        end
    end)
end

BindButton(CamlockButton, function()
    SetCamlock(not CamlockEnabled)
end)

BindButton(GuiToggle, function()
    Main.Visible = not Main.Visible
    GuiToggle.Text = Main.Visible and "HIDE GUI" or "SHOW GUI"
end)

--========================================================--
-- SLIDER DRAG
--========================================================--

local sliderDragging = false

local function UpdateSliderFromInput(input)
    local absPos = SliderBG.AbsolutePosition
    local absSize = SliderBG.AbsoluteSize
    local alpha = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
    PING_MULTIPLIER = SLIDER_MIN + alpha * (SLIDER_MAX - SLIDER_MIN)
    UpdateSliderVisual()
end

SliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        UpdateSliderFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        UpdateSliderFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

--========================================================--
-- KEYBIND (Q)
--========================================================--

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        SetCamlock(not CamlockEnabled)
    end
end)

--========================================================--
-- MAIN LOOP
--========================================================--

local labelTimer = 0

RunService.RenderStepped:Connect(function(dt)
    CurrentTarget = GetClosestTarget()
    UpdateESP()
    UpdateTracer(CurrentTarget)

    labelTimer = labelTimer + dt
    if labelTimer >= 0.15 then
        labelTimer = 0
        TargetLabel.Text = CurrentTarget and ("TARGET  •  " .. CurrentTarget.Name) or "TARGET  •  NONE"
        PingLabel.Text   = string.format("PING  •  %d ms", math.floor(GetPing() * 1000))
    end

    if not CamlockEnabled or not CurrentTarget then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local predicted = GetPredictedPosition(CurrentTarget)
    if not predicted then return end

    local desired = CFrame.lookAt(camera.CFrame.Position, predicted)
    camera.CFrame = camera.CFrame:Lerp(desired, AIM_SMOOTHNESS)
end)

--========================================================--
-- CLEANUP
--========================================================--

Players.PlayerRemoving:Connect(function(player)
    local box = ESPFolder:FindFirstChild(player.Name .. "_Box")
    if box then box:Destroy() end
    if CurrentTarget == player then CurrentTarget = nil end
end)

--========================================================--
-- INIT
--========================================================--

SetCamlock(false)
UpdateSliderVisual()

pcall(function()
    if setthreadidentity then setthreadidentity(2) end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "IVORY CAMLOCK",
        Text  = "Fixed build loaded • Press Q",
        Duration = 5,
    })
end)
