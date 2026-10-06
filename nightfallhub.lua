-- =============================================
-- NIGHTFALL HUB V4 — Da Hood
-- Remote Silent Aim (No Metamethod Hooks)
-- =============================================

print("🌙 Nightfall Hub V4 loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local MainEvent = ReplicatedStorage:WaitForChild("MainEvent", 10)

-- =============================================
-- CONFIG
-- =============================================
local F = {
    SilentAim = false,
    AimKey = Enum.KeyCode.E,
    FOV = 120,
    ShowFOV = true,
    WallCheck = true,
    MaxDist = 1000,
    TeamCheck = true,

    ESP = false,
    ESPHealth = true,
    ESPDistance = true,
    ESPBox = true,
    Tracers = false,
    TracerColor = "Red",
    Fullbright = false,

    WalkSpeed = 16, WalkSpeedOn = false,
    JumpPower = 50, JumpPowerOn = false,
    InfJump = false,
    Fly = false, FlySpeed = 50,
    Noclip = false,

    NoRecoil = false,
    InfAmmo = false,
    HitboxExpander = false,
    HitboxSize = 6,

    AntiAFK = false,
}

local Target = nil
local TargetPart = nil

-- =============================================
-- BYPASS (getconnections only)
-- =============================================
local function neutralizeGripChecker(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(tool:GetPropertyChangedSignal("Grip"))) do
                pcall(function() conn:Disable() end)
                local func = conn.Function
                if func and not iscclosure(func) then
                    pcall(function()
                        local constants = debug.getconstants(func)
                        for i, c in pairs(constants) do
                            if c == "CHECKER_4" then
                                debug.setconstant(func, i, "RandomRemote")
                            end
                        end
                    end)
                end
            end
            for _, conn in ipairs(getconnections(tool.Changed)) do
                pcall(function() conn:Disable() end)
            end
        end
    end)
end

local function attachToolGuard()
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then neutralizeGripChecker(tool) end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.02)
            neutralizeGripChecker(child)
        end
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(0.3)
    attachToolGuard()
end)
if player.Character then attachToolGuard() end

-- Anti-AFK
task.spawn(function()
    while true do
        task.wait(60)
        if F.AntiAFK then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton1(Vector2.new(0,0))
            end)
        end
    end
end)

-- Hidden GUI container
local parent
pcall(function()
    if gethui then parent = gethui() end
end)
parent = parent or player:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("NightfallHub")
if old then old:Destroy() end

-- =============================================
-- GUI
-- =============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "NightfallHub"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = parent

local COLORS = {
    BLACK = Color3.fromRGB(6,6,8), DARK = Color3.fromRGB(11,11,14),
    DARKER = Color3.fromRGB(17,15,20), CARD = Color3.fromRGB(22,19,24),
    WHITE = Color3.fromRGB(242,240,244), GRAY = Color3.fromRGB(140,138,148),
    RED = Color3.fromRGB(255,45,65), RED_DIM = Color3.fromRGB(150,20,40),
    RED_GLOW = Color3.fromRGB(255,90,110), GREEN = Color3.fromRGB(60,240,130),
    YELLOW = Color3.fromRGB(255,210,60), BLUE = Color3.fromRGB(80,150,255),
    CYAN = Color3.fromRGB(0,255,255), PURPLE = Color3.fromRGB(180,80,255),
}

local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o end
local function Stroke(o, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.fromRGB(45,40,50); s.Thickness = t or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end
local function Tween(o, p, t, style)
    TweenService:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p):Play()
