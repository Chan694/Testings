-- This script is designed to work with the game's specific enemy management system.

-- Get the module that manages all active units/enemies
local unitsModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Units"):WaitForChild("base"))

-- Check if the module and the function to get entities exist
if not (unitsModule and unitsModule.GetActiveEntities) then
    print("Error: Could not find the required game modules. The game might have updated.")
    return
end

-- Function to freeze a single enemy
local function freezeEnemy(enemy)
    -- Check if the enemy has the GetActualSpeed function
    if enemy and type(enemy.GetActualSpeed) == "function" then
        -- Override the function to always return 0
        enemy.GetActualSpeed = function()
            return 0
        end
        print("Froze enemy: " .. tostring(enemy.UnitId))
    end
end

-- Loop through all enemies that are currently active and freeze them
local activeEnemies = unitsModule.GetActiveEntities()
for _, enemy in pairs(activeEnemies) do
    freezeEnemy(enemy)
end

print("All current enemies have been frozen.")

-- The game likely creates new enemy instances as they spawn.
-- To handle new enemies, we need to periodically check for them.
-- This will run in a loop and freeze any new enemies that appear.
while true do
    -- Wait for a short duration before checking again
    -- A value between 0.5 and 2 seconds is usually a good balance
    task.wait(1)

    -- Get the latest list of active enemies
    local latestActiveEnemies = unitsModule.GetActiveEntities()
    for _, enemy in pairs(latestActiveEnemies) do
        -- The GetActualSpeed function is a table, so we check if it's a function
        -- to see if we've already replaced it.
        if type(enemy.GetActualSpeed) == "function" then
            freezeEnemy(enemy)
        end
    end
end
