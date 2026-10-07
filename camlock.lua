--// IVORY'S CAMLOCK
--// FINAL MOBILE VERSION
--// LocalScript -> StarterPlayer > StarterPlayerScripts

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
local FOV_ANGLE = 180

-- Lower = smoother
local SMOOTHNESS = 0.16

-- How far finger must move before it becomes a drag
local DRAG_THRESHOLD = 14

--==================================================
-- STATE
--==================================================

local FeatureEnabled = false
local CamlockEnabled = false
local TracerEnabled = false

local CurrentTarget = nil

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "IvorysCamlock"
Gui.ResetOnSpawn = false

-- IMPORTANT:
-- Keep GUI coordinates aligned with WorldToScreenPoint()
Gui.IgnoreGuiInset = false

Gui.DisplayOrder = 1000
Gui.Parent = PlayerGui

--==================================================
-- GUI OPEN/CLOSE BUTTON
--==================================================

local GuiToggle = Instance.new("TextButton")

GuiToggle.Name = "IvoryToggle"
GuiToggle.Size = UDim2.fromOffset(58, 58)
GuiToggle.Position = UDim2.fromOffset(20, 215)

GuiToggle.BackgroundColor3 = Color3.fromRGB(25,25,30)
GuiToggle.BorderSizePixel = 0

GuiToggle.Text = "IVORY"
GuiToggle.TextColor3 = Color3.fromRGB(245,245,245)
GuiToggle.Font = Enum.Font.GothamBold
GuiToggle.TextSize = 12

GuiToggle.AutoButtonColor = true
GuiToggle.Active = true
GuiToggle.ZIndex = 200

GuiToggle.Parent = Gui

local GuiCorner = Instance.new("UICorner")
GuiCorner.CornerRadius = UDim.new(1,0)
GuiCorner.Parent = GuiToggle

local GuiStroke = Instance.new("UIStroke")
GuiStroke.Thickness = 1.5
GuiStroke.Color = Color3.fromRGB(150,150,160)
GuiStroke.Parent = GuiToggle

--==================================================
-- MAIN PANEL
--==================================================

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.Size = UDim2.fromOffset(190,155)
Main.Position = UDim2.new(1,-210,0.5,-75)

Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0

Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Color = Color3.fromRGB(150,150,160)
MainStroke.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1,-10,0,32)
Title.Position = UDim2.fromOffset(5,5)

Title.BackgroundTransparency = 1

Title.Text = "Ivory's Camlock"
Title.TextColor3 = Color3.fromRGB(245,245,245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17

Title.Parent = Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(Name,Text,Y)

	local Button = Instance.new("TextButton")

	Button.Name = Name
	Button.Size = UDim2.new(1,-20,0,34)
	Button.Position = UDim2.fromOffset(10,Y)

	Button.BackgroundColor3 =
		Color3.fromRGB(43,43,50)

	Button.BorderSizePixel = 0

	Button.Text = Text
	Button.TextColor3 =
		Color3.fromRGB(240,240,240)

	Button.Font =
		Enum.Font.GothamSemibold

	Button.TextSize = 13

	Button.Active = true
	Button.AutoButtonColor = true

	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,9)
	Corner.Parent = Button

	return Button
end

--==================================================
-- PANEL BUTTONS
--==================================================

local FeatureButton = CreateButton(
	"FeatureButton",
	"CAMLOCK FEATURE  •  OFF",
	42
)

local TracerButton = CreateButton(
	"TracerButton",
	"TRACER  •  OFF",
	82
)

local Status = Instance.new("TextLabel")

Status.Size = UDim2.new(1,-20,0,22)
Status.Position = UDim2.fromOffset(10,122)

Status.BackgroundTransparency = 1

Status.Text = "READY"
Status.TextColor3 = Color3.fromRGB(165,165,170)

Status.Font = Enum.Font.Gotham
Status.TextSize = 11

Status.Parent = Main

--==================================================
-- FLOATING CAMLOCK BUTTON
--==================================================