end
local function Text(parent, txt, size, bold, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1; t.Text = txt
    t.TextColor3 = color or COLORS.WHITE; t.TextSize = size
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end
local function ClickAnim(btn)
    if not btn then return end
    btn.MouseButton1Down:Connect(function()
        pcall(function()
            Tween(btn, {BackgroundTransparency = 0.5}, 0.08, Enum.EasingStyle.Quad)
            Tween(btn, {BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad)
        end)
    end)
end

-- FOV Circle
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "NightfallFOV"; FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true; FOVGui.DisplayOrder = 2
FOVGui.Parent = parent

local FOVRing = Instance.new("Frame")
FOVRing.AnchorPoint = Vector2.new(0.5,0.5)
FOVRing.BackgroundTransparency = 1; FOVRing.BorderSizePixel = 0
FOVRing.ZIndex = 100; FOVRing.Parent = FOVGui
Corner(FOVRing, 999)
Stroke(FOVRing, COLORS.RED, 2, 0.15)

RunService.RenderStepped:Connect(function()
    if F.ShowFOV and F.SilentAim then
        local c = Camera.ViewportSize / 2
        FOVRing.Position = UDim2.new(0, c.X, 0, c.Y)
        FOVRing.Size = UDim2.fromOffset(F.FOV * 2, F.FOV * 2)
        FOVRing.Visible = true
    else
        FOVRing.Visible = false
    end
end)

-- =============================================
-- REMOTE SILENT AIM
-- =============================================
local function isVisible(part)
    if not F.WallCheck then return true end
    local ray = Ray.new(Camera.CFrame.Position, part.Position - Camera.CFrame.Position)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {player.Character}, false, true)
    if hit and hit:IsDescendantOf(player.Character) then return true end
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

local function inFOV(part)
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return false end
    local c = Camera.ViewportSize / 2
    return (Vector2.new(sp.X, sp.Y) - c).Magnitude <= F.FOV
end

local function getTarget()
    local best, bestPart, bestDist = nil, nil, math.huge
    local myChar = player.Character
    if not myChar then return nil, nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and hrp and head then
                local dist = (hrp.Position - myRoot.Position).Magnitude
                if dist <= F.MaxDist and inFOV(hrp) and isVisible(head) then
                    if F.TeamCheck and plr.Team == player.Team then continue end
                    if dist < bestDist then
                        bestDist = dist; best = plr; bestPart = head
                    end
                end
            end
        end
    end
    return best, bestPart
end

-- The remote shoot
local function SilentShoot(targetCharacter)
    if not MainEvent then return end
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetRoot or not targetHead then return end

    pcall(function()
        MainEvent:FireServer(
            "ShootGun",
            handle,
            handle.Position,
            targetRoot.Position,
            targetHead,
            Vector3.new(0, 0, -1),
            workspace:GetServerTimeNow()
        )
    end)
end

-- Aim loop
RunService.RenderStepped:Connect(function()
    if not F.SilentAim or not UserInputService:IsKeyDown(F.AimKey) then
        Target, TargetPart = nil, nil
        return
    end
    Target, TargetPart = getTarget()
end)

-- Fire on click
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if F.SilentAim and Target and Target.Character then
            SilentShoot(Target.Character)
        end
    end
end)

-- =============================================
-- ESP
-- =============================================
local espObjects = {}

local function destroyESP(plr)
    local e = espObjects[plr]
    if e then
        if e.billboard then pcall(function() e.billboard:Destroy() end) end
        if e.highlight then pcall(function() e.highlight:Destroy() end) end
        if e.connection then pcall(function() e.connection:Disconnect() end) end
        espObjects[plr] = nil
    end
end

local function createESP(plr)
    if plr == player or espObjects[plr] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NightfallESP"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
    billboard.MaxDistance = 1000
    billboard.Parent = Gui

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = billboard

    local nameLbl = Text(holder, "", 13, true, COLORS.WHITE)
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextStrokeColor3 = Color3.new(0,0,0)
    nameLbl.TextStrokeTransparency = 0.2

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, -40, 0, 5)
    healthBg.Position = UDim2.new(0, 20, 0, 20)
    healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = holder
    Corner(healthBg, 3)

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = COLORS.GREEN
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    Corner(healthFill, 3)

    local distLbl = Text(holder, "", 11, false, COLORS.GRAY)
    distLbl.Size = UDim2.new(1, 0, 0, 14)
    distLbl.Position = UDim2.new(0, 0, 0, 30)
    distLbl.TextXAlignment = Enum.TextXAlignment.Center
    distLbl.TextStrokeColor3 = Color3.new(0,0,0)
    distLbl.TextStrokeTransparency = 0.4

    local highlight = Instance.new("Highlight")
    highlight.Name = "NightfallHL"
    highlight.FillTransparency = 1
    highlight.OutlineColor = COLORS.RED
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Gui

    local entry = {billboard = billboard, nameLbl = nameLbl, healthBg = healthBg,
        healthFill = healthFill, distLbl = distLbl, highlight = highlight, plr = plr}
    espObjects[plr] = entry

    local function update()
        local char = plr.Character
        if not char then billboard.Adornee = nil; highlight.Adornee = nil; return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then billboard.Adornee = hrp; highlight.Adornee = char end
        if hum then
            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            healthFill.Size = UDim2.new(hp, 0, 1, 0)
            healthFill.BackgroundColor3 = hp > 0.6 and COLORS.GREEN or (hp > 0.3 and COLORS.YELLOW or COLORS.RED)
            healthBg.Visible = F.ESPHealth
        end
        nameLbl.Text = plr.Name
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myRoot then
            distLbl.Text = string.format("%d studs", math.floor((hrp.Position - myRoot.Position).Magnitude))
            distLbl.Visible = F.ESPDistance
        end
        highlight.Enabled = F.ESPBox
    end
    update()
    entry.connection = RunService.Heartbeat:Connect(update)
