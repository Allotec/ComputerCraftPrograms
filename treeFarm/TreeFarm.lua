length = 14
rows = 4
slotcount = 16
maxfuel = 64
maxsaplings = 64

-- global visited table to track positions we've already checked
local visited = {}
local max_depth = 4   -- configurable max exploration depth
local leafcount = 0   -- track how many leaves we've broken
local max_leaves = 64 -- stop after breaking this many leaves (configurable)

-- Timer variables
local lastRefuelCheck = os.clock()
local refuelCheckInterval = 10 -- check fuel every 10 seconds

-- Chest protection variables
local chestDetectionEnabled = true -- Set to true to enable chest protection
local safeBlockTypes = {
	["minecraft:chest"] = true,
	["minecraft:trapped_chest"] = true,
	["minecraft:barrel"] = true,
	["minecraft:hopper"] = true,
	["minecraft:furnace"] = true,
	["minecraft:smoker"] = true,
	["minecraft:blast_furnace"] = true,
	["computercraft:turtle"] = true,
	["computercraft:computer"] = true,
}

-- Function to check fuel periodically
function checkFuel()
	local currentTime = os.clock()
	if currentTime - lastRefuelCheck >= refuelCheckInterval then
		if turtle.getFuelLevel() < 500 then
			print("Periodic fuel check - refueling")
			refuel()
		end
		lastRefuelCheck = currentTime
		return true
	end
	return false
end

-- Enhanced movement functions that verify success
function goforward()
	checkFuel() -- Check fuel before attempting movement

	local tries = 0
	local maxTries = 3
	local success = false

	while tries < maxTries and not success do
		-- If there's something in front, check if it's a protected block
		if turtle.detect() then
			local inspectSuccess, data = turtle.inspect()

			-- Check if it's a chest or protected block - restart cycle if found
			if inspectSuccess and safeBlockTypes[data.name] then
				print("DETECTED HOME: Found " .. data.name .. " - restarting cycle")
				return "restart"
			end

			turtle.dig()
			os.sleep(0.2) -- Short delay to allow blocks to finish breaking
		end

		success = turtle.forward()
		tries = tries + 1

		if not success and tries < maxTries then
			os.sleep(0.5) -- Wait a bit before retrying
		end
	end

	if not success then
		print("WARNING: Failed to move forward after " .. maxTries .. " attempts")
	end

	return success
end

function goback()
	local tries = 0
	local maxTries = 3
	local success = false

	while tries < maxTries and not success do
		-- Try moving back first
		success = turtle.back()

		-- If failed, turn around to check what's blocking us
		if not success and tries < maxTries then
			-- Turn around
			turtle.turnRight()
			turtle.turnRight()

			-- Check if there's a block and dig if needed
			local inspectSuccess, data = turtle.inspect()
			if inspectSuccess then
				-- Check if it's a chest or protected block
				if safeBlockTypes[data.name] then
					print("DETECTED HOME: Found " .. data.name .. " - restarting cycle")
					-- Return to original orientation before restarting
					turtle.turnRight()
					turtle.turnRight()
					return "restart"
				end

				-- Not a protected block, dig it
				turtle.dig()
				os.sleep(0.2)
			end

			-- Turn back to original orientation
			turtle.turnRight()
			turtle.turnRight()

			-- Try again
			os.sleep(0.2)
		end

		tries = tries + 1

		if not success and tries < maxTries then
			os.sleep(0.5) -- Wait before next attempt
		end
	end

	if not success then
		print("WARNING: Failed to move back after " .. maxTries .. " attempts")
	end

	return success
end

function goup()
	checkFuel() -- Check fuel before attempting movement

	local tries = 0
	local maxTries = 3
	local success = false

	while tries < maxTries and not success do
		-- If there's something above, check if it's a protected block
		if turtle.detectUp() then
			local inspectSuccess, data = turtle.inspectUp()

			-- Check if it's a chest or protected block
			if inspectSuccess and safeBlockTypes[data.name] then
				print("DETECTED HOME: Found " .. data.name .. " above - restarting cycle")
				return "restart"
			end

			turtle.digUp()
			os.sleep(0.2) -- Short delay to allow blocks to finish breaking
		end

		success = turtle.up()
		tries = tries + 1

		if not success and tries < maxTries then
			os.sleep(0.5) -- Wait a bit before retrying
		end
	end

	if not success then
		print("WARNING: Failed to move up after " .. maxTries .. " attempts")
	end

	return success
end

