--// IVORY'S CAMLOCK — DA HOOD OPTIMIZED (FULL)
--// Ping-adaptive prediction + K.O./grab filtering + Box ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local SETTINGS = {
	MAX_DISTANCE    = 400,
	FOV             = 120,
	STICKY_TARGET   = true,
	STICKY_RANGE    = 1.35,

	AIM_PART        = "UpperTorso",

	BASE_PREDICTION = 0.125,
	PING_MULTIPLIER = 0.0008,

	SMOOTHNESS      = 0.18,

	BOX_PADDING     = 5,
	BOX_THICKNESS   = 1.5,
	BOX_COLOR       = Color3.fromRGB(255, 255, 255),
	BOX_FILL_TRANSP = 0.88,
	BOX_CORNER      = 4,
	SHOW_LABEL      = true,
}

--==================================================
-- STATE
--==================================================

local CamlockEnabled = false
local CurrentPart    = nil

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name           = "IvoryCamlock"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder   = 1000
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = PlayerGui

--==================================================
-- BUTTON
--==================================================

local Button = Instance.new("TextButton")
Button.Size             = UDim2.fromOffset(160, 48)
Button.Position         = UDim2.new(0.5, -80, 0.85, 0)
Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Button.BorderSizePixel  = 0
Button.Text             = "IVORY CAMLOCK • OFF"
Button.TextColor3       = Color3.fromRGB(245, 245, 245)
Button.Font             = Enum.Font.GothamBold
Button.TextSize         = 13
Button.Active           = true
Button.AutoButtonColor  = true
Button.Selectable       = false
Button.Parent           = Gui

Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 13)

local ButtonStroke = Instance.new("UIStroke", Button)
ButtonStroke.Thickness = 1.5
ButtonStroke.Color     = Color3.fromRGB(150, 150, 160)

--==================================================
-- BOX ESP
--==================================================

local BoxContainer = Instance.new("Frame")
BoxContainer.BackgroundTransparency = 1
BoxContainer.Size                  = UDim2.fromScale(1, 1)
BoxContainer.Visible               = false
BoxContainer.ZIndex                = 50
BoxContainer.Parent                = Gui

local Box = Instance.new("Frame")
Box.AnchorPoint            = Vector2.new(0.5, 0.5)
Box.BackgroundColor3       = SETTINGS.BOX_COLOR
Box.BackgroundTransparency = SETTINGS.BOX_FILL_TRANSP
Box.BorderSizePixel        = 0
Box.ZIndex                 = 50
Box.Parent                 = BoxContainer

Instance.new("UICorner", Box).CornerRadius = UDim.new(0, SETTINGS.BOX_CORNER)

local BoxStroke = Instance.new("UIStroke", Box)
BoxStroke.Thickness       = SETTINGS.BOX_THICKNESS
BoxStroke.Color           = SETTINGS.BOX_COLOR
BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Label = Instance.new("TextLabel")
Label.BackgroundTransparency = 1
Label.AnchorPoint            = Vector2.new(0.5, 1)
Label.Font                   = Enum.Font.GothamBold
Label.TextSize               = 12
Label.TextColor3             = SETTINGS.BOX_COLOR
Label.TextStrokeTransparency = 0.5
Label.TextStrokeColor3       = Color3.new(0, 0, 0)
Label.ZIndex                 = 52
Label.Visible                = SETTINGS.SHOW_LABEL
Label.Parent                 = BoxContainer

--==================================================
-- PREDICTION (PING-ADAPTIVE)
--==================================================

local function getPrediction()
	local ping = 50
	pcall(function()
		local pingStat = Stats.Network.ServerStatsItem["Data Ping"]
		if pingStat then
			ping = pingStat:GetValue()
		end
	end)
	local prediction = SETTINGS.BASE_PREDICTION + (ping * SETTINGS.PING_MULTIPLIER)
	return math.clamp(prediction, 0.10, 0.20)
end

--==================================================
-- TARGET VALIDATION
--==================================================

local function isKOd(character)
	local be = character:FindFirstChild("BodyEffects")
	if not be then return false end
	local ko = be:FindFirstChild("K.O")
	return ko and ko.Value == true
end

local function isGrabbed(character)
	return character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil
end

local function IsValidTarget(part)
	if not part or not part.Parent then return false end
	local character = part.Parent
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if isKOd(character) or isGrabbed(character) then return false end
	return true
end

local function GetPredictedPosition(part)
	if not IsValidTarget(part) then return nil end
	local v = part.AssemblyLinearVelocity
	local biasedVel = Vector3.new(v.X, v.Y * 0.4, v.Z)
	return part.Position + (biasedVel * getPrediction())
end

--==================================================
-- TARGET FINDING
--==================================================

