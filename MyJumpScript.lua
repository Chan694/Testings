-- This is a client-side script for use in an executor.
-- It creates a GUI slider to control your own jump power.

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorJumpSliderGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorJumpSliderGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")

-- CONFIGURATION --
local MIN_JUMP_POWER = 50 -- The normal, default jump power
local MAX_JUMP_POWER = 200 -- The maximum jump power the slider can go to

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorJumpSliderGui"
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
titleLabel.Text = "Jump Power"
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

-- SLIDER LOGIC --
local function updateJumpPower()
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    local humanoid = character.Humanoid
    
    local trackWidth = sliderTrack.AbsoluteSize.X
    local thumbPosition = sliderThumb.Position.X.Offset
    
    local percentage = math.clamp(thumbPosition / trackWidth, 0, 1)
    local jumpPower = MIN_JUMP_POWER + (MAX_JUMP_POWER - MIN_JUMP_POWER) * percentage
    
    titleLabel.Text = "Jump Power: " .. math.floor(jumpPower)
    
    -- Directly change your humanoid's JumpPower
    humanoid.JumpPower = jumpPower
end

-- Handle dragging the slider
sliderThumb.DragStopped:Connect(function()
    sliderThumb.Position = UDim2.new(sliderThumb.Position.X.Scale, sliderThumb.Position.X.Offset, 0, 45)
end)

sliderThumb:GetPropertyChangedSignal("Position"):Connect(function()
    local trackWidth = sliderTrack.AbsoluteSize.X
    local newX = math.clamp(sliderThumb.Position.X.Offset, 0, trackWidth)
    sliderThumb.Position = UDim2.new(0, newX, 0, 45)
    
    updateJumpPower()
end)

-- Initialize
updateJumpPower()

print("Jump Power Slider loaded.")
