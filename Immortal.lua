-- This is a client-side script for use in an executor.
-- It automatically gives the player a ForceField when any tool is equipped,
-- and removes it when all tools are unequipped.

-- SERVICES --
local Players = game:GetService("Players")

-- LOCAL PLAYER --
local player = Players.LocalPlayer

-- CONNECTIONS TABLE FOR CLEANUP --
local connections = {}

-- CORE LOGIC --
local function setupCharacter(character)
    -- Clean up any old connections for this character model if they exist
    if connections[character] then
        for _, conn in ipairs(connections[character]) do
            conn:Disconnect()
        end
        connections[character] = nil
    end
    connections[character] = {}

    -- Function to add a ForceField if one doesn't exist
    local function addForceField()
        if not character:FindFirstChildOfClass("ForceField") then
            print("Tool equipped, creating ForceField.")
            local forceField = Instance.new("ForceField")
            forceField.Visible = false
            forceField.Parent = character
        end
    end

    -- Function to remove the ForceField if no tools are equipped
    local function removeForceField()
        -- Wait a moment to ensure the new tool has time to be parented if switching.
        task.wait() 
        
        local hasToolEquipped = false
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                hasToolEquipped = true
                break
            end
        end

        if not hasToolEquipped then
            local forceField = character:FindFirstChildOfClass("ForceField")
            if forceField then
                print("Last tool unequipped, destroying ForceField.")
                forceField:Destroy()
            end
        end
    end

    -- Connect to ChildAdded to detect when a tool is equipped
    local childAddedConn = character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            addForceField()
        end
    end)
    table.insert(connections[character], childAddedConn)

    -- Connect to ChildRemoved to detect when a tool is unequipped
    local childRemovedConn = character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            removeForceField()
        end
    end)
    table.insert(connections[character], childRemovedConn)

    -- Initial check in case a tool is already equipped when the script runs
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            addForceField()
            break -- Only need to find one
        end
    end
end

-- MAIN SETUP --
-- Connect to the CharacterAdded event for future spawns
local charAddedConn = player.CharacterAdded:Connect(setupCharacter)
table.insert(connections, charAddedConn)

-- If the character already exists, set it up now
if player.Character then
    setupCharacter(player.Character)
end

print("ForceField on Equip script loaded.")

