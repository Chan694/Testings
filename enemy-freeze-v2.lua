--[[
    Script:         Movable Enemy Janitor GUI
    Version:        13.0 ("The Janitor")
    Author:         GitHub Copilot & Chan694
    Description:    Creates a draggable GUI with a single-use "Clean Up" button.
                    When clicked, it finds and neutralizes all current enemies, then stops.
                    This is designed to be used between levels to remove stuck enemies
                    without affecting the next wave.
]]

-- Prevent the GUI from being created more than once
if getgenv().enemyJanitorGui then
    getgenv().enemyJanitorGui:Destroy()
end

-- --- Core Logic ---
local ENEMY_NAME_KEYWORDS = {
    "Worm", "Toxitail", "Toxic Spider", "Toxic Slug", "Toxic Mantis", "Toxic Ant", "Spineserpent",
    "Snail King", "Snail", "Slug", "Shell Crab", "Scorpion King", "Scorpion", "Sand Worm", "Sand Spider",
    "Sand Scorpion", "Sand Beetle", "Rolling Toxic Spider", "Mutant Rat", "Roach", "Queen Spider",
    "King Wasp", "Rat", "Mutant Roach", "Toxic Stinger", "Mouse", "Moth", "Mosquito", "Mole",
    "Locust", "Lobster", "Ladybug", "King Octopus", "Chicken Zombie", "Goblin Rider", "Hydraviper",
    "House Fly", "Dragonfly", "Crab", "Cobra", "Chameleon", "Bed Bug", "Earwig", "Ant"
}

-- --- GUI Creation ---
local CoreGui = game:GetService("CoreGui")

local screenGui = Instance.new("ScreenGui")
getgenv().enemyJanitorGui = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 80)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -40)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Enemy Janitor v13"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

local cleanupButton = Instance.new("TextButton")
cleanupButton.Size = UDim2.new(1, -20, 0, 30)
cleanupButton.Position = UDim2.new(0.5, -100, 0, 40)
cleanupButton.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
cleanupButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cleanupButton.Text = "Clean Up Stuck Enemies"
cleanupButton.Font = Enum.Font.SourceSansBold
cleanupButton.TextSize = 16
cleanupButton.Parent = mainFrame

screenGui.Parent = CoreGui

-- The function that neutralizes an enemy
local function neutralize(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:Destroy() end
    
    for _, descendant in ipairs(model:GetDescendants()) do
        pcall(function()
            if descendant:IsA("BasePart") then
                descendant.Transparency = 1
                descendant.CanCollide = false
            elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
                descendant.Disabled = true
            end
        end)
    end
end

-- --- Button Logic ---
cleanupButton.MouseButton1Click:Connect(function()
    print("Starting cleanup... Searching for stuck enemies.")
    cleanupButton.Text = "Cleaning..."
    cleanupButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

    local enemiesFound = 0
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
                neutralize(model)
                enemiesFound = enemiesFound + 1
            end
        end
    end
    
    print("Cleanup complete. Neutralized " .. enemiesFound .. " enemies.")
    cleanupButton.Text = "Clean Up Stuck Enemies"
    cleanupButton.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
end)
