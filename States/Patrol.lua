-->> Modules
local Shared = require(game:GetService("ReplicatedStorage").Modules.Shared)

-->> State

local State = {}

-->> States

State.Request = function(self)
	
	return self.Bored or self.PatrolPosition
	
end

State.Enter = function(self)
	
	self:MoveTo(self.PatrolPosition or Shared.getRandomPointInZone()):andThen(function()
		self.Bored = false
		self.PatrolPosition = nil
		self.MoveTrack:Stop()
		self:Update()
	end)
	
end

State.Update = function(self)
	
end

State.Exit = function(self)
	
	if self.Path.Status ~= self.Path.StatusType.Idle then
		self.Path:Stop()
	end
	
	self.MoveTrove:Destroy()
	self.MoveTrack:Stop()
	
end

-->> Initialization

State.Priority = 2

return State
