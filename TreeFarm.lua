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

function breakoakleavesrecursive(x, y, z, facing, depth)
	-- initialize depth if not provided
	depth = depth or 0

	-- early termination conditions
	if depth > max_depth or leafcount >= max_leaves then
		return
	end

	-- check fuel and refuel if needed
	if turtle.getFuelLevel() < 500 then
		refuel()
	end

	-- create a unique key for the current position
	local poskey = x .. "," .. y .. "," .. z

	-- skip if we've already visited this position
	if visited[poskey] then
		return
	end

	-- mark current position as visited
	visited[poskey] = true

	-- create a priority queue of directions to check
	-- we'll check each direction first before moving to reduce unnecessary movement
	local directions = {}

	-- check forward direction first without turning
	local success, data = turtle.inspect()
	if success and data.name == "minecraft:oak_leaves" then
		table.insert(directions, {
			dir = "forward",
			facing = facing,
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.forward()
			end,
			returnmove = function()
				return turtle.back()
			end,
			calcnewpos = function()
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
				return newx, newy, newz, facing
			end,
		})
	end

	-- check up direction
	local successup, dataup = turtle.inspectUp()
	if successup and dataup.name == "minecraft:oak_leaves" then
		table.insert(directions, {
			dir = "up",
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.up()
			end,
			returnmove = function()
				return turtle.down()
			end,
			calcnewpos = function()
				return x, y + 1, z, facing
			end,
		})
	end

	-- check down direction
	local successdown, datadown = turtle.inspectDown()
	if successdown and datadown.name == "minecraft:oak_leaves" then
		table.insert(directions, {
			dir = "down",
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.down()
			end,
			returnmove = function()
				return turtle.up()
			end,
			calcnewpos = function()
				return x, y - 1, z, facing
			end,
		})
	end

	-- check right direction
	turtle.turnRight()
	local successright, dataright = turtle.inspect()
	if successright and dataright.name == "minecraft:oak_leaves" then
		local newfacing = (facing + 1) % 4
		table.insert(directions, {
			dir = "right",
			facing = newfacing,
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.forward()
			end,
			returnmove = function()
				return turtle.back()
			end,
			calcnewpos = function()
				local newx, newy, newz = x, y, z
				if newfacing == 0 then
					newz = z - 1
				elseif newfacing == 1 then
					newx = x + 1
				elseif newfacing == 2 then
					newz = z + 1
				elseif newfacing == 3 then
					newx = x - 1
				end
				return newx, newy, newz, newfacing
			end,
		})
	end

	-- check back direction
	turtle.turnRight()
	local successback, databack = turtle.inspect()
	if successback and databack.name == "minecraft:oak_leaves" then
		local newfacing = (facing + 2) % 4
		table.insert(directions, {
			dir = "back",
			facing = newfacing,
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.forward()
			end,
			returnmove = function()
				return turtle.back()
			end,
			calcnewpos = function()
				local newx, newy, newz = x, y, z
				if newfacing == 0 then
					newz = z - 1
				elseif newfacing == 1 then
					newx = x + 1
				elseif newfacing == 2 then
					newz = z + 1
				elseif newfacing == 3 then
					newx = x - 1
				end
				return newx, newy, newz, newfacing
			end,
		})
	end

	-- check left direction
	turtle.turnRight()
	local successleft, dataleft = turtle.inspect()
	if successleft and dataleft.name == "minecraft:oak_leaves" then
		local newfacing = (facing + 3) % 4
		table.insert(directions, {
			dir = "left",
			facing = newfacing,
			check = function()
				return true
			end, -- already checked
			move = function()
				return turtle.forward()
			end,
			returnmove = function()
				return turtle.back()
			end,
			calcnewpos = function()
				local newx, newy, newz = x, y, z
				if newfacing == 0 then
					newz = z - 1
				elseif newfacing == 1 then
					newx = x + 1
				elseif newfacing == 2 then
					newz = z + 1
				elseif newfacing == 3 then
					newx = x - 1
				end
				return newx, newy, newz, newfacing
			end,
		})
	end

	-- return to original orientation
	turtle.turnRight()

	-- process each viable direction
	for _, dir in ipairs(directions) do
		-- dig in the appropriate direction
		if dir.dir == "forward" then
			turtle.dig()
			leafcount = leafcount + 1
		elseif dir.dir == "up" then
			turtle.digUp()
			leafcount = leafcount + 1
		elseif dir.dir == "down" then
			turtle.digDown()
			leafcount = leafcount + 1
		elseif dir.dir == "right" then
			turtle.turnRight()
			turtle.dig()
			leafcount = leafcount + 1
		elseif dir.dir == "back" then
			turtle.turnRight()
			turtle.turnRight()
			turtle.dig()
			leafcount = leafcount + 1
		elseif dir.dir == "left" then
			turtle.turnLeft()
			turtle.dig()
			leafcount = leafcount + 1
		end

		if dir.move() then
			local newx, newy, newz, newfacing = dir.calcnewpos()
			breakoakleavesrecursive(newx, newy, newz, newfacing or facing, depth + 1)
			dir.returnmove()
		end

		-- return to original orientation if we turned
		if dir.dir == "right" then
			turtle.turnLeft()
		elseif dir.dir == "back" then
			turtle.turnRight()
			turtle.turnRight()
		elseif dir.dir == "left" then
			turtle.turnRight()
		end
	end
