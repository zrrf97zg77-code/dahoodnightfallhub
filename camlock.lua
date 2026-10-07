--// IVORY'S CAMLOCK
--// Mobile / Fixed Button / Permanent Tracer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local PREDICTION = 0.12
local MAX_DISTANCE = 300

-- 180 degree targeting
local FOV = 180

-- Camera smoothness
local SMOOTHNESS = 0.18

--==================================================
-- STATE
--==================================================

local CamlockEnabled = false
local CurrentTarget = nil

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "IvoryCamlock"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder = 1000
Gui.Parent = PlayerGui

--==================================================
-- FIXED CAMLOCK BUTTON
--==================================================

local Button = Instance.new("TextButton")

Button.Name = "IvoryCamlockButton"

Button.Size =
	UDim2.fromOffset(150,52)

-- FIXED POSITION
Button.Position =
	UDim2.new(
		0.5,
		-75,
		0.78,
		0
	)

Button.BackgroundColor3 =
	Color3.fromRGB(25,25,30)

Button.BorderSizePixel = 0

Button.Text =
	"IVORY CAMLOCK • OFF"

Button.TextColor3 =
	Color3.fromRGB(245,245,245)

Button.Font =
	Enum.Font.GothamBold

Button.TextSize = 13

-- Touchable, but absolutely no drag code
Button.Active = true
Button.AutoButtonColor = true
Button.Selectable = false

Button.Parent = Gui

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius =
	UDim.new(0,13)
ButtonCorner.Parent = Button

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Thickness = 1.5
ButtonStroke.Color =
	Color3.fromRGB(150,150,160)
ButtonStroke.Parent = Button

--==================================================
-- PERMANENT TRACER
--==================================================

local Tracer = Instance.new("Frame")

Tracer.Name = "PermanentTracer"

Tracer.AnchorPoint =
	Vector2.new(0,0.5)

Tracer.BackgroundColor3 =
	Color3.fromRGB(245,245,245)

Tracer.BorderSizePixel = 0

Tracer.Size =
	UDim2.fromOffset(0,2)

Tracer.Visible = true

Tracer.ZIndex = 50

Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius =
	UDim.new(1,0)
TracerCorner.Parent = Tracer

--==================================================
-- TARGET DOT
--==================================================

local TargetDot = Instance.new("Frame")

TargetDot.Name = "TargetDot"

TargetDot.AnchorPoint =
	Vector2.new(0.5,0.5)

TargetDot.Size =
	UDim2.fromOffset(12,12)

TargetDot.BackgroundTransparency = 1
TargetDot.BorderSizePixel = 0

TargetDot.Visible = false

TargetDot.ZIndex = 51

TargetDot.Parent = Gui

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius =
	UDim.new(1,0)
DotCorner.Parent = TargetDot

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color =
	Color3.fromRGB(245,245,245)
DotStroke.Parent = TargetDot

--==================================================
-- VALID TARGET
--==================================================

local function IsValidTarget(Root)

	if not Root then
		return false
	end

	if not Root.Parent then
		return false
	end

	local Humanoid =
		Root.Parent:FindFirstChildOfClass("Humanoid")

	if not Humanoid then
		return false
	end

	if Humanoid.Health <= 0 then
		return false
	end

	return true
end

--==================================================
-- PREDICTION
--==================================================

local function GetPredictedPosition(Root)

	if not IsValidTarget(Root) then
		return nil
	end

	return Root.Position +
		(
			Root.AssemblyLinearVelocity
			* PREDICTION
		)
end

--==================================================
-- FIND BEST TARGET
--==================================================

