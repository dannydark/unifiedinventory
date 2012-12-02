--loading modules
modpath=minetest.get_modpath("unified_inventory")
dofile(modpath.."/bags.lua")

-- expose api
unified_inventory = {}
-- define buttons
unified_inventory.buttons = {}
unified_inventory.control_buttons = {}
unified_inventory.players = {}
unified_inventory.current_page = {}
unified_inventory.current_index = {}
unified_inventory.items_list_size = 0
unified_inventory.items_list = {}
unified_inventory.filtered_items_list_size = {}
unified_inventory.filtered_items_list = {}
unified_inventory.activefilter = {}

-- default inventory page
unified_inventory.default = minetest.setting_get("inventory_default") or "craft"


local home_gui = {}
local homepos = {}
unified_inventory.home_filename = minetest.get_worldpath()..'/unified_inventory_home'

-- register_button
unified_inventory.register_button = function(player,name,label)
	local player_name = player:get_player_name()
	if unified_inventory.buttons[player_name] == nil then
		unified_inventory.buttons[player_name] = {}
	end
	unified_inventory.buttons[player_name][name] = label
end

unified_inventory.register_control_button = function(player,name,label)
	local player_name = player:get_player_name()
	if unified_inventory.control_buttons[player_name] == nil then
		unified_inventory.control_buttons[player_name] = {}
	end
	unified_inventory.control_buttons[player_name][name] = label
end

-- set_inventory_formspec
unified_inventory.set_inventory_formspec = function(player,formspec)
	if minetest.setting_getbool("creative_mode") then
		-- if creative mode is on then wait a bit
		minetest.after(0.01,function()
			player:set_inventory_formspec(formspec)
		end)
	else
		player:set_inventory_formspec(formspec)
	end
end

-- get_formspec
unified_inventory.get_formspec = function(player,page)
	local player_name = player:get_player_name()
	unified_inventory.current_page[player_name]=page
	
	local formspec = "size[14,10]"
	
	-- player inventory
	formspec = formspec .. "list[current_player;main;0,4.5;8,4;]"
	
	-- main buttons
		formspec = formspec .. "button[0,9;1.8,.5;craft;Craft]"
		formspec = formspec .. "button[1.6,9;1.8,.5;craftguide;Craft Guide]"
		formspec = formspec .. "button[3.2,9;1.8,.5;bags;Bags]"
		formspec = formspec .. "button[4.8,9;1.8,.5;misc;Misc.]"
		
	--controls to flip items pages
		local start_x=9.2
		formspec = formspec .. "button["..(start_x+.6*0)..",9;.8,.5;start_list;|<]"
		formspec = formspec .. "button["..(start_x+.6*1)..",9;.8,.5;rewind3;<<]"
		formspec = formspec .. "button["..(start_x+.6*2)..",9;.8,.5;rewind1;<]"
		formspec = formspec .. "button["..(start_x+.6*3)..",9;.8,.5;forward1;>]"
		formspec = formspec .. "button["..(start_x+.6*4)..",9;.8,.5;forward3;>>]"
		formspec = formspec .. "button["..(start_x+.6*5)..",9;.8,.5;end_list;>|]"
	
	-- search box	
		formspec = formspec .. "field[9.195,8.325;3,1;searchbox;;]"
	  	formspec = formspec .. "button[12,8;1.2,1;searchbutton;Search]"
	  	
	if page=="main" then
		return formspec
		end
	
	-- craft page
	if page=="craft" then
		formspec = formspec.."label[0,0;Crafting]"
		formspec = formspec.."list[current_player;craftpreview;5.25,2;1,1;]"
		formspec = formspec.."list[current_player;craft;1.75,1;3,3;]"
			if minetest.setting_getbool("creative_mode") then
				formspec = formspec.."label[0,2.5;Refill:]"
				formspec = formspec.."list[detached:refill;main;0,3;1,1;]"
				formspec = formspec.."label[7,2.5;Trash:]"
				formspec = formspec.."list[detached:trash;main;7,3;1,1;]"
			end
		end
		
	-- craft guide page
	if page=="craftguide" then
		formspec = formspec.."label[0,0;Crafting Guide]"
	end
		
	-- bags
	if page=="bags" then
	formspec = formspec.."label[0,0;Bags]"		
	formspec=formspec.."button[0,2;2,0.5;bag1;Bag 1]"
	formspec=formspec.."button[2,2;2,0.5;bag2;Bag 2]"
	formspec=formspec.."button[4,2;2,0.5;bag3;Bag 3]"
	formspec=formspec.."button[6,2;2,0.5;bag4;Bag 4]"
	formspec=formspec.."list[detached:"..player:get_player_name().."_bags;bag1;0.5,1;1,1;]"
	formspec=formspec.."list[detached:"..player:get_player_name().."_bags;bag2;2.5,1;1,1;]"
	formspec=formspec.."list[detached:"..player:get_player_name().."_bags;bag3;4.5,1;1,1;]"
	formspec=formspec.."list[detached:"..player:get_player_name().."_bags;bag4;6.5,1;1,1;]"
		end
	
	for i=1,4 do
		if page=="bag"..i then
			local image = player:get_inventory():get_stack("bag"..i, 1):get_definition().inventory_image
			formspec=formspec.."image[7,0;1,1;"..image.."]"
			formspec=formspec.."list[current_player;bag"..i.."contents;0,1;8,3;]"
		end
	end
	
	-- Miscellaneous
	if page=="misc" then
		formspec = formspec.."label[0,0;Miscellaneous]"
		formspec=formspec.."button[0,1;2,0.5;home_gui_set;Set Home]"
		formspec=formspec.."button_exit[2,1;2,0.5;home_gui_go;Go Home]"
		local home = homepos[player:get_player_name()]
		if home ~= nil then
		formspec = formspec
			formspec=formspec.."label[4,.9;Home set to:]"
			formspec=formspec.."label[5.7,.9;("..math.floor(home.x)..","..math.floor(home.y)..","..math.floor(home.z)..")]"
		end	
		if minetest.setting_getbool("creative_mode") then
			formspec=formspec.."button[0,2;2,0.5;misc_set_day;Set Day]"
			formspec=formspec.."button[2,2;2,0.5;misc_set_night;Set Night]"
		end
	end
	
	--Items list
	local list_index=unified_inventory.current_index[player_name]
	local page=math.floor(list_index / (80) + 1)
	local pagemax = math.floor((unified_inventory.filtered_items_list_size[player_name]-1) / (80) + 1)
	local image
	local item={}
	for y=0,9,1 do
	for x=0,7,1 do
		name=unified_inventory.filtered_items_list[player_name][list_index]	
		if minetest.registered_items[name] then
		formspec=formspec.."item_image_button["..(8.2+x*.7)..","..(1+y*.7)..";.81,.81;"..name..";item_button"..list_index..";]"
		list_index=list_index+1
		end
	end
	end	
	formspec=formspec.."label[8.2,0;Page:]"
	formspec=formspec.."label[9,0;"..page.."/"..pagemax.."]"
	formspec=formspec.."label[8.2,0.4;Filter:]"
	formspec=formspec.."label[9,0.4;"..unified_inventory.activefilter[player_name].."]"
	return formspec
