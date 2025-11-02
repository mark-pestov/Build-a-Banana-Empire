-- FarmingGameMaster.lua
-- Master configuration and plot system for Banana Farming Game

local FarmingGameMaster = {}

-- Game configuration
FarmingGameMaster.PlotSize = 8
FarmingGameMaster.MaxPlots = 12
FarmingGameMaster.DefaultBananaType = "Classic"
FarmingGameMaster.BananaTypes = {
	"Classic", "Golden", "Radioactive", "Frozen", "Mystic"
}

-- Plot data structure
FarmingGameMaster.Plots = {}

function FarmingGameMaster:CreatePlot(player, plotId)
	if not self.Plots[player.UserId] then
		self.Plots[player.UserId] = {}
	end
	self.Plots[player.UserId][plotId] = {
		BananaType = self.DefaultBananaType,
		GrowthStage = 0,
		Watered = false,
		Fertilized = false,
		PestStatus = nil,
		WorkerAssigned = nil
	}
end

function FarmingGameMaster:GetPlayerPlots(player)
	return self.Plots[player.UserId] or {}
end

function FarmingGameMaster:ResetPlayerPlots(player)
	self.Plots[player.UserId] = nil
end

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return

return FarmingGameMaster
