SLOTCOUNT = 16

function compactInventory()
	for i = 1, SLOTCOUNT do
		turtle.select(i)
		local currentSlot = turtle.getItemDetail(i)
		if currentSlot == nil or currentSlot.count == 0 or currentSlot.count == 64 then
			goto continue
		end

		for j = i + 1, SLOTCOUNT do
			turtle.select(j)
			local nextSlot = turtle.getItemDetail(j)

			if nextSlot ~= nil and nextSlot.name == currentSlot.name then
				turtle.transferTo(i, nextSlot.count)
			end
		end

		::continue::
	end
end

compactInventory()