end

local function refreshAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then createESP(plr) end
    end
end

Players.PlayerAdded:Connect(function(p) if F.ESP then createESP(p) end end)
Players.PlayerRemoving:Connect(destroyESP)

RunService.Heartbeat:Connect(function()
    for plr, e in pairs(espObjects) do
        if e.billboard then e.billboard.Enabled = F.ESP and plr.Character ~= nil end
        if e.highlight then e.highlight.Enabled = F.ESP and F.ESPBox and plr.Character ~= nil end
    end
end)

-- =============================================
-- TRACERS
-- =============================================
local TRACER_MAP = {
    Red = Color3.fromRGB(255,45,65), White = Color3.fromRGB(245,245,245),
    Green = Color3.fromRGB(60,240,130), Blue = Color3.fromRGB(80,150,255),
    Cyan = Color3.fromRGB(0,255,255), Purple = Color3.fromRGB(180,80,255),
}

local tracerFolder = Instance.new("Folder")
tracerFolder.Name = "NightfallTracers"; tracerFolder.Parent = Workspace

local tracers = {}

local function destroyTracer(plr)
    local t = tracers[plr]
    if not t then return end
    pcall(function() t.att0:Destroy() end)
    pcall(function() t.att1:Destroy() end)
    pcall(function() t.beam:Destroy() end)
    tracers[plr] = nil
end

local function addTracer(plr)
    if tracers[plr] or plr == player then return end
    local att0 = Instance.new("Attachment")
    local att1 = Instance.new("Attachment")
    att0.Parent = tracerFolder; att1.Parent = tracerFolder
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0; beam.Attachment1 = att1
    beam.Width0 = 0.08; beam.Width1 = 0.08
    beam.FaceCamera = true; beam.LightEmission = 1; beam.LightInfluence = 0
    beam.Enabled = false
    beam.Color = ColorSequence.new(TRACER_MAP[F.TracerColor] or TRACER_MAP.Red)
    beam.Transparency = NumberSequence.new(0.15)
    beam.Parent = tracerFolder
    tracers[plr] = {att0 = att0, att1 = att1, beam = beam}
end

for _, plr in ipairs(Players:GetPlayers()) do addTracer(plr) end
Players.PlayerAdded:Connect(addTracer)
Players.PlayerRemoving:Connect(destroyTracer)

