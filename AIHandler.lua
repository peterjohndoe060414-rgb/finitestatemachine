-->> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-->> Modules
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)
local Promise = require(Packages.Promise)
local ZonePlus = require(Packages.Zone)
local SimplePath = require(Packages.SimplePath)
local Synapse = require(script.Synapse)
local States = require(script.States)

-->> Variables

local WallParams = RaycastParams.new()
local Walls = game:GetService("CollectionService"):GetTagged("Wall")

WallParams.FilterType = Enum.RaycastFilterType.Include
WallParams.FilterDescendantsInstances = Walls

-->> AIHandler
local AIHandler = {}
AIHandler.__index = AIHandler

local AI = {}
local Detections = {}
local Targets = {}

-->> Creation

function AIHandler.new(Animal)

	local self = setmetatable({}, AIHandler)

	self.Animal = Animal
	self.AnimationController = self.Animal:FindFirstChild("Humanoid") or self.Animal:FindFirstChild("AnimationController")
	self.Animator = self.AnimationController.Animator
	self.Detection = Animal:WaitForChild("Detection")
	self.StateTrove = Trove.new()
	self.MoveTrove = Trove.new()
	self.Path = SimplePath.new(Animal, {})

	table.insert(Detections, self.Detection)
	AI[Animal] = self

	self:setSynapse()
	self:loadAnimations()
	self:Start()

	return self

end

-->> StateHandler

function AIHandler:ChangeState(State)
	
	if self.State == State then
		self.States[self.State].Update(self)
		return
	elseif self.State ~= nil then
		self.States[self.State].Exit(self)
	end
	
	self.MoveTrove:Destroy()
	self.StateTrove:Destroy()
	
	self.State = State
	self.Entering = true
	self.States[State].Enter(self)
	self.Entering = false
	
end

function AIHandler:Update()
	
	self.Target = self:GetTarget()
	
	if self.Entering then
		return
	end
	
	local chosenState, chosenPriority
	for index, state in pairs(self.States) do
		
		if state.Request(self) and (not chosenState or state.Priority > chosenPriority) then
			chosenState = index
			chosenPriority = state.Priority
		end
		
	end
	
	self:ChangeState(chosenState)
	
end

function AIHandler:Start()
	
	task.spawn(function()
		while true do
			self:Update()
			task.wait(0.5)
		end
	end)
	
	
	game:GetService("RunService").Stepped:Connect(function()
		self:UpdateBeams()
	end)
	
end

function AIHandler:MoveTo(Position)
	
	self.MoveTrove:Destroy()
	
	local Promise = Promise.new(function(Resolve, Reject)
		
		self.MoveTrack:Play()
		self.Path:Run(Position)
		
		for Index, Connection in {"Blocked", "Error", "Reached"} do
			self.MoveTrove:Add(self.Path[Connection]:Connect(function()
				Resolve()
			end))
		end
		
		self.MoveTrove:Add(task.delay(15, function()
			Resolve()
		end))
		
	end)
	
	self.MoveTrove:AddPromise(Promise)
	
	return Promise
	
end

-->> Target Detection

function AIHandler:GetTargetDistance()
	return self.Target and (self.Target.Position - self.Detection.Position).Magnitude
end

function AIHandler:GetTarget()
	
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = Targets
	params.FilterType = Enum.RaycastFilterType.Include
	
	local detection = self.Detection
	local target
	
	for index, part in ipairs(workspace:GetPartBoundsInRadius(detection.Position, 50, params)) do
		
		if not part.Parent:FindFirstChild("Humanoid") or part.Parent.Humanoid.Health <= 0 then
			table.remove(Targets, table.find(Targets, part))
			continue
		end
		
		local result = workspace:Raycast(self.Detection.Position, (part.Position - self.Detection.Position), WallParams)
		if result then
			return
		end
		
		local lookVector = detection.CFrame.LookVector
		local targetUnit = (part.Position - detection.Position).Unit
		
		local cos = lookVector:Dot(targetUnit)
		local rad = math.rad(50)
		local threshold = math.cos(rad)
		
		if cos < threshold then
			continue
		end
		
		if not target then
			target = part
		end
		
	end
	
	return target
	
