-- =============================================
-- NIGHTFALL HUB V2 — Da Hood
-- Silent Aim + ESP + Tracers + Movement + More
-- Fixed: No __namecall hook (avoids detector)
-- =============================================

print("🌙 Nightfall Hub V2 loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- =============================================
-- CONFIG STATE
-- =============================================
local F = {
    -- Aim
    SilentAim = false,
    AimKey = Enum.KeyCode.E,
    AimKeyName = "E",
    FOV = 120,
    ShowFOV = true,
    WallCheck = true,
    MaxDist = 1000,
    TeamCheck = true,

    -- Visuals
    ESP = false,
    ESPHealth = true,
    ESPDistance = true,
    ESPBox = false,
    Tracers = false,
    TracerColor = "Red",
    Fullbright = false,

    -- Movement
    WalkSpeed = 16,
    WalkSpeedOn = false,
    JumpPower = 50,
    JumpPowerOn = false,
    InfJump = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,

    -- Combat
    NoRecoil = false,
    InfAmmo = false,
    HitboxExpander = false,
    HitboxSize = 6,

    -- Utility
    AutoCollect = false,
    AntiAFK = false,
}

-- =============================================
-- SAFE BYPASS (getconnections ONLY — no __namecall)
-- =============================================
local function neutralizeGripChecker(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        if getconnections then
            local gripConns = getconnections(tool:GetPropertyChangedSignal("Grip"))
            for _, conn in ipairs(gripConns) do
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
            local changedConns = getconnections(tool.Changed)
            for _, conn in ipairs(changedConns) do
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

-- Anti-AFK (keeps client alive)
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

-- Hidden GUI
local parent
pcall(function()
    if gethui then parent = gethui() end
end)
parent = parent or player:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("NightfallHub")
if old then old:Destroy() end

-- =============================================
-- GUI SETUP
-- =============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "NightfallHub"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = parent

local COLORS = {
    BLACK     = Color3.fromRGB(6, 6, 8),
    DARK      = Color3.fromRGB(11, 11, 14),
    DARKER    = Color3.fromRGB(17, 15, 20),
    CARD      = Color3.fromRGB(22, 19, 24),
    WHITE     = Color3.fromRGB(242, 240, 244),
    GRAY      = Color3.fromRGB(140, 138, 148),
    RED       = Color3.fromRGB(255, 45, 65),
    RED_DIM   = Color3.fromRGB(150, 20, 40),
    RED_GLOW  = Color3.fromRGB(255, 90, 110),
    GREEN     = Color3.fromRGB(60, 240, 130),
    YELLOW    = Color3.fromRGB(255, 210, 60),
    BLUE      = Color3.fromRGB(80, 150, 255),
}

-- =============================================
-- HELPERS
-- =============================================
local function Corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
end

local function Stroke(o, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.fromRGB(45, 40, 50)
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function Tween(o, p, t, style)
    TweenService:Create(o, TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ), p):Play()
end

local function Text(parent, txt, size, bold, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = txt
    t.TextColor3 = color or COLORS.WHITE
    t.TextSize = size
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

-- =============================================
-- FOV CIRCLE
-- =============================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "NightfallFOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 2
FOVGui.Parent = parent

local FOVRing = Instance.new("Frame")
FOVRing.AnchorPoint = Vector2.new(0.5, 0.5)
FOVRing.BackgroundTransparency = 1
FOVRing.BorderSizePixel = 0
FOVRing.ZIndex = 100
FOVRing.Parent = FOVGui
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
-- TARGET FINDER + SILENT AIM
-- =============================================
local Target = nil
local TargetPart = nil

local function isVisible(part)
    if not F.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray,
        {player.Character, Target and Target.Character or nil}, false, true)
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
                    if dist < bestDist then
                        bestDist = dist
                        best = plr
                        bestPart = head
                    end
                end
            end
        end
    end
    return best, bestPart
end

RunService.RenderStepped:Connect(function()
    if not F.SilentAim or not UserInputService:IsKeyDown(F.AimKey) then
        Target, TargetPart = nil, nil
        return
    end
    Target, TargetPart = getTarget()
end)

-- Silent Aim via mouse metatable (safe — only __index for mouse)
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if checkcaller() then return oldIndex(self, key) end
        if F.SilentAim and TargetPart and self == mouse then
            if key == "Hit" then return CFrame.new(TargetPart.Position) end
            if key == "Target" then return TargetPart end
            if key == "X" then return Camera:WorldToViewportPoint(TargetPart.Position).X end
            if key == "Y" then return Camera:WorldToViewportPoint(TargetPart.Position).Y end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end)

-- =============================================
-- ESP
-- =============================================
local espObjects = {}

local function destroyESP(plr)
    local e = espObjects[plr]
    if e then
        if e.billboard then pcall(function() e.billboard:Destroy() end) end
        if e.box then pcall(function() e.box:Destroy() end) end
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
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = F.MaxDist
    billboard.Parent = Gui

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = billboard

    local nameLbl = Text(holder, "", 13, true, COLORS.WHITE)
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
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
    distLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLbl.TextStrokeTransparency = 0.4

    local entry = {
        billboard = billboard,
        nameLbl = nameLbl,
        healthFill = healthFill,
        distLbl = distLbl,
        plr = plr,
    }
    espObjects[plr] = entry

    local function update()
        local char = plr.Character
        if not char then
            billboard.Adornee = nil
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then billboard.Adornee = hrp end
        if hum then
            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            healthFill.Size = UDim2.new(hp, 0, 1, 0)
            healthFill.BackgroundColor3 = hp > 0.6 and COLORS.GREEN or (hp > 0.3 and COLORS.YELLOW or COLORS.RED)
            healthBg.Visible = F.ESPHealth
        end
        nameLbl.Text = plr.Name
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if hrp and myRoot then
            distLbl.Text = string.format("%d studs", math.floor((hrp.Position - myRoot.Position).Magnitude))
            distLbl.Visible = F.ESPDistance
        end
    end

    update()
    entry.connection = RunService.Heartbeat:Connect(update)
end

local function refreshAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then createESP(plr) end
    end
end

Players.PlayerAdded:Connect(function(p)
    if F.ESP then createESP(p) end
end)
Players.PlayerRemoving:Connect(destroyESP)

RunService.Heartbeat:Connect(function()
    for plr, e in pairs(espObjects) do
        if e.billboard then
            e.billboard.Enabled = F.ESP and plr.Character ~= nil
        end
    end
end)

-- =============================================
-- TRACERS
-- =============================================
local TRACER_MAP = {
    Red = Color3.fromRGB(255, 45, 65),
    White = Color3.fromRGB(245, 245, 245),
    Green = Color3.fromRGB(60, 240, 130),
    Blue = Color3.fromRGB(80, 150, 255),
    Cyan = Color3.fromRGB(0, 255, 255),
    Purple = Color3.fromRGB(180, 80, 255),
}

local tracerFolder = Instance.new("Folder")
tracerFolder.Name = "NightfallTracers"
tracerFolder.Parent = Workspace

local tracers = {}

local function ensureTracer(plr)
    if tracers[plr] then return tracers[plr] end
    local att0 = Instance.new("Attachment")
    local att1 = Instance.new("Attachment")
    att0.Parent = tracerFolder
    att1.Parent = tracerFolder
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 0.08
    beam.Width1 = 0.08
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Enabled = false
    beam.Color = ColorSequence.new(TRACER_MAP[F.TracerColor] or TRACER_MAP.Red)
    beam.Transparency = NumberSequence.new(0.15)
    beam.Parent = tracerFolder
    tracers[plr] = {att0 = att0, att1 = att1, beam = beam}
    return tracers[plr]
end

local function destroyTracer(plr)
    local t = tracers[plr]
    if not t then return end
    pcall(function() t.att0:Destroy() end)
    pcall(function() t.att1:Destroy() end)
    pcall(function() t.beam:Destroy() end)
    tracers[plr] = nil
end

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
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            t.att0.WorldPosition = originPart.Position
            t.att1.WorldPosition = hrp.Position + Vector3.new(0, 1, 0)
            t.beam.Color = ColorSequence.new(TRACER_MAP[F.TracerColor] or TRACER_MAP.Red)
            t.beam.Enabled = true
        else
            t.beam.Enabled = false
        end
    end
end)

