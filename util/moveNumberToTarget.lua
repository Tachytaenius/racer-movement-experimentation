local sign = require("util.sign")

return function(current, target, rate, dt)
	return target - sign(target - current) * math.max(0, math.abs(target - current) - rate * dt)
end
