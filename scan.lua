-- This is a client-side script for use in an executor.
-- It creates a movable GUI that displays health status and the last attacker.

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorHealthInspectorGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorHealthInspectorGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- STATE VARIABLES --
local lastAttacker = "None"
local healthConnection = nil
local lastHealth = 0

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorHealthInspectorGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "InspectorFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 80)
mainFrame.Position = UDim2.new(0, 10, 0, 10) -- Top-left corner
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Text = "Health Inspector"
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.TextSize = 16
titleBar.Parent = mainFrame

local infoDisplay = Instance.new("TextLabel")
infoDisplay.Name = "InfoDisplay"
infoDisplay.Size = UDim2.new(1, -20, 1, -35) -- Padding
infoDisplay.Position = UDim2.new(0, 10, 0, 30)
infoDisplay.BackgroundColor3 = Color3.fromHSV(0, 0, 0)
infoDisplay.BackgroundTransparency = 1
infoDisplay.Font = Enum.Font.Code
infoDisplay.TextColor3 = Color3.fromRGB(240, 240, 240)
infoDisplay.TextSize = 14
infoDisplay.TextXAlignment = Enum.TextXAlignment.Left
infoDisplay.TextYAlignment = Enum.TextYAlignment.Top
infoDisplay.Parent = mainFrame

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

-- CORE LOGIC --
local function updateDisplay(humanoid)
    local health = math.floor(humanoid.Health)
    local maxHealth = math.floor(humanoid.MaxHealth)
    
    local idText = player.Name .. " (" .. player.UserId .. ")"
    local healthText = "Health: " .. health .. " / " .. maxHealth
    local attackerText = "Last Hit By: " .. lastAttacker
    
    infoDisplay.Text = idText .. "\n" .. healthText .. "\n" .. attackerText
end

local function onHealthChanged(newHealth)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Check if health went down (took damage)
    if newHealth < lastHealth then
        local creatorTag = humanoid:FindFirstChild("creator")
        if creatorTag and creatorTag.Value and creatorTag.Value:IsA("Player") then
            lastAttacker = creatorTag.Value.Name
        else
            -- If no creator tag, check what's touching the character
            local foundAttacker = false
            if character:FindFirstChild("HumanoidRootPart") then
                local touchingParts = character.HumanoidRootPart:GetTouchingParts()
                for _, part in ipairs(touchingParts) do
                    -- Make sure the part is not part of our own character
                    if part.Parent and not part:IsDescendantOf(character) then
                        if part.Parent:IsA("Model") and part.Parent.Name ~= "Workspace" then
                            -- Display as "ModelName (PartName)" for more detail
                            lastAttacker = part.Parent.Name .. " (" .. part.Name .. ")"
                        else
                            -- If the part's parent isn't a model, just show the part's name
                            lastAttacker = part.Name
                        end
                        foundAttacker = true
                        break -- We found the likely cause, so we can stop looking
                    end
                end
                if not foundAttacker then
                    lastAttacker = "Environmental" -- A better default if nothing is touching
                end
            else
                 lastAttacker = "Unknown Source" -- Fallback if no root part exists
            end
        end
    end

    lastHealth = newHealth
    updateDisplay(humanoid)
end

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    lastHealth = humanoid.Health
    lastAttacker = "None"
    
    if healthConnection then
        healthConnection:Disconnect()
    end
    healthConnection = humanoid.HealthChanged:Connect(onHealthChanged)
    
    -- Initial display update
    updateDisplay(humanoid)
end

-- HANDLE RESPAWNS --
player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    setupCharacter(player.Character)
end

-- CLEANUP --
screenGui.Destroying:Connect(function()
    if healthConnection then
        healthConnection:Disconnect()
    end
end)

print("Health Inspector loaded.")

