-- This is a client-side script for use in an executor.
-- It creates a GUI slider to control your character's levitation force.

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorLevitationSliderGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorLevitationSliderGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- LOCAL PLAYER --
local player = Players.LocalPlayer
local bodyForce = nil

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorLevitationSliderGui"
screenGui.ResetOnSpawn = false -- Keeps the GUI when you respawn

local mainFrame = Instance.new("Frame")
mainFrame.Name = "SliderFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 80)
mainFrame.Position = UDim2.new(0.5, -150, 1, -100) -- Position at the bottom-center
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Levitation Control"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(0.9, 0, 0, 10)
sliderTrack.Position = UDim2.new(0.05, 0, 0, 50)
sliderTrack.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = mainFrame

local sliderThumb = Instance.new("TextButton")
sliderThumb.Name = "SliderThumb"
sliderThumb.Size = UDim2.new(0, 20, 0, 20)
sliderThumb.Position = UDim2.new(0, -10, 0, 45) -- Start at the beginning
sliderThumb.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
sliderThumb.BorderSizePixel = 0
sliderThumb.Text = ""
sliderThumb.Draggable = true
sliderThumb.Parent = mainFrame

-- Parent the GUI to the player's screen
screenGui.Parent = player.PlayerGui

-- LEVITATION LOGIC --
local function getCharacterMass(character)
    local mass = 0
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            mass = mass + part:GetMass()
        end
    end
    return mass
end

local function updateLevitationForce()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    
    -- Create the BodyForce if it doesn't exist
    if not bodyForce or bodyForce.Parent ~= rootPart then
        if bodyForce then bodyForce:Destroy() end
        bodyForce = Instance.new("BodyForce")
        bodyForce.Name = "LevitationForce"
        bodyForce.Parent = rootPart
    end
    
    -- Calculate the force needed to hover
    local mass = getCharacterMass(character)
    local hoverForce = mass * Workspace.Gravity
    
    -- Set the max force to be double the hover force for a good range of control
    local MAX_FORCE = hoverForce * 2
    
    local trackWidth = sliderTrack.AbsoluteSize.X
    local thumbPosition = sliderThumb.Position.X.Offset
    
    local percentage = math.clamp(thumbPosition / trackWidth, 0, 1)
    local appliedForce = MAX_FORCE * percentage
    
    titleLabel.Text = "Force: " .. math.floor(appliedForce)
    
    -- Apply the force on the Y-axis (upward)
    bodyForce.Force = Vector3.new(0, appliedForce, 0)
end

-- Handle dragging the slider
sliderThumb.DragStopped:Connect(function()
    sliderThumb.Position = UDim2.new(sliderThumb.Position.X.Scale, sliderThumb.Position.X.Offset, 0, 45)
end)

sliderThumb:GetPropertyChangedSignal("Position"):Connect(function()
    local trackWidth = sliderTrack.AbsoluteSize.X
    local newX = math.clamp(sliderThumb.Position.X.Offset, 0, trackWidth)
    sliderThumb.Position = UDim2.new(0, newX, 0, 45)
    
    updateLevitationForce()
end)

-- Clean up the BodyForce when the GUI is removed
screenGui.Destroying:Connect(function()
    if bodyForce then
        bodyForce:Destroy()
        bodyForce = nil
    end
end)


-- Initialize
updateLevitationForce()

print("Levitation Slider loaded.")

