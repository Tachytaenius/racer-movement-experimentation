local vec2 = require("lib.mathsies").vec2
local consts = require("consts")

local setVectorLength = require("util.setVectorLength")
local moveNumberToTarget = require("util.moveNumberToTarget")
local sign = require("util.sign")
local getAccelerationMultiplier = require("util.getAccelerationMultiplier")
local multiplyVectorInDirection = require("util.multiplyVectorInDirection")
local getEffectMultiplierFromMagnitude = require("util.getEffectMultiplierFromMagnitude")
local getShortestAngleDifference = require("util.getShortestAngleDifference")
local moveVectorToTarget = require("util.moveVectorToTarget")
local moveVectorInDirectionTowardsZero = require("util.moveVectorInDirectionTowardsZero")

local player, dots

local prevDt

function love.load()
	player = {
		position = vec2(),
		velocity = vec2(),
		angle = 0,
		angularVelocity = 0,
		controlChangePerformanceMultiplier = 1,
		controlChangePerformanceMultiplierChangeRate = 1, -- Initialise to controlChangePerformanceMultiplierChangeRateMaximum

		radius = 10,
		-- restitution = 0.1,
		-- mass = 1000,
		maxSpeed = 200,
		engineMaxAcceleration = 100,
		engineAccelerationCurveShaper = 1.5,
		maxAngularSpeed = consts.tau * 0.125,
		angularAcceleration = consts.tau * 2,
		angularAccelerationOutOfSpeedRange = consts.tau * 6,
		angularSpeedPerformanceLossRange = consts.tau * 0.25,
		angularSpeedPerformanceLossMultiplier = 0.075,
		-- gripPadWidth = 0.375,
		-- gripPadLength = 0.375,
		brakeDeceleration = 175,
		-- gripFriction = 0.01, -- Hovering, but the grip causes... friction at a distance
		drag = 0.00075,
		maximumTargetAcceleratorMultiplierRotate = consts.tau / 8, -- Maximum amount to rotate target engine accelerator multiplier by when rotating accelerator left/right
		targetAcceleratorMultiplierRotateMaxLengthWithMaxPenalty = 0.25, -- The maximum length of the engine accelerator multiplier when rotating it left or right from forwards by an amount greater than or equal to the penalty range
		targetAcceleratorMultiplierRotateLengthPenaltyRange = consts.tau / 8,
		controlChangePerformanceMultiplierMinimum = 0.8,
		controlChangePerformanceMultiplierChangeRateResetRate = 1,
		controlChangePerformanceMultiplierChangeRateMaximum = 1,
		controlChangePerformanceMultiplierChangeRateMinimum = -0.25,
		controlChangePerformanceMultiplierChangeRateChangeRateAccelerator = 2.5,
		controlChangePerformanceMultiplierChangeRateChangeRateTurning = 2.5,
		controlChangePerformanceMultiplierChangeRateChangeRateSidewaysVelocityDecelerationMultiplier = 1,
		acceleratorMultiplierMaxChangeRate = 10,
		targetAngularVelocityMaxChangeRate = consts.tau * 15,
		sidewaysVelocityDecelerationMax = 50,
		sidewaysVelocityDecelerationMultiplierChangeRate = 4,

		controlling = true
	}

	dots = {}
	for _=1, 15000 do
		dots[#dots+1] = {
			x = (love.math.random() * 2 - 1) * 4000,
			y = (love.math.random() * 2 - 1) * 4000
		}
	end
end

local function getPerformanceMultiplier(entity)
	-- Boost would be a coefficient >= 1
	return
		entity.controlChangePerformanceMultiplier
		* (1 - getEffectMultiplierFromMagnitude(entity.angularVelocity, entity.angularSpeedPerformanceLossRange) * entity.angularSpeedPerformanceLossMultiplier)
end

local function getModifiedMaxSpeed(entity)
	return getPerformanceMultiplier(entity) * entity.maxSpeed
end

local function getModifiedEngineMaxAcceleration(entity)
	return getPerformanceMultiplier(entity) * entity.engineMaxAcceleration
end

