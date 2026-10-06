-- =============================================
-- NIGHTFALL HUB — Da Hood
-- Silent Aim + ESP + Tracers
-- WITH HARDENED ANTI-CHEAT BYPASS
-- =============================================

print("🌙 Nightfall Hub loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VIM = VirtualInputManager
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- =============================================
-- ANTI-DETECTION BYPASS (MUST RUN FIRST)
-- =============================================

-- Neutralize grip checker connections + constants
local function neutralizeGripChecker(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    pcall(function()
        if getconnections then
            -- Disable the Grip property connection
            local gripConnections = getconnections(tool:GetPropertyChangedSignal("Grip"))
            for _, conn in ipairs(gripConnections) do
                pcall(function() conn:Disable() end)
                
                -- Change CHECKER_4 constant if it's a Lua function
                local func = conn.Function
                if func and not iscclosure(func) then
                    local constants = debug.getconstants(func)
                    for i, constant in pairs(constants) do
                        if constant == "CHECKER_4" or (type(constant) == "string" and constant:find("CHECKER")) then
                            debug.setconstant(func, i, "RandomRemote")
                            break
                        end
                    end
                end
            end
            
            -- Disable the generic Tool.Changed connection
            local changedConnections = getconnections(tool.Changed)
            for _, conn in ipairs(changedConnections) do
                pcall(function() conn:Disable() end)
            end
        end
    end)
end

-- Attach guard to current and future tools
local function attachToolGuard()
    local char = player.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        neutralizeGripChecker(tool)
    end
    
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

-- Globally block any CHECKER remote from firing
pcall(function()
    if hookmetamethod and getrawmetatable then
        local mt = getrawmetatable(game)
        if mt and mt.__namecall then
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" then
                    local remoteName = tostring(self.Name or "")
                    if remoteName:find("CHECKER") or remoteName:find("checker") then
                        return nil
                    end
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end
    end
end)

-- Hidden GUI container
local function getHiddenContainer()
    if gethui then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    return player:WaitForChild("PlayerGui")
end

-- =============================================
-- FEATURES CONFIG
-- =============================================
local F = {
    SilentAim = false,
    AimKey = Enum.KeyCode.E,
    AimKeyName = "E",
    FOV = 120,
    ShowFOV = true,
    WallCheck = true,
    ESP = false,
    Tracers = false,
    TracerColor = "Red",
    MaxDist = 1000,
}

-- =============================================
-- PARENT GUI
-- =============================================
local parent = getHiddenContainer()
local old = parent:FindFirstChild("NightfallHub")
if old then old:Destroy() end

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
local fovStroke = Stroke(FOVRing, COLORS.RED, 2, 0.15)

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
-- TARGET FINDER
-- =============================================
local Target = nil
local TargetPart = nil
local TargetHRP = nil

local function isVisible(part)
    if not F.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local ray = Ray.new(origin, dir)
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray,
        {player.Character, Target and Target.Character or nil}, false, true)
    if hit and hit:IsDescendantOf(player.Character) then
        return true
    end
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

local function inFOV(part)
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return false end
    local c = Camera.ViewportSize / 2
    return (Vector2.new(sp.X, sp.Y) - c).Magnitude <= F.FOV
end

local function getTarget()
    local best, bestPart, bestHRP, bestDist = nil, nil, nil, math.huge
    local myChar = player.Character
    if not myChar then return nil, nil, nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end

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
                        bestHRP = hrp
                    end
                end
            end
        end
    end
    return best, bestPart, bestHRP
end

RunService.RenderStepped:Connect(function()
    if not F.SilentAim or not UserInputService:IsKeyDown(F.AimKey) then
        Target, TargetPart, TargetHRP = nil, nil, nil
        return
    end
    local plr, part, hrp = getTarget()
    Target, TargetPart, TargetHRP = plr, part, hrp
end)

-- =============================================
-- SILENT AIM (Mouse.Hit redirect)
-- =============================================
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    setreadonly(mt, false)
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex

    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and F.SilentAim and TargetPart and self == mouse then
            if key == "Hit" then return CFrame.new(TargetPart.Position) end
            if key == "Target" then return TargetPart end
            if key == "X" then return Camera:WorldToViewportPoint(TargetPart.Position).X end
            if key == "Y" then return Camera:WorldToViewportPoint(TargetPart.Position).Y end
        end
        return oldIndex(self, key)
    end)

    mt.__newindex = newcclosure(function(self, key, val)
        if not checkcaller() and F.SilentAim and TargetPart and self == mouse then
            if key == "Hit" or key == "Target" then return end
        end
        return oldNewIndex(self, key, val)
    end)
    setreadonly(mt, true)
