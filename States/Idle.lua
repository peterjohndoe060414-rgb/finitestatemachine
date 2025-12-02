-->> State

local State = {}

-->> States

State.Request = function(self)
	
	return true
	
end

State.Enter = function(self)
	
	self.StateTrove:Add(task.delay(math.random(5, 10), function()
		self.Bored = true
	end))
	
end

State.Update = function(self)
	
end

State.Exit = function(self)
	
end

-->> Initialization

State.Priority = 1

return State
