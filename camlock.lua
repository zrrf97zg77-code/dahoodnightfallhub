--// IVORY'S CAMLOCK
--// Mobile / LocalScript
--// StarterPlayer > StarterPlayerScripts

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
Main.Size = UDim2.fromOffset(190, 155)
Main.Position = UDim2.new(1, -210, 0.5, -78)

Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0

Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Color = Color3.fromRGB(150, 150, 160)
MainStroke.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 32)
Title.Position = UDim2.fromOffset(5, 5)

Title.BackgroundTransparency = 1
Title.Text = "Ivory's Camlock"

Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17

Title.Parent = Main

--==================================================
-- BUTTON FUNCTION
--==================================================

local function MakeButton(Name, Text, Y)

	local Button = Instance.new("TextButton")

	Button.Name = Name
	Button.Size = UDim2.new(1, -20, 0, 34)
	Button.Position = UDim2.fromOffset(10, Y)

	Button.BackgroundColor3 =
		Color3.fromRGB(43, 43, 50)

	Button.BorderSizePixel = 0

	Button.Text = Text
	Button.TextColor3 =
		Color3.fromRGB(240, 240, 240)

	Button.Font =
		Enum.Font.GothamSemibold

	Button.TextSize = 13

	Button.AutoButtonColor = true
	Button.Active = true

	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 9)
	Corner.Parent = Button

	return Button
end

--==================================================
-- MAIN TOGGLE BUTTON
--==================================================

local FeatureButton = MakeButton(
	"FeatureToggle",
	"CAMLOCK FEATURE  •  OFF",
	42
)

--==================================================
-- TRACER TOGGLE
--==================================================

local TracerButton = MakeButton(
	"TracerToggle",
	"TRACER  •  OFF",
	82
)

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")

Status.Size = UDim2.new(1, -20, 0, 22)
Status.Position = UDim2.fromOffset(10, 122)

Status.BackgroundTransparency = 1

Status.Text = "READY"
Status.TextColor3 =
	Color3.fromRGB(165, 165, 170)

Status.Font = Enum.Font.Gotham
Status.TextSize = 11

Status.Parent = Main

--==================================================
-- FLOATING CAMLOCK BUTTON
--==================================================

local FloatingButton = Instance.new("TextButton")

FloatingButton.Name = "CamlockButton"

FloatingButton.Size =
	UDim2.fromOffset(135, 50)

-- Initial position
FloatingButton.Position =
	UDim2.new(0.5, -67, 0.78, 0)

FloatingButton.BackgroundColor3 =
	Color3.fromRGB(25, 25, 30)

FloatingButton.BackgroundTransparency = 0.05

FloatingButton.BorderSizePixel = 0

FloatingButton.Text =
	"CAMLOCK  •  OFF"

FloatingButton.TextColor3 =
	Color3.fromRGB(245, 245, 245)

FloatingButton.Font =
	Enum.Font.GothamBold

FloatingButton.TextSize = 13

FloatingButton.Active = true
FloatingButton.Visible = false

FloatingButton.ZIndex = 100

FloatingButton.Parent = Gui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 13)
FloatCorner.Parent = FloatingButton

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 1.5
FloatStroke.Transparency = 0.25
FloatStroke.Color = Color3.fromRGB(150, 150, 160)
FloatStroke.Parent = FloatingButton

--==================================================
-- TRACER
--==================================================

local Tracer = Instance.new("Frame")

Tracer.Name = "TargetTracer"

Tracer.AnchorPoint =
	Vector2.new(0, 0.5)

Tracer.BackgroundColor3 =
	Color3.fromRGB(240, 240, 245)

Tracer.BorderSizePixel = 0

Tracer.Size =
	UDim2.fromOffset(0, 2)

Tracer.Visible = false
Tracer.ZIndex = 40

Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius = UDim.new(1, 0)
TracerCorner.Parent = Tracer

-- Target marker
local TargetDot = Instance.new("Frame")

TargetDot.Name = "TargetDot"

TargetDot.AnchorPoint =
	Vector2.new(0.5, 0.5)

TargetDot.Size =
	UDim2.fromOffset(12, 12)

TargetDot.BackgroundTransparency = 1
TargetDot.BorderSizePixel = 0

TargetDot.Visible = false
TargetDot.ZIndex = 41

TargetDot.Parent = Gui

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color =
	Color3.fromRGB(240, 240, 245)
DotStroke.Parent = TargetDot

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = TargetDot

--==================================================
-- TARGET CHECK
--==================================================

local function IsValidTarget(Root)

	if not Root then
		return false
	end

	if not Root.Parent then
		return false
	end

	local Character = Root.Parent

	local Humanoid =
		Character:FindFirstChildOfClass("Humanoid")

	if not Humanoid then
		return false
	end

	return Humanoid.Health > 0
end

--==================================================
-- PREDICTION
--==================================================

local function GetPredictedPosition(Root)

	return Root.Position +
		(Root.AssemblyLinearVelocity * PREDICTION)

end

