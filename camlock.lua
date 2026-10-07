--// IVORY'S CAMLOCK
--// Mobile version
--// LocalScript -> StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local PREDICTION = 0.12
local MAX_DISTANCE = 300

-- ALWAYS 180 DEGREES
local FOV_ANGLE = 180

--==================================================
-- STATE
--==================================================

local FeatureEnabled = false
local CamlockEnabled = false
local TracerEnabled = false

local LockedTarget = nil

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "IvorysCamlock"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

--==================================================
-- MAIN PANEL
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(180, 150)
Main.Position = UDim2.new(1, -200, 0.5, -75)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.35
MainStroke.Color = Color3.fromRGB(150, 150, 160)
MainStroke.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 30)
Title.Position = UDim2.fromOffset(5, 5)
Title.BackgroundTransparency = 1
Title.Text = "Ivory's Camlock"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.Parent = Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function MakeButton(name, text, y)

	local Button = Instance.new("TextButton")

	Button.Name = name
	Button.Size = UDim2.new(1, -20, 0, 32)
	Button.Position = UDim2.fromOffset(10, y)

	Button.BackgroundColor3 = Color3.fromRGB(43, 43, 50)
	Button.BorderSizePixel = 0

	Button.Text = text
	Button.TextColor3 = Color3.fromRGB(240, 240, 240)

	Button.Font = Enum.Font.GothamSemibold
	Button.TextSize = 13

	Button.AutoButtonColor = true

	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 9)
	Corner.Parent = Button

	return Button
end

local FeatureButton =
	MakeButton(
		"FeatureButton",
		"CAMLOCK FEATURE  •  OFF",
		40
	)

local TracerButton =
	MakeButton(
		"TracerButton",
		"TRACER  •  OFF",
		78
	)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 22)
Status.Position = UDim2.fromOffset(10, 118)
Status.BackgroundTransparency = 1
Status.Text = "READY"
Status.TextColor3 = Color3.fromRGB(160, 160, 165)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = Main

--==================================================
-- FLOATING CAMLOCK BUTTON
--==================================================

local FloatingButton = Instance.new("TextButton")

FloatingButton.Name = "FloatingCamlock"
FloatingButton.Size = UDim2.fromOffset(125, 48)
FloatingButton.Position = UDim2.new(0.5, -62, 0.78, 0)

FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
FloatingButton.BackgroundTransparency = 0.05

FloatingButton.BorderSizePixel = 0

FloatingButton.Text = "CAMLOCK  •  OFF"
FloatingButton.TextColor3 = Color3.fromRGB(245, 245, 245)

FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.TextSize = 13

FloatingButton.Visible = false
FloatingButton.ZIndex = 50

FloatingButton.Parent = Gui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 13)
FloatingCorner.Parent = FloatingButton

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Thickness = 1.5
FloatingStroke.Color = Color3.fromRGB(150, 150, 160)
FloatingStroke.Transparency = 0.25
FloatingStroke.Parent = FloatingButton

--==================================================
-- TARGET TRACER
--==================================================

local Tracer = Instance.new("Frame")

Tracer.Name = "TargetTracer"

Tracer.AnchorPoint = Vector2.new(0, 0.5)

Tracer.BackgroundColor3 =
	Color3.fromRGB(240, 240, 245)

Tracer.BackgroundTransparency = 0.05

Tracer.BorderSizePixel = 0

Tracer.Size = UDim2.fromOffset(0, 2)

Tracer.Visible = false

Tracer.ZIndex = 40

Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius = UDim.new(1, 0)
TracerCorner.Parent = Tracer

-- Target dot
local TargetDot = Instance.new("Frame")

TargetDot.Name = "TargetDot"

TargetDot.AnchorPoint = Vector2.new(0.5, 0.5)

TargetDot.Size = UDim2.fromOffset(12, 12)

TargetDot.BackgroundTransparency = 1
TargetDot.BorderSizePixel = 0

TargetDot.Visible = false

TargetDot.ZIndex = 41

TargetDot.Parent = Gui

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color = Color3.fromRGB(240, 240, 245)
DotStroke.Parent = TargetDot

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = TargetDot

--==================================================
-- TARGET SELECTION
--==================================================

local function IsValidTarget(root)

	if not root then
		return false
	end

	if not root.Parent then
		return false
	end

	local Character = root.Parent

	local Humanoid =
		Character:FindFirstChildOfClass("Humanoid")

	if not Humanoid then
		return false
	end

	if Humanoid.Health <= 0 then
		return false
	end

	return true
end

local function GetPredictedPosition(root)

	return root.Position +
		(root.AssemblyLinearVelocity * PREDICTION)

end

local function GetTarget()

	local Camera = workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local CameraPosition =
		Camera.CFrame.Position

	local CameraLook =
		Camera.CFrame.LookVector

	local Closest = nil
	local ClosestScreenDistance = math.huge

	-- 180 degree front hemisphere
	local MinimumDot =
		math.cos(math.rad(FOV_ANGLE / 2))

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			local Character = Player.Character

			if Character then

				local Humanoid =
					Character:FindFirstChildOfClass("Humanoid")

				local Root =
					Character:FindFirstChild("HumanoidRootPart")

				if Humanoid and Root and Humanoid.Health > 0 then

					local Offset =
						Root.Position - CameraPosition

					local Distance =
						Offset.Magnitude

					if Distance > 0 and Distance <= MAX_DISTANCE then

						local Direction =
							Offset.Unit

						local Dot =
							CameraLook:Dot(Direction)

						-- 180 degree range
						if Dot >= MinimumDot then

							local ScreenPosition, Visible =
								Camera:WorldToViewportPoint(
									Root.Position
								)

							if Visible and ScreenPosition.Z > 0 then

								local Center =
									Vector2.new(
										Camera.ViewportSize.X / 2,
										Camera.ViewportSize.Y / 2
									)

								local TargetScreen =
									Vector2.new(
										ScreenPosition.X,
										ScreenPosition.Y
									)

								local ScreenDistance =
									(TargetScreen - Center).Magnitude

								if ScreenDistance <
									ClosestScreenDistance then

									ClosestScreenDistance =
										ScreenDistance

									Closest = Root
								end
							end
						end
					end
				end
			end
		end
	end

	return Closest
