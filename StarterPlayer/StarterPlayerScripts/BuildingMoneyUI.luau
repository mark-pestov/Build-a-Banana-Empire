-- BuildingMoneyUI.luau
-- Client script to display money generated above buildings

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local BuildingMoneyEvent = ReplicatedStorage:WaitForChild("BuildingMoneyEvent")

-- Utility: Create or reuse a BillboardGui above a building
local function showMoneyAboveBuilding(building, amount)
    if not building or not building:IsA("BasePart") then return end
    local gui = building:FindFirstChild("MoneyBillboardGui")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "MoneyBillboardGui"
        gui.Size = UDim2.new(0, 100, 0, 40)
        gui.StudsOffset = Vector3.new(0, 5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = building
        local label = Instance.new("TextLabel")
        label.Name = "MoneyLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 255, 0)
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = gui
    end
    local label = gui:FindFirstChild("MoneyLabel")
    if label then
        label.Text = "+$" .. tostring(amount)
        label.TextTransparency = 0
        label.TextStrokeTransparency = 0.5
        -- Fade out
        spawn(function()
            for i = 0, 1, 0.05 do
                label.TextTransparency = i
                label.TextStrokeTransparency = 0.5 + i * 0.5
                wait(0.03)
            end
        end)
    end
end

BuildingMoneyEvent.OnClientEvent:Connect(function(building, amount)
    showMoneyAboveBuilding(building, amount)
end)
