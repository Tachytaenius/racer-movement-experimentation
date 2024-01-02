-- Range should not be negative
-- Range can be inf (math.huge), which always returns 0
return function(x, range)
	if range == 0 then -- Interpret as "infinitesimal range"
		return x == 0 and 0 or 1
	end
	return math.min(math.abs(x) / range, 1)
end
