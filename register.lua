
minetest.register_privilege("creative", {
	description = "Can use the creative inventory",
	give_to_singleplayer = false,
})

local trash = minetest.create_detached_inventory("trash", {
	--allow_put = function(inv, listname, index, stack, player)
	--	if unified_inventory.is_creative(player:get_player_name()) then
	--		return stack:get_count()
	--	else
	--		return 0
	--	end
	--end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, nil)
		local player_name = player:get_player_name()
		minetest.sound_play("trash", {to_player=player_name, gain = 1.0})
	end,
})
trash:set_size("main", 1)

unified_inventory.register_button("craft", {
	type = "image",
	image = "ui_craft_icon.png",
})

unified_inventory.register_button("craftguide", {
	type = "image",
	image = "ui_craftguide_icon.png",
})

unified_inventory.register_button("home_gui_set", {
	type = "image",
	image = "ui_sethome_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		unified_inventory.set_home(player, player:getpos())
		local home = unified_inventory.home_pos[player_name]
		if home ~= nil then
			minetest.sound_play("dingdong",
					{to_player=player_name, gain = 1.0})
			minetest.chat_send_player(player_name,
					"Home position set to: "
					..minetest.pos_to_string(home))
		end
	end,
})

unified_inventory.register_button("home_gui_go", {
	type = "image",
	image = "ui_gohome_icon.png",
	action = function(player)
		minetest.sound_play("teleport",
				{to_player=player:get_player_name(), gain = 1.0})
		unified_inventory.go_home(player)
	end,
})

