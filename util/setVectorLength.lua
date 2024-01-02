local normaliseOrZero = require("util.normaliseOrZero")

return function(v, l)
	return normaliseOrZero(v) * l
end
