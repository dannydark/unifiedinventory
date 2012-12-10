-- override minetest.register_craft
crafts_table ={}
crafts_table_count=0

local minetest_register_craft = minetest.register_craft
minetest.register_craft = function (options) 
	minetest_register_craft(options) 
	register_craft(options)
end

-- register_craft
register_craft = function(options)
	if  options.output == nil then
		return
	end
	local itemstack = ItemStack(options.output)
	if itemstack:is_empty() then
		return
	end
	if crafts_table[itemstack:get_name()]==nil then
		crafts_table[itemstack:get_name()] = {}
	end
	table.insert(crafts_table[itemstack:get_name()],options)
	crafts_table_count=crafts_table_count+1
end


