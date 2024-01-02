local consts = require("consts")

return function(a, b)
	-- a to b is b - a
	return (b - a + consts.tau / 2) % consts.tau - consts.tau / 2
end