end)

-- Hook RemoteEvent FireServer to overwrite shot args
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and F.SilentAim and TargetPart and method == "FireServer" then
            local nm = string.lower(tostring(self.Name or ""))
            if string.find(nm, "shoot", 1, true) or string.find(nm, "gun", 1, true) or
               string.find(nm, "hit", 1, true) then
                local args = {...}
                local new = table.pack(table.unpack(args))
                local changed = false
                for i, v in ipairs(new) do
                    if typeof(v) == "CFrame" then
                        new[i] = CFrame.new(TargetPart.Position)
                        changed = true
                    elseif typeof(v) == "Vector3" then
                        new[i] = TargetPart.Position
                        changed = true
                    end
                end
                if changed then
                    return oldNamecall(self, table.unpack(new, 1, new.n))
                end
            end
        end
        return oldNamecall(self, ...)
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
    billboard.Adornee = nil
    billboard.Parent = Gui

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = billboard

    local nameLbl = Text(holder, "", 13, true, COLORS.WHITE)
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Position = UDim2.new(0, 0, 0, 0)
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
        holder = holder,
        nameLbl = nameLbl,
        healthBg = healthBg,
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
        if hrp then
            billboard.Adornee = hrp
        end
        if hum then
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            healthFill.Size = UDim2.new(hp, 0, 1, 0)
            healthFill.BackgroundColor3 = hp > 0.6 and COLORS.GREEN or (hp > 0.3 and COLORS.YELLOW or COLORS.RED)
        end
        nameLbl.Text = plr.Name
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if hrp and myRoot then
            distLbl.Text = string.format("%d studs", math.floor((hrp.Position - myRoot.Position).Magnitude))
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
    att0.Name = "NFAtt0"
    att1.Name = "NFAtt1"
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
    beam.Segments = 1
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
-- UI
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

local toggleGlow = Instance.new("ImageLabel")
toggleGlow.Size = UDim2.new(1, 30, 1, 30)
toggleGlow.Position = UDim2.new(0, -15, 0, -15)
toggleGlow.BackgroundTransparency = 1
toggleGlow.Image = "rbxassetid://5028857084"
toggleGlow.ImageColor3 = COLORS.RED
toggleGlow.ImageTransparency = 0.5
toggleGlow.ZIndex = ToggleBtn.ZIndex - 1
toggleGlow.Parent = ToggleBtn

task.spawn(function()
    while ToggleBtn and ToggleBtn.Parent do
        Tween(toggleGlow, {ImageTransparency = 0.15}, 1.6, Enum.EasingStyle.Sine)
        task.wait(1.6)
        Tween(toggleGlow, {ImageTransparency = 0.55}, 1.6, Enum.EasingStyle.Sine)
        task.wait(1.6)
    end
end)

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

-- Main panel
local Main = Instance.new("Frame")
Main.Name = "NfMain"
Main.Size = UDim2.new(0, 520, 0, 360)
Main.Position = UDim2.new(0.5, -260, 0.5, -180)
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

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.Position = UDim2.new(0, -30, 0, -30)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = COLORS.RED
shadow.ImageTransparency = 0.65
shadow.ZIndex = Main.ZIndex - 1
shadow.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 46)
Top.BackgroundColor3 = COLORS.DARK
Top.BorderSizePixel = 0
Top.Parent = Main
Corner(Top, 16)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, -24, 0, 1)
topLine.Position = UDim2.new(0, 12, 1, -1)
topLine.BackgroundColor3 = COLORS.RED
topLine.BackgroundTransparency = 0.5
topLine.BorderSizePixel = 0
topLine.Parent = Top

local logoDot = Instance.new("Frame")
logoDot.Size = UDim2.fromOffset(8, 8)
logoDot.Position = UDim2.new(0, 15, 0.5, -4)
logoDot.BackgroundColor3 = COLORS.RED
logoDot.BorderSizePixel = 0
logoDot.Parent = Top
Corner(logoDot, 20)

local logoGlow = Instance.new("ImageLabel")
logoGlow.Size = UDim2.new(1, 20, 1, 20)
logoGlow.Position = UDim2.new(0, -10, 0, -10)
logoGlow.BackgroundTransparency = 1
logoGlow.Image = "rbxassetid://5028857084"
logoGlow.ImageColor3 = COLORS.RED
logoGlow.ImageTransparency = 0.3
logoGlow.ZIndex = logoDot.ZIndex - 1
logoGlow.Parent = logoDot

