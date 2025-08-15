-- Configuration
length = 18
rows = 4
row_space = 2
height_sep = 5
farm_above = 3
slotcount = 16

pumpkin_name = "minecraft:pumpkin"

maxfuel = 64
min_amount_blocks = 5000

-- Maximum retries for operations
max_retries = 3

-- Debug mode
debug_mode = true

function log(message)
	if debug_mode then
		print("[LOG] " .. message)
	end
end

-- Safe movement functions with retry
function safeUp(retries)
	retries = retries or max_retries
	for i = 1, retries do
		if turtle.up() then
			return true
		else
			log("Failed to move up, retrying (" .. i .. "/" .. retries .. ")")
			if turtle.getFuelLevel() == 0 then
				log("Out of fuel, attempting emergency refuel")
				emergencyRefuel()
			end
			os.sleep(1)
		end
	end
	log("Failed to move up after " .. retries .. " attempts")
	return false
end

function safeDown(retries)
	retries = retries or max_retries
	for i = 1, retries do
		if turtle.down() then
			return true
		else
			log("Failed to move down, retrying (" .. i .. "/" .. retries .. ")")
			if turtle.getFuelLevel() == 0 then
				log("Out of fuel, attempting emergency refuel")
				emergencyRefuel()
			end
			os.sleep(1)
		end
	end
	log("Failed to move down after " .. retries .. " attempts")
	return false
end

function safeForward(retries)
	retries = retries or max_retries
	for i = 1, retries do
		if turtle.forward() then
			return true
		else
			log("Failed to move forward, retrying (" .. i .. "/" .. retries .. ")")
			if turtle.getFuelLevel() == 0 then
				log("Out of fuel, attempting emergency refuel")
				emergencyRefuel()
			end
			-- Try to clear obstacle
			if turtle.detect() then
				turtle.dig()
			end
			os.sleep(1)
		end
	end
	log("Failed to move forward after " .. retries .. " attempts")
	return false
end

-- Emergency refuel function
function emergencyRefuel()
	log("Attempting emergency refuel")
	if selectItem("minecraft:charcoal") then
		turtle.refuel(1)
		log("Emergency refuel successful")
		return true
	end
	log("No fuel available for emergency refuel!")
	return false
end

-- Check if inventory has space for more items
function hasInventorySpace()
	for i = 1, slotcount do
		if turtle.getItemCount(i) == 0 then
			return true
		end
	end
	return false
end

-- Count empty inventory slots
function emptySlotCount()
	local count = 0
	for i = 1, slotcount do
		if turtle.getItemCount(i) == 0 then
			count = count + 1
		end
	end
	return count
end

function farmEverything()
	log("Starting farming cycle")
	if not homeDumpRefuel() then
		log("Failed at homeDumpRefuel, retrying next cycle")
		return false
	end

	local up_amount = height_sep * farm_above
	log("Farming up " .. up_amount .. " blocks")
	for i = 1, up_amount do
		if not safeUp() then
			log("Failed to move up to farming height, attempting to return home")
			returnToHome(i)
			return false
		end
	end

	for i = 1, farm_above + 1 do
		log("Farming layer " .. i .. " of " .. (farm_above + 1))
		if not getFarm() then
			log("Farming layer failed, attempting to return home")
			returnToHome(0)
			return false
		end

		if not returnBack() then
			log("Return path failed, attempting to return home")
			returnToHome(0)
			return false
		end

		if i <= farm_above then
			log("Moving down to next layer")
			for j = 1, height_sep do
				if not safeDown() then
					log("Failed to move down to next layer, attempting to return home")
					returnToHome(0)
					return false
				end
			end
		end
	end
	return true
end

-- Emergency return to home function
function returnToHome(upCount)
	log("Attempting emergency return to home")

	-- Try to get back down if we're up in the air
	for i = 1, upCount do
		safeDown()
	end

	-- Turn around and try to get back
	turtle.turnRight()
	turtle.turnRight()

	-- Try to move forward a reasonable distance to get back
	for i = 1, 30 do
		if not safeForward() then
			-- If we can't move forward, try turning and moving
			turtle.turnRight()
			safeForward()
			turtle.turnLeft()
		end
	end

	log("Emergency return complete - position may not be accurate")
end

function returnBack()
	log("Returning to start position")
	turtle.turnRight()

	for i = 1, row_space * 4 + 1 do
		if not safeForward() then
			log("Failed to return back at step " .. i)
			return false
		end
	end

	turtle.turnRight()
	return true
end

function getFarm()
	log("Starting to farm pumpkins")

	-- Check if we have enough inventory space
	if emptySlotCount() < 3 then
		log("Low inventory space before farming, returning early")
		return false
	end

	local dir = true

	for i = 1, rows do
		if not farmRow() then
			log("Farming row " .. i .. " failed")
			return false
		end

		if i < rows then
			if not startNewRow(dir) then
				log("Failed to start new row")
				return false
			end
		end

		dir = not dir
	end
	return true