function godown()
	checkFuel() -- Check fuel before attempting movement

	local tries = 0
	local maxTries = 3
	local success = false

	while tries < maxTries and not success do
		-- If there's something below, check if it's a protected block
		if turtle.detectDown() then
			local inspectSuccess, data = turtle.inspectDown()

			-- Check if it's a chest or protected block
			if inspectSuccess and safeBlockTypes[data.name] then
				print("DETECTED HOME: Found " .. data.name .. " below - restarting cycle")
				return "restart"
			end

			turtle.digDown()
			os.sleep(0.2) -- Short delay to allow blocks to finish breaking
		end

		success = turtle.down()
		tries = tries + 1

		if not success and tries < maxTries then
			os.sleep(0.5) -- Wait a bit before retrying
		end
	end

	if not success then
		print("WARNING: Failed to move down after " .. maxTries .. " attempts")
	end

	return success
end

function breakoakleavesrecursive(x, y, z, facing, depth)
	-- initialize depth if not provided
	depth = depth or 0

	-- store original facing for restoring later
	local originalFacing = facing

	-- early termination conditions
	if depth > max_depth or leafcount >= max_leaves then
		return facing
	end

	-- check fuel and refuel if needed
	checkFuel()

	-- create a unique key for the current position
	local poskey = x .. "," .. y .. "," .. z

	-- skip if we've already visited this position
	if visited[poskey] then
		return facing
	end

	-- mark current position as visited
	visited[poskey] = true

	-- Check and process forward direction
	local success, data = turtle.inspect()
	if success and data.name == "minecraft:oak_leaves" then
		turtle.dig()
		leafcount = leafcount + 1

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			local newx, newy, newz = x, y, z
			if facing == 0 then
				newz = z - 1
			elseif facing == 1 then
				newx = x + 1
			elseif facing == 2 then
				newz = z + 1
			elseif facing == 3 then
				newx = x - 1
			end

			facing = breakoakleavesrecursive(newx, newy, newz, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = goback()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Check and process up direction
	local successup, dataup = turtle.inspectUp()
	if successup and dataup.name == "minecraft:oak_leaves" then
		turtle.digUp()
		leafcount = leafcount + 1

		local moveResult = goup()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			facing = breakoakleavesrecursive(x, y + 1, z, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = godown()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Check and process down direction
	local successdown, datadown = turtle.inspectDown()
	if successdown and datadown.name == "minecraft:oak_leaves" then
		turtle.digDown()
		leafcount = leafcount + 1

		local moveResult = godown()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			facing = breakoakleavesrecursive(x, y - 1, z, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = goup()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Check and process right direction
	turtle.turnRight()
	facing = (facing + 1) % 4
	local successright, dataright = turtle.inspect()
	if successright and dataright.name == "minecraft:oak_leaves" then
		turtle.dig()
		leafcount = leafcount + 1

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			local newx, newy, newz = x, y, z
			if facing == 0 then
				newz = z - 1
			elseif facing == 1 then
				newx = x + 1
			elseif facing == 2 then
				newz = z + 1
			elseif facing == 3 then
				newx = x - 1
			end

			facing = breakoakleavesrecursive(newx, newy, newz, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = goback()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Check and process back direction
	turtle.turnRight()
	facing = (facing + 1) % 4
	local successback, databack = turtle.inspect()
	if successback and databack.name == "minecraft:oak_leaves" then
		turtle.dig()
		leafcount = leafcount + 1

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			local newx, newy, newz = x, y, z
			if facing == 0 then
				newz = z - 1
			elseif facing == 1 then
				newx = x + 1
			elseif facing == 2 then
				newz = z + 1
			elseif facing == 3 then
				newx = x - 1
			end

			facing = breakoakleavesrecursive(newx, newy, newz, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = goback()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Check and process left direction
	turtle.turnRight()
	facing = (facing + 1) % 4
	local successleft, dataleft = turtle.inspect()
	if successleft and dataleft.name == "minecraft:oak_leaves" then
		turtle.dig()
		leafcount = leafcount + 1

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			local newx, newy, newz = x, y, z
			if facing == 0 then
				newz = z - 1
			elseif facing == 1 then
				newx = x + 1
			elseif facing == 2 then
				newz = z + 1
			elseif facing == 3 then
				newx = x - 1
			end

			facing = breakoakleavesrecursive(newx, newy, newz, facing, depth + 1)
			if facing == "restart" then
				return "restart"
			end

			moveResult = goback()
			if moveResult == "restart" then
				return "restart"
			end
		end
	end

	-- Restore original orientation by calculating the required turns
	while facing ~= originalFacing do
		turtle.turnRight()
		facing = (facing + 1) % 4
	end

	return facing
end

-- function to reset the leaf harvesting for a new tree
function resetleafharvesting()
	visited = {}
	leafcount = 0
end

function hasSaplings()
	local count = 0

	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:oak_sapling" then
			count = count + data.count
		end
	end

	return count < 64
end

function breaktree()
	resetleafharvesting()
	checkFuel()

	height = 0
	local success, data = turtle.inspect()

	if not success or data.name ~= "minecraft:oak_log" then
		for i = 1, slotcount do
			turtle.select(i)
			local data1 = turtle.getItemDetail(i)
			if data1 ~= nil and data1.name == "minecraft:oak_sapling" then
				turtle.place()
				return "continue"
			end
		end
		return "continue" -- Nothing to break, not a tree
	end

	-- reset the visited table before starting a new tree
	visited = {}
	local has_saplings = hasSaplings()

	while success and data.name == "minecraft:oak_log" do
		-- check fuel and refuel if needed before continuing
		checkFuel()

		--break base
		turtle.dig()

		--plant sapling if it is in inventory
		for i = 1, slotcount do
			turtle.select(i)
			local data1 = turtle.getItemDetail(i)
			if data1 ~= nil and data1.name == "minecraft:oak_sapling" then
				turtle.place()
				break
			end
		end

		--breaks above
		if turtle.detectUp() then
			turtle.digUp()
		end

		local moveResult = goup()
		if moveResult == "restart" then
			return "restart"
		elseif moveResult then
			height = height + 1

			if not has_saplings then
				for i = 1, 4 do
					turtle.turnRight()
					if turtle.detect() then
						local success, data1 = turtle.inspect()
						if success and data1.name == "minecraft:oak_leaves" then
							checkFuel()

							local x, y, z = 0, 0, 0 -- starting position is relative origin
							local facing = (i - 1) % 4 -- calculate facing based on turns
							-- call our recursive function to break leaves
							local leafResult = breakoakleavesrecursive(x, y, z, facing, 0)
							has_saplings = hasSaplings()
							if leafResult == "restart" then
								return "restart"
							end
						end
					end
				end
			end

			success, data = turtle.inspect()
		else
			print("WARNING: Failed to move up while breaking tree")
			break
		end
	end

	-- check fuel before heading back down
	checkFuel()

	-- Return to original position
	for i = 1, height do
		local moveResult = godown()
		if moveResult == "restart" then
			return "restart"
		elseif not moveResult then
			print("WARNING: Failed to return to original height at step " .. i .. " of " .. height)
			-- Try emergency descent - brute force approach
			for j = 1, 3 do
				turtle.digDown()
				if turtle.down() then
					break
				end
				os.sleep(1)
			end
		end
	end

	return "continue"
end

function compactinventory()
	for i = 1, slotcount do
		turtle.select(i)
		local currentslot = turtle.getItemDetail(i)
		if currentslot == nil or currentslot.count == 0 or currentslot.count == 64 then
			goto continue
		end

		for j = i + 1, slotcount do
			turtle.select(j)
			local nextslot = turtle.getItemDetail(j)

			if nextslot ~= nil and nextslot.name == currentslot.name then
				turtle.transferTo(i, nextslot.count)
			end
		end

		::continue::
	end
end

-- Function to safely navigate to a chest or storage area
function returnToBase(numBlocks)
	print("Returning to base - moving " .. numBlocks .. " blocks")

	-- Try to find a chest before destroying anything
	for i = 1, numBlocks do
		-- Look for chests before moving
		local success, data = turtle.inspect()
		if success and safeBlockTypes[data.name] then
			print("FOUND HOME: Detected " .. data.name .. " - stopping early after " .. (i - 1) .. " blocks")
			return true
		end

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		elseif not moveResult then
			print("ERROR: Failed to return to base at step " .. i .. " of " .. numBlocks)
			-- Try emergency recovery with chest detection
			for j = 1, 3 do
				local inspectSuccess, inspectData = turtle.inspect()
				if inspectSuccess and safeBlockTypes[inspectData.name] then
					print("SAFETY: Found protected block during recovery")
					break
				end

				if turtle.forward() then
					break
				end

				turtle.dig()
				os.sleep(0.5)
			end
		end
	end

	return true
end

-- Function to verify we're at the chest station
function verifyHomePosition()
	-- Try to detect chests in expected positions
	local frontCheck, frontData = turtle.inspect()

	-- Turn right and check
	turtle.turnRight()
	local rightCheck, rightData = turtle.inspect()

	-- Turn back and check left
	turtle.turnLeft()
	turtle.turnLeft()
	local leftCheck, leftData = turtle.inspect()

	-- Return to original orientation
	turtle.turnRight()

	-- Look up to check for chest
	local upCheck, upData = turtle.inspectUp()

	-- If any of these are chests, we're probably at the right place
	if
			(frontCheck and safeBlockTypes[frontData.name])
			or (rightCheck and safeBlockTypes[rightData.name])
			or (leftCheck and safeBlockTypes[leftData.name])
			or (upCheck and safeBlockTypes[upData.name])
	then
		return true
	end

	print("WARNING: Home position verification failed - no chests detected nearby")
	return false
end

--breaks a row given the length
function breakrow()
	for i = 1, length do
		checkFuel()

		local moveResult = goforward()
		if moveResult == "restart" then
			return "restart"
		end

		while turtle.suck() do
		end

		turtle.turnRight()
		while turtle.suck() do
		end

		local treeResult = breaktree()
		if treeResult == "restart" then
			return "restart"
		end

		turtle.turnLeft()
		turtle.turnLeft()
		while turtle.suck() do
		end

		treeResult = breaktree()
		if treeResult == "restart" then
			return "restart"
		end

		turtle.turnRight()
		while turtle.suck() do
		end
	end

	return "continue"
end

--refuels using charcoal
function refuel()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:charcoal" then
			turtle.refuel(32)
			return true
		end
	end
	print("WARNING: No fuel found!")
	return false
end

--deposits all logs
function depositlogs()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:oak_log" then
			turtle.drop(turtle.getItemCount(i))
		end
	end
end

--deposit excess saplings
function depositextra()
	local count = 0

	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:oak_sapling" then
			count = count + turtle.getItemCount(i)

			if count > maxsaplings then
				turtle.drop(turtle.getItemCount(i))
			end
		end
	end

	if count < maxsaplings then
		turtle.suck(maxsaplings - count)
	end
end

--gets the proper amount of charcoal
function getfuel()
	local count = 0

	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:charcoal" then
			count = count + turtle.getItemCount(i)

			if count > maxfuel then
				turtle.drop(turtle.getItemCount(i))
			end
		end
	end

	if count < maxfuel then
		turtle.suck(maxfuel - count)
	end
end

function dump()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name ~= "minecraft:charcoal" and data.name ~= "minecraft:oak_sapling" then
			turtle.drop(turtle.getItemCount(i))
		end
	end
end

-- Main function that coordinates the entire farming cycle
function startFarmingCycle()
	--true is left false is turn right
	--true for turn left first 1 for turn right first
	local direction = true
	print("Tree Farm starting - " .. length .. "x" .. rows .. " grid")

	while true do
		for i = 1, rows do
			local rowResult = breakrow()
			if rowResult == "restart" then
				print("Detected chest during row - restarting cycle")
				return
			end

			if i == rows then
				break
			end

			--turn into row
			if direction then
				turtle.turnLeft()
				local moveResult = goforward()
				if moveResult == "restart" then
					print("Detected chest during row transition - restarting cycle")
					return
				end

				moveResult = goforward()
				if moveResult == "restart" then
					print("Detected chest during row transition - restarting cycle")
					return
				end

				turtle.turnLeft()
				direction = false
			else
				turtle.turnRight()
				local moveResult = goforward()
				if moveResult == "restart" then
					print("Detected chest during row transition - restarting cycle")
					return
				end

				moveResult = goforward()
				if moveResult == "restart" then
					print("Detected chest during row transition - restarting cycle")
					return
				end

				turtle.turnRight()
				direction = true
			end

			compactinventory()
		end

		--fix direction
		if not direction then
			turtle.turnLeft()
			direction = true
		else
			turtle.turnRight()
			direction = false
		end

		amount = (2 * (rows - 1))
		local returnResult = returnToBase(amount)
		if returnResult == "restart" then
			print("Detected chest during return to base - restarting cycle")
			return
		end

		if not verifyHomePosition() then
			print("WARNING: Failed to verify home position, but will attempt to deposit items anyway")
		else
			print("Successfully verified home position")
		end

		print("Depositing items")
		--deposit logs
		depositlogs()

		if turtle.detectUp() then
			turtle.digUp()
		end

		local moveResult = goup()
		if moveResult == "restart" then
			print("Detected chest during vertical movement - restarting cycle")
			return
		elseif moveResult then
			--deposit excess saplings
			depositextra()

			if turtle.detectUp() then
				turtle.digUp()
			end

			moveResult = goup()
			if moveResult == "restart" then
				print("Detected chest during vertical movement - restarting cycle")
				return
			elseif moveResult then
				--get max amount of charcoal
				getfuel()

				--dump the rest
				moveResult = goup()
				if moveResult == "restart" then
					print("Detected chest during vertical movement - restarting cycle")
					return
				elseif moveResult then
					dump()

					godown()
					godown()
					godown()
				else
					print("ERROR: Failed to reach top chest")
					-- Try to get back to starting position
					godown()
					godown()
				end
			else
				print("ERROR: Failed to reach middle chest")
				godown()
			end
		else
			print("ERROR: Failed to reach first chest")
		end

		--reset
		if direction then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end

		print("Cycle complete - starting new harvesting cycle")
	end
end

-- Run the main farming cycle in a loop that can restart if needed
while true do
	print("Starting new farming cycle - " .. os.date())
	startFarmingCycle()
	print("Restarting from the beginning due to chest detection or error")
	-- Optional: Add a small delay before restarting
	os.sleep(1)
end