local Title = Text(Top, "NIGHTFALL", 18, true)
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
        Tween(Main, {Size = UDim2.new(0, 520, 0, 360)}, 0.28)
        Tween(ToggleBtn, {BackgroundColor3 = COLORS.RED, TextColor3 = COLORS.BLACK})
    else
        Tween(ToggleBtn, {BackgroundColor3 = COLORS.BLACK, TextColor3 = COLORS.WHITE})
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 105, 1, -58)
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
Content.Size = UDim2.new(1, -121, 1, -58)
Content.Position = UDim2.new(0, 113, 0, 54)
Content.BackgroundColor3 = COLORS.DARK
Content.BackgroundTransparency = 0.15
Content.BorderSizePixel = 0
Content.Parent = Main
Corner(Content, 12)
Stroke(Content, Color3.fromRGB(38, 34, 42), 1)

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
    knob.Size = UDim2.new(0, 16((, 0, 16)
    knob.Position = UDim2.newValue - minVal) / (maxVal - minVal), -8, 0.5, -8)
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
-- PAGES
-- =============================================
local MainPage = CreatePage("Main")
local AimPage = CreatePage("Aim")
local VisualsPage = CreatePage("Visuals")
local ConfigPage = CreatePage("Config")

-- Main
Section(MainPage, "NIGHTFALL")
local mtL = Text(MainPage, "NIGHTFALL HUB", 17, true)
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
        if F.SilentAim then table.insert(active, "Silent Aim") end
        if F.ESP then table.insert(active, "ESP") end
        if F.Tracers then table.insert(active, "Tracers") end
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

-- Aim
Section(AimPage, "SILENT AIM")
Toggle(AimPage, "Enable Silent Aim", F.SilentAim, function(s)
    F.SilentAim = s
    if not s then Target, TargetPart, TargetHRP = nil, nil, nil end
end)
Button(AimPage, "Aim Key: " .. F.AimKeyName .. " (tap to change)", function() end)
Slider(AimPage, "FOV Radius", F.FOV, 20, 500, function(v) F.FOV = v end, "px")
Toggle(AimPage, "Show FOV Circle", F.ShowFOV, function(s) F.ShowFOV = s end)
Toggle(AimPage, "Wall Check", F.WallCheck, function(s) F.WallCheck = s end)
Slider(AimPage, "Max Distance", F.MaxDist, 50, 3000, function(v) F.MaxDist = v end, " studs")

Section(AimPage, "INFO")
local info1 = Text(AimPage, "Hold your Aim Key to lock onto the nearest target in FOV.", 9, false, COLORS.GRAY)
info1.Size = UDim2.new(1, -10, 0, 14)
info1.TextWrapped = true
local info2 = Text(AimPage, "Wall Check: skips targets behind walls.", 9, false, COLORS.GRAY)
info2.Size = UDim2.new(1, -10, 0, 14)
info2.TextWrapped = true

-- Visuals
Section(VisualsPage, "PLAYER ESP")
Toggle(VisualsPage, "Enable ESP", F.ESP, function(s)
    F.ESP = s
    if s then refreshAllESP()
    else
        for plr in pairs(espObjects) do destroyESP(plr) end
    end
end)

Section(VisualsPage, "TRACERS")
Toggle(VisualsPage, "Enable Tracers", F.Tracers, function(s) F.Tracers = s end)
CycleButton(VisualsPage, "Tracer Color", {"Red", "White", "Green", "Blue", "Cyan", "Purple"}, F.TracerColor, function(v)
    F.TracerColor = v
end)

-- Config
Section(ConfigPage, "CONFIG")
Button(ConfigPage, "Unload UI", function()
    Gui:Destroy()
end)

-- =============================================
-- TABS
-- =============================================
local Tabs = {
    {name="MAIN", icon="🏠", page=MainPage},
    {name="AIM", icon="🎯", page=AimPage},
    {name="VISUALS", icon="👁", page=VisualsPage},
    {name="CONFIG", icon="⚙", page=ConfigPage},
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

-- Dragging
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

-- Minimize
local Min = false
Minimize.MouseButton1Click:Connect(function()
    Min = not Min
    if Min then
        Sidebar.Visible = false
        Content.Visible = false
        shadow.Visible = false
        Tween(Main, {Size = UDim2.new(0, 520, 0, 46)})
        Minimize.Text = "+"
    else
        Tween(Main, {Size = UDim2.new(0, 520, 0, 360)})
        task.wait(0.15)
        Sidebar.Visible = true
        Content.Visible = true
        shadow.Visible = true
        Minimize.Text = "—"
    end
end)

Close.MouseButton1Click: `Connect(function()
    Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
    task.wait(0.25)
    Gui:Destroy()
end)

print("========================================")
print("     NIGHTFALL HUB LOADED")
print("     Made by Nightfall")
print("========================================")
