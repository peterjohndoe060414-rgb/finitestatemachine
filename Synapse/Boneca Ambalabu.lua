-->> Local Synapse
local Synapse = {}

Synapse.States = {
	["Idle"] = true,
	["Attack"]= true,
	["Patrol"] = true,
	["Stun"] = true
}

Synapse.IdleAnimation = script.Idle
Synapse.MoveAnimation = script.Run
Synapse.AttackAnimation = script.Attack

return Synapse
