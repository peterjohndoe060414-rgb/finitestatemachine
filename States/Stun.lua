-->> State

local State = {}

-->> States

State.Request = function(self)
	
	return self.Stun and self.Stun > 0
	
end

State.Enter = function(self)
	
	local Detection = self.Animal.Detection
	local Beams = Detection.Beams
	
	for Index, BeamHolder in pairs(Beams:GetChildren()) do
		
		local Beam: Beam = BeamHolder.Beam
		Beam.Enabled = false
		
	end
	
	self.Stunned = true
	
end

State.Update = function(self)
	
	self.Stun -= 0.5
	
end

State.Exit = function(self)
	
	self.Stunned = false
	
	local Detection = self.Animal.Detection
	local Beams = Detection.Beams

	for Index, BeamHolder in pairs(Beams:GetChildren()) do

		local Beam: Beam = BeamHolder.Beam
		Beam.Enabled = true

	end
	
end

-->> Initialization

State.Priority = 6

return State
