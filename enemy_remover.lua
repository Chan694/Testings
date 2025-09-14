--[[
    Script:         Enhanced Enemy Eraser (Auto Toggle 10 Min)
    Version:        20.0
    Author:         GitHub Copilot & Chan694
    Description:    Draggable floating GUI with a counter.
                    The eraser auto-turns on/off every 10 minutes.
]]

-- Prevent duplicate GUI
if getgenv().enhancedEraserGui then
    getgenv().enhancedEraserGui:Destroy()
end

local totalEnemiesRemoved = 0

local ENEMY_NAME_KEYWORDS = {
    "Worm", "Toxitail", "Toxic Spider", "Toxic Slug", "Toxic Mantis", "Toxic Ant", "Spineserpent",
    "Snail King", "Snail", "Slug", "Shell Crab", "Scorpion King", "Scorpion", "Sand Worm", "Sand Spider",
    "Sand Scorpion", "Sand Beetle", "Rolling Toxic Spider", "Mutant Rat", "Roach", "Queen Spider",
    "King Wasp", "Rat", "Mutant Roach", "Toxic Stinger", "Mouse", "Moth", "Mosquito", "Mole",
    "Locust", "Lobster", "Ladybug", "King Octopus", "Chicken Zombie", "Goblin Rider", "Hydraviper",
    "House Fly", "Dragonfly", "Crab", "Cobra", "Chameleon", "Bed Bug", "Earwig", "Ant", "enemy_ant","enemy_aphid",
    "enemy_baby_octopus","enemy_beetle","enemy_behavior","enemy_bg_beetle","enemy_bg_caterpillar",
    "enemy_bg_pincher","enemy_bullet_ant","enemy_caterpillar","enemy_chameleon","enemy_cobra","enemy_crab","enemy_dragonfly",
    "enemy_house_fly","enemy_hydraviper_boss","enemy_jockey_summer","enemy_king_octopus","enemy_ladybug","enemy_lobster","enemy_locust",
    "enemy_mole","enemy_mosquito","enemy_moth","enemy_mouse","enemy_mutant_ant","enemy_mutant_fly","enemy_queen_bee",
    "enemy_queen_spider","enemy_rat","enemy_roach","enemy_rodent_boss","enemy_rollie_pollie","enemy_sand_beetle","enemy_sand_scorpion",
    "enemy_sand_spider","enemy_sand_worm","enemy_scorpion_king","enemy_scorpion","enemy_shell_crab","enemy_slug","enemy_snail_king",
    "enemy_snail","enemy_spineserpent","enemy_toxic_ant","enemy_toxic_fly","enemy_toxic_mantis","enemy_toxic_slug","enemy_toxic_spider",
    "enemy_toxitail","enemy_worm","enemy_jockey"
}

-- GUI Setup
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = CoreGui
getgenv().enhancedEraserGui = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0, 50, 0, 300) -- bottom-left
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
mainFrame.Active = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Enhanced Eraser v20"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0.5, -100, 0, 40)
statusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
statusLabel.BorderSizePixel = 0
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLabel.Text = "Eraser Status: OFF"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.Parent = mainFrame

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, -20, 0, 20)
counterLabel.Position = UDim2.new(0.5, -100, 0, 70)
counterLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
counterLabel.BorderSizePixel = 0
counterLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
counterLabel.Text = "Enemies Removed: 0"
counterLabel.Font = Enum.Font.SourceSans
counterLabel.TextSize = 14
counterLabel.Parent = mainFrame

-- Custom Dragging System
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Eraser Logic
local eraserActive = false

local function runEraser()
    while eraserActive do
        for _, descendant in ipairs(game:GetService("Workspace"):GetDescendants()) do
            if descendant and descendant:IsA("Model") then
                local model = descendant
                local isEnemy = false
                
                if model:GetAttribute("UnitType") == "enemy" then isEnemy = true end
                if not isEnemy then
                    local unitTypeObj = model:FindFirstChild("UnitType")
                    if unitTypeObj and unitTypeObj:IsA("StringValue") and unitTypeObj.Value == "enemy" then isEnemy = true end
                end
                if not isEnemy then
                    local nameLower = model.Name:lower()
                    for _, keyword in ipairs(ENEMY_NAME_KEYWORDS) do
                        if string.find(nameLower, keyword:lower()) then isEnemy = true; break end
                    end
                end

                if isEnemy then
                    pcall(function() model:Destroy() end)
                    totalEnemiesRemoved += 1
                    counterLabel.Text = "Enemies Removed: " .. totalEnemiesRemoved
                end
            end
        end
        task.wait()
    end
end

-- Auto toggle every 10 mins (600s)
task.spawn(function()
    while true do
        -- Turn ON
        eraserActive = true
        statusLabel.Text = "Eraser Status: ON"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.spawn(runEraser)
        task.wait(10)

        -- Turn OFF
        eraserActive = false
        statusLabel.Text = "Eraser Status: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        task.wait(100)
    end
end)
