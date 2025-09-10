-- This is a client-side script for use in an executor.
-- It creates a movable GUI to toggle "God Mode" (immortality).

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorGodModeGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorGodModeGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- GOD MODE STATE --
local isGodMode = false
local healthConnection = nil

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorGodModeGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "GodModeFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 40)
mainFrame.Position = UDim2.new(0.5, -100, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleButton.Text = "God Mode: OFF [G]"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextColor3 = Color3.fromRGB(255, 80, 80)
toggleButton.TextSize = 18
toggleButton.Parent = mainFrame

screenGui.Parent = player.PlayerGui

-- WINDOW DRAGGING LOGIC --
local dragging = false
local dragInput, frameStartPosition, dragStartPosition
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        frameStartPosition = mainFrame.Position
        dragStartPosition = Vector2.new(input.Position.X, input.Position.Y)
    end
end)
mainFrame.InputEnded:Connect(function(input)
    if input == dragInput then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPosition
        mainFrame.Position = UDim2.new(frameStartPosition.X.Scale, frameStartPosition.X.Offset + delta.X, frameStartPosition.Y.Scale, frameStartPosition.Y.Offset + delta.Y)
    end
end)

-- GOD MODE LOGIC --
local function enableGodMode()
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    local humanoid = character:FindFirstChild("Humanoid")

    -- Disconnect any old connection to prevent duplicates
    if healthConnection then healthConnection:Disconnect() end

    humanoid.Health = humanoid.MaxHealth -- Heal instantly on enable
    
    healthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        -- We check > 0 to still allow death from falling out of the map (health set to 0)
        if newHealth < humanoid.MaxHealth and newHealth > 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    isGodMode = true
    toggleButton.Text = "God Mode: ON [G]"
    toggleButton.TextColor3 = Color3.fromRGB(80, 255, 80)
end

local function disableGodMode()
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end
    
    isGodMode = false
    toggleButton.Text = "God Mode: OFF [G]"
    toggleButton.TextColor3 = Color3.fromRGB(255, 80, 80)
end

local function toggleGodMode()
    if isGodMode then
        disableGodMode()
    else
        enableGodMode()
    end
end

-- INPUT HANDLING --
toggleButton.MouseButton1Click:Connect(toggleGodMode)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        toggleGodMode()
    end
end)

-- HANDLE RESPAWNS --
player.CharacterAdded:Connect(function(character)
    -- If god mode was active before dying, re-enable it for the new character.
    if isGodMode then
        -- A small delay to ensure the Humanoid is fully loaded before we access it
        task.wait(0.1)
        enableGodMode()
    end
end)

-- CLEANUP --
screenGui.Destroying:Connect(disableGodMode)

print("God Mode Script loaded. Press 'G' to toggle.")