local CamlockButton = Instance.new("TextButton")

CamlockButton.Name = "CamlockButton"

CamlockButton.Size =
	UDim2.fromOffset(145,52)

CamlockButton.Position =
	UDim2.new(0.5,-72,0.78,0)

CamlockButton.BackgroundColor3 =
	Color3.fromRGB(25,25,30)

CamlockButton.BorderSizePixel = 0

CamlockButton.Text =
	"CAMLOCK  •  OFF"

CamlockButton.TextColor3 =
	Color3.fromRGB(245,245,245)

CamlockButton.Font =
	Enum.Font.GothamBold

CamlockButton.TextSize = 13

CamlockButton.Active = true
CamlockButton.Visible = false

CamlockButton.ZIndex = 200

CamlockButton.Parent = Gui

local CamCorner = Instance.new("UICorner")
CamCorner.CornerRadius = UDim.new(0,13)
CamCorner.Parent = CamlockButton

local CamStroke = Instance.new("UIStroke")
CamStroke.Thickness = 1.5
CamStroke.Color = Color3.fromRGB(150,150,160)
CamStroke.Parent = CamlockButton

--==================================================
-- TRACER
--==================================================

local Tracer = Instance.new("Frame")

Tracer.Name = "TargetTracer"

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
DotCorner.CornerRadius = UDim.new(1,0)
DotCorner.Parent = TargetDot

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color = Color3.fromRGB(245,245,245)
DotStroke.Parent = TargetDot

--==================================================
-- TARGET VALIDATION
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
-- TARGET SELECTION
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
		math.cos(math.rad(FOV_ANGLE / 2))

	for _,Player in ipairs(Players:GetPlayers()) do

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

					if Distance > 0
						and Distance <= MAX_DISTANCE then

						local Direction =
							Offset.Unit

						local Dot =
							CameraLook:Dot(Direction)

						if Dot >= MinimumDot then

							local ScreenPosition,Visible =
								Camera:WorldToScreenPoint(
									Root.Position
								)

							if Visible
								and ScreenPosition.Z > 0 then

								local Center =
									Vector2.new(
										Gui.AbsoluteSize.X / 2,
										Gui.AbsoluteSize.Y / 2
									)

								local TargetScreen =
									Vector2.new(
										ScreenPosition.X,
										ScreenPosition.Y
									)

								local ScreenDistance =
									(TargetScreen-Center).Magnitude

								if ScreenDistance <
									BestScreenDistance then

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
-- TRACER
--==================================================

local function HideTracer()

	Tracer.Visible = false
	TargetDot.Visible = false

