local vec2 = require("lib.mathsies").vec2

return function(v, a, m)
	local vRotated = vec2.rotate(v, -a)
	vRotated.x = vRotated.x * m
	return vec2.rotate(vRotated, a)
end