RunService.RenderStepped:Connect(function()
    if not F.Tracers then
        for _, t in pairs(tracers) do t.beam.Enabled = false end
        return
    end
    local originPart = player.Character and (player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart"))
    if not originPart then
        for _, t in pairs(tracers) do t.beam.Enabled = false end
        return
    end
    for plr, t in pairs(tracers) do
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            t.att0.WorldPosition = originPart.Position
            t.att1.WorldPosition = hrp.Position + Vector3.new(0,1,0)
            t.beam.Color = ColorSequence.new(TRACER_MAP[F.TracerColor] or TRACER_MAP.Red)
            t.beam.Enabled = true
        else
            t.beam.Enabled = false
        end
    end
end)

-- =============================================
-- MOVEMENT / COMBAT
-- =============================================
local flyBV

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if F.WalkSpeedOn then hum.WalkSpeed = F.WalkSpeed end
    if F.JumpPowerOn then hum.UseJumpPower = true; hum.JumpPower = F.JumpPower end

    if F.Fly then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not flyBV or not flyBV.Parent then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBV.Velocity = Vector3.zero
                flyBV.Parent = hrp
            end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            flyBV.Velocity = dir * F.FlySpeed
        end
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
    end

    if F.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if F.NoRecoil or F.InfAmmo then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in ipairs(tool:GetDescendants()) do
                    if F.NoRecoil and v.Name:lower():find("recoil") and v:IsA("ValueBase") then
                        pcall(function() v.Value = 0 end)
                    end
                    if F.InfAmmo and v.Name == "Ammo" and v:IsA("IntValue") then
                        pcall(function() v.Value = 9999 end)
                    end
                end
            end
        end
    end

    if F.HitboxExpander then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local s = Vector3.new(F.HitboxSize, F.HitboxSize, F.HitboxSize)
                    if hrp.Size ~= s then hrp.Size = s; hrp.Transparency = 0.7 end
                end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if F.InfJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

local defaultAmbient = Lighting.Ambient
local defaultBrightness = Lighting.Brightness
local defaultClockTime = Lighting.ClockTime

local function setFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = defaultAmbient
        Lighting.Brightness = defaultBrightness
        Lighting.ClockTime = defaultClockTime
    end
end

-- =============================================
-- UI BUILD (compact — same UI as V3)
-- =============================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(46,46)
ToggleBtn.Position = UDim2.new(0, 15, 0.5, -23)
ToggleBtn.BackgroundColor3 = COLORS.BLACK
ToggleBtn.Text = "N"; ToggleBtn.TextColor3 = COLORS.WHITE; ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = Gui; Corner(ToggleBtn, 12); Stroke(ToggleBtn, COLORS.RED, 2)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 560, 0, 400)
Main.Position = UDim2.new(0.5, -280, 0.5, -200)
Main.BackgroundColor3 = COLORS.BLACK; Main.BorderSizePixel = 0
Main.Visible = false; Main.ClipsDescendants = true
Main.Parent = Gui; Corner(Main, 16); Stroke(Main, COLORS.RED_DIM, 1.5)

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 46)
Top.BackgroundColor3 = COLORS.DARK
Top.BorderSizePixel = 0; Top.Parent = Main; Corner(Top, 16)

local Title = Text(Top, "NIGHTFALL V4", 18, true)
Title.Position = UDim2.new(0, 30, 0, 5); Title.Size = UDim2.new(0, 200, 0, 22)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28); Close.Position = UDim2.new(1, -36, 0.5, -14)
Close.BackgroundColor3 = COLORS.DARKER; Close.Text = "×"; Close.TextColor3 = COLORS.WHITE
Close.TextSize = 18; Close.Font = Enum.Font.GothamBold; Close.AutoButtonColor = false
Close.Parent = Top; Corner(Close, 8)

local ToggleDrag = {active=false, moved=false, startPos=nil, startMouse=nil}
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ToggleDrag.active = true; ToggleDrag.moved = false
        ToggleDrag.startMouse = input.Position; ToggleDrag.startPos = ToggleBtn.Position
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ToggleDrag.active = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not ToggleDrag.active then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - ToggleDrag.startMouse
    if d.Magnitude > 6 then ToggleDrag.moved = true end
    ToggleBtn.Position = UDim2.new(ToggleDrag.startPos.X.Scale, ToggleDrag.startPos.X.Offset + d.X,
        ToggleDrag.startPos.Y.Scale, ToggleDrag.startPos.Y.Offset + d.Y)
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if ToggleDrag.moved then return end
    Main.Visible = not Main.Visible
end)
Close.MouseButton1Click:Connect(function() Gui:Destroy() end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 115, 1, -58)
Sidebar.Position = UDim2.new(0, 8, 0, 54)
Sidebar.BackgroundColor3 = COLORS.DARK
Sidebar.BackgroundTransparency = 0.15; Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main; Corner(Sidebar, 12); Stroke(Sidebar, Color3.fromRGB(38,34,42), 1)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 3); TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = Sidebar
local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 6); Pad.PaddingLeft = UDim.new(0, 4); Pad.PaddingRight = UDim.new(0, 4)
Pad.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -131, 1, -58)
Content.Position = UDim2.new(0, 123, 0, 54)
Content.BackgroundColor3 = COLORS.DARK
Content.BackgroundTransparency = 0.15; Content.BorderSizePixel = 0
Content.Parent = Main; Corner(Content, 12); Stroke(Content, Color3.fromRGB(38,34,42), 1)

local Pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -10, 1, -10); page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 2; page.ScrollBarImageColor3 = COLORS.RED
    page.Visible = false; page.CanvasSize = UDim2.new()
    page.Parent = Content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 4); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = page
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10)
    end)
    Pages[name] = page; return page
end

local function Section(parent, txt)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 20); wrap.BackgroundTransparency = 1; wrap.Parent = parent
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = COLORS.RED
    l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 12); l.Parent = wrap
end

local function Button(parent, txt, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28); b.BackgroundColor3 = COLORS.CARD
    b.BorderSizePixel = 0; b.Text = txt; b.TextColor3 = COLORS.WHITE
    b.TextSize = 10; b.Font = Enum.Font.GothamMedium; b.AutoButtonColor = false
    b.Parent = parent; Corner(b, 8); Stroke(b, Color3.fromRGB(38,34,42), 1)
    b.MouseButton1Click:Connect(cb)
end

local function CycleButton(parent, txt, options, default, cb)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i break end end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28); b.BackgroundColor3 = COLORS.CARD
    b.BorderSizePixel = 0; b.Text = txt .. ": " .. options[idx]
    b.TextColor3 = COLORS.WHITE; b.TextSize = 10; b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false; b.Parent = parent; Corner(b, 8); Stroke(b, Color3.fromRGB(38,34,42), 1)
    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = txt .. ": " .. options[idx]
        if cb then cb(options[idx]) end
    end)
end

local function Toggle(parent, txt, default, cb)
    local state = default or false
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 28); h.BackgroundColor3 = COLORS.CARD
    h.BorderSizePixel = 0; h.Parent = parent; Corner(h, 8); Stroke(h, Color3.fromRGB(38,34,42), 1)
    local lbl = Text(h, txt .. ": OFF", 10, false)
    lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(1, -50, 1, 0)
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 28, 0, 15); sw.Position = UDim2.new(1, -36, 0.5, -7.5)
    sw.BackgroundColor3 = Color3.fromRGB(38,34,42); sw.Text = ""; sw.BorderSizePixel = 0
    sw.Parent = h; Corner(sw, 20)
    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 11, 0, 11); ball.Position = UDim2.new(0, 2, 0.5, -5.5)
    ball.BackgroundColor3 = COLORS.GRAY; ball.BorderSizePixel = 0; ball.Parent = sw
    Corner(ball, 20)
    local function Update()
        if state then
            Tween(sw, {BackgroundColor3 = COLORS.RED})
            Tween(ball, {Position = UDim2.new(1, -13, 0.5, -5.5), BackgroundColor3 = COLORS.WHITE})
            lbl.Text = txt .. ": ON"
        else
            Tween(sw, {BackgroundColor3 = Color3.fromRGB(38,34,42)})
            Tween(ball, {Position = UDim2.new(0, 2, 0.5, -5.5), BackgroundColor3 = COLORS.GRAY})
            lbl.Text = txt .. ": OFF"
        end
        if cb then cb(state) end
    end
    sw.MouseButton1Click:Connect(function() state = not state Update() end)
    Update()
end

local ActiveSlider = nil
UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        ActiveSlider(input.Position)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ActiveSlider = nil
    end
end)

