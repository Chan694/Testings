-- This is a client-side script for use in an executor.
-- It creates a movable window that logs various in-game events in real-time.

-- Make sure the script doesn't error if it's run more than once
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ExecutorGameLoggerGui") then
    game.Players.LocalPlayer.PlayerGui.ExecutorGameLoggerGui:Destroy()
end

-- SERVICES --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- CONFIG --
local MAX_LOGS = 150 -- Max number of lines to keep in the log

-- CREATE THE GUI --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorGameLoggerGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "LoggerFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Text = "Game Event Logger"
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.TextSize = 16
titleBar.Parent = mainFrame

local logContainer = Instance.new("ScrollingFrame")
logContainer.Name = "LogContainer"
logContainer.Size = UDim2.new(1, -10, 1, -30)
logContainer.Position = UDim2.new(0, 5, 0, 25)
logContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
logContainer.BorderSizePixel = 0
logContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
logContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
logContainer.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = logContainer
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)

screenGui.Parent = player.PlayerGui

-- WINDOW DRAGGING LOGIC --
local dragging = false
local dragInput, frameStartPosition, dragStartPosition
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        frameStartPosition = mainFrame.Position
        dragStartPosition = Vector2.new(input.Position.X, input.Position.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input == dragInput then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPosition
        mainFrame.Position = UDim2.new(frameStartPosition.X.Scale, frameStartPosition.X.Offset + delta.X, frameStartPosition.Y.Scale, frameStartPosition.Y.Offset + delta.Y)
    end
end)

-- LOGGER LOGIC --
local function logEvent(message)
    -- Prune old logs if limit is reached
    if #logContainer:GetChildren() > MAX_LOGS then
        logContainer:GetChildren()[1]:Destroy()
    end

    local logEntry = Instance.new("TextLabel")
    logEntry.Name = "LogEntry"
    logEntry.Text = string.format("[%s] %s", os.date("%H:%M:%S"), message)
    logEntry.Font = Enum.Font.Code
    logEntry.TextSize = 14
    logEntry.TextColor3 = Color3.fromRGB(220, 220, 220)
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.Size = UDim2.new(1, 0, 0, 16)
    logEntry.BackgroundTransparency = 1
    logEntry.RichText = true
    logEntry.Parent = logContainer

    -- Auto-scroll to bottom
    logContainer.CanvasPosition = Vector2.new(0, uiListLayout.AbsoluteContentSize.Y)
end

-- EVENT CONNECTIONS --
local connections = {}

-- Player Connections
local function onPlayerAdded(p)
    logEvent(string.format("<font color='#00FF00'>Player Joined:</font> %s (%d)", p.Name, p.UserId))
    
    connections[#connections + 1] = p.Chatted:Connect(function(msg)
        logEvent(string.format("<font color='#ADD8E6'>[CHAT] %s:</font> %s", p.Name, msg))
    end)
    
    connections[#connections + 1] = p.CharacterAdded:Connect(function(char)
        logEvent(string.format("<font color='#FFFF00'>Character Spawned:</font> %s", p.Name))
        local humanoid = char:WaitForChild("Humanoid")
        connections[#connections + 1] = humanoid.Died:Connect(function()
            local killerTag = humanoid:FindFirstChild("creator")
            local killerName = (killerTag and killerTag.Value and killerTag.Value.Name) or "Unknown"
            logEvent(string.format("<font color='#FF4500'>Character Died:</font> %s (Killed by: %s)", p.Name, killerName))
        end)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
connections[#connections + 1] = Players.PlayerRemoving:Connect(function(p)
    logEvent(string.format("<font color='#FF0000'>Player Left:</font> %s", p.Name))
end)

-- Workspace Connections (for NPCs)
connections[#connections + 1] = Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Humanoid") and not Players:GetPlayerFromCharacter(descendant.Parent) then
        logEvent(string.format("<font color='#90EE90'>NPC Spawned:</font> %s", descendant.Parent.Name))
        connections[#connections + 1] = descendant.Died:Connect(function()
             local killerTag = descendant:FindFirstChild("creator")
             local killerName = (killerTag and killerTag.Value and killerTag.Value.Name) or "Unknown"
            logEvent(string.format("<font color='#FFA07A'>NPC Died:</font> %s (Killed by: %s)", descendant.Parent.Name, killerName))
        end)
    end
end)


-- Initial Setup (for existing players)
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
logEvent("<font color='#FFFFFF'>Logger initialized. Monitoring game events.</font>")


-- CLEANUP --
screenGui.Destroying:Connect(function()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
end)

print("Game Event Logger loaded.")
