local sign = require("util.sign")

local vec2 = require("lib.mathsies").vec2

return function(v, a, s)
	local vRotated = vec2.rotate(v, -a)
	vRotated.x = sign(vRotated.x) * math.max(0, math.abs(vRotated.x) - s)
	return vec2.rotate(vRotated, a)
end