end

-- trash slot
unified_inventory.trash = minetest.create_detached_inventory("trash", {
	allow_put = function(inv, listname, index, stack, player)
		if minetest.setting_getbool("creative_mode") then
			return stack:get_count()
		else
			return 0
		end
	end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, nil)
	end,
})
unified_inventory.trash:set_size("main", 1)

-- refill slot
unified_inventory.refill = minetest.create_detached_inventory("refill", {
	allow_put = function(inv, listname, index, stack, player)
		if minetest.setting_getbool("creative_mode") then
			return stack:get_count()
		else
			return 0
		end
	end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, ItemStack(stack:get_name().." "..stack:get_stack_max()))
	end,
})
unified_inventory.refill:set_size("main", 1)

-- register_on_joinplayer
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	table.insert(unified_inventory.players, player_name)
	unified_inventory.current_index[player_name] = 1
	minetest.after(1,function()
		unified_inventory.set_inventory_formspec(player,unified_inventory.get_formspec(player, unified_inventory.default))
	end)
	unified_inventory.filtered_items_list[player_name] = {}
	unified_inventory.filtered_items_list[player_name] = unified_inventory.items_list
	unified_inventory.filtered_items_list_size[player_name]=unified_inventory.items_list_size
	unified_inventory.activefilter[player_name]=""
end)

