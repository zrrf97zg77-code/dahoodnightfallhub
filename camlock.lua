--// IVORY'S CAMLOCK — DA HOOD OPTIMIZED
--// Ping-adaptive prediction + K.O./grab filtering

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local SETTINGS = {
	-- Targeting
	MAX_DISTANCE     = 400,
	FOV              = 120,
	STICKY_TARGET    = true,
	STICKY_RANGE     = 1.35,

	-- Aim part (torso is most stable hitbox)
	AIM_PART         = "UpperTorso",

	-- Prediction (base value, gets ping-adjusted)
	BASE_PREDICTION  = 0.125,
	PING_MULTIPLIER  = 0.0008,  -- adds ~0.08 at 100ms

	-- Camera
	SMOOTHNESS       = 0.18,

	-- ESP
	BOX_PADDING      = 5,
	BOX_COLOR        = Color3.fromRGB(255, 255, 255),
}

--==================================================
-- STATE
--==================================================

local CamlockEnabled = false
local CurrentTarget  = nil
local CurrentPart    = nil

--==================================================
-- PING-ADAPTIVE PREDICTION
--==================================================

local function getPrediction()
	local ping = 50 -- default fallback

	pcall(function()
		local pingStat = Stats.Network.ServerStatsItem["Data Ping"]
		if pingStat then
			ping = pingStat:GetValue()
		end
	end)

	-- Scale prediction with ping
	-- 50ms  -> ~0.125
	-- 100ms -> ~0.145
	-- 150ms -> ~0.165
	local prediction = SETTINGS.BASE_PREDICTION + (ping * SETTINGS.PING_MULTIPLIER)
	return math.clamp(prediction, 0.10, 0.20)
end

--==================================================
-- TARGET VALIDATION
--==================================================

local function isKOd(character)
	local bodyEffects = character:FindFirstChild("BodyEffects")
	if not bodyEffects then return false end
	local ko = bodyEffects:FindFirstChild("K.O")
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

	-- Skip K.O. or grabbed players (unhittable)
	if isKOd(character) or isGrabbed(character) then
		return false
	end

	return true
end

--==================================================
-- PREDICTION
--==================================================

local function GetPredictedPosition(part)
	if not IsValidTarget(part) then return nil end

	local velocity = part.AssemblyLinearVelocity
	local prediction = getPrediction()

	-- Bias vertical velocity down (Da Hood has lots of jumping/ragdoll)
	local biasedVel = Vector3.new(velocity.X, velocity.Y * 0.4, velocity.Z)

	return part.Position + (biasedVel * prediction)
end

--==================================================
-- TARGET FINDING
--==================================================

local function getScreenCenter()
	return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function FindTarget()
	local center = getScreenCenter()
	local best, bestDist = nil, math.huge
	local minDot = math.cos(math.rad(SETTINGS.FOV / 2))

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local part = character:FindFirstChild(SETTINGS.AIM_PART)
			local hum = character:FindFirstChildOfClass("Humanoid")

			if part and hum and hum.Health > 0 and IsValidTarget(part) then
				local offset = part.Position - Camera.CFrame.Position
				local distance = offset.Magnitude

				if distance > 0 and distance <= SETTINGS.MAX_DISTANCE then
					local dot = Camera.CFrame.LookVector:Dot(offset.Unit)

					if dot >= minDot then
						local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
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
	-- Sticky target: keep current if still valid
	if SETTINGS.STICKY_TARGET and IsValidTarget(CurrentPart) then
		local offset = CurrentPart.Position - Camera.CFrame.Position
		if offset.Magnitude <= SETTINGS.MAX_DISTANCE * SETTINGS.STICKY_RANGE then
			return CurrentPart
		end
	end
	return FindTarget()
end

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function(dt)
		if not Camera then return end

		CurrentPart = pickTarget()
		CurrentTarget = CurrentPart

		-- Camera lock
		if CamlockEnabled and IsValidTarget(CurrentPart) then
			local aimPos = GetPredictedPosition(CurrentPart)

			if aimPos then
				local desired = CFrame.lookAt(Camera.CFrame.Position, aimPos)
				-- Frame-rate independent smoothing
				local alpha = 1 - math.exp(-SETTINGS.SMOOTHNESS * 60 * dt)
				Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
			end
		end
	end
)
