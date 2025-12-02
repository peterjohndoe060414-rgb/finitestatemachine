local CombatService = require(script.Parent.Parent.Parent.CombatService)
-->> State

local State = {}

-->> States

State.Request = function(self)
	
	return self.Target
	
end

State.Enter = function(self)
	
	self:LookAt(self.Target.Position)
	self.AttackTrack:Play()
	task.delay(0.25, function()
		CombatService.Fling(self.Target.Parent, CFrame.new() * CFrame.Angles(0, math.rad(180), 0))
	end)
	task.wait(1)
	self:ChangeState("Idle")
	
end

State.Update = function(self)
	
end

State.Exit = function(self)
	
end

-->> Initialization

State.Priority = 4

return State
