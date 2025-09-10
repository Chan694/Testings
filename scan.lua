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
    if not mainFrame or not mainFrame.Parent then return end
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
local allConnections = {}
local damageTrackers = {} -- To store last health values and connections for characters

-- Player/NPC Monitoring
local function setupCharacterMonitoring(char)
    if not char or damageTrackers[char] then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local p = Players:GetPlayerFromCharacter(char)
    local isLocalPlayer = (p == player)
    
    damageTrackers[char] = { lastHealth = humanoid.Health, connections = {} }

    -- Monitor Health Changes (Damage Taken / Dealt)
    local healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        local lastHealth = damageTrackers[char].lastHealth
        if newHealth < lastHealth then
            local damage = math.floor(lastHealth - newHealth)
            if isLocalPlayer then
                local attackerName = "Unknown"
                local nearestDist, nearestModel = math.huge, nil
                for _, thing in ipairs(Workspace:GetChildren()) do
                    if thing:IsA("Model") and thing ~= char and thing.PrimaryPart then
                        local dist = (char.PrimaryPart.Position - thing.PrimaryPart.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist, nearestModel = dist, thing
                        end
                    end
                end
                if nearestModel and nearestDist < 75 then
                    attackerName = nearestModel.Name
                end
                logEvent(string.format("<font color='#FF6347'>Damage Taken:</font> %d from %s", damage, attackerName))
            else
                local creatorTag = humanoid:FindFirstChild("creator")
                if creatorTag and creatorTag.Value == player then
                     logEvent(string.format("<font color='#40E0D0'>Damage Dealt:</font> %d to %s", damage, char.Name))
                end
            end
        end
        damageTrackers[char].lastHealth = newHealth
    end)
    table.insert(damageTrackers[char].connections, healthConn)

    -- Monitor Death
    local diedConn = humanoid.Died:Connect(function()
        local killerTag = humanoid:FindFirstChild("creator")
        local killerName = (killerTag and killerTag.Value and killerTag.Value.Name) or "Unknown"
        if p then
            logEvent(string.format("<font color='#FF4500'>Player Died:</font> %s (Killed by: %s)", p.Name, killerName))
        else
            logEvent(string.format("<font color='#FFA07A'>NPC Died:</font> %s (Killed by: %s)", char.Name, killerName))
        end
        
        if damageTrackers[char] then
            for _, c in ipairs(damageTrackers[char].connections) do c:Disconnect() end
            damageTrackers[char] = nil
        end
    end)
    table.insert(damageTrackers[char].connections, diedConn)
end

-- Player Connections
local function onPlayerAdded(p)
    logEvent(string.format("<font color='#00FF00'>Player Joined:</font> %s (%d)", p.Name, p.UserId))
    
    table.insert(allConnections, p.Chatted:Connect(function(msg)
        logEvent(string.format("<font color='#ADD8E6'>[CHAT] %s:</font> %s", p.Name, msg))
    end))
    
    table.insert(allConnections, p.CharacterAdded:Connect(function(char)
        logEvent(string.format("<font color='#FFFF00'>Character Spawned:</font> %s", p.Name))
        setupCharacterMonitoring(char)
    end))
    
    if p.Character then
        setupCharacterMonitoring(p.Character)
    end
end

table.insert(allConnections, Players.PlayerAdded:Connect(onPlayerAdded))
table.insert(allConnections, Players.PlayerRemoving:Connect(function(p)
    logEvent(string.format("<font color='#FF0000'>Player Left:</font> %s", p.Name))
end))

-- Workspace Connections (for NPCs and custom bugs)
table.insert(allConnections, Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Humanoid") and not Players:GetPlayerFromCharacter(descendant.Parent) then
        logEvent(string.format("<font color='#90EE90'>NPC Spawned:</font> %s", descendant.Parent.Name))
        setupCharacterMonitoring(descendant.Parent)
    elseif descendant:IsA("Model") and descendant.PrimaryPart and not descendant:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(descendant) and not descendant:IsA("Accessory") and not descendant:IsDescendantOf(Players) and not descendant:IsDescendantOf(Workspace.Terrain) then
        logEvent(string.format("<font color='#DA70D6'>Model Spawned:</font> %s", descendant.Name))
    end
end))

-- Initial Setup
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
logEvent("<font color='#FFFFFF'>Logger initialized. Monitoring game events.</font>")

-- CLEANUP --
screenGui.Destroying:Connect(function()
    for _, conn in ipairs(allConnections) do conn:Disconnect() end
    for _, tracker in pairs(damageTrackers) do
        for _, conn in ipairs(tracker.connections) do conn:Disconnect() end
    end
end)

print("Game Event Logger loaded.")