--==================================================
-- GET TARGET
--==================================================

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

	-- Fixed 180 degree range
	local MinimumDot =
		math.cos(math.rad(FOV_ANGLE / 2))

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			local Character =
				Player.Character

			if Character then

				local Humanoid =
					Character:FindFirstChildOfClass("Humanoid")

				local Root =
					Character:FindFirstChild("HumanoidRootPart")

				if Humanoid and Root then

					if Humanoid.Health > 0 then

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

							-- 180 degree front hemisphere
							if Dot >= MinimumDot then

								local ScreenPosition, Visible =
									Camera:WorldToViewportPoint(
										Root.Position
									)

								if Visible and
									ScreenPosition.Z > 0 then

									local Center =
										Vector2.new(
											Camera.ViewportSize.X / 2,
											Camera.ViewportSize.Y / 2
										)

									local ScreenTarget =
										Vector2.new(
											ScreenPosition.X,
											ScreenPosition.Y
										)

									local ScreenDistance =
										(ScreenTarget - Center).Magnitude

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
	end

	return Closest
end

--==================================================
-- HIDE TRACER
--==================================================

local function HideTracer()

	Tracer.Visible = false
	TargetDot.Visible = false

end

--==================================================
-- UPDATE TRACER
--==================================================

local function UpdateTracer(Target)

	if not FeatureEnabled
		or not TracerEnabled
		or not IsValidTarget(Target) then

		HideTracer()
		return
	end

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		HideTracer()
		return
	end

	local WorldPosition =
		GetPredictedPosition(Target)

	local ScreenPosition, Visible =
		Camera:WorldToViewportPoint(
			WorldPosition
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
-- MAIN FEATURE TOGGLE
--==================================================

FeatureButton.Activated:Connect(function()

	FeatureEnabled =
		not FeatureEnabled

	if FeatureEnabled then

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  ON"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(65, 65, 75)

		-- The actual in-game button appears.
		FloatingButton.Visible = true

		Status.Text =
			"CAMLOCK BUTTON ACTIVE"

	else

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  OFF"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(43, 43, 50)

		CamlockEnabled = false
		LockedTarget = nil

		FloatingButton.Text =
			"CAMLOCK  •  OFF"

		FloatingButton.BackgroundColor3 =
			Color3.fromRGB(25, 25, 30)

		FloatingButton.Visible = false

		HideTracer()

		Status.Text = "READY"
	end
end)

--==================================================
-- TRACER TOGGLE
--==================================================

TracerButton.Activated:Connect(function()

	if not FeatureEnabled then
		return
	end

	TracerEnabled =
		not TracerEnabled

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
-- FLOATING BUTTON TOGGLE
--==================================================

FloatingButton.Activated:Connect(function()

	if not FeatureEnabled then
		return
	end

	-- Toggle regardless of whether a player is currently found.
	CamlockEnabled =
		not CamlockEnabled

	if CamlockEnabled then

		-- Select the target immediately.
		LockedTarget =
			GetTarget()

		FloatingButton.Text =
			"CAMLOCK  •  ON"

		FloatingButton.BackgroundColor3 =
			Color3.fromRGB(65, 65, 75)

		if LockedTarget then
			Status.Text = "TARGET LOCKED"
		else
			Status.Text = "WAITING FOR TARGET"
		end

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
-- PROPER MOBILE DRAGGING
--==================================================

local Dragging = false
local DragMoved = false

local DragStart = nil
local StartAbsolute = nil

FloatingButton.InputBegan:Connect(function(Input)

	if Input.UserInputType ==
		Enum.UserInputType.Touch then

		Dragging = true
		DragMoved = false

		DragStart = Input.Position
		StartAbsolute = FloatingButton.AbsolutePosition

	elseif Input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		Dragging = true
		DragMoved = false

		DragStart = Input.Position
		StartAbsolute = FloatingButton.AbsolutePosition
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

	if Delta.Magnitude > 6 then
		DragMoved = true
	end

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return
	end

	local Viewport =
		Camera.ViewportSize

	local NewX =
		StartAbsolute.X + Delta.X

	local NewY =
		StartAbsolute.Y + Delta.Y

	-- Keep button completely on screen.
	local ButtonWidth =
		FloatingButton.AbsoluteSize.X

	local ButtonHeight =
		FloatingButton.AbsoluteSize.Y

	NewX =
		math.clamp(
			NewX,
			0,
			Viewport.X - ButtonWidth
		)

	NewY =
		math.clamp(
			NewY,
			0,
			Viewport.Y - ButtonHeight
		)

	-- IMPORTANT:
	-- Use pure pixel offsets after dragging.
	FloatingButton.Position =
		UDim2.fromOffset(
			NewX,
			NewY
		)
end)

UserInputService.InputEnded:Connect(function(Input)

	if Input.UserInputType ==
		Enum.UserInputType.Touch
		or Input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		Dragging = false
	end
end)

--==================================================
-- CAMERA LOOP
--==================================================

RunService:BindToRenderStep(
	"IvorysCamlock",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not FeatureEnabled then
			return
		end

		-- Preview the target when not locked.
		if not CamlockEnabled then

			local Preview =
				GetTarget()

			UpdateTracer(Preview)

			return
		end

		-- If target disappears/dies,
		-- automatically find another one.
		if not IsValidTarget(LockedTarget) then

			LockedTarget =
				GetTarget()

			if not LockedTarget then

				Status.Text =
					"WAITING FOR TARGET"

				UpdateTracer(nil)

				return
			end
		end

		-- Tracer follows the same target.
		UpdateTracer(LockedTarget)

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