local function Slider(parent, txt, default, minVal, maxVal, cb, suffix)
    local Value = default or 50
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 40); h.BackgroundColor3 = COLORS.CARD
    h.BorderSizePixel = 0; h.Parent = parent; Corner(h, 8); Stroke(h, Color3.fromRGB(38,34,42), 1)
    local lbl = Text(h, txt .. ": " .. tostring(Value) .. (suffix or ""), 10, false)
    lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(1, -50, 1, 0)
    local barHolder = Instance.new("Frame")
    barHolder.Size = UDim2.new(1, -20, 0, 20); barHolder.Position = UDim2.new(0, 10, 0, 22)
    barHolder.BackgroundTransparency = 1; barHolder.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 5); bg.Position = UDim2.new(0, 0, 0.5, -2.5)
    bg.BackgroundColor3 = Color3.fromRGB(45,40,50); bg.BorderSizePixel = 0
    bg.Parent = barHolder; Corner(bg, 4)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Value - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.RED; fill.BorderSizePixel = 0; fill.Parent = bg; Corner(fill, 4)
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((Value - minVal) / (maxVal - minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = COLORS.WHITE; knob.Text = ""; knob.BorderSizePixel = 0
    knob.Parent = bg; Corner(knob, 20); Stroke(knob, COLORS.RED, 2)
    local function UpdateSlider(v)
        local cv = math.clamp(v, minVal, maxVal)
        Value = cv
        local r = (cv - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -8, 0.5, -8)
        lbl.Text = txt .. ": " .. tostring(math.floor(cv * 100) / 100) .. (suffix or "")
        if cb then cb(cv) end
    end
    local function fromPos(pos)
        local ap = bg.AbsolutePosition; local sz = bg.AbsoluteSize.X
        local rx = math.clamp(pos.X - ap.X, 0, sz)
        UpdateSlider(minVal + (rx / sz) * (maxVal - minVal))
    end
    local fullBar = Instance.new("TextButton")
    fullBar.Size = UDim2.new(1, 0, 0, 20); fullBar.Position = UDim2.new(0, 0, 0.5, -10)
    fullBar.BackgroundTransparency = 1; fullBar.Text = ""; fullBar.Parent = barHolder
    fullBar.MouseButton1Down:Connect(function()
        ActiveSlider = fromPos
        fromPos(UserInputService:GetMouseLocation())
    end)
    knob.MouseButton1Down:Connect(function() ActiveSlider = fromPos end)
end

-- =============================================
-- PAGES
-- =============================================
local MainPage = CreatePage("Main")
local AimPage = CreatePage("Aim")
local VisualsPage = CreatePage("Visuals")
local MovementPage = CreatePage("Movement")
local CombatPage = CreatePage("Combat")
local MiscPage = CreatePage("Misc")

Section(MainPage, "NIGHTFALL V4")
local mtL = Text(MainPage, "NIGHTFALL HUB V4", 17, true)
mtL.Size = UDim2.new(1, 0, 0, 24); mtL.TextXAlignment = Enum.TextXAlignment.Center
local msub = Text(MainPage, "Remote Silent Aim • 6 tabs", 10, false, COLORS.GRAY)
msub.Size = UDim2.new(1, 0, 0, 16); msub.Position = UDim2.new(0, 0, 0, 26)
msub.TextXAlignment = Enum.TextXAlignment.Center

Section(AimPage, "REMOTE SILENT AIM")
Toggle(AimPage, "Enable Silent Aim", F.SilentAim, function(s)
    F.SilentAim = s
    if not s then Target, TargetPart = nil, nil end
end)
Slider(AimPage, "FOV Radius", F.FOV, 20, 500, function(v) F.FOV = v end, "px")
Toggle(AimPage, "Show FOV Circle", F.ShowFOV, function(s) F.ShowFOV = s end)
Toggle(AimPage, "Wall Check", F.WallCheck, function(s) F.WallCheck = s end)
Toggle(AimPage, "Team Check", F.TeamCheck, function(s) F.TeamCheck = s end)
Slider(AimPage, "Max Distance", F.MaxDist, 50, 3000, function(v) F.MaxDist = v end, " studs")

Section(VisualsPage, "PLAYER ESP")
Toggle(VisualsPage, "Enable ESP", F.ESP, function(s)
    F.ESP = s
    if s then refreshAllESP() else for plr in pairs(espObjects) do destroyESP(plr) end end
end)
Toggle(VisualsPage, "Show Box", F.ESPBox, function(s) F.ESPBox = s end)
Toggle(VisualsPage, "Show Health", F.ESPHealth, function(s) F.ESPHealth = s end)
Toggle(VisualsPage, "Show Distance", F.ESPDistance, function(s) F.ESPDistance = s end)

Section(VisualsPage, "TRACERS")
Toggle(VisualsPage, "Enable Tracers", F.Tracers, function(s) F.Tracers = s end)
CycleButton(VisualsPage, "Tracer Color", {"Red","White","Green","Blue","Cyan","Purple"}, F.TracerColor, function(v) F.TracerColor = v end)

Section(VisualsPage, "ENVIRONMENT")
Toggle(VisualsPage, "Fullbright", F.Fullbright, function(s) F.Fullbright = s; setFullbright(s) end)

Section(MovementPage, "SPEED")
Toggle(MovementPage, "Enable WalkSpeed", false, function(s) F.WalkSpeedOn = s end)
Slider(MovementPage, "WalkSpeed", 16, 16, 500, function(v) F.WalkSpeed = v end, " spd")

Section(MovementPage, "JUMP")
Toggle(MovementPage, "Enable JumpPower", false, function(s) F.JumpPowerOn = s end)
Slider(MovementPage, "JumpPower", 50, 50, 500, function(v) F.JumpPower = v end, " jmp")
Toggle(MovementPage, "Infinite Jump", false, function(s) F.InfJump = s end)

Section(MovementPage, "FLIGHT")
Toggle(MovementPage, "Enable Fly", false, function(s) F.Fly = s end)
Slider(MovementPage, "Fly Speed", 50, 10, 300, function(v) F.FlySpeed = v end, " spd")

Section(MovementPage, "NOCLIP")
Toggle(MovementPage, "Enable Noclip", false, function(s) F.Noclip = s end)

Section(CombatPage, "WEAPON MODS")
Toggle(CombatPage, "No Recoil", false, function(s) F.NoRecoil = s end)
Toggle(CombatPage, "Infinite Ammo", false, function(s) F.InfAmmo = s end)

Section(CombatPage, "HITBOX")
Toggle(CombatPage, "Hitbox Expander", false, function(s) F.HitboxExpander = s end)
Slider(CombatPage, "Hitbox Size", 6, 2, 20, function(v) F.HitboxSize = v end, " studs")

Section(MiscPage, "UTILITY")
Toggle(MiscPage, "Anti-AFK", false, function(s) F.AntiAFK = s end)

-- =============================================
-- TABS
-- =============================================
local Tabs = {
    {name="MAIN", icon="🏠", page=MainPage},
    {name="AIM", icon="🎯", page=AimPage},
    {name="VISUALS", icon="👁", page=VisualsPage},
    {name="MOVE", icon="🏃", page=MovementPage},
    {name="COMBAT", icon="⚔", page=CombatPage},
    {name="MISC", icon="⚙", page=MiscPage},
}

local function SelectTab(btn, page)
    for _, d in ipairs(Tabs) do
        if d.button then
            Tween(d.button, {BackgroundColor3 = COLORS.DARKER}, 0.2)
            d.button.TextColor3 = COLORS.GRAY
        end
        d.page.Visible = false
    end
    Tween(btn, {BackgroundColor3 = COLORS.RED}, 0.2)
    btn.TextColor3 = COLORS.WHITE
    page.Visible = true
end

for _, d in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28); btn.BackgroundColor3 = COLORS.DARKER
    btn.BorderSizePixel = 0; btn.Text = "  " .. d.icon .. "  " .. d.name
    btn.TextColor3 = COLORS.GRAY; btn.TextSize = 9; btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
    btn.Parent = Sidebar; Corner(btn, 8); Stroke(btn, Color3.fromRGB(38,34,42), 1)
    d.button = btn
    btn.MouseButton1Click:Connect(function() SelectTab(btn, d.page) end)
end
SelectTab(Tabs[1].button, Tabs[1].page)

-- Dragging
local Drag, DStart, SPos = false, nil, nil
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Drag = true; DStart = input.Position; SPos = Main.Position
    end
end)
Top.InputEnded:Connect(function(input) Drag = false end)
UserInputService.InputChanged:Connect(function(input)
    if Drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - DStart
        Main.Position = UDim2.new(SPos.X.Scale, SPos.X.Offset + d.X, SPos.Y.Scale, SPos.Y.Offset + d.Y)
    end
end)

print("========================================")
print("     NIGHTFALL HUB V4 LOADED")
print("========================================")
