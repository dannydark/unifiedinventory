
unified_inventory.registered_group_items = {
	mesecon_conductor_craftable = "mesecons:wire_00000000_off",
	wool = "wool:white",
}

function unified_inventory.register_group_item(groupname, itemname)
	unified_inventory.registered_group_items[groupname] = itemname
end


-- This is used when displaying craft recipes, where an ingredient is
-- specified by group rather than as a specific item.  A single-item group
-- is represented by that item, with the single-item status signalled
-- in the "sole" field.  If the group contains no items at all, the item
-- field will be nil.
--
-- Within a multiple-item group, we prefer to use an item that has the
-- same specific name as the group, and if there are more than one of
-- those items we prefer the one registered for the group by a mod.
-- Among equally-preferred items, we just pick the one with the
-- lexicographically earliest name.

function compute_group_item(group_name)
	local candidate_items = {}
	for itemname, itemdef in pairs(minetest.registered_items) do
		if (itemdef.groups.not_in_creative_inventory or 0) == 0 and
				(itemdef.groups[group_name] or 0) ~= 0 then
			table.insert(candidate_items, itemname)
		end
	end
	local num_candidates = #candidate_items
	if num_candidates == 0 then
		return {sole = true}
	elseif num_candidates == 1 then
		return {item = candidate_items[1], sole = true}
	end
	local bestitem = ""
	local bestpref = 0
	for _, item in ipairs(candidate_items) do
		local pref
		if item == unified_inventory.registered_group_items[group_name] then
			pref = 3
		elseif item:gsub("^[^:]+:", "") == group_name then
			pref = 2
		else
			pref = 1
		end
		if pref > bestpref or (pref == bestpref and item < bestitem) then
			bestitem = item
			bestpref = pref
		end
	end
	return {item = bestitem, sole = false}
end


local group_item_cache = {}

function unified_inventory.get_group_item(group_name)
	if not group_item_cache[group_name] then
		group_item_cache[group_name] = compute_group_item(group_name)
	end
	return group_item_cache[group_name]
end

