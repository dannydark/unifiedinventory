unified_inventory.hud_colors = {
			{"#FFFFFF", 0xFFFFFF, "White"},
			{"#DBBB00", 0xf1d32c, "Yellow"},
			{"#DD0000", 0xDD0000, "Red"},
			{"#2cf136", 0x2cf136, "Green"},
			{"#2c4df1", 0x2c4df1, "Blue"},		
			}
unified_inventory.hud_colors_max = #unified_inventory.hud_colors
			
unified_inventory.register_page("waypoints", {
	get_formspec = function(player)
		local waypoints = datastorage.get_container (player, "waypoints")
		local formspec = "background[0,4.5;8,4;ui_main_inventory.png]"..
			"image[0,0;1,1;ui_waypoints_icon.png]"..
			"label[1,0;Waypoints]" 

		-- Tabs buttons:
		local i
		for i = 1, 5, 1 do
			if i == waypoints.selected then
				formspec = formspec ..
					"image_button[0.0,".. 0.2 + i*0.7 ..";.8,.8;ui_blue_icon_background.png^ui_"..
						i .."_icon.png;select_waypoint".. i .. ";]"
			else
				formspec = formspec ..
					"image_button[0.0,".. 0.2 + i*0.7 ..";.8,.8;ui_"..
					i .."_icon.png;select_waypoint".. i .. ";]"
			end
		end
		
		i = waypoints.selected
		
		-- Main buttons:
		formspec = formspec .. 
				"image_button[4.5,3.7;.8,.8;ui_waypoint_set_icon.png;set_waypoint".. i .. ";]"

		if waypoints[i].active then  
			formspec = formspec ..
				"image_button[5.2,3.7;.8,.8;ui_on_icon.png;toggle_waypoint".. i .. ";]"
		else 
			formspec = formspec ..
				"image_button[5.2,3.7;.8,.8;ui_off_icon.png;toggle_waypoint".. i .. ";]"
		end	

		if waypoints[i].display_pos then
			formspec = formspec .. 
				"image_button[5.9,3.7;.8,.8;ui_green_icon_background.png^ui_xyz_icon.png;toggle_display_pos".. i .. ";]"
		else
			formspec = formspec .. 
				"image_button[5.9,3.7;.8,.8;ui_red_icon_background.png^ui_xyz_icon.png;toggle_display_pos".. i .. ";]"
		end

		formspec = formspec .. 
				"image_button[6.6,3.7;.8,.8;ui_circular_arrows_icon.png;toggle_color".. i .. ";]"..
				"image_button[7.3,3.7;.8,.8;ui_pencil_icon.png;rename_waypoint".. i .. ";]"
		
		-- Waypoint's info:	
		if waypoints[i].active then
			formspec = formspec .. 	"label[1,0.8;Waypoint active]"
		else 
			formspec = formspec .. 	"label[1,0.8;Waypoint inactive]"
		end

		if waypoints[i].edit then
			formspec = formspec ..
				"field[1.3,3.2;6,.8;rename_box" .. i .. ";;"..waypoints[i].name.."]" ..
				"image_button[7.3,2.9;.8,.8;ui_ok_icon.png;confirm_rename".. i .. ";]"
		end
		
		formspec = formspec .. "label[1,1.3;World position: " .. 
			minetest.pos_to_string(waypoints[i].world_pos) .. "]" ..
			"label[1,1.8;Name: ".. waypoints[i].name .. "]" ..
			"label[1,2.3;Hud text color: " ..
			unified_inventory.hud_colors[waypoints[i].color][3] .. "]"
			
		return {formspec=formspec}
	end,
})

unified_inventory.register_button("waypoints", {
	type = "image",
	image = "ui_waypoints_icon.png",
})

unified_inventory.update_hud = function (player, waypoint)	
	local name
	if waypoint.display_pos then
		name = "(".. 
			waypoint.world_pos.x .. "," ..
			waypoint.world_pos.y .. "," ..
			waypoint.world_pos.z .. ")"
		if waypoint.name ~= "" then 	 
			name = name .. ", " ..
			waypoint.name
		end
	else
		name = waypoint.name
	end
	if waypoint.hud then
		player:hud_remove(waypoint.hud)
	end
	if waypoint.active then
		waypoint.hud = player:hud_add({
			hud_elem_type = "waypoint",
			number = unified_inventory.hud_colors[waypoint.color][2] ,
			name = name,
			text = "m",
			world_pos = waypoint.world_pos
		})
	else 
		waypoint.hud = nil
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then
		return
	end

	local update_formspec = false
	local update_hud = false
	
	local waypoints = datastorage.get_container (player, "waypoints")		
	for i = 1, 5, 1 do

		if fields["select_waypoint"..i] then
			waypoints.selected = i
			update_formspec = true
		end

		if fields["toggle_waypoint"..i] then
			waypoints[i].active = not (waypoints[i].active)
			update_hud = true
			update_formspec = true
		end
		
		if fields["set_waypoint"..i] then
			local pos = player:getpos()
			pos.x = math.floor(pos.x)
			pos.y = math.floor(pos.y)
			pos.z = math.floor(pos.z)
			waypoints[i].world_pos = pos
			update_hud = true
			update_formspec = true
		end
		
		if fields["rename_waypoint"..i] then
			waypoints[i].edit = true
			update_formspec = true
		end

		if fields["toggle_display_pos"..i] then
			waypoints[i].display_pos = not waypoints[i].display_pos
			update_hud = true
			update_formspec = true
		end

		if fields["toggle_color"..i] then
			local color = waypoints[i].color
			color = color + 1
			if color > unified_inventory.hud_colors_max then
				color = 1
			end
			waypoints[i].color = color
			update_hud = true
			update_formspec = true
		end

		if fields["confirm_rename"..i] then
			waypoints[i].edit = false
			waypoints[i].name = fields["rename_box"..i] 
			update_hud = true
			update_formspec = true
		end

		if update_hud then
			unified_inventory.update_hud (player, waypoints[i])
		end
	
		if update_formspec then
			unified_inventory.set_inventory_formspec(player, "waypoints")
		end
	
	end
end)

minetest.register_on_joinplayer(function(player)
	local waypoints = datastorage.get_container (player, "waypoints")
	local need_save = false
	-- Create new waypoints data
		for i = 1, 5, 1 do
			if waypoints[i] == nil then 
				need_save = true
				waypoints[i] = {
					edit = false,
					active = false,
					display_pos = true,
					color = 1,
					name = "Waypoint ".. i,
					world_pos = {x = 0, y = 0, z = 0},
				}
			end	
		end
	if need_save then datastorage.save_container (player) end

	-- Initialize waypoints
	minetest.after(0.5, function()
		waypoints.selected = 1
		for i = 1, 5, 1 do
			waypoints[i].edit = false
			unified_inventory.update_hud (player, waypoints[i])		
		end
	end)
end)