unified_inventory.register_button("misc_set_day", {
	type = "image",
	image = "ui_sun_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then
			minetest.sound_play("birds",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((6000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
					"Time of day set to 6am")
		else
			minetest.chat_send_player(player_name,
					"You don't have the"
					.." settime priviledge!")
		end
	end,
})

unified_inventory.register_button("misc_set_night", {
	type = "image",
	image = "ui_moon_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then
			minetest.sound_play("owl",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((21000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
					"Time of day set to 9pm")
		else
			minetest.chat_send_player(player_name,
					"You don't have the"
					.." settime priviledge!")
		end
	end,
})

unified_inventory.register_button("clear_inv", {
	type = "image",
	image = "ui_trash_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if not unified_inventory.is_creative(player_name) then
			minetest.chat_send_player(player_name,
					"This button has been disabled outside"
					.." of creative mode to prevent"
					.." accidental inventory trashing."
					.." Use the trash slot instead.")
			return
		end
		player:get_inventory():set_list("main", {})
		minetest.chat_send_player(player_name, 'Inventory Cleared!')
		minetest.sound_play("trash_all",
				{to_player=player_name, gain = 1.0})
	end,
})

unified_inventory.register_page("craft", {
	get_formspec = function(player, formspec)
		local player_name = player:get_player_name()
		local formspec = "background[0,1;8,3;ui_crafting_form.png]"
		formspec = formspec.."background[0,4.5;8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,0;Crafting]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		formspec = formspec.."list[current_player;craftpreview;6,1;1,1;]"
		formspec = formspec.."list[current_player;craft;2,1;3,3;]"
		formspec = formspec.."label[7,2.5;Trash:]"
		formspec = formspec.."list[detached:trash;main;7,3;1,1;]"
		if unified_inventory.is_creative(player_name) then
			formspec = formspec.."label[0,2.5;Refill:]"
			formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."refill;main;0,3;1,1;]"
		end
		return {formspec=formspec}
	end,
})

-- group_representative_item(): select representative item for a group
--
-- This is used when displaying craft recipes, where an ingredient is
-- specified by group rather than as a specific item.  A single-item group
-- is represented by that item, with the single-item status signalled
-- so that stack_image_button() can treat it as just the item.  If the
-- group contains no items at all, it will be treated as containing a
-- single unknown item.
--
-- Within a multiple-item group, we prefer to use an item that has the
-- same specific name as the group, and if there are more than one of
-- those items we prefer the one specified by the default mod if there
-- is one.  If this produces a bad result, the mod defining a group can
-- register its preference for which item should represent the group,
-- and we'll use that instead if possible.  Also, for a handful of groups
-- (predating this registration system) we have built-in preferences
-- that are used like registered preferences.  Among equally-preferred
-- items, we just pick the one with the lexicographically earliest name,
-- for determinism.
local builtin_group_representative_items = {
	mesecon_conductor_craftable = "mesecons:wire_00000000_off",
	stone = "default:cobble",
	wool = "wool:white",
}
local function compute_group_representative_item(groupspec)
	local groupname = string.sub(groupspec, 7)
	local candidate_items = {}
	for itemname, itemdef in pairs(minetest.registered_items) do
		if (itemdef.groups.not_in_creative_inventory or 0) == 0 and (itemdef.groups[groupname] or 0) ~= 0 then
			table.insert(candidate_items, itemname)
		end
	end
	if #candidate_items == 0 then return { item = "unobtainium!", sole = true } end
	if #candidate_items == 1 then return { item = candidate_items[1], sole = true } end
	local bestitem = ""
	local bestpref = 0
	for _, item in ipairs(candidate_items) do
		local pref
		if item == unified_inventory.registered_group_representative_items[groupname] then
			pref = 5
		elseif item == builtin_group_representative_items[groupname] then
			pref = 4
		elseif item == "default:"..groupname then
			pref = 3
		elseif item:gsub("^[^:]*:", "") == groupname then
			pref = 2
		else
			pref = 1
		end
		if pref > bestpref or (pref == bestpref and item < bestitem) then
			bestitem = item
			bestpref = pref
		end
	end
	return { item = bestitem, sole = false }
end
local group_representative_item_cache = {}
local function group_representative_item(groupspec)
	if not group_representative_item_cache[groupspec] then
		group_representative_item_cache[groupspec] = compute_group_representative_item(groupspec)
	end
	return group_representative_item_cache[groupspec]
end

-- stack_image_button(): generate a form button displaying a stack of items
--
-- Normally a simple item_image_button[] is used.  If the stack contains
-- more than one item, item_image_button[] doesn't have an option to
-- display an item count in the way that an inventory slot does, so
-- we have to fake it using the label facility.  This doesn't let us
-- specify that the count should appear at bottom right, so we use some
-- dodgy whitespace to shift it away from the centre of the button.
-- Unfortunately the correct amount of whitespace depends on display
-- resolution, so the results from this will be variable.  This should be
-- replaced as soon as the engine adds support for a proper item count,
-- or at least label placement control, on buttons.
--
-- The specified item may be a group.  In that case, the group will be
-- represented by some item in the group, along with a flag indicating
-- that it's a group.  If the group contains only one item, it will be
-- treated as if that item had been specified directly.
local function stack_image_button(x, y, w, h, buttonname_prefix, stackstring)
	local st = ItemStack(stackstring)
	local specitem = st:get_name()
	local c = st:get_count()
	local clab = c == 1 and "       " or string.format("%7d", c)
	local gflag, displayitem, selectitem
	if string.sub(specitem, 1, 6) == "group:" then
		local gri = group_representative_item(specitem)
		gflag = not gri.sole
		displayitem = gri.item
		selectitem = gri.sole and gri.item or specitem
	else
		gflag = false
		displayitem = specitem
		selectitem = specitem
	end
	local label = string.format("\n\n%s%7d", gflag and "G" or "  ", c):gsub(" 1$", " .")
	if label == "\n\n        ." then label = "" end
	return "item_image_button["..x..","..y..";"..w..","..h..";"..minetest.formspec_escape(displayitem)..";"..minetest.formspec_escape(buttonname_prefix..selectitem)..";"..label.."]"
end

unified_inventory.register_page("craftguide", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local formspec = ""
		formspec = formspec.."background[0,4.5;8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,0;Crafting Guide]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		local craftinv = minetest.get_inventory({
			type = "detached",
			name = player_name.."craftrecipe"
		})
		local item_name = unified_inventory.current_item[player_name]
		if not item_name then return {formspec=formspec} end
		formspec = formspec.."textarea[0.3,0.6;10,1;;Result: "..minetest.formspec_escape(item_name)..";]"
		formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."craftrecipe;output;6,1;1,1;]"

		local alternate, alternates, craft, craft_type
		alternate = unified_inventory.alternate[player_name]
		local crafts = unified_inventory.crafts_table[item_name]
		if crafts ~= nil and #crafts > 0 then
			alternates = #crafts
			craft = crafts[alternate]
		end
		if not craft then
			craftinv:set_stack("output", 1, item_name)
			formspec = formspec.."label[6,3.35;No recipes]"
			return {formspec=formspec}
		end

		formspec = formspec.."background[0,1;8,3;ui_craftguide_form.png]"
		craft_type = unified_inventory.registered_craft_types[craft.type] or unified_inventory.canonicalise_craft_type(craft.type, {})
		formspec = formspec.."label[6,3.35;Method:]"
		formspec = formspec.."label[6,3.75;"..minetest.formspec_escape(craft_type.description).."]"
		craftinv:set_stack("output", 1, craft.output)

		-- fake buttons just to make grid
		for y = 1, craft_type.height do
		for x = 1, craft_type.width do
			formspec = formspec.."image_button["
				..(1.0 + x)..","..(0.0 + y)..";1.1,1.1;ui_blank_image.png;;]"
		end
		end

		local width = craft.width
		if width == 0 then
			-- Shapeless recipe
			width = craft_type.width
		end

		local i = 1
		for y = 1, craft_type.height do
		for x = 1, width do
			local item = craft.items[i]
			if item then
				formspec = formspec..stack_image_button(1.0+x, 0.0+y, 1.1, 1.1, "item_button_", item)
			end
			i = i + 1
		end
		end

		if craft_type.uses_crafting_grid then
			formspec = formspec.."label[6,1.95;Copy to craft grid:]"
					.."button[6,2.5;0.6,0.5;craftguide_craft_1;1]"
					.."button[6.6,2.5;0.6,0.5;craftguide_craft_10;10]"
					.."button[7.2,2.5;0.6,0.5;craftguide_craft_max;All]"
		end

		if alternates > 1 then
			formspec = formspec.."label[0,2.6;Recipe "
					..tostring(alternate).." of "
					..tostring(alternates).."]"
					.."button[0,3.15;2,1;alternate;Alternate]"
		end
		return {formspec=formspec}
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local amount
	for k, v in pairs(fields) do
		amount = k:match("craftguide_craft_(.*)")
		if amount then break end
	end
	if not amount then return end
	local player_name = player:get_player_name()
	local recipe_inv = minetest.get_inventory({
		type="detached",
		name=player_name.."craftrecipe",
	})

	local output = unified_inventory.current_item[player_name]
	if (not output) or (output == "") then return end

	local player_inv = player:get_inventory()

	local crafts = unified_inventory.crafts_table[output]
	if (not crafts) or (#crafts == 0) then return end

	local alternate = unified_inventory.alternate[player_name]

	local craft = crafts[alternate]
	if craft.width > 3 then return end

	local needed = craft.items

	local craft_list = player_inv:get_list("craft")

	local width = craft.width
	if width == 0 then
		-- Shapeless recipe
		width = 3
	end

	if amount == "max" then
		amount = 99 -- Arbitrary; need better way to do this.
	else
		amount = tonumber(amount)
	end

	for iter = 1, amount do
		local index = 1
		for y = 1, 3 do
			for x = 1, width do
				local needed_item = needed[index]
				if needed_item then
					local craft_index = ((y - 1) * 3) + x
					local craft_item = craft_list[craft_index]
					if (not craft_item) or (craft_item:is_empty()) or (craft_item:get_name() == needed_item) then
						itemname = craft_item and craft_item:get_name() or needed_item
						local needed_stack = ItemStack(needed_item)
						if player_inv:contains_item("main", needed_stack) then
							local count = (craft_item and craft_item:get_count() or 0) + 1
							if count <= needed_stack:get_definition().stack_max then
								local stack = ItemStack({name=needed_item, count=count})
								craft_list[craft_index] = stack
								player_inv:remove_item("main", needed_stack)
							end
						end
					end
				end
				index = index + 1
			end
		end
	end

	player_inv:set_list("craft", craft_list)

	unified_inventory.set_inventory_formspec(player, "craft")
end)