end

function startNewRow(dir)
	turnProperly(dir)
	for i = 1, row_space + 1 do
		if not safeForward() then
			return false
		end
	end
	turnProperly(dir)
	return true
end

function turnProperly(direction)
	if direction then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
end

function farmRow()
	log("Farming a row of pumpkins")
	for i = 1, length - 1 do
		-- Check if inventory is getting full
		if emptySlotCount() < 2 then
			log("Inventory nearly full while farming row, continuing cautiously")
		end

		if turtle.inspectDown() then
			turtle.digDown()
		end
		if not safeForward() then
			return false
		end
	end

	if turtle.inspectDown() then
		turtle.digDown()
	end
	return true
end

function compactInventory()
	log("Compacting inventory")
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
	turtle.select(1)
end

function selectItem(item)
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == item then
			return true
		end
	end
	return false
end

function getFuel()
	log("Getting fuel")
	local count = 0

	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:charcoal" then
			count = count + data.count
		end
	end

	if count < maxfuel then
		log("Getting more fuel from chest, need " .. (maxfuel - count))
		-- Try multiple times to get fuel
		for i = 1, 3 do
			turtle.suck(maxfuel - count)
			-- Recount fuel after attempt
			count = 0
			for j = 1, slotcount do
				turtle.select(j)
				local data = turtle.getItemDetail(j)
				if data ~= nil and data.name == "minecraft:charcoal" then
					count = count + data.count
				end
			end
			if count >= maxfuel then
				break
			end
			os.sleep(1)
		end
	end

	if selectItem("minecraft:charcoal") then
		local current_fuel = turtle.getFuelLevel()
		log("Current fuel level: " .. current_fuel)

		if current_fuel < min_amount_blocks then
			log("Refueling to minimum level")
			while turtle.getFuelLevel() < min_amount_blocks do
				if not turtle.refuel(1) then
					log("Failed to refuel, may be out of charcoal")
					break
				end
			end
		end
		return turtle.getFuelLevel() >= min_amount_blocks
	else
		log("No charcoal found for refueling!")
		return false
	end
end

function dump()
	log("Dumping items into chest")
	local dumped_items = false

	-- Try multiple times to dump items
	while true do
		dumped_items = false

		for i = 1, slotcount do
			turtle.select(i)
			local data = turtle.getItemDetail(i)
			if data ~= nil and data.name ~= "minecraft:charcoal" then
				log("Dropping " .. data.name .. " x" .. data.count)
				if turtle.drop(data.count) then
					dumped_items = true
				else
					log("Failed to drop items, chest may be full")
					break
				end
			end
		end

		-- If we successfully dumped items or have nothing to dump, break
		local has_items = false
		for i = 1, slotcount do
			turtle.select(i)
			local data = turtle.getItemDetail(i)
			if data ~= nil and data.name ~= "minecraft:charcoal" then
				has_items = true
				break
			end
		end

		if not has_items or dumped_items then
			break
		end

		log("Chest may be full, waiting before retry ")
		os.sleep(5)
	end

	turtle.select(1)
	return dumped_items
end

function homeDumpRefuel()
	log("Starting home routine")
	turtle.turnLeft()

	-- Try to get fuel first
	if not getFuel() then
		log("Failed to get fuel")
		turtle.turnRight() -- Return to original orientation
		return false
	end

	compactInventory()

	-- Try to move up to access chest
	if not safeUp() then
		log("Failed to move up to chest, trying to continue anyway")
	end

	-- Try to dump items
	if not dump() then
		log("Warning: Failed to dump all items, inventory may be full")
		-- Even if dump failed, try to continue
	end

	-- Try to move back down
	if not safeDown() then
		log("Failed to move back down from chest!")
		-- Try to continue anyway
	end

	turtle.turnRight()
	return true
end

function recoverFromError()
	log("Attempting to recover from error state")
	-- Try to compact inventory to free up space
	compactInventory()

	-- If we're looking at a chest, try to dump items
	local success, data = turtle.inspect()
	if success and (data.name:find("chest") or data.name:find("barrel")) then
		log("Found chest/barrel in front, trying to use it")
		dump()
	end

	-- Try to get back to a known state
	turtle.turnRight()
	turtle.turnRight()

	log("Recovery attempt complete")
end

-- Main loop with error handling
while true do
	log("Starting new farming cycle - " .. os.date())

	local status, err = pcall(function()
		if not farmEverything() then
			log("Farming cycle encountered issues")
		end
	end)

	if not status then
		log("ERROR: " .. tostring(err))
		log("Attempting recovery...")
		pcall(recoverFromError)
	end

	log("Farming cycle complete, sleeping for 60 seconds")
	os.sleep(20)
end