local function getTargetAcceleratorMultiplierRotateMaxLength(angle, entity)
	return 1 - math.min(
		1 - entity.targetAcceleratorMultiplierRotateMaxLengthWithMaxPenalty,
		-((entity.targetAcceleratorMultiplierRotateMaxLengthWithMaxPenalty - 1) * math.abs(angle)) / entity.targetAcceleratorMultiplierRotateLengthPenaltyRange
	)
end

function love.update(dt)
	prevDt = prevDt or 1 -- Don't care-ish value

	player.previousVelocity = player.velocity

	-- Speed loss effects
	local speed = #player.velocity
	local slowdownAmount = player.drag * consts.airDensity * speed ^ 2 -- Drag
	-- Add any other ones that go in the direction of motion
	player.velocity = setVectorLength(player.velocity, math.max(0, #player.velocity - slowdownAmount * dt))
	-- Sideways deceleration
	player.velocity = moveVectorInDirectionTowardsZero(
		player.velocity,
		player.angle + consts.tau / 4,
		player.sidewaysVelocityDecelerationMax * (player.machineControl and player.machineControl.sidewaysVelocityDecelerationMultiplier or consts.defaultSidewaysVelocityDecelerationMultiplier) * dt
	)

	-- Control machine
	-- Everything set under the if statement must also be set (to a neutral value) under the else statement
	local previousMachineControl = player.machineControl
	if player.controlling then
		player.machineControl = {}

		local targetEngineAcceleratorMultiplier = love.keyboard.isDown(consts.controls.accelerate) and vec2(1, 0) or vec2()
		if love.keyboard.isDown(consts.controls.reverse) then
			targetEngineAcceleratorMultiplier = -targetEngineAcceleratorMultiplier
		end
		local rotateAngleLeftPart = 0
		if love.keyboard.isDown(consts.controls.rotateAcceleratorTargetLeft) then
			rotateAngleLeftPart = -player.maximumTargetAcceleratorMultiplierRotate
		end
		local rotateAngleRightPart = 0
		if love.keyboard.isDown(consts.controls.rotateAcceleratorTargetRight) then
			rotateAngleRightPart = player.maximumTargetAcceleratorMultiplierRotate
		end
		local rotateAngle = rotateAngleLeftPart + rotateAngleRightPart
		-- If rotating accelerator left/right, rotate such that vector moves left/right. Not just clockwise/anticlockwise
		if targetEngineAcceleratorMultiplier.x < 0 then
		-- if vec2.dot(targetEngineAcceleratorMultiplier, vec2(1, 0)) < 0 then
			rotateAngle = -rotateAngle
		end
		targetEngineAcceleratorMultiplier = vec2.rotate(targetEngineAcceleratorMultiplier, rotateAngle)
		targetEngineAcceleratorMultiplier = setVectorLength(targetEngineAcceleratorMultiplier, getTargetAcceleratorMultiplierRotateMaxLength(rotateAngle, player))
		-- assert(#targetEngineAcceleratorMultiplier <= 1, "Target engine accelerator multiplier cannot have a magnitude greater than 1") -- I don't trust the precision
		player.machineControl.engineAcceleratorMultiplier = moveVectorToTarget(
			previousMachineControl and previousMachineControl.engineAcceleratorMultiplier or consts.defaultEngineAcceleratorMultiplier,
			targetEngineAcceleratorMultiplier,
			player.acceleratorMultiplierMaxChangeRate,
			dt
		)

		local targetSidewaysVelocityDecelerationMultiplier = 1
		if consts.disableSidewaysVelocityDecelerationWhenRotatingAccelerator then
			-- Use rotation amounts to control sidewaysVelocityDecelerationMultiplier
			if rotateAngleRightPart ~= 0 or rotateAngleLeftPart ~= 0 then
				targetSidewaysVelocityDecelerationMultiplier = 1 - math.min(1, (math.abs(rotateAngleLeftPart) + math.abs(rotateAngleRightPart)) / player.maximumTargetAcceleratorMultiplierRotate)
			end
		end
		-- Move sideways deceleration multiplier to target
		player.machineControl.sidewaysVelocityDecelerationMultiplier = moveNumberToTarget(
			previousMachineControl and previousMachineControl.sidewaysVelocityDecelerationMultiplier or consts.defaultSidewaysVelocityDecelerationMultiplier,
			targetSidewaysVelocityDecelerationMultiplier,
			player.sidewaysVelocityDecelerationMultiplierChangeRate,
			dt
		)

		player.machineControl.brakeMultiplier = love.keyboard.isDown(consts.controls.brake) and 1 or 0

		local targetAngularVelocity = 0
		if love.keyboard.isDown(consts.controls.turnLeft) then
			targetAngularVelocity = targetAngularVelocity - 1
		end
		if love.keyboard.isDown(consts.controls.turnRight) then
			targetAngularVelocity = targetAngularVelocity + 1
		end
		player.machineControl.targetAngularVelocity = targetAngularVelocity
	else
		player.machineControl = {
			engineAcceleratorMultiplier = consts.defaultEngineAcceleratorMultiplier,
			sidewaysVelocityDecelerationMultiplier = consts.defaultSidewaysVelocityDecelerationMultiplier,
			brakeMultiplier = consts.defaultBrakeMultiplier,
			targetAngularVelocity = consts.defaultTargetAngularVelocity
		}
	end

	-- Compare control to previous control and modify controlChangePerformanceMultiplierChangeRate, then modify controlChangePerformanceMultiplier with that
	local controlChangeChange = player.controlChangePerformanceMultiplierChangeRateResetRate
	if previousMachineControl then
		controlChangeChange = controlChangeChange - #(player.machineControl.engineAcceleratorMultiplier - previousMachineControl.engineAcceleratorMultiplier) / prevDt * player.controlChangePerformanceMultiplierChangeRateChangeRateAccelerator
		controlChangeChange = controlChangeChange - math.abs(player.machineControl.targetAngularVelocity - previousMachineControl.targetAngularVelocity) / prevDt * player.controlChangePerformanceMultiplierChangeRateChangeRateTurning
		controlChangeChange = controlChangeChange - math.abs(player.machineControl.sidewaysVelocityDecelerationMultiplier - previousMachineControl.sidewaysVelocityDecelerationMultiplier) / prevDt * player.controlChangePerformanceMultiplierChangeRateChangeRateSidewaysVelocityDecelerationMultiplier 
	end
	player.controlChangePerformanceMultiplierChangeRate = math.max(player.controlChangePerformanceMultiplierChangeRateMinimum,
		math.min(player.controlChangePerformanceMultiplierChangeRateMaximum,
			player.controlChangePerformanceMultiplierChangeRate + controlChangeChange * dt
		)
	)
	player.controlChangePerformanceMultiplier = math.min(1, math.max(player.controlChangePerformanceMultiplierMinimum, player.controlChangePerformanceMultiplier + player.controlChangePerformanceMultiplierChangeRate * dt))

	-- Make machine controls change things
	-- Accelerate
	local engineAccelerationVector = vec2.rotate(player.machineControl.engineAcceleratorMultiplier, player.angle) -- Could multiply (1, 0) rotated by angle by the multiplier
	local accelerationVector
	if #player.velocity > 0 then
		local velocityAngle = vec2.toAngle(player.velocity)
		local accelRotated = vec2.rotate(engineAccelerationVector, -velocityAngle)
		local multiplier = getAccelerationMultiplier(#player.velocity, accelRotated.x, getModifiedMaxSpeed(player), player.engineAccelerationCurveShaper)
		accelerationVector = multiplyVectorInDirection(getModifiedEngineMaxAcceleration(player) * engineAccelerationVector, velocityAngle, multiplier)
	else
		accelerationVector = getModifiedEngineMaxAcceleration(player) * engineAccelerationVector
	end
	-- If acceleration would increase speed while being over max speed, cap it to previous speed or max speed, whichever is higher. Preserves direction
	local attemptedDelta = accelerationVector * dt
	local attemptedNewVelocity = player.velocity + attemptedDelta
	local finalDelta, finalNewVelocity
	if #attemptedNewVelocity > getModifiedMaxSpeed(player) and #attemptedNewVelocity > #player.velocity then
		finalNewVelocity = setVectorLength(attemptedNewVelocity, math.max(getModifiedMaxSpeed(player), #player.velocity) * consts.speedRegulationMultiplier)
		finalDelta = finalNewVelocity - player.velocity
		-- #finalDelta may be larger than #attemptedDelta
		-- assert(#finalNewVelocity <= #attemptedNewVelocity, "Attempted to prevent speed increase but speed increased anyway") -- Not confident in the precision when small numbers are involved
	else
		finalDelta = attemptedDelta
		finalNewVelocity = attemptedNewVelocity
	end
	player.velocity = finalNewVelocity
	player.dampedEngineAcceleration = finalDelta / dt -- Just for visualisation

	-- Brake
	player.velocity = setVectorLength(player.velocity, math.max(0, #player.velocity - player.brakeDeceleration * player.machineControl.brakeMultiplier * dt))

	-- Turn
	if math.abs(player.angularVelocity) > player.maxAngularSpeed then
		player.angularVelocity = moveNumberToTarget(
			player.angularVelocity,
			sign(player.angularVelocity) * player.maxAngularSpeed,
			player.angularAccelerationOutOfSpeedRange,
			dt
		)
	else
		local target = player.machineControl.targetAngularVelocity * player.maxAngularSpeed
		player.angularVelocity = moveNumberToTarget(
			player.angularVelocity,
			target,
			player.angularAcceleration,
			dt
		)
	end

	-- Move by linear/angular velocity
	player.position = player.position + player.velocity * dt
	player.angle = (player.angle + player.angularVelocity * dt) % consts.tau

	prevDt = dt
end

function love.draw()
	if player then
		love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
		love.graphics.rotate(-(player.angle + consts.tau / 4))
		love.graphics.translate(-player.position.x, -player.position.y)

		for _, dot in ipairs(dots) do
			love.graphics.points(dot.x, dot.y)
		end

		love.graphics.circle("line", player.position.x, player.position.y, player.radius)

		local playerDirection = vec2.rotate(vec2(1, 0), player.angle)
		local playerDirectionParallel = vec2()
		playerDirectionParallel.x, playerDirectionParallel.y = playerDirection.y, -playerDirection.x
		local playerLine1Start = player.position + playerDirection * player.radius - playerDirectionParallel * 3
		local playerLine1End = playerLine1Start + playerDirection * 50
		local playerLine2Start = player.position + playerDirection * player.radius + playerDirectionParallel * 3
		local playerLine2End = playerLine2Start + playerDirection * 50
		love.graphics.line(playerLine1Start.x, playerLine1Start.y, playerLine1End.x, playerLine1End.y)
		love.graphics.line(playerLine2Start.x, playerLine2Start.y, playerLine2End.x, playerLine2End.y)

		local velocityLineEnd = player.position + player.velocity
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2.5)
		love.graphics.line(player.position.x, player.position.y, velocityLineEnd.x, velocityLineEnd.y)

		love.graphics.setLineWidth(4)
		love.graphics.setColor(1, 0, 0)
		-- if player.dampedEngineAcceleration then
		-- 	love.graphics.line(player.position.x, player.position.y, vec2.components(player.position + player.dampedEngineAcceleration))
		-- end
		if player.previousVelocity then
			love.graphics.line(player.position.x, player.position.y, vec2.components(player.position + (player.velocity - player.previousVelocity) / prevDt)) -- update finishes and sets prevDt to dt, then draw happens
		end
		love.graphics.setColor(1, 1, 1)

		love.graphics.setLineWidth(1)
		-- Axis lines
		-- love.graphics.line(player.position.x - 75, player.position.y, player.position.x + 75, player.position.y)
		-- love.graphics.line(player.position.x, player.position.y - 75, player.position.x, player.position.y + 75)

		love.graphics.origin()

		love.graphics.print(
			"Speed: " .. math.floor(#player.velocity + 0.5) .. "\n"
			.. "Forward velocity: " .. math.floor(vec2.dot(player.velocity, vec2.rotate(vec2(1, 0), player.angle)) + 0.5) .. "\n"
			.. "Velocity to facing angle difference: " .. (
				#player.velocity > 0 and
					math.floor(
						getShortestAngleDifference(player.angle, vec2.toAngle(player.velocity))
						/ (consts.tau / 2) * 100 + 0.5
					) .. "%"
				or
					"N/A"
			) .. "\n"
			.. "Performance: " .. math.floor(getPerformanceMultiplier(player) * 100 + 0.5) .. "%\n"
			.. "\nPlease experiment with editing stats and stuff!"
		)
	end
end