-- =============================================
-- MOVEMENT & MISC LOOPS
-- =============================================
local flyBV, flyBG
local noclipConn

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- WalkSpeed
    if F.WalkSpeedOn then
        hum.WalkSpeed = F.WalkSpeed
    end

    -- JumpPower
    if F.JumpPowerOn then
        hum.JumpPower = F.JumpPower
        hum.UseJumpPower = true
    end

    -- Fly
    if F.Fly then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not flyBV then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBV.Velocity = Vector3.zero
                flyBV.Parent = hrp
            end
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            flyBV.Velocity = moveDir * F.FlySpeed
        end
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
    end

    -- Noclip
    if F.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Weapon mods
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

    -- Hitbox expander
    if F.HitboxExpander then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Size ~= Vector3.new(F.HitboxSize, F.HitboxSize, F.HitboxSize) then
                    hrp.Size = Vector3.new(F.HitboxSize, F.HitboxSize, F.HitboxSize)
                    hrp.Transparency = 0.7
                end
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if F.InfJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- Fullbright
local function setFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end

-- =============================================
-- UI BUILD
-- =============================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "NfToggle"
ToggleBtn.Size = UDim2.fromOffset(46, 46)
ToggleBtn.Position = UDim2.new(0, 15, 0.5, -23)
ToggleBtn.BackgroundColor3 = COLORS.BLACK
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "N"
ToggleBtn.TextColor3 = COLORS.WHITE
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = Gui
Corner(ToggleBtn, 12)
Stroke(ToggleBtn, COLORS.RED, 2)

