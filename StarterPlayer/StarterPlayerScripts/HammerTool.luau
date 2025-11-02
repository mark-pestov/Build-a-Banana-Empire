-- HammerTool.luau
-- Always in player's inventory. Used to pick up buildings with confirmation dialog.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Tool = Instance.new("Tool")
Tool.Name = "Hammer"
Tool.RequiresHandle = false
Tool.CanBeDropped = false

-- Give to all players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if not char:FindFirstChild("Hammer") then
            local toolClone = Tool:Clone()
            toolClone.Parent = player.Backpack
        end
    end)
end)

-- Confirmation UI
local function showConfirmation(building, player)
    -- Replace with your UI system
    local confirm = Instance.new("ScreenGui")
    confirm.Name = "HammerConfirm"
    confirm.Parent = player.PlayerGui
    local frame = Instance.new("Frame", confirm)
    frame.Size = UDim2.new(0, 300, 0, 120)
    frame.Position = UDim2.new(0.5, -150, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.Text = "Are you sure you want to pick up this building?"
    label.BackgroundTransparency = 1
    local yes = Instance.new("TextButton", frame)
    yes.Size = UDim2.new(0.45, 0, 0.3, 0)
    yes.Position = UDim2.new(0.05, 0, 0.6, 0)
    yes.Text = "Yes"
    local no = Instance.new("TextButton", frame)
    no.Size = UDim2.new(0.45, 0, 0.3, 0)
    no.Position = UDim2.new(0.5, 0, 0.6, 0)
    no.Text = "No"
    yes.MouseButton1Click:Connect(function()
        confirm:Destroy()
        -- Remove building and add to inventory (server event)
        ReplicatedStorage:WaitForChild("PickUpBuildingEvent"):FireServer(building)
    end)
    no.MouseButton1Click:Connect(function()
        confirm:Destroy()
    end)
end

-- Tool logic
Tool.Activated:Connect(function()
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()
    local target = mouse.Target
    if target and target.Parent == Workspace.Buildings then
        showConfirmation(target, player)
    end
end)