end

function AIHandler:LookAt(Position)
	
	local RootPart = self.Animal:FindFirstChild("HumanoidRootPart")
	RootPart.CFrame = CFrame.lookAt(RootPart.Position, Vector3.new(Position.X, RootPart.Position.Y, Position.Z))
	
end

function AIHandler:UpdateBeams()
	
	if self.Stunned then
		return
	end
	
	local Detection = self.Detection
	local Beams = Detection.Beams
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = game:GetService("CollectionService"):GetTagged("Wall")
	
	for Index, Beam in pairs(Beams:GetChildren()) do
		
		local Result = workspace:Raycast(Detection.Position, Beam.CFrame.RightVector * 50, Params)
		if Result then
			
			local Distance: Attachment = (Result.Position - Beam.Position).Magnitude
			Beam.Attachment1.Position = Vector3.new(Distance,0,0)
			Beam.Beam.Width1 = 4.44 * Distance/50
		else
			
			Beam.Beam.Width1 = 4.44
			Beam.Attachment1.Position = Vector3.new(50,0,0)
			
		end
		
	end
	
end

-->> Loading Animal

function AIHandler:loadAnimations()
	
	self.IdleTrack = self.Animator:LoadAnimation(self.Synapse.IdleAnimation)
	self.MoveTrack = self.Animator:LoadAnimation(self.Synapse.MoveAnimation)
	self.AttackTrack = self.Animator:LoadAnimation(self.Synapse.AttackAnimation)
	
	self.IdleTrack.Priority = Enum.AnimationPriority.Idle
	self.IdleTrack:Play()
	
end

function AIHandler:setSynapse()
	
	self.Synapse = Synapse[self.Animal.Name]
	self.States = {}
	
	for Name, State in pairs(self.Synapse.States) do
		if States[Name] then
			self.States[Name] = States[Name]
		end
	end
	
end

-->> Initialization

function AIHandler.receiveRandomAI()
	
	local List = {}
	for Index, Synapse in pairs(AI) do
		table.insert(List, Synapse)
	end
	
	if #List ~= 0 then
		return List[math.random(1, #List)]
	end
	
end

function AIHandler.Initialize()
	
	task.spawn(function()
		while task.wait(10) do
			
			if #Targets == 0 then
				continue
			end
			
			local Synapse = AIHandler.receiveRandomAI()
			local Target = Targets[math.random(1, #Targets)]
			
			if Synapse and Target then
				Synapse.PatrolPosition = Target.Position
			end
			
		end
	end)
	
end

function AIHandler.playerEnteredZone(player)
	
	player:SetAttribute("InZone", true)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		table.insert(Targets, hrp)
	end
	
end

function AIHandler.playerExitedZone(player)
	
	player:SetAttribute("InZone", false)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local index = hrp and table.find(Targets, hrp)
	if index then
		table.remove(Targets, index)
	end
	
end

function AIHandler.stunAnimals()
	
	for index, animal in pairs(AI) do
		animal.Stun = animal.Stun or 0
		animal.Stun += 60
		print(`Stunned animal {animal.Animal}`)
	end
	
end

function AIHandler.alertAnimals(Position, Size)
	
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = Detections
	params.FilterType = Enum.RaycastFilterType.Include
	
	local alerted
	for index, animal in pairs(workspace:GetPartBoundsInRadius(Position, Size/2, params)) do
		if AI[animal.Parent] then
			AI[animal.Parent].PatrolPosition = Position
			AI[animal.Parent]:ChangeState("Idle")
			alerted = true
		end
	end
	
	return alerted
	
end

return AIHandler
