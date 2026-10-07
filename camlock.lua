--// IVORY'S CAMLOCK
--// Delta Executor Version - Mobile Friendly
--// With toggleable floating button

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local PREDICTION = 0.12
local MAX_DISTANCE = 300
local FOV_ANGLE = 180

--==================================================
-- STATE
--==================================================

local CamlockEnabled = false
local TracerEnabled = false
local Locked = false
local Target = nil
local GuiOpen = false

--==================================================
-- CLEANUP OLD GUI
--==================================================

pcall(function()
    local oldGui = CoreGui:FindFirstChild("IvorysCamlock")
    if oldGui then oldGui:Destroy() end
    local oldBtn = CoreGui:FindFirstChild("IvorysCamlockToggle")
    if oldBtn then oldBtn:Destroy() end
end)

--==================================================
-- MAIN GUI (ScreenGui)
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "IvorysCamlock"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999
Gui.Parent = CoreGui

--==================================================
-- FLOATING TOGGLE BUTTON
--==================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "IvorysCamlockToggle"
ToggleButton.Size = UDim2.fromOffset(50, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "IV"
ToggleButton.TextColor3 = Color3.fromRGB(235, 235, 240)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.AutoButtonColor = true
ToggleButton.Active = true
ToggleButton.ZIndex = 100
ToggleButton.Parent = Gui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(150, 150, 160)
ToggleStroke.Transparency = 0.3
ToggleStroke.Parent = ToggleButton

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(175, 150)
Main.Position = UDim2.new(0.5, -87, 0.5, -75)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false -- start hidden
Main.ZIndex = 50
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.35
MainStroke.Color = Color3.fromRGB(150, 150, 160)
MainStroke.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "Ivory's Camlock"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.ZIndex = 51
Title.Parent = Main

--==================================================
-- BUTTON HELPER
--==================================================

local function createButton(name, text, y)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, -20, 0, 32)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundColor3 = Color3.fromRGB(42, 42, 49)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(235, 235, 240)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Button.AutoButtonColor = true
    Button.ZIndex = 51
    Button.Parent = Main

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button

    return Button
end

local CamlockButton = createButton("CamlockButton", "CAMLOCK  •  OFF", 38)
local TracerButton = createButton("TracerButton", "TRACER  •  OFF", 76)
local LockButton = createButton("LockButton", "LOCK TARGET", 114)

--==================================================
-- TRACER
--==================================================

local Tracer = Instance.new("Frame")
Tracer.Name = "TargetTracer"
Tracer.AnchorPoint = Vector2.new(0, 0.5)
Tracer.BorderSizePixel = 0
Tracer.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
Tracer.BackgroundTransparency = 0.05
Tracer.Visible = false
Tracer.ZIndex = 20
Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius = UDim.new(1, 0)
TracerCorner.Parent = Tracer

local Marker = Instance.new("Frame")
Marker.Name = "TargetMarker"
Marker.AnchorPoint = Vector2.new(0.5, 0.5)
Marker.Size = UDim2.fromOffset(12, 12)
Marker.BackgroundTransparency = 1
Marker.BorderSizePixel = 0
Marker.Visible = false
Marker.ZIndex = 21
Marker.Parent = Gui

local MarkerStroke = Instance.new("UIStroke")
MarkerStroke.Thickness = 2
MarkerStroke.Color = Color3.fromRGB(235, 235, 240)
MarkerStroke.Parent = Marker

local MarkerCorner = Instance.new("UICorner")
MarkerCorner.CornerRadius = UDim.new(1, 0)
MarkerCorner.Parent = Marker

--==================================================
-- TARGET FUNCTIONS
--==================================================

local function IsValidTarget(root)
    if not root or not root.Parent then return false end
    local character = root.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function GetPredictedPosition(root)
    return root.Position + (root.AssemblyLinearVelocity * PREDICTION)
end

local function GetClosestTarget()
    local closestRoot = nil
    local closestScreenDistance = math.huge

    local cameraPosition = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    local minimumDot = math.cos(math.rad(FOV_ANGLE / 2))

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character then
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and root and humanoid.Health > 0 then
                local offset = root.Position - cameraPosition
                local distance = offset.Magnitude

                if distance <= MAX_DISTANCE and distance > 0 then
                    local direction = offset.Unit
                    local dot = cameraLook:Dot(direction)

                    if dot >= minimumDot then
                        local screenPosition, visible = Camera:WorldToViewportPoint(root.Position)

                        if visible and screenPosition.Z > 0 then
                            local screenCenter = Vector2.new(
                                Camera.ViewportSize.X / 2,
                                Camera.ViewportSize.Y / 2
                            )

                            local screenDistance = (Vector2.new(
                                screenPosition.X,
                                screenPosition.Y
                            ) - screenCenter).Magnitude

                            if screenDistance < closestScreenDistance then
                                closestScreenDistance = screenDistance
                                closestRoot = root
                            end
                        end
                    end
                end
            end
        end
    end

    return closestRoot