local function getScreenCenter()
	local cam = workspace.CurrentCamera
	return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

local function FindTarget()
	local cam = workspace.CurrentCamera
	if not cam then return nil end

	local center = getScreenCenter()
	local best, bestDist = nil, math.huge
	local minDot = math.cos(math.rad(SETTINGS.FOV / 2))

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local part = character:FindFirstChild(SETTINGS.AIM_PART)
			local hum = character:FindFirstChildOfClass("Humanoid")

			if part and hum and hum.Health > 0 and IsValidTarget(part) then
				local offset = part.Position - cam.CFrame.Position
				local dist = offset.Magnitude

				if dist > 0 and dist <= SETTINGS.MAX_DISTANCE then
					local dot = cam.CFrame.LookVector:Dot(offset.Unit)
					if dot >= minDot then
						local screenPos, visible = cam:WorldToViewportPoint(part.Position)
						if visible and screenPos.Z > 0 then
							local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
							if d < bestDist then
								bestDist = d
								best = part
							end
						end
					end
				end
			end
		end
	end

	return best
end

local function pickTarget()
	if SETTINGS.STICKY_TARGET and IsValidTarget(CurrentPart) then
		local cam = workspace.CurrentCamera
		if cam then
			local offset = CurrentPart.Position - cam.CFrame.Position
			if offset.Magnitude <= SETTINGS.MAX_DISTANCE * SETTINGS.STICKY_RANGE then
				return CurrentPart
			end
		end
	end
	return FindTarget()
end

--==================================================
-- BOX RENDERING
--==================================================

local function getBoundingBox(part)
	local cam = workspace.CurrentCamera
	local character = part.Parent
	if not cam or not character then return nil end

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyVisible = false

	local scale = (cam.ViewportSize.Y * 0.5) / math.tan(math.rad(cam.FieldOfView * 0.5))

	for _, p in ipairs(character:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local pos, visible = cam:WorldToViewportPoint(p.Position)
			if visible and pos.Z > 0 then
				anyVisible = true
				local dist = (p.Position - cam.CFrame.Position).Magnitude
				local px = (p.Size.X * 0.5) * scale / math.max(dist, 1)
				local py = (p.Size.Y * 0.5) * scale / math.max(dist, 1)

				minX = math.min(minX, pos.X - px)
				maxX = math.max(maxX, pos.X + px)
				minY = math.min(minY, pos.Y - py)
				maxY = math.max(maxY, pos.Y + py)
			end
		end
	end

	if not anyVisible then return nil end
	return minX, minY, maxX, maxY
end

local function UpdateBox(part)
	local cam = workspace.CurrentCamera
	if not cam or not IsValidTarget(part) then
		BoxContainer.Visible = false
		return
	end

	local minX, minY, maxX, maxY = getBoundingBox(part)
	if not minX then
		BoxContainer.Visible = false
		return
	end

	local pad    = SETTINGS.BOX_PADDING
	local width  = (maxX - minX) + pad * 2
	local height = (maxY - minY) + pad * 2
	local cx     = (minX + maxX) / 2
	local cy     = (minY + maxY) / 2

	Box.Position = UDim2.fromOffset(cx, cy)
	Box.Size     = UDim2.fromOffset(width, height)

	if SETTINGS.SHOW_LABEL then
		local dist = (part.Position - cam.CFrame.Position).Magnitude
		Label.Text     = string.format("%s  [%d]", part.Parent.Name, math.floor(dist))
		Label.Position = UDim2.new(0.5, 0, 0, -6)
		Label.Size     = UDim2.fromOffset(math.max(width, 140), 16)
		Label.Visible  = true
	end

	BoxContainer.Visible = true
end

--==================================================
-- BUTTON TOGGLE
--==================================================

Button.Activated:Connect(function()
	CamlockEnabled = not CamlockEnabled
	if CamlockEnabled then
		Button.Text             = "IVORY CAMLOCK • ON"
		Button.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
	else
		Button.Text             = "IVORY CAMLOCK • OFF"
		Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		CurrentPart = nil
	end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function(dt)
		local cam = workspace.CurrentCamera
		if not cam then return end

		CurrentPart = pickTarget()

		if IsValidTarget(CurrentPart) then
			UpdateBox(CurrentPart)
		else
			BoxContainer.Visible = false
		end

		if CamlockEnabled and IsValidTarget(CurrentPart) then
			local aimPos = GetPredictedPosition(CurrentPart)
			if aimPos then
				local desired = CFrame.lookAt(cam.CFrame.Position, aimPos)
				local alpha = 1 - math.exp(-SETTINGS.SMOOTHNESS * 60 * dt)
				cam.CFrame = cam.CFrame:Lerp(desired, alpha)
			end
		end
	end
)
