--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              IVORY CAMLOCK — DES HOOD                    ║
    ║              Delta Executor Edition                      ║
    ╠══════════════════════════════════════════════════════════╣
    ║  Features:                                               ║
    ║   • IVORY CAMLOCK GUI                                    ║
    ║   • Fixed CAMLOCK button                                 ║
    ║   • Fixed 180° target range                              ║
    ║   • No FOV circle / slider                               ║
    ║   • White player boxes                                   ║
    ║   • White target tracer                                  ║
    ║   • Smooth camlock                                       ║
    ║   • Velocity + projectile prediction                     ║
    ║   • Projectile speed = 50                                ║
    ║   • PC + Mobile support                                  ║
    ║   • Keybind: Q                                           ║
    ╚══════════════════════════════════════════════════════════╝
--]]

--========================================================--
-- DELTA EXECUTOR HEADER
--========================================================--

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Ensure executor environment
if not syn and not secure_call and not getgenv then
    warn("[IVORY] Unsupported executor. Delta required.")
    return
end

-- Clean previous instance if re-executed
if getgenv().IvoryCamlock then
    pcall(function()
        getgenv().IvoryCamlock:Destroy()
    end)
end

--========================================================--
-- SERVICES
--========================================================--

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- SETTINGS
--========================================================--

local PROJECTILE_SPEED = 50
local HALF_FOV         = 90      -- literal 180° field
local MAX_DISTANCE     = 1000
local AIM_SMOOTHNESS   = 0.20
local PING_MULTIPLIER  = 1

--========================================================--
-- STATE
--========================================================--

local CamlockEnabled = false
local CurrentTarget  = nil

--========================================================--
-- SCREEN GUI
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "IvoryCamlock"
ScreenGui.ResetOnSpawn    = false
ScreenGui.IgnoreGuiInset  = true
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = PlayerGui

getgenv().IvoryCamlock = ScreenGui

--========================================================--
-- MAIN GUI
--========================================================--

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.fromOffset(260, 150)
Main.Position         = UDim2.new(0.5, -130, 0.5, -75)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.Parent           = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent       = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color        = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness    = 1.2
MainStroke.Transparency = 0.65
MainStroke.Parent       = Main

--========================================================--
-- TITLE
--========================================================--

local Title = Instance.new("TextLabel")
Title.Name                 = "Title"
Title.BackgroundTransparency = 1
Title.Position             = UDim2.fromOffset(15, 10)
Title.Size                 = UDim2.new(1, -30, 0, 30)
Title.Text                 = "IVORY CAMLOCK"
Title.TextColor3           = Color3.fromRGB(255, 255, 255)
Title.TextSize             = 19
Title.Font                 = Enum.Font.GothamBold
Title.Parent               = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Name                 = "Subtitle"
Subtitle.BackgroundTransparency = 1
Subtitle.Position             = UDim2.fromOffset(15, 38)
Subtitle.Size                 = UDim2.new(1, -30, 0, 20)
Subtitle.Text                 = "DES HOOD  •  180°"
Subtitle.TextColor3           = Color3.fromRGB(145, 145, 145)
Subtitle.TextSize             = 10
Subtitle.Font                 = Enum.Font.Gotham
Subtitle.Parent               = Main

--========================================================--
-- GUI TOGGLE
--========================================================--

local GuiToggle = Instance.new("TextButton")
GuiToggle.Name             = "GuiToggle"
GuiToggle.Size             = UDim2.new(1, -30, 0, 45)
GuiToggle.Position         = UDim2.fromOffset(15, 80)
GuiToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GuiToggle.BorderSizePixel  = 0
GuiToggle.Text             = "HIDE GUI"
GuiToggle.TextColor3       = Color3.fromRGB(255, 255, 255)
GuiToggle.TextSize         = 13
GuiToggle.Font             = Enum.Font.GothamBold
GuiToggle.AutoButtonColor  = false
GuiToggle.Parent           = Main

local GuiToggleCorner = Instance.new("UICorner")
GuiToggleCorner.CornerRadius = UDim.new(0, 8)
GuiToggleCorner.Parent       = GuiToggle

--========================================================--
-- FLOATING CAMLOCK BUTTON
--========================================================--

local CamlockButton = Instance.new("TextButton")
CamlockButton.Name             = "CamlockButton"
CamlockButton.Size             = UDim2.fromOffset(140, 48)
CamlockButton.Position         = UDim2.new(0.5, -70, 0.82, 0)
CamlockButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
CamlockButton.BorderSizePixel  = 0
CamlockButton.Text             = "CAMLOCK • OFF"
CamlockButton.TextColor3       = Color3.fromRGB(255, 255, 255)
CamlockButton.TextSize         = 13
CamlockButton.Font             = Enum.Font.GothamBold
CamlockButton.AutoButtonColor  = false
CamlockButton.Active           = true
CamlockButton.Draggable        = true
CamlockButton.Parent           = ScreenGui

local CamlockCorner = Instance.new("UICorner")
CamlockCorner.CornerRadius = UDim.new(0, 10)
CamlockCorner.Parent       = CamlockButton

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
-- TARGET BOX
--========================================================--

