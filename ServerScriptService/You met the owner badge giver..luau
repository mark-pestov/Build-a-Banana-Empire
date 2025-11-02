local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local badge = 2769199021907255 -- Enter your badge ID here.
local owner = 3389224707 -- Enter the owner ID here.
local online = false

local function AwardBadge(player, badge)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badge)
	end) if not success then print("hasBadge error") return
	end

	if not hasBadge then
		local success, badgeInfo = pcall(function()
			return BadgeService:GetBadgeInfoAsync(badge)
		end) if not success then print("badgeInfo error") return
		end

		if success then
			if badgeInfo.IsEnabled then
				local awarded, errorMessage = pcall(function()
					BadgeService:AwardBadge(player.UserId, badge)
				end)

				if not awarded then	warn("Awarding error:", errorMessage)
				else print("Awarding badge")
				end
			end
		end
	end
end

game.Players.PlayerAdded:Connect(function(player)
	if player.UserId == owner then online = true 
		for _,p in pairs(game.Players:GetPlayers()) do
			AwardBadge(p, badge) task.wait(1)
		end
	elseif online == true then
		AwardBadge(player, badge)		
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	if player.UserId == owner then online = false end 
end)