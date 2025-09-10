-- This is a client-side script for use in an executor.
-- It creates a movable GUI to toggle "God Mode" (immortality) and display health.
-- It now includes a network hook to attempt to block outgoing damage reports.

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorGodModeGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorGodModeGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- GOD MODE STATE --
local isGodMode = false
local godModeConnection = nil
local originalMaxHealth = nil -- Variable to store original max health
local oldNamecall -- For storing the original network function

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorGodModeGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "GodModeFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 65)
mainFrame.Position = UDim2.new(0.5, -100, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleButton.Text = "God Mode: OFF [G]"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextColor3 = Color3.fromRGB(255, 80, 80)
toggleButton.TextSize = 18
toggleButton.Parent = mainFrame

local healthStatus = Instance.new("TextLabel")
healthStatus.Name = "HealthStatus"
healthStatus.Size = UDim2.new(1, 0, 0, 25)
healthStatus.Position = UDim2.new(0, 0, 0, 40)
healthStatus.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
healthStatus.Font = Enum.Font.SourceSansSemibold
healthStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
healthStatus.TextSize = 16
healthStatus.Text = "Health: --- / ---"
healthStatus.Parent = mainFrame

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
local function updateHealthDisplay()
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        local currentHealth = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        
        local healthStr = (currentHealth == math.huge) and "Infinite" or tostring(math.floor(currentHealth))
        local maxHealthStr = (maxHealth == math.huge) and "Infinite" or tostring(math.floor(maxHealth))
        
        healthStatus.Text = "Health: " .. healthStr .. " / " .. maxHealthStr
    else
        healthStatus.Text = "Health: --- / ---"
    end
end

local function enableGodMode()
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    local humanoid = character:FindFirstChild("Humanoid")

    if not originalMaxHealth then
        originalMaxHealth = humanoid.MaxHealth
    end
    
    humanoid.BreakJointsOnDeath = false

    -- Physical God Mode (client-side)
    if godModeConnection then godModeConnection:Disconnect() end
    godModeConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if humanoid.MaxHealth ~= math.huge then humanoid.MaxHealth = math.huge end
            if humanoid.Health ~= math.huge then humanoid.Health = math.huge end
            updateHealthDisplay()
        end)
    end)

    -- Network God Mode (hook namecall)
    -- This requires an executor that supports hookmetamethod or a similar function.
    if not oldNamecall and typeof(hookmetamethod) == "function" then
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            -- We are looking for a remote event being fired from inside the character model
            -- This is a guess that damage events are fired from scripts inside the character
            if typeof(self) == "Instance" and self:IsA("RemoteEvent") and method == "FireServer" and self:IsDescendantOf(character) then
                -- Block the call by returning nothing
                return
            end
            return oldNamecall(self, ...)
        end)
    end
    
    isGodMode = true
    toggleButton.Text = "God Mode: ON [G]"
    toggleButton.TextColor3 = Color3.fromRGB(80, 255, 80)
end

local function disableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end

    -- Restore network function if it was hooked
    if oldNamecall and typeof(hookmetamethod) == "function" then
        hookmetamethod(game, "__namecall", oldNamecall)
        oldNamecall = nil
    end
    
    pcall(function()
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            local humanoid = character.Humanoid
            humanoid.BreakJointsOnDeath = true
            if originalMaxHealth then
                humanoid.MaxHealth = originalMaxHealth
                humanoid.Health = originalMaxHealth
            end
        end
    end)
    
    originalMaxHealth = nil
    
    isGodMode = false
    toggleButton.Text = "God Mode: OFF [G]"
    toggleButton.TextColor3 = Color3.fromRGB(255, 80, 80)
    updateHealthDisplay()
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
    updateHealthDisplay()
    if isGodMode then
        task.wait(0.1)
        originalMaxHealth = nil -- Reset for the new character
        enableGodMode()
    end
end)

-- CLEANUP --
screenGui.Destroying:Connect(disableGodMode)

-- Initial setup if character already exists
if player.Character then
    updateHealthDisplay()
end

print("God Mode Script loaded. Press 'G' to toggle.")

