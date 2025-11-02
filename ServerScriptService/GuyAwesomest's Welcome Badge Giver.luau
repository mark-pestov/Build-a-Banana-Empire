warn("["..script.Name.."] has loaded")



local BadgeID = 937926008543654
game.Players.PlayerAdded:Connect(function(plr)
	local DefaultNum = 00000000
	if BadgeID == DefaultNum then 
		error("Forgot to add badge ID (line 5)")
	elseif DefaultNum == BadgeID then
		error("Do not change \"DefaultNum\" to your ID (Line 7)")
	elseif BadgeID == nil then
		error("Badge ID doesn't exist or is nil (line 5)")
	end
	print("Giving BadgeID: " .. BadgeID .. " to: " .. plr.Name)
	local b = game:GetService("BadgeService")
	b:AwardBadge(plr.userId, BadgeID)
end)