local toggleDrag = {active=false, moved=false, startPos=nil, startMouse=nil}
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDrag.active = true
        toggleDrag.moved = false
        toggleDrag.startMouse = input.Position
        toggleDrag.startPos = ToggleBtn.Position
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDrag.active = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not toggleDrag.active then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - toggleDrag.startMouse
    if d.Magnitude > 6 then toggleDrag.moved = true end
    ToggleBtn.Position = UDim2.new(
        toggleDrag.startPos.X.Scale, toggleDrag.startPos.X.Offset + d.X,
        toggleDrag.startPos.Y.Scale, toggleDrag.startPos.Y.Offset + d.Y)
end)

-- Main Panel
local Main = Instance.new("Frame")
Main.Name = "NfMain"
Main.Size = UDim2.new(0, 560, 0, 400)
Main.Position = UDim2.new(0.5, -280, 0.5, -200)
Main.BackgroundColor3 = COLORS.BLACK
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = Gui
Corner(Main, 16)
Stroke(Main, COLORS.RED_DIM, 1.5)

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 3, 8)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 6, 8)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 3, 8)),
})
mainGrad.Rotation = 135
mainGrad.Parent = Main

-- Header
local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 46)
Top.BackgroundColor3 = COLORS.DARK
Top.BorderSizePixel = 0
Top.Parent = Main
Corner(Top, 16)

local logoDot = Instance.new("Frame")
logoDot.Size = UDim2.fromOffset(8, 8)
logoDot.Position = UDim2.new(0, 15, 0.5, -4)
logoDot.BackgroundColor3 = COLORS.RED
logoDot.BorderSizePixel = 0
logoDot.Parent = Top
Corner(logoDot, 20)

local Title = Text(Top, "NIGHTFALL V2", 18, true)
Title.Position = UDim2.new(0, 30, 0, 5)
Title.Size = UDim2.new(0, 200, 0, 22)

local SubTitle = Text(Top, "DA HOOD", 9, false, COLORS.RED)
SubTitle.Position = UDim2.new(0, 31, 0, 26)
SubTitle.Size = UDim2.new(0, 100, 0, 12)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -36, 0.5, -14)
Close.BackgroundColor3 = COLORS.DARKER
Close.Text = "×"
Close.TextColor3 = COLORS.WHITE
Close.TextSize = 18
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.AutoButtonColor = false
Close.Parent = Top
Corner(Close, 8)
Stroke(Close, Color3.fromRGB(50, 50, 55), 1)
ClickAnim(Close)
Close.MouseEnter:Connect(function() Tween(Close, {BackgroundColor3 = COLORS.RED}) end)
Close.MouseLeave:Connect(function() Tween(Close, {BackgroundColor3 = COLORS.DARKER}) end)

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 28, 0, 28)
Minimize.Position = UDim2.new(1, -70, 0.5, -14)
Minimize.BackgroundColor3 = COLORS.DARKER
Minimize.Text = "—"
Minimize.TextColor3 = COLORS.WHITE
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.BorderSizePixel = 0
Minimize.AutoButtonColor = false
Minimize.Parent = Top
Corner(Minimize, 8)
Stroke(Minimize, Color3.fromRGB(50, 50, 55), 1)
ClickAnim(Minimize)
Minimize.MouseEnter:Connect(function() Tween(Minimize, {BackgroundColor3 = COLORS.RED}) end)
Minimize.MouseLeave:Connect(function() Tween(Minimize, {BackgroundColor3 = COLORS.DARKER}) end)

