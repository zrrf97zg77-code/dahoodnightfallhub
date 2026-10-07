--// IVORY'S CAMLOCK
--// Mobile LocalScript
--// Put inside StarterPlayer > StarterPlayerScripts

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
local SMOOTHNESS = 0.18

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
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 1000
Gui.Parent = PlayerGui

--==================================================
-- GUI TOGGLE
--==================================================

local GuiToggle = Instance.new("TextButton")
GuiToggle.Name = "GuiToggle"
GuiToggle.Size = UDim2.fromOffset(58, 58)
GuiToggle.Position = UDim2.fromOffset(20, 220)
GuiToggle.BackgroundColor3 = Color3.fromRGB(25,25,30)
GuiToggle.BorderSizePixel = 0
GuiToggle.Text = "IVORY"
GuiToggle.TextColor3 = Color3.fromRGB(245,245,245)
GuiToggle.Font = Enum.Font.GothamBold
GuiToggle.TextSize = 12
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
Main.Visible = true
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

local function MakeButton(name,text,y)

	local Button = Instance.new("TextButton")

	Button.Name = name
	Button.Size = UDim2.new(1,-20,0,34)
	Button.Position = UDim2.fromOffset(10,y)

	Button.BackgroundColor3 =
		Color3.fromRGB(43,43,50)

	Button.BorderSizePixel = 0

	Button.Text = text
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
-- SETTINGS BUTTONS
--==================================================

local FeatureButton = MakeButton(
	"FeatureButton",
	"CAMLOCK FEATURE  •  OFF",
	42
)

local TracerButton = MakeButton(
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
CamlockButton.Size = UDim2.fromOffset(135,50)

CamlockButton.Position =
	UDim2.new(0.5,-67,0.78,0)

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

Tracer.Name = "Tracer"
Tracer.AnchorPoint = Vector2.new(0,0.5)
Tracer.BackgroundColor3 = Color3.fromRGB(240,240,245)
Tracer.BorderSizePixel = 0
Tracer.Size = UDim2.fromOffset(0,2)
Tracer.Visible = false
Tracer.ZIndex = 100
Tracer.Parent = Gui

local TracerCorner = Instance.new("UICorner")
TracerCorner.CornerRadius = UDim.new(1,0)
TracerCorner.Parent = Tracer

local TargetDot = Instance.new("Frame")

TargetDot.Name = "TargetDot"
TargetDot.Size = UDim2.fromOffset(12,12)
TargetDot.AnchorPoint = Vector2.new(0.5,0.5)
TargetDot.BackgroundTransparency = 1
TargetDot.BorderSizePixel = 0
TargetDot.Visible = false
TargetDot.ZIndex = 101
TargetDot.Parent = Gui

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1,0)
DotCorner.Parent = TargetDot

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 2
DotStroke.Color = Color3.fromRGB(240,240,245)
DotStroke.Parent = TargetDot

--==================================================
-- TARGET CHECK
--==================================================

local function ValidTarget(root)

	if not root or not root.Parent then
		return false
	end

	local humanoid =
		root.Parent:FindFirstChildOfClass("Humanoid")

	return humanoid ~= nil and humanoid.Health > 0
end

--==================================================
-- PREDICTION
--==================================================

local function GetPredictedPosition(root)

	return root.Position +
		root.AssemblyLinearVelocity * PREDICTION

end

--==================================================
-- FIND TARGET
--==================================================

local function FindTarget()

	local Camera = workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local CameraPosition =
		Camera.CFrame.Position

	local CameraLook =
		Camera.CFrame.LookVector

	local BestTarget = nil
	local BestScreenDistance = math.huge

	-- 180 degrees
	local MinimumDot =
		math.cos(math.rad(FOV_ANGLE / 2))

	for _,Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			local Character = Player.Character

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
								Camera:WorldToViewportPoint(
									Root.Position
								)

							if Visible
								and ScreenPosition.Z > 0 then

								local Center =
									Vector2.new(
										Camera.ViewportSize.X/2,
										Camera.ViewportSize.Y/2
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

									BestTarget = Root
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

local function DrawTracer(Target)

	if not FeatureEnabled
		or not TracerEnabled
		or not ValidTarget(Target) then

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

	local ScreenPosition,Visible =
		Camera:WorldToViewportPoint(
			WorldPosition
		)

	if not Visible or ScreenPosition.Z <= 0 then
		HideTracer()
		return
	end

	local Start =
		Vector2.new(
			Camera.ViewportSize.X/2,
			Camera.ViewportSize.Y/2
		)

	local End =
		Vector2.new(
			ScreenPosition.X,
			ScreenPosition.Y
		)

	local Difference =
		End-Start

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
-- GUI TOGGLE
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
-- CAMLOCK TOGGLE
--==================================================

CamlockButton.Activated:Connect(function()

	if not FeatureEnabled then
		return
	end

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
end)

--==================================================
-- FIXED MOBILE DRAGGING
--==================================================

local function MakeDraggable(Button)

	local dragging = false
	local dragStart = nil
	local startPosition = nil

	local DRAG_THRESHOLD = 12

	Button.InputBegan:Connect(function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch
			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = true

			dragStart =
				Input.Position

			startPosition =
				Button.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)

		if not dragging then
			return
		end

		if Input.UserInputType ~=
			Enum.UserInputType.Touch
			and Input.UserInputType ~=
			Enum.UserInputType.MouseMovement then

			return
		end

		local Delta =
			Input.Position - dragStart

		-- Small movements are taps,
		-- NOT drags.
		if Delta.Magnitude < DRAG_THRESHOLD then
			return
		end

		Button.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + Delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + Delta.Y
			)
	end)

	UserInputService.InputEnded:Connect(function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch
			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false
		end
	end)
end

MakeDraggable(GuiToggle)
MakeDraggable(CamlockButton)

--==================================================
-- CAMERA LOOP
--==================================================

RunService:BindToRenderStep(
	"IvoryCamlock",
	Enum.RenderPriority.Camera.Value + 5,
	function()

		if not FeatureEnabled then
			return
		end

		-- Preview target
		if not CamlockEnabled then

			local Preview =
				FindTarget()

			DrawTracer(Preview)

			return
		end

		-- Get another target if current one disappears
		if not ValidTarget(CurrentTarget) then

			CurrentTarget =
				FindTarget()

			if not CurrentTarget then

				Status.Text =
					"SEARCHING..."

				DrawTracer(nil)

				return
			end
		end

		DrawTracer(CurrentTarget)

		local Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		local AimPosition =
			GetPredictedPosition(
				CurrentTarget
			)

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