end

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

	-- Use WorldToScreenPoint so the coordinates
	-- match the ScreenGui's coordinate system.
	local ScreenPosition,Visible =
		Camera:WorldToScreenPoint(
			GetPredictedPosition(Target)
		)

	if not Visible
		or ScreenPosition.Z <= 0 then

		HideTracer()
		return
	end

	-- Actual center of the player's screen.
	local Start =
		Vector2.new(
			Gui.AbsoluteSize.X / 2,
			Gui.AbsoluteSize.Y / 2
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

	-- Draw from exact screen center
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
-- GUI BUTTON
--==================================================

GuiToggle.Activated:Connect(function()

	Main.Visible =
		not Main.Visible

end)

--==================================================
-- FEATURE TOGGLE
--==================================================

FeatureButton.Activated:Connect(function()

	FeatureEnabled =
		not FeatureEnabled

	if FeatureEnabled then

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  ON"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(65,65,75)

		CamlockButton.Visible = true

		Status.Text =
			"CAMLOCK READY"

	else

		FeatureButton.Text =
			"CAMLOCK FEATURE  •  OFF"

		FeatureButton.BackgroundColor3 =
			Color3.fromRGB(43,43,50)

		CamlockEnabled = false
		CurrentTarget = nil

		CamlockButton.Visible = false

		CamlockButton.Text =
			"CAMLOCK  •  OFF"

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
			Color3.fromRGB(65,65,75)

	else

		TracerButton.Text =
			"TRACER  •  OFF"

		TracerButton.BackgroundColor3 =
			Color3.fromRGB(43,43,50)

		HideTracer()
	end
end)

--==================================================
-- CAMLOCK TOUCH CONTROL
--==================================================

local TouchStart = nil
local ButtonStart = nil
local IsDragging = false
local ActiveTouch = nil

local function ClampButtonPosition(X,Y)

	local ScreenSize =
		Gui.AbsoluteSize

	local ButtonSize =
		CamlockButton.AbsoluteSize

	X = math.clamp(
		X,
		0,
		math.max(0,ScreenSize.X-ButtonSize.X)
	)

	Y = math.clamp(
		Y,
		0,
		math.max(0,ScreenSize.Y-ButtonSize.Y)
	)

	return X,Y
end

CamlockButton.InputBegan:Connect(function(Input)

	if Input.UserInputType ==
		Enum.UserInputType.Touch then

		ActiveTouch = Input

		TouchStart =
			Input.Position

		ButtonStart =
			CamlockButton.AbsolutePosition

		IsDragging = false

	elseif Input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		ActiveTouch = Input

		TouchStart =
			Input.Position

		ButtonStart =
			CamlockButton.AbsolutePosition

		IsDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(Input)

	if not ActiveTouch then
		return
	end

	if Input.UserInputType ~=
		Enum.UserInputType.Touch
		and Input.UserInputType ~=
		Enum.UserInputType.MouseMovement then

		return
	end

	local Delta =
		Input.Position - TouchStart

	if not IsDragging then

		if Delta.Magnitude < DRAG_THRESHOLD then
			return
		end

		IsDragging = true
	end

	local NewX =
		ButtonStart.X + Delta.X

	local NewY =
		ButtonStart.Y + Delta.Y

	NewX,NewY =
		ClampButtonPosition(
			NewX,
			NewY
		)

	CamlockButton.Position =
		UDim2.fromOffset(
			NewX,
			NewY
		)
end)

UserInputService.InputEnded:Connect(function(Input)

	if Input ~= ActiveTouch then
		return
	end

	-- If the finger barely moved,
	-- treat it as a TAP.
	if not IsDragging then

		if FeatureEnabled then

			CamlockEnabled =
				not CamlockEnabled

			if CamlockEnabled then

				CurrentTarget =
					FindTarget()

				CamlockButton.Text =
					"CAMLOCK  •  ON"

				CamlockButton.BackgroundColor3 =
					Color3.fromRGB(65,65,75)

				Status.Text =
					CurrentTarget
					and "TARGET LOCKED"
					or "SEARCHING..."

			else

				CurrentTarget = nil

				CamlockButton.Text =
					"CAMLOCK  •  OFF"

				CamlockButton.BackgroundColor3 =
					Color3.fromRGB(25,25,30)

				Status.Text =
					"CAMLOCK READY"
			end
		end
	end

	ActiveTouch = nil
	TouchStart = nil
	ButtonStart = nil
	IsDragging = false
end)

--==================================================
-- CAMERA
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function()

		if not FeatureEnabled then
			return
		end

		-- Preview the exact target
		if not CamlockEnabled then

			local Preview =
				FindTarget()

			UpdateTracer(Preview)

			return
		end

		-- Get a new target if necessary
		if not IsValidTarget(CurrentTarget) then

			CurrentTarget =
				FindTarget()

			if not CurrentTarget then

				Status.Text =
					"SEARCHING..."

				UpdateTracer(nil)

				return
			end
		end

		-- Tracer follows same target
		UpdateTracer(CurrentTarget)

		local Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		local AimPosition =
			GetPredictedPosition(
				CurrentTarget
			)

		local Desired =
			CFrame.lookAt(
				Camera.CFrame.Position,
				AimPosition
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				Desired,
				SMOOTHNESS
			)
	end
)