ToggleBtn.MouseButton1Click:Connect(function()
    if toggleDrag.moved then return end
    Main.Visible = not Main.Visible
    if Main.Visible then
        Main.Size = UDim2.new(0, 0, 0, 0)
        Tween(Main, {Size = UDim2.new(0, 560, 0, 400)}, 0.28)
        Tween(ToggleBtn, {BackgroundColor3 = COLORS.RED, TextColor3 = COLORS.BLACK})
    else
        Tween(ToggleBtn, {BackgroundColor3 = COLORS.BLACK, TextColor3 = COLORS.WHITE})
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 115, 1, -58)
Sidebar.Position = UDim2.new(0, 8, 0, 54)
Sidebar.BackgroundColor3 = COLORS.DARK
Sidebar.BackgroundTransparency = 0.15
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Corner(Sidebar, 12)
Stroke(Sidebar, Color3.fromRGB(38, 34, 42), 1)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 3)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = Sidebar

local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 6)
Pad.PaddingLeft = UDim.new(0, 4)
Pad.PaddingRight = UDim.new(0, 4)
Pad.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -131, 1, -58)
Content.Position = UDim2.new(0, 123, 0, 54)
Content.BackgroundColor3 = COLORS.DARK
Content.BackgroundTransparency = 0.15
Content.BorderSizePixel = 0
Content.Parent = Main
Corner(Content, 12)
Stroke(Content, Color3.fromRGB(38, 34, 42), 1)

-- Page creator
local Pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = COLORS.RED
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = Content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = page
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10)
    end)
    Pages[name] = page
    return page
end

local function Section(parent, txt)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 20)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = COLORS.RED
    l.TextSize = 9
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 12)
    l.Parent = wrap
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 16)
    line.BackgroundColor3 = COLORS.RED
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    line.Parent = wrap
    return wrap
end

local function Button(parent, txt, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = COLORS.CARD
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = COLORS.WHITE
    b.TextSize = 10
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.Parent = parent
    Corner(b, 8)
    local st = Stroke(b, Color3.fromRGB(38, 34, 42), 1)
    ClickAnim(b)
    b.MouseEnter:Connect(function()
        Tween(b, {BackgroundColor3 = Color3.fromRGB(32, 26, 32)})
        Tween(st, {Color = COLORS.RED_DIM})
    end)
    b.MouseLeave:Connect(function()
        Tween(b, {BackgroundColor3 = COLORS.CARD})
        Tween(st, {Color = Color3.fromRGB(38, 34, 42)})
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function CycleButton(parent, txt, options, default, cb)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i break end end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = COLORS.CARD
    b.BorderSizePixel = 0
    b.Text = txt .. ": " .. options[idx]
    b.TextColor3 = COLORS.WHITE
    b.TextSize = 10
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.Parent = parent
    Corner(b, 8)
    local st = Stroke(b, Color3.fromRGB(38, 34, 42), 1)
    ClickAnim(b)
    b.MouseEnter:Connect(function()
        Tween(b, {BackgroundColor3 = Color3.fromRGB(32, 26, 32)})
        Tween(st, {Color = COLORS.RED_DIM})
    end)
    b.MouseLeave:Connect(function()
        Tween(b, {BackgroundColor3 = COLORS.CARD})
        Tween(st, {Color = Color3.fromRGB(38, 34, 42)})
    end)
    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = txt .. ": " .. options[idx]
        if cb then cb(options[idx]) end
    end)
    return b
end

local function Toggle(parent, txt, default, cb)
    local state = default or false
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 28)
    h.BackgroundColor3 = COLORS.CARD
    h.BorderSizePixel = 0
    h.Parent = parent
    Corner(h, 8)
    Stroke(h, Color3.fromRGB(38, 34, 42), 1)
    local lbl = Text(h, txt .. ": OFF", 10, false)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 28, 0, 15)
    sw.Position = UDim2.new(1, -36, 0.5, -7.5)
    sw.BackgroundColor3 = Color3.fromRGB(38, 34, 42)
    sw.Text = ""
    sw.BorderSizePixel = 0
    sw.Parent = h
    Corner(sw, 20)
    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 11, 0, 11)
    ball.Position = UDim2.new(0, 2, 0.5, -5.5)
    ball.BackgroundColor3 = COLORS.GRAY
    ball.BorderSizePixel = 0
    ball.Parent = sw
    Corner(ball, 20)
    local function Update()
        if state then
            Tween(sw, {BackgroundColor3 = COLORS.RED})
            Tween(ball, {Position = UDim2.new(1, -13, 0.5, -5.5), BackgroundColor3 = COLORS.WHITE})
            lbl.Text = txt .. ": ON"
        else
            Tween(sw, {BackgroundColor3 = Color3.fromRGB(38, 34, 42)})
            Tween(ball, {Position = UDim2.new(0, 2, 0.5, -5.5), BackgroundColor3 = COLORS.GRAY})
            lbl.Text = txt .. ": OFF"
        end
        if cb then cb(state) end
    end
    sw.MouseButton1Click:Connect(function() state = not state Update() end)
    Update()
    return h