local function CreatePlayerBox(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name          = player.Name .. "_Box"
    billboard.Size          = UDim2.fromOffset(65, 90)
    billboard.AlwaysOnTop   = true
    billboard.LightInfluence= 0
    billboard.Enabled       = false
    billboard.Parent        = ESPFolder

    local box = Instance.new("Frame")
    box.Name                 = "Box"
    box.Size                 = UDim2.fromScale(1, 1)
    box.BackgroundTransparency = 1
    box.BorderSizePixel      = 0
    box.Parent               = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Name      = "Outline"
    stroke.Color     = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Parent    = box

    return billboard
end

local function GetPlayerBox(player)
    local box = ESPFolder:FindFirstChild(player.Name .. "_Box")
    if not box then
        box = CreatePlayerBox(player)
    end
    return box
end

--========================================================--
-- TRACER
--========================================================--

local Tracer = Instance.new("Frame")
Tracer.Name               = "TargetTracer"
Tracer.AnchorPoint        = Vector2.new(0.5, 0.5)
Tracer.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
Tracer.BorderSizePixel    = 0
Tracer.Visible            = false
Tracer.ZIndex             = 20
Tracer.Parent             = ScreenGui

--========================================================--
-- CHARACTER CHECK
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

    local cameraPosition = camera.CFrame.Position
    local cameraLook     = camera.CFrame.LookVector

    local closestPlayer = nil
    local closestAngle  = HALF_FOV

    for _, player in ipairs(Players:GetPlayers()) do
        local character, humanoid, root, head = GetCharacterInfo(player)
        if character then
            local offset   = head.Position - cameraPosition
            local distance = offset.Magnitude

            if distance > 0 and distance <= MAX_DISTANCE then
                local direction = offset.Unit
                local dot = math.clamp(cameraLook:Dot(direction), -1, 1)
                local angle = math.deg(math.acos(dot))

                if angle <= closestAngle then
                    closestAngle  = angle
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

--========================================================--
-- PING
--========================================================--

local function GetPing()
    local success, ping = pcall(function()
        return LocalPlayer:GetNetworkPing()
    end)

    if success and typeof(ping) == "number" then
        return math.clamp(ping, 0, 0.5)
    end

    return 0
end

--========================================================--
-- PREDICTION
--========================================================--

local function GetPredictedPosition(player)
    local character, humanoid, root, head = GetCharacterInfo(player)
    if not character then return nil end

    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local distance   = (head.Position - camera.CFrame.Position).Magnitude
    local travelTime = distance / PROJECTILE_SPEED
    local ping       = GetPing()
    local predictionTime = travelTime + (ping * PING_MULTIPLIER)
    local velocity   = root.AssemblyLinearVelocity

    return head.Position + (velocity * predictionTime)
end

--========================================================--
-- TRACER UPDATE
--========================================================--

local function UpdateTracer(target)
    if not target then
        Tracer.Visible = false
        return
    end

    local character, humanoid, root, head = GetCharacterInfo(target)
    if not character then
        Tracer.Visible = false
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local position, visible = camera:WorldToViewportPoint(head.Position)
    if not visible then
        Tracer.Visible = false
        return
    end

    local viewport = camera.ViewportSize
    local start    = Vector2.new(viewport.X / 2, viewport.Y)
    local finish   = Vector2.new(position.X, position.Y)
    local difference = finish - start
    local length     = difference.Magnitude

    if length < 1 then
        Tracer.Visible = false
        return
    end

    Tracer.Visible  = true
    Tracer.Position = UDim2.fromOffset(
        (start.X + finish.X) / 2,
        (start.Y + finish.Y) / 2
    )
    Tracer.Size     = UDim2.fromOffset(length, 2)
    Tracer.Rotation = math.deg(math.atan2(difference.Y, difference.X))
end

--========================================================--
-- ESP UPDATE
--========================================================--

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local billboard = GetPlayerBox(player)
            local character, humanoid, root, head = GetCharacterInfo(player)

            if character and head then
                billboard.Adornee  = character
                billboard.Enabled  = true

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
    else
        CamlockButton.Text             = "CAMLOCK • OFF"
        CamlockButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        CurrentTarget                  = nil
    end
end

--========================================================--
-- BUTTON CONNECTIONS
--========================================================--

CamlockButton.Activated:Connect(function()
    SetCamlock(not CamlockEnabled)
end)

GuiToggle.Activated:Connect(function()
    Main.Visible = not Main.Visible
    GuiToggle.Text = Main.Visible and "HIDE GUI" or "SHOW GUI"
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

RunService.RenderStepped:Connect(function()
    CurrentTarget = GetClosestTarget()
    UpdateESP()
    UpdateTracer(CurrentTarget)

    if not CamlockEnabled then return end
    if not CurrentTarget then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local predictedPosition = GetPredictedPosition(CurrentTarget)
    if not predictedPosition then return end

    local cameraPosition = camera.CFrame.Position
    local desiredCFrame  = CFrame.lookAt(cameraPosition, predictedPosition)

    camera.CFrame = camera.CFrame:Lerp(desiredCFrame, AIM_SMOOTHNESS)
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
-- INITIAL STATE
--========================================================--

SetCamlock(false)

-- Notify
pcall(function()
    if setthreadidentity then setthreadidentity(2) end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "IVORY CAMLOCK",
        Text  = "Loaded • Press Q to toggle",
        Duration = 5,
    })
end)