end

-- function to reset the leaf harvesting for a new tree
function resetleafharvesting()
	visited = {}
	leafcount = 0
end

function nosaplings()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:oak_sapling" then
			return false -- saplings found
		end
	end

	return true
end

function breaktree()
	resetleafharvesting()
	if turtle.getFuelLevel() < 500 then
		refuel()
	end

	height = 0
	local success, data = turtle.inspect()

	if data.name ~= "minecraft:oak_log" then
		for i = 1, slotcount do
			turtle.select(i)
			local data1 = turtle.getItemDetail(i)
			if data1 ~= nil and data1.name == "minecraft:oak_sapling" then
				turtle.place()
				return
			end
		end
	end

	-- reset the visited table before starting a new tree
	visited = {}

	while data.name == "minecraft:oak_log" do
		-- check fuel and refuel if needed before continuing
		if turtle.getFuelLevel() < 500 then
			refuel()
		end

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

		goup()

		if nosaplings() then
			for i = 1, 4 do
				turtle.turnRight()
				if turtle.detect() then
					local success, data1 = turtle.inspect()
					if success and data1.name == "minecraft:oak_leaves" then
						-- check fuel before exploring leaves
						if turtle.getFuelLevel() < 500 then
							refuel()
						end

						local x, y, z = 0, 0, 0 -- starting position is relative origin
						local facing = (i - 1) % 4 -- calculate facing based on turns
						-- call our recursive function to break leaves
						breakoakleavesrecursive(x, y, z, facing, 0)
					end
				end
			end
		end

		height = height + 1
		success, data = turtle.inspect()
	end

	-- check fuel before heading back down
	if turtle.getFuelLevel() < 500 then
		refuel()
	end

	for i = 1, height do
		godown()
	end
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

--breaks a row given the length
function breakrow()
	for i = 1, length do
		--check for low fuel
		if turtle.getFuelLevel() < 500 then
			refuel()
		end

		goforward()
		while turtle.suck() do
		end
		turtle.turnRight()
		while turtle.suck() do
		end

		breaktree()
		turtle.turnLeft()
		turtle.turnLeft()
		while turtle.suck() do
		end

		breaktree()
		turtle.turnRight()
		while turtle.suck() do
		end
	end
end

--refuels using charcoal
function refuel()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:charcoal" then
			turtle.refuel(32)
			return
		end
	end
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

	if count < maxsaplings then
		turtle.suck(maxfuel - count)
	end
end

--force go forward
function goforward()
	if turtle.detect() then
		turtle.dig()
	end

	turtle.forward()
end

--force go down
function godown()
	if turtle.detectDown() then
		turtle.digDown()
	end

	turtle.down()
end

--force go up
function goup()
	if turtle.detectUp() then
		turtle.digUp()
	end

	turtle.up()
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

--true is left false is turn right
--true for turn left first 1 for turn right first
direction = true
while true do
	for i = 1, rows do
		breakrow()

		if i == rows then
			break
		end

		--turn into row
		if direction then
			turtle.turnLeft()
			goforward()
			goforward()
			turtle.turnLeft()
			direction = false
		else
			turtle.turnRight()
			goforward()
			goforward()
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
	--go back to beginning
	for i = 1, amount do
		goforward()
	end

	--deposit logs
	depositlogs()

	if turtle.detectUp() then
		turtle.digUp()
	end

	goup()
	--deposit excess saplings
	depositextra()

	if turtle.detectUp() then
		turtle.digUp()
	end

	goup()
	--get max amount of charcoal
	getfuel()

	--dump the rest
	goup()
	dump()

	godown()
	godown()
	godown()

	--reset
	if direction then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
end