end

local ActiveSlider = nil
UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        ActiveSlider(input.Position)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        ActiveSlider = nil
    end
end)

local function Slider(parent, txt, default, minVal, maxVal, cb, suffix)
    local Value = default or 50
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 40)
    h.BackgroundColor3 = COLORS.CARD
    h.BorderSizePixel = 0
    h.Parent = parent
    Corner(h, 8)
    Stroke(h, Color3.fromRGB(38, 34, 42), 1)
    local lbl = Text(h, txt .. ": " .. tostring(Value) .. (suffix or ""), 10, false)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    local barHolder = Instance.new("Frame")
    barHolder.Size = UDim2.new(1, -20, 0, 20)
    barHolder.Position = UDim2.new(0, 10, 0, 22)
    barHolder.BackgroundTransparency = 1
    barHolder.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 5)
    bg.Position = UDim2.new(0, 0, 0.5, -2.5)
    bg.BackgroundColor3 = Color3.fromRGB(45, 40, 50)
    bg.BorderSizePixel = 0
    bg.Parent = barHolder
    Corner(bg, 4)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Value - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.RED
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Corner(fill, 4)
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.RED_DIM),
        ColorSequenceKeypoint.new(1, COLORS.RED_GLOW),
    })
    fillGrad.Parent = fill
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((Value - minVal) / (maxVal - minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = COLORS.WHITE
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Corner(knob, 20)
    Stroke(knob, COLORS.RED, 2)
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
        local ap = bg.AbsolutePosition
        local sz = bg.AbsoluteSize.X
        local rx = math.clamp(pos.X - ap.X, 0, sz)
        UpdateSlider(minVal + (rx / sz) * (maxVal - minVal))
    end
    local fullBar = Instance.new("TextButton")
    fullBar.Size = UDim2.new(1, 0, 0, 20)
    fullBar.Position = UDim2.new(0, 0, 0.5, -10)
    fullBar.BackgroundTransparency = 1
    fullBar.Text = ""
    fullBar.Parent = barHolder
    fullBar.MouseButton1Down:Connect(function()
        ActiveSlider = fromPos
        fromPos(UserInputService:GetMouseLocation())
    end)
    knob.MouseButton1Down:Connect(function() ActiveSlider = fromPos end)
    return h
end

-- =============================================
-- TABS & PAGES
-- =============================================
local MainPage = CreatePage("Main")
local AimPage = CreatePage("Aim")
local VisualsPage = CreatePage("Visuals")
local MovementPage = CreatePage("Movement")
local CombatPage = CreatePage("Combat")
local MiscPage = CreatePage("Misc")
local ConfigPage = CreatePage("Config")

-- ===== MAIN =====
Section(MainPage, "NIGHTFALL")
local mtL = Text(MainPage, "NIGHTFALL HUB V2", 17, true)
mtL.Size = UDim2.new(1, 0, 0, 24)
mtL.TextXAlignment = Enum.TextXAlignment.Center

local msub = Text(MainPage, "Da Hood", 10, false, COLORS.GRAY)
msub.Size = UDim2.new(1, 0, 0, 16)
msub.Position = UDim2.new(0, 0, 0, 26)
msub.TextXAlignment = Enum.TextXAlignment.Center

local mby = Text(MainPage, "✦ Made by Nightfall ✦", 11, true, COLORS.RED)
mby.Size = UDim2.new(1, 0, 0, 20)
mby.Position = UDim2.new(0, 0, 0, 46)
mby.TextXAlignment = Enum.TextXAlignment.Center

Section(MainPage, "STATUS")
local statusLbl = Text(MainPage, "Active: None", 10, false, COLORS.GRAY)
statusLbl.Size = UDim2.new(1, -10, 0, 16)

task.spawn(function()
    while Gui and Gui.Parent do
        local active = {}
        if F.SilentAim then table.insert(active, "Aim") end
        if F.ESP then table.insert(active, "ESP") end
        if F.Tracers then table.insert(active, "Tracers") end
        if F.Fly then table.insert(active, "Fly") end
        if F.Noclip then table.insert(active, "Noclip") end
        if F.Fullbright then table.insert(active, "Bright") end
        if #active == 0 then
            statusLbl.Text = "Active: None"
            statusLbl.TextColor3 = COLORS.GRAY
        else
            statusLbl.Text = "Active: " .. table.concat(active, ", ")
            statusLbl.TextColor3 = COLORS.GREEN
        end
        task.wait(0.4)
    end
end)

-- ===== AIM =====
Section(AimPage, "SILENT AIM")
Toggle(AimPage, "Enable Silent Aim", F.SilentAim, function(s)
    F.SilentAim = s
    if not s then Target, TargetPart = nil, nil end
end)
Slider(AimPage, "FOV Radius", F.FOV, 20, 500, function(v) F.FOV = v end, "px")
Toggle(AimPage, "Show FOV Circle", F.ShowFOV, function(s) F.ShowFOV = s end)
Toggle(AimPage, "Wall Check", F.WallCheck, function(s) F.WallCheck = s end)
Toggle(AimPage, "Team Check", F.TeamCheck, function(s) F.TeamCheck = s end)
Slider(AimPage, "Max Distance", F.MaxDist, 50, 3000, function(v) F.MaxDist = v end, " studs")

Section(AimPage, "INFO")
local info1 = Text(AimPage, "Hold E to lock onto nearest target in FOV.", 9, false, COLORS.GRAY)
info1.Size = UDim2.new(1, -10, 0, 14)
info1.TextWrapped = true

-- ===== VISUALS =====
Section(VisualsPage, "PLAYER ESP")
Toggle(VisualsPage, "Enable ESP", F.ESP, function(s)
    F.ESP = s
    if s then refreshAllESP()
    else
        for plr in pairs(espObjects) do destroyESP(plr) end
    end
end)
Toggle(VisualsPage, "Show Health Bar", F.ESPHealth, function(s) F.ESPHealth = s end)
Toggle(VisualsPage, "Show Distance", F.ESPDistance, function(s) F.ESPDistance = s end)

Section(VisualsPage, "TRACERS")
Toggle(VisualsPage, "Enable Tracers", F.Tracers, function(s) F.Tracers = s end)
CycleButton(VisualsPage, "Tracer Color", {"Red", "White", "Green", "Blue", "Cyan", "Purple"}, F.TracerColor, function(v)
    F.TracerColor = v
end)

Section(VisualsPage, "ENVIRONMENT")
Toggle(VisualsPage, "Fullbright", F.Fullbright, function(s)
    F.Fullbright = s
    setFullbright(s)
end)

-- ===== MOVEMENT =====
Section(MovementPage, "SPEED")
Toggle(MovementPage, "Enable WalkSpeed", false, function(s)
    F.WalkSpeedOn = s
end)
Slider(MovementPage, "WalkSpeed", 16, 16, 500, function(v) F.WalkSpeed = v end, " spd")

Section(MovementPage, "JUMP")
Toggle(MovementPage, "Enable JumpPower", false, function(s)
    F.JumpPowerOn = s
end)
Slider(MovementPage, "JumpPower", 50, 50, 500, function(v) F.JumpPower = v end, " jmp")
Toggle(MovementPage, "Infinite Jump", false, function(s) F.InfJump = s end)

Section(MovementPage, "FLIGHT")
Toggle(MovementPage, "Enable Fly", false, function(s) F.Fly = s end)
Slider(MovementPage, "Fly Speed", 50, 10, 300, function(v) F.FlySpeed = v end, " spd")

Section(MovementPage, "NOCLIP")
Toggle(MovementPage, "Enable Noclip", false, function(s) F.Noclip = s end)

-- ===== COMBAT =====
Section(CombatPage, "WEAPON MODS")
Toggle(CombatPage, "No Recoil", false, function(s) F.NoRecoil = s end)
Toggle(CombatPage, "Infinite Ammo", false, function(s) F.InfAmmo = s end)

Section(CombatPage, "HITBOX")
Toggle(CombatPage, "Hitbox Expander", false, function(s)
    F.HitboxExpander = s
    if not s then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end
end)
Slider(CombatPage, "Hitbox Size", 6, 2, 20, function(v) F.HitboxSize = v end, " studs")

-- ===== MISC =====
Section(MiscPage, "UTILITY")
Toggle(MiscPage, "Auto Collect Items", false, function(s) F.AutoCollect = s end)
Toggle(MiscPage, "Anti-AFK", false, function(s) F.AntiAFK = s end)

Section(MiscPage, "TELEPORT")
Button(MiscPage, "Teleport to Random Player", function()
    local others = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            table.insert(others, plr)
        end
    end
    if #others > 0 then
        local t = others[math.random(1, #others)]
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local thrp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then
            hrp.CFrame = thrp.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

Section(MiscPage, "INFO")
local info2 = Text(MiscPage, "Use features responsibly.", 9, false, COLORS.GRAY)
info2.Size = UDim2.new(1, -10, 0, 14)

-- ===== CONFIG =====
Section(ConfigPage, "CONFIG")
Button(ConfigPage, "Unload UI", function()
    Gui:Destroy()
end)

-- =============================================
-- TAB SWITCHING
-- =============================================
local Tabs = {
    {name="MAIN", icon="🏠", page=MainPage},
    {name="AIM", icon="🎯", page=AimPage},
    {name="VISUALS", icon="👁", page=VisualsPage},
    {name="MOVE", icon="🏃", page=MovementPage},
    {name="COMBAT", icon="⚔", page=CombatPage},
    {name="MISC", icon="⚙", page=MiscPage},
    {name="CONFIG", icon="🔧", page=ConfigPage},
}

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 3, 0, 22)
indicator.Position = UDim2.new(0, 1, 0, 0)
indicator.BackgroundColor3 = COLORS.RED
indicator.BorderSizePixel = 0
indicator.ZIndex = 5
indicator.Parent = Sidebar
Corner(indicator, 4)

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
    Tween(indicator, {Position = UDim2.new(0, 1, 0, btn.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y)}, 0.18)
end

for _, d in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = COLORS.DARKER
    btn.BorderSizePixel = 0
    btn.Text = "  " .. d.icon .. "  " .. d.name
    btn.TextColor3 = COLORS.GRAY
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    Corner(btn, 8)
    Stroke(btn, Color3.fromRGB(38, 34, 42), 1)
    ClickAnim(btn)
    d.button = btn
    btn.MouseEnter:Connect(function()
        if d.page.Visible then return end
        Tween(btn, {BackgroundColor3 = Color3.fromRGB(32, 26, 32)})
    end)
    btn.MouseLeave:Connect(function()
        if d.page.Visible then return end
        Tween(btn, {BackgroundColor3 = COLORS.DARKER})
    end)
    btn.MouseButton1Click:Connect(function() SelectTab(btn, d.page) end)
end
SelectTab(Tabs[1].button, Tabs[1].page)

-- =============================================
-- DRAGGING & MINIMIZE
-- =============================================
local Drag, DStart, SPos = false, nil, nil
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Drag = true
        DStart = input.Position
        SPos = Main.Position
    end
end)
Top.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Drag = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if Drag and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - DStart
        Main.Position = UDim2.new(SPos.X.Scale, SPos.X.Offset + d.X, SPos.Y.Scale, SPos.Y.Offset + d.Y)
    end
end)

local Min = false
Minimize.MouseButton1Click:Connect(function()
    Min = not Min
    if Min then
        Sidebar.Visible = false
        Content.Visible = false
        Tween(Main, {Size = UDim2.new(0, 560, 0, 46)})
        Minimize.Text = "+"
    else
        Tween(Main, {Size = UDim2.new(0, 560, 0, 400)})
        task.wait(0.15)
        Sidebar.Visible = true
        Content.Visible = true
        Minimize.Text = "—"
    end
end)

Close.MouseButton1Click:Connect(function()
    Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
    task.wait(0.25)
    Gui:Destroy()
end)

print("========================================")
print("     NIGHTFALL HUB V2 LOADED")
print("     7 tabs • Fixed bypass")
print("========================================")
