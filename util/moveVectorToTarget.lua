local normaliseOrZero = require("util.normaliseOrZero")

-- TODO:

-- Add option to try to move current along arc on circle of radius #target. Would presumably need to have a prioritisation number from 0 to 1,
-- where 0 means to try to move straight from current to target, and 1 means to move straight onto the circle and then walk along the arc to
-- target, and any number inbetween is some curve prioritising result length more or less. The result would eventually reach the desired length
-- whatever the method.

-- In more concrete terms, its means that if this is being used for putting acceleration into velocity, don't try to walk the line between
-- current and target, intead, try to maximise speed more (according to the prioritisation number).

return function(current, target, rate, dt)
	local currentToTarget = target - current
	local direction = normaliseOrZero(currentToTarget)
	local distance = #currentToTarget
	local newCurrentToTarget = direction * math.max(0, distance - rate * dt)
	return target - newCurrentToTarget
end