end

--==================================================
-- TRACER
--==================================================

local function HideTracer()

	Tracer.Visible = false
	TargetDot.Visible = false

end

local function UpdateTracer(Target)

	if not FeatureEnabled then
		HideTracer()
		return
	end

	if not TracerEnabled then
		HideTracer()
		return
	end

	if not IsValidTarget(Target) then
		HideTracer()
		return
	end

	local Camera = workspace.CurrentCamera

	if not Camera then
		HideTracer()
		return
	end

	-- IMPORTANT:
	-- This is the exact same prediction used by Camlock.
	local Position3D =
		GetPredictedPosition(Target)

	local ScreenPosition, Visible =
		Camera:WorldToViewportPoint(
			Position3D
		)

	if not Visible or ScreenPosition.Z <= 0 then
		HideTracer()
		return
	end

	local Start =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	local End =
		Vector2.new(
			ScreenPosition.X,
			ScreenPosition.Y
		)

	local Difference =
		End - Start

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
			End.X,
			End.Y
		)

	TargetDot.Visible = true

end

--==================================================
-- CAMLOCK FEATURE TOGGLE
--==================================================

FeatureButton.Activated:Connect(function()

	FeatureEnabled = not FeatureEnabled

	if FeatureEnabled then

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  ON"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(65, 65, 75)

		Status.Text =
			"CAMLOCK BUTTON ACTIVE"

		-- THIS IS THE IMPORTANT PART:
		-- The actual touchable Camlock button appears
		-- over the game.
		FloatingButton.Visible = true

	else

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  OFF"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(43, 43, 50)

		Status.Text = "READY"

		CamlockEnabled = false
		LockedTarget = nil

		FloatingButton.Text =
			"CAMLOCK  •  OFF"

		FloatingButton.BackgroundColor3 =
			Color3.fromRGB(25, 25, 30)

		FloatingButton.Visible = false

		HideTracer()

	end
end)

--==================================================
-- TRACER TOGGLE
--==================================================

TracerButton.Activated:Connect(function()

	if not FeatureEnabled then
		return
	end

	TracerEnabled = not TracerEnabled

	if TracerEnabled then

		TracerButton.Text =
			"TRACER  •  ON"

		TracerButton.BackgroundColor3 =
			Color3.fromRGB(65, 65, 75)

	else

		TracerButton.Text =
			"TRACER  •  OFF"

		TracerButton.BackgroundColor3 =
			Color3.fromRGB(43, 43, 50)

		HideTracer()

	end
end)

--==================================================
-- FLOATING CAMLOCK BUTTON
--==================================================

FloatingButton.Activated:Connect(function()

	if not FeatureEnabled then
		return
	end

	CamlockEnabled = not CamlockEnabled

	if CamlockEnabled then

		-- Select the exact target currently previewed
		-- by the tracer.
		LockedTarget = GetTarget()

		FloatingButton.Text =
			"CAMLOCK  •  ON"

		FloatingButton.BackgroundColor3 =
			Color3.fromRGB(65, 65, 75)

		Status.Text =
			LockedTarget and "TARGET LOCKED"
			or "NO TARGET"

	else

		LockedTarget = nil

		FloatingButton.Text =
			"CAMLOCK  •  OFF"

		FloatingButton.BackgroundColor3 =
			Color3.fromRGB(25, 25, 30)

		Status.Text =
			"CAMLOCK BUTTON ACTIVE"

	end
end)

--==================================================
-- MAKE FLOATING BUTTON DRAGGABLE
--==================================================

local Dragging = false
local DragStart
local StartPosition

FloatingButton.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseButton1 then

		Dragging = true

		DragStart = Input.Position
		StartPosition = FloatingButton.Position

	end
end)

FloatingButton.InputChanged:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseMovement then

		-- handled below
	end
end)

UserInputService.InputChanged:Connect(function(Input)

	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.Touch
		and Input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local Delta =
		Input.Position - DragStart

	FloatingButton.Position =
		UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)

end)

UserInputService.InputEnded:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseButton1 then

		Dragging = false

	end
end)

--==================================================
-- CAMERA + TARGET UPDATE
--==================================================

RunService:BindToRenderStep(
	"IvorysCamlock",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not FeatureEnabled then
			return
		end

		-- If we're NOT locked:
		-- continuously preview the target.
		if not CamlockEnabled then

			local PreviewTarget =
				GetTarget()

			UpdateTracer(PreviewTarget)

			return
		end

		-- If target died/disappeared,
		-- automatically select another valid target.
		if not IsValidTarget(LockedTarget) then

			LockedTarget =
				GetTarget()

			if not LockedTarget then
				CamlockEnabled = false

				FloatingButton.Text =
					"CAMLOCK  •  OFF"

				FloatingButton.BackgroundColor3 =
					Color3.fromRGB(25, 25, 30)

				Status.Text =
					"NO TARGET"

				return
			end
		end

		-- Update tracer to the locked target.
		UpdateTracer(LockedTarget)

		-- Camera lock.
		local Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		local PredictedPosition =
			GetPredictedPosition(
				LockedTarget
			)

		Camera.CFrame =
			CFrame.lookAt(
				Camera.CFrame.Position,
				PredictedPosition
			)

	end
)