local function FindTarget()

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local CameraPosition =
		Camera.CFrame.Position

	local CameraLook =
		Camera.CFrame.LookVector

	local BestTarget = nil
	local BestScreenDistance = math.huge

	-- Exactly 180 degrees
	local MinimumDot =
		math.cos(
			math.rad(FOV / 2)
		)

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			local Character =
				Player.Character

			if Character then

				local Humanoid =
					Character:FindFirstChildOfClass("Humanoid")

				local Root =
					Character:FindFirstChild(
						"HumanoidRootPart"
					)

				if Humanoid
					and Root
					and Humanoid.Health > 0 then

					local Offset =
						Root.Position
						- CameraPosition

					local Distance =
						Offset.Magnitude

					if Distance > 0
						and Distance <= MAX_DISTANCE then

						local Direction =
							Offset.Unit

						local Dot =
							CameraLook:Dot(Direction)

						if Dot >= MinimumDot then

							local ScreenPosition, Visible =
								Camera:WorldToScreenPoint(
									Root.Position
								)

							if Visible
								and ScreenPosition.Z > 0 then

								local Center =
									Vector2.new(
										Camera.ViewportSize.X / 2,
										Camera.ViewportSize.Y / 2
									)

								local TargetPoint =
									Vector2.new(
										ScreenPosition.X,
										ScreenPosition.Y
									)

								local ScreenDistance =
									(
										TargetPoint
										- Center
									).Magnitude

								if ScreenDistance
									< BestScreenDistance then

									BestScreenDistance =
										ScreenDistance

									BestTarget =
										Root
								end
							end
						end
					end
				end
			end
		end
	end

	return BestTarget
end

--==================================================
-- UPDATE TRACER
--==================================================

local function UpdateTracer(Target)

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return
	end

	if not IsValidTarget(Target) then

		Tracer.Visible = false
		TargetDot.Visible = false

		return
	end

	local Predicted =
		GetPredictedPosition(Target)

	if not Predicted then

		Tracer.Visible = false
		TargetDot.Visible = false

		return
	end

	-- Project the EXACT predicted world position
	-- onto the screen.
	local ScreenPosition, Visible =
		Camera:WorldToScreenPoint(
			Predicted
		)

	if not Visible
		or ScreenPosition.Z <= 0 then

		Tracer.Visible = false
		TargetDot.Visible = false

		return
	end

	-- Screen center
	local Start =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	-- Target's projected position
	local Finish =
		Vector2.new(
			ScreenPosition.X,
			ScreenPosition.Y
		)

	local Difference =
		Finish - Start

	local Length =
		Difference.Magnitude

	if Length <= 1 then
		return
	end

	--==================================================
	-- DRAW LINE
	--==================================================

	Tracer.Position =
		UDim2.fromOffset(
			Start.X,
			Start.Y
		)

	Tracer.Size =
		UDim2.fromOffset(
			Length,
			2
		)

	Tracer.Rotation =
		math.deg(
			math.atan2(
				Difference.Y,
				Difference.X
			)
		)

	Tracer.Visible = true

	--==================================================
	-- DRAW TARGET POINT
	--==================================================

	TargetDot.Position =
		UDim2.fromOffset(
			Finish.X,
			Finish.Y
		)

	TargetDot.Visible = true
end

--==================================================
-- BUTTON
--==================================================

Button.Activated:Connect(function()

	CamlockEnabled =
		not CamlockEnabled

	if CamlockEnabled then

		Button.Text =
			"IVORY CAMLOCK • ON"

		Button.BackgroundColor3 =
			Color3.fromRGB(65,65,75)

	else

		Button.Text =
			"IVORY CAMLOCK • OFF"

		Button.BackgroundColor3 =
			Color3.fromRGB(25,25,30)
	end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function()

		local Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		--==================================================
		-- ALWAYS FIND THE TARGET
		--==================================================

		local NewTarget =
			FindTarget()

		CurrentTarget =
			NewTarget

		--==================================================
		-- TRACER IS ALWAYS ACTIVE
		--==================================================

		UpdateTracer(CurrentTarget)

		--==================================================
		-- CAMERA LOCK
		--==================================================

		if CamlockEnabled
			and IsValidTarget(CurrentTarget) then

			local AimPosition =
				GetPredictedPosition(
					CurrentTarget
				)

			if AimPosition then

				local DesiredCFrame =
					CFrame.lookAt(
						Camera.CFrame.Position,
						AimPosition
					)

				Camera.CFrame =
					Camera.CFrame:Lerp(
						DesiredCFrame,
						SMOOTHNESS
					)
			end
		end
	end
)
