--// IVORY'S CAMLOCK
--// Mobile / Fixed Button
--// One button controls everything

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local PREDICTION = 0.12
local MAX_DISTANCE = 300
local FOV = 180
local SMOOTHNESS = 0.18

-- Fixed position. Change these if you want it somewhere else.
local BUTTON_X = 0.5
local BUTTON_Y = 0.78

--==================================================
-- STATE
--==================================================

local Enabled = false
local Target = nil

--==================================================
-- SCREEN GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "IvoryCamlock"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder = 1000
Gui.Parent = PlayerGui

--==================================================
-- CAMLOCK BUTTON
--==================================================

local Button = Instance.new("TextButton")

Button.Name = "IvoryCamlockButton"
Button.Size = UDim2.fromOffset(150, 52)

-- FIXED POSITION
Button.Position = UDim2.new(
	BUTTON_X,
	-75,
	BUTTON_Y,
	0
)

Button.BackgroundColor3 =
	Color3.fromRGB(25,25,30)

Button.BorderSizePixel = 0

Button.Text = "IVORY CAMLOCK • OFF"

Button.TextColor3 =
	Color3.fromRGB(245,245,245)

Button.Font =
	Enum.Font.GothamBold

Button.TextSize = 13

-- IMPORTANT:
-- Touchable, but NOT draggable.
Button.Active = true
Button.Selectable = false
Button.AutoButtonColor = true

Button.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,13)
Corner.Parent = Button

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(150,150,160)
Stroke.Parent = Button

--==================================================
-- TRACER
--==================================================

local Tracer = Instance.new("Frame")

Tracer.Name = "CamlockTracer"

Tracer.AnchorPoint =
	Vector2.new(0,0.5)

Tracer.BackgroundColor3 =
	Color3.fromRGB(245,245,245)

Tracer.BorderSizePixel = 0

Tracer.Size =
	UDim2.fromOffset(0,2)

Tracer.Visible = false
Tracer.ZIndex = 50

Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius = UDim.new(1,0)
TracerCorner.Parent = Tracer

-- Target marker

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

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color = Color3.fromRGB(245,245,245)
DotStroke.Parent = TargetDot

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1,0)
DotCorner.Parent = TargetDot

--==================================================
-- TARGET CHECK
--==================================================

local function ValidTarget(Root)

	if not Root or not Root.Parent then
		return false
	end

	local Humanoid =
		Root.Parent:FindFirstChildOfClass("Humanoid")

	return Humanoid
		and Humanoid.Health > 0
end

--==================================================
-- PREDICTION
--==================================================

local function PredictedPosition(Root)

	return Root.Position +
		(Root.AssemblyLinearVelocity * PREDICTION)

end

--==================================================
-- FIND CLOSEST TARGET TO CENTER
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
	local BestDistance = math.huge

	-- 180 degree field
	local MinimumDot =
		math.cos(math.rad(FOV / 2))

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			local Character =
				Player.Character

			if Character then

				local Humanoid =
					Character:FindFirstChildOfClass("Humanoid")

				local Root =
					Character:FindFirstChild("HumanoidRootPart")

				if Humanoid
					and Root
					and Humanoid.Health > 0 then

					local Offset =
						Root.Position - CameraPosition

					local Distance =
						Offset.Magnitude

					if Distance <= MAX_DISTANCE
						and Distance > 0 then

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

								local ScreenPoint =
									Vector2.new(
										ScreenPosition.X,
										ScreenPosition.Y
									)

								local ScreenDistance =
									(ScreenPoint - Center).Magnitude

								if ScreenDistance <
									BestDistance then

									BestDistance =
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
-- TRACER
--==================================================

local function HideTracer()

	Tracer.Visible = false
	TargetDot.Visible = false

end

local function UpdateTracer(Root)

	if not Enabled or not ValidTarget(Root) then

		HideTracer()
		return
	end

	local Camera =
		workspace.CurrentCamera

	if not Camera then

		HideTracer()
		return
	end

	local Position =
		PredictedPosition(Root)

	local ScreenPosition, Visible =
		Camera:WorldToScreenPoint(Position)

	if not Visible
		or ScreenPosition.Z <= 0 then

		HideTracer()
		return
	end

	-- Exact center of screen
	local Start =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	local Finish =
		Vector2.new(
			ScreenPosition.X,
			ScreenPosition.Y
		)

	local Difference =
		Finish - Start

	local Length =
		Difference.Magnitude

	if Length < 1 then

		HideTracer()
		return
	end

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

	TargetDot.Position =
		UDim2.fromOffset(
			Finish.X,
			Finish.Y
		)

	TargetDot.Visible = true
end

--==================================================
-- SINGLE TOUCH BUTTON
--==================================================

Button.Activated:Connect(function()

	Enabled = not Enabled

	if Enabled then

		Target = FindTarget()

		Button.Text =
			"IVORY CAMLOCK • ON"

		Button.BackgroundColor3 =
			Color3.fromRGB(65,65,75)

	else

		Target = nil

		Button.Text =
			"IVORY CAMLOCK • OFF"

		Button.BackgroundColor3 =
			Color3.fromRGB(25,25,30)

		HideTracer()
	end
end)

--==================================================
-- CAMLOCK LOOP
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function()

		if not Enabled then
			return
		end

		-- Find a new target if needed
		if not ValidTarget(Target) then

			Target = FindTarget()

			if not Target then

				HideTracer()
				return
			end
		end

		-- Tracer always shows the same
		-- predicted position Camlock uses.
		UpdateTracer(Target)

		local Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		local AimPosition =
			PredictedPosition(Target)

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
)
