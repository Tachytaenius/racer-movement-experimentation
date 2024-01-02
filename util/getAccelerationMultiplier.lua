local sign = require("util.sign")

return function(velocity, accelerationDirection, maxSpeed, accelCurveShaper)
	if accelerationDirection == 0 then
		return 0
	end
	local function getAccelerationMultiplierCore(speed, accelerationDirection)
		-- Speed can't be negative, and accelerationDirection should be negated (whether that's positive or negative) if velocity was too
		if accelerationDirection <= 0 then
			return 1
		end
		return ((maxSpeed - speed) / maxSpeed) ^ (1 / accelCurveShaper)
	end
	if velocity > -maxSpeed and velocity <= 0 then
		return getAccelerationMultiplierCore(-velocity, -accelerationDirection)
	elseif velocity >= 0 and velocity < maxSpeed then
		return getAccelerationMultiplierCore(velocity, accelerationDirection)
	elseif sign(velocity) * sign(accelerationDirection) == 1 then
		-- If you're trying to accelerate in the same direction you're moving and abs(vel) >= maxSpeed then no movement
		return 0
	else
		return 1
	end
end
