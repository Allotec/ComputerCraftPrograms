length = 18
rows = 4
row_space = 2
height_sep = 4
farm_above = 1
slotcount = 16

pumpkin_name = "minecraft:pumpkin"

maxfuel = 64
min_amount_blocks = 5000

function farmEverything()
	homeDumpRefuel()
	local up_amount = height_sep * farm_above
	print("Farming up " .. up_amount .. " blocks")
	for i = 1, up_amount + 1, 1 do
		turtle.up()
	end

	for i = 1, farm_above + 1, 1 do
		print("Farming a layer of pumpkins")
		getFarm()

		returnBack()
		for i = 1, height_sep, 1 do
			turtle.down()
		end
	end
end

function returnBack()
	turtle.turnLeft()

	for i = 1, row_space * 3, 1 do
		turtle.forward()
	end

	turtle.turnLeft()
end

function getFarm()
	print("Farming a row of pumpkins")
	local right = true

	for i = 1, rows - 1, 1 do
		farmRow()
		turnProperly(right)

		for i = 1, row_space + 1, 1 do
			turtle.forward()
		end

		turnProperly(right)

		right = not right
	end
end

function turnProperly(direction)
	if direction then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
end

function farmRow()
	print("Farming a row of pumpkins")
	for i = 1, length - 1 do
		if turtle.inspectDown() then
			turtle.digDown()
		end
		turtle.forward()
	end

	if turtle.inspectDown() then
		turtle.digDown()
	end
end

function compactInventory()
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
	local count = 0

	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name == "minecraft:charcoal" then
			count = count + turtle.getItemCount(i)
		end
	end

	if count < maxfuel then
		turtle.suck(maxfuel - count)
	end

	selectItem("minecraft:charcoal")
	while turtle.getFuelLevel() < min_amount_blocks do
		turtle.refuel(1)
	end
end

function dump()
	for i = 1, slotcount do
		turtle.select(i)
		local data = turtle.getItemDetail(i)
		if data ~= nil and data.name ~= "minecraft:charcoal" then
			turtle.drop(turtle.getItemCount(i))
		end
	end
end

function homeDumpRefuel()
	turtle.turnLeft()
	getFuel()
	compactInventory()
	local result = turtle.up()
	if not result then
		print("Failed to go up, trying to refuel")
	end
	dump()
	turtle.down()
	turtle.turnRight()
end

while true do
	print("Starting new farming cycle - " .. os.date())
	farmEverything()

	os.sleep(60)
end