-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local player_name = player:get_player_name()
	
	-- main
	if fields.craft then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"craft"))
		return
	end
	
	if fields.craftguide then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"craftguide"))
		return
	end
	
	if fields.bags then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"bags"))
		return
	end
	
	if fields.misc then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"misc"))
		return
	end
	
	-- bags
	for i=1,4 do
		local page = "bag"..i
		if fields[page] then
			if player:get_inventory():get_stack(page, 1):get_definition().groups.bagslots==nil then
				page = "bags"
			end
			unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,page))
			return
		end
	end
	
	-- Miscellanous
	if fields.home_gui_set then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"misc"))
		unified_inventory.set_home(player, player:getpos())
	end
	if fields.home_gui_go then
		unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,"craft"))
		unified_inventory.go_home(player)
	end
	if fields.misc_set_day then
		minetest.env:set_timeofday((12000 % 24000) / 24000)
		minetest.chat_send_player(player_name, "Time of day set to noon.")
	end
	if fields.misc_set_night then
		minetest.env:set_timeofday(0)
		minetest.chat_send_player(player_name, "Time of day set to midnight.")	
	end
	
	-- Inventory page controls
	local start_i=math.floor(unified_inventory.current_index[player_name]/80 +1 )
	local pagemax = math.floor((unified_inventory.filtered_items_list_size[player_name]-1) / (80) + 1)
	
	if fields.start_list then
		start_i = 1
	end
	if fields.rewind1 then
		start_i = start_i - 1
	end
	if fields.forward1 then
		start_i = start_i + 1
	end
	if fields.rewind3 then
		start_i = start_i - 3
	end
	if fields.forward3 then
		start_i = start_i + 3
	end
	if fields.end_list then
		start_i = pagemax
	end
	if start_i < 1 then
		start_i = 1
	end
	if start_i > pagemax then
		start_i =  pagemax
	end
		
	unified_inventory.current_index[player_name] = (start_i-1)*80+1
	unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,unified_inventory.current_page[player_name]))
	
	local list_index=unified_inventory.current_index[player_name]
	
	for i=0,80,1 do
		local button="item_button"..list_index
		if fields[button] then 
			local input={}
			input=minetest.get_craft_recipe(unified_inventory.filtered_items_list[player_name][list_index])
			print (dump(input))
			if minetest.setting_getbool("creative_mode") then
				local inv = player:get_inventory()
				dst_stack={}
				dst_stack["name"] = unified_inventory.filtered_items_list[player_name][list_index] 
				dst_stack["count"]=99
				if inv:room_for_item("main",dst_stack) then
				inv:add_item("main",dst_stack)
				end
			end	
		end	
	list_index=list_index+1
	end
	
	if fields.searchbutton then
		local size=0
		unified_inventory.filtered_items_list[player_name]={}
		for name,def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory or def.groups.not_in_creative_inventory == 0)
				and def.description and def.description ~= "" then
			if string.find(def.name, fields.searchbox) or string.find(def.description, fields.searchbox) then
				table.insert(unified_inventory.filtered_items_list[player_name], name)
				size=size+1
			end
		end
	
	end
	table.sort(unified_inventory.filtered_items_list[player_name])
	unified_inventory.filtered_items_list_size[player_name]=size
	unified_inventory.current_index[player_name]=1	
	unified_inventory.activefilter[player_name]=fields.searchbox
	unified_inventory.set_inventory_formspec(player, unified_inventory.get_formspec(player,unified_inventory.current_page[player_name]))
	end	
	
end)

-- load_home
local load_home = function()
    local input = io.open(unified_inventory.home_filename..".home", "r")
    if input then
        while true do
            local x = input:read("*n")
            if x == nil then
                break
            end
            local y = input:read("*n")
            local z = input:read("*n")
            local name = input:read("*l")
            homepos[name:sub(2)] = {x = x, y = y, z = z}
        end
        io.close(input)
    else
        homepos = {}
    end
end
load_home() -- run it now

-- set_home
unified_inventory.set_home = function(player, pos)
	homepos[player:get_player_name()] = pos
	-- save the home data from the table to the file
	local output = io.open(unified_inventory.home_filename..".home", "w")
	for k, v in pairs(homepos) do
		if v ~= nil then
			output:write(math.floor(v.x).." "..math.floor(v.y).." "..math.floor(v.z).." "..k.."\n")
		end
	end
	io.close(output)
end

-- go_home 
unified_inventory.go_home = function(player)
	local pos = homepos[player:get_player_name()]
	if pos~=nil then
		player:setpos(pos)
	end
end


-- Create detached creative inventory after loading all mods
minetest.after(0.01, function()
	unified_inventory.items_list = {}
	for name,def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory or def.groups.not_in_creative_inventory == 0)
				and def.description and def.description ~= "" then
			table.insert(unified_inventory.items_list, name)
		end
	end
	table.sort(unified_inventory.items_list)
	unified_inventory.items_list_size = #unified_inventory.items_list
	print ("Unified Inventory. inventory size: "..unified_inventory.items_list_size)

end)

