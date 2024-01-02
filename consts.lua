local vec2 = require("lib.mathsies").vec2

local consts = {}

consts.controls = {
	accelerate = "space",
	reverse = "lctrl",
	brake = "lshift",
	shiftLeft = "a",
	shiftRight = "d",
	turnLeft = "j",
	turnRight = "l",
	rotateAcceleratorTargetLeft = "q",
	rotateAcceleratorTargetRight = "e"
}

consts.tau = math.pi * 2

consts.speedRegulationHarshness = 10e-10
consts.speedRegulationMultiplier = 1 - consts.speedRegulationHarshness

consts.airDensity = 0.5

consts.disableSidewaysVelocityDecelerationWhenRotatingAccelerator = true -- Rotating accelerator can be ineffective if this is false. Also rotate left and right at the same time to disable without rotating

consts.defaultEngineAcceleratorMultiplier = vec2()
consts.defaultSidewaysVelocityDecelerationMultiplier = 1
consts.defaultBrakeMultiplier = 0
consts.defaultTargetAngularVelocity = 0

return consts
