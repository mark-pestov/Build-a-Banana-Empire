
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')

local PlotHolders = Instance.new("Folder")
PlotHolders.Parent = ReplicatedStorage
PlotHolders.Name = "PlotHolders"

Players.PlayerAdded:Connect(function(player)
	local PlotNumber = Instance.new("IntValue")
	PlotNumber.Name = "PlotNumber"
	PlotNumber.Parent = player
	for i = 1, 8 do
		if not PlotHolders:FindFirstChild(i) then
			local ClaimPlot = Instance.new("ObjectValue")
			ClaimPlot.Parent = PlotHolders
			ClaimPlot.Name = i
			ClaimPlot.Value = player

			PlotNumber.Value = i

			break
		end
	end
	
	if PlotNumber.Value == 0 then
		player:Kick("Max players in game")
	end
	
	local plotFolder = workspace.Map.Plots:FindFirstChild(PlotNumber.Value)
	player.CharacterAdded:Connect(function(character)
		local teleportPart = plotFolder.teleport
		
		character:PivotTo(teleportPart.CFrame)
	end)
	
	local sign = plotFolder.Sign
	sign.PlayerDisplay.SurfaceGui.PlayerName.Text = player.Name .. "'s Plot"
	
	local thumbnailType = Enum.ThumbnailType.HeadShot
	local thumbnailSize = Enum.ThumbnailSize.Size420x420
	
	local playerIcon, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbnailType, thumbnailSize)
	
	sign.PlayerDisplay.SurfaceGui.PlayerIcon.Image = playerIcon
	
	sign.PlayerDisplay.SurfaceGui.Enabled = true
end)

Players.PlayerRemoving:Connect(function(player)
	local PlotNumber = player.PlotNumber.Value
	local plotClaimed = PlotHolders:FindFirstChild(PlotNumber)
	plotClaimed:Destroy()
	local playerPlot = workspace.Map.Plots:FindFirstChild(PlotNumber)
	playerPlot.Sign.PlayerDisplay.SurfaceGui.Enabled = false
end)