end

--==================================================
-- TRACER UPDATE
--==================================================

local function UpdateTracer(targetRoot)
    if not TracerEnabled or not CamlockEnabled or not targetRoot then
        Tracer.Visible = false
        Marker.Visible = false
        return
    end

    if not IsValidTarget(targetRoot) then
        Tracer.Visible = false
        Marker.Visible = false
        return
    end

    local predictedPosition = GetPredictedPosition(targetRoot)
    local screenPosition, visible = Camera:WorldToViewportPoint(predictedPosition)

    if not visible or screenPosition.Z <= 0 then
        Tracer.Visible = false
        Marker.Visible = false
        return
    end

    local start = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    local finish = Vector2.new(screenPosition.X, screenPosition.Y)
    local difference = finish - start
    local length = difference.Magnitude

    if length < 1 then
        Tracer.Visible = false
        Marker.Visible = false
        return
    end

    Tracer.Position = UDim2.fromOffset(start.X, start.Y)
    Tracer.Size = UDim2.fromOffset(length, 2)
    Tracer.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    Tracer.Visible = true

    Marker.Position = UDim2.fromOffset(finish.X, finish.Y)
    Marker.Visible = true
end

--==================================================
-- TOGGLE OPEN/CLOSE GUI
--==================================================

ToggleButton.Activated:Connect(function()
    GuiOpen = not GuiOpen
    Main.Visible = GuiOpen
    ToggleButton.Text = GuiOpen and "×" or "IV"
end)

--==================================================
-- CAMLOCK TOGGLE
--==================================================

CamlockButton.Activated:Connect(function()
    CamlockEnabled = not CamlockEnabled

    if CamlockEnabled then
        CamlockButton.Text = "CAMLOCK  •  ON"
        CamlockButton.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
        TracerButton.Visible = true
        LockButton.Visible = true
    else
        CamlockButton.Text = "CAMLOCK  •  OFF"
        CamlockButton.BackgroundColor3 = Color3.fromRGB(42, 42, 49)
        Locked = false
        Target = nil
        Tracer.Visible = false
        Marker.Visible = false
        TracerButton.Text = "TRACER  •  OFF"
        TracerEnabled = false
        LockButton.Text = "LOCK TARGET"
    end
end)

--==================================================
-- TRACER TOGGLE
--==================================================

TracerButton.Activated:Connect(function()
    if not CamlockEnabled then return end
    TracerEnabled = not TracerEnabled

    if TracerEnabled then
        TracerButton.Text = "TRACER  •  ON"
        TracerButton.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
    else
        TracerButton.Text = "TRACER  •  OFF"
        TracerButton.BackgroundColor3 = Color3.fromRGB(42, 42, 49)
        Tracer.Visible = false
        Marker.Visible = false
    end
end)

--==================================================
-- LOCK TARGET
--==================================================

LockButton.Activated:Connect(function()
    if not CamlockEnabled then return end

    if Locked then
        Locked = false
        Target = nil
        LockButton.Text = "LOCK TARGET"
    else
        local selectedTarget = GetClosestTarget()
        if selectedTarget then
            Target = selectedTarget
            Locked = true
            LockButton.Text = "UNLOCK TARGET"
        end
    end
end)

--==================================================
-- UNIVERSAL DRAG HELPER (mouse + touch)
--==================================================

local function makeDraggable(frame, dragTarget)
    dragTarget = dragTarget or frame
    local dragging = false
    local dragStart, startPos
    local activeInput = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = input
            dragStart = input.Position
            startPos = dragTarget.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeInput = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and activeInput then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                dragTarget.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- Drag main window by title
makeDraggable(Title, Main)
-- Drag toggle button
makeDraggable(ToggleButton, ToggleButton)

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
    "IvorysCamlock",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if not CamlockEnabled then return end

        if Locked then
            if not IsValidTarget(Target) then
                Locked = false
                Target = nil
                LockButton.Text = "LOCK TARGET"
            end
        else
            Target = GetClosestTarget()
        end

        UpdateTracer(Target)

        if Locked and IsValidTarget(Target) then
            local predictedPosition = GetPredictedPosition(Target)
            Camera.CFrame = CFrame.lookAt(
                Camera.CFrame.Position,
                predictedPosition
            )
        end
    end
)

--==================================================
-- NOTIFICATION
--==================================================

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Ivory's Camlock",
        Text = "Tap the 'IV' button to open the menu.",
        Duration = 4
    })
end)

print("[Ivory's Camlock] Loaded ✓ Tap the IV button.")
