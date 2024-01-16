

local addonName, addon = ...;

local Database = addon.Database;

Equipmate.Api = {}

---Scan the players currently equipped items
---@return table equipment an ipairs table of items
function Equipmate.Api.GetPlayerEquipment()
    local equipment = {}
    for k, v in ipairs(Equipmate.Constants.InventorySlots) do
        local slotID = GetInventorySlotInfo(v.slot)
        local link = GetInventoryItemLink('player', slotID)
        if link then
            local itemLoc = ItemLocation:CreateFromEquipmentSlot(slotID)
            if itemLoc then
                local itemGUID = C_Item.GetItemGUID(itemLoc)
                table.insert(equipment, {
                    slot = v.slot,
                    icon = v.icon,
                    link = link,
                    guid = itemGUID,
                    slotID = slotID,
                })
            end
        else
            table.insert(equipment, {
                slot = v.slot,
                icon = v.icon,
                link = false,
                guid = false,
                slotID = false,
            })
        end
    end
    return equipment;
end


function Equipmate.Api.GetEquipmentSetsForCharacter(nameRealm)

    local t = {}

    local outfits = Database:GetOutfits(nameRealm)

    if #outfits > 0 then
        for k, outfit in ipairs(outfits) do
            local copy = {}
            for x, y in pairs(outfit) do
                if type(y) ~= "table" then
                    copy[x] = y;
                else
                    if x == "items" then
                        local items = {}
                        for a, b in ipairs(y) do
                            table.insert(items, b)
                        end
                        copy.items = items;
                    end
                end
            end
            table.insert(t, copy)
        end
    end

    return t;
end


function Equipmate.Api.GetInfoForEquipmentSetItems(items)

    local playerBags = {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc then
                    local guid = C_Item.GetItemGUID(itemLoc)
                    playerBags[guid] = {
                        bag = bag,
                        slot = slot,
                    }
                    --print("added", info.hyperlink, guid)
                end
            end
        end
    end

    --DevTools_Dump(playerBags)

    local ret = {
        numItems = 1,
        totalItemLevel = 1,
        itemsInBags = {},
        itemsInBank = {},
    }
    for k, v in ipairs(items) do
        -- local item = Item:CreateFromItemLink(v.link)
        -- if not item:IsItemEmpty() then
            
        -- end
        if type(v.link) == "string" then
            local effectiveILvl, isPreview, baseILvl = GetDetailedItemLevelInfo(v.link)
            ret.numItems = ret.numItems + 1
            ret.totalItemLevel = ret.totalItemLevel + effectiveILvl;
        end
        if type(v.guid) == "string" then
            --print(v.link, v.guid)
            if type(playerBags[v.guid]) == "table" then
                table.insert(ret.itemsInBags, v)
            end
        end
    end

    ret.averageItemLevel = tonumber(string.format("%.2f", (ret.totalItemLevel / ret.numItems)))

    --DevTools_Dump(ret)

    return ret;
end


---Performs checks on the item provided to see if it fits the inventory slot and class/character skills
---@return boolean
function Equipmate.Api.TestItemForClassAndSlot(unitClassID, equipLoc, itemClassID, itemSubClassID, invSlot, ignoreSkillCheck)

    local armorCheck, weaponCheck = false, false;
    if (itemClassID == 2) and (not ignoreSkillCheck) then
        local weaponSpellID = Equipmate.Constants.ItemSubClassIdToWeaponSkillSpellId[itemSubClassID]
        if type(weaponSpellID) == "number" then
            weaponCheck = IsPlayerSpell(weaponSpellID)
        end

        --override for generic (skinning knife)
        if itemSubClassID == Enum.ItemWeaponSubclass.Generic then
            weaponCheck = true;
        end
    end


    if itemClassID == 4 then
        --[[
            TODO:
                make class table for these subClassID, ie librams for paladins etc
        ]]

        -- Spellstones, Firestones, Trinkets, Rings and Necks
        if itemSubClassID == 0 then

            --mostly these items are usable by all classes
            armorCheck = true;


        --cosmetic
        elseif itemSubClassID == 5 then

        --shields
        elseif itemSubClassID == 6 then
            armorCheck = IsPlayerSpell(Equipmate.Constants.ClassSkillSpellId.Shields)
            
        --librams
        elseif itemSubClassID == 7 then
            
        --idols
        elseif itemSubClassID == 8 then
            
        --totems
        elseif itemSubClassID == 9 then
            
        --sigil
        elseif itemSubClassID == 10 then
            
        --relic
        elseif itemSubClassID == 11 then

        else
            --it shouldn't go out of these bounds but just check
            if (itemSubClassID >= 1) and (itemSubClassID <= 4) and (type(Equipmate.Constants.ItemSubClassIdToArmorSkillSpellId[itemSubClassID]) == "number") then
                armorCheck = IsPlayerSpell(Equipmate.Constants.ItemSubClassIdToArmorSkillSpellId[itemSubClassID])
            end
        end
    end

    --local canDualWield = IsPlayerSpell(Equipmate.Constants.ClassSkillSpellId.DualWield)

    local invSlotID = Equipmate.Constants.GlobalNameToInvSlot[equipLoc]
    local slotMatch;
    if type(invSlotID) == "table" then
        for k, v in ipairs(invSlotID) do
            if v == invSlot then
                slotMatch = v;
            end
        end
    else
        slotMatch = invSlotID
    end

    if (weaponCheck or armorCheck) and (invSlot == slotMatch) then

        --print(string.format("got to the item GUID call using bag %s and slot %s", bag, slot))

        return true
    end

    return false
end


---Scan the player containers for items that fit the specified inventory slot
---@param invSlot number the inventory slot ID
---@param includeBank boolean indicates if bank containers should be scanned
---@return table items an ipairs table of items
function Equipmate.Api.GetItemsForInvSlot(invSlot, includeBank)

    local _, _, classID = UnitClass("player")

    local items = {}

    local link = GetInventoryItemLink('player', invSlot)

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local _, _, _, equipLoc, icon, itemClassID, itemSubClassID = GetItemInfoInstant(info.hyperlink)
                if itemClassID == 2 or itemClassID == 4 then
                    local match = Equipmate.Api.TestItemForClassAndSlot(classID, equipLoc, itemClassID, itemSubClassID, invSlot, IsShiftKeyDown())
                    if match then
                        local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                        if itemLoc then
                            local guid = C_Item.GetItemGUID(itemLoc)
                            table.insert(items, {
                                link = info.hyperlink,
                                guid = guid,
                                invSlotID = invSlot,
                                icon = icon,
                                bag = bag,
                                slot = slot,
                            })
                        end
                    end
                end
            end
        end
    end

    if includeBank then

        --bank
        for slot = 1, C_Container.GetContainerNumSlots(-1) do
            local info = C_Container.GetContainerItemInfo(-1, slot)
            if info and info.hyperlink then
                local _, _, _, equipLoc, icon, itemClassID, itemSubClassID = GetItemInfoInstant(info.hyperlink)
                if itemClassID == 2 or itemClassID == 4 then
                    local match, slotID = Equipmate.Api.TestItemForClassAndSlot(classID, equipLoc, itemClassID, itemSubClassID, invSlot, IsShiftKeyDown())
                    if match then
                        local itemLoc = ItemLocation:CreateFromBagAndSlot(-1, slot)
                        if itemLoc then
                            local guid = C_Item.GetItemGUID(itemLoc)
                            table.insert(items, {
                                link = info.hyperlink,
                                guid = guid,
                                invSlotID = invSlot,
                                icon = icon,
                                bag = -1,
                                slot = slot,
                            })
                        end
                    end
                end
            end
        end
        
        --bank bags
        for bag = 5, 11 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.hyperlink then
                    local _, _, _, equipLoc, icon, itemClassID, itemSubClassID = GetItemInfoInstant(info.hyperlink)
                    if itemClassID == 2 or itemClassID == 4 then
                        local match, slotID = Equipmate.Api.TestItemForClassAndSlot(classID, equipLoc, itemClassID, itemSubClassID, invSlot, IsShiftKeyDown())
                        if match then
                            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                            if itemLoc then
                                local guid = C_Item.GetItemGUID(itemLoc)
                                table.insert(items, {
                                    link = info.hyperlink,
                                    guid = guid,
                                    invSlotID = invSlot,
                                    icon = icon,
                                    bag = bag,
                                    slot = slot,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    return items;
end

function Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(button, isReversed)
	if ( button:GetParent().verticalFlyout ) then
		if ( isReversed ) then
			button:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0, 0.5);
			--button:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 0.5, 1);
		else
			button:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0);
			--button:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5);
		end
	else
		if ( isReversed ) then
			button:GetNormalTexture():SetTexCoord(0.15625, 0, 0.84375, 0, 0.15625, 0.5, 0.84375, 0.5);
			--button:GetHighlightTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 1, 0.84375, 1);
		else
			button:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0);
			--button:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5);
		end
	end
end


function Equipmate.Api.EquipItemsFromKeyBinding(id)
    
    local outfit = Database:GetOutfitFromKeyBindingID(id)
    if outfit and outfit.items then
        Equipmate.Api.EquipItemSet(outfit.items, Equipmate.Constants.IsBankOpen)
    end
end



function Equipmate.Api.EquipItemSet(items, isBankOpen)
    --these need to be checked for container types - ammo/shards etc
    local bagsWithEmptySlots = {}
    local emptySlotindex = 1
    for bag = 4, 0, -1 do
        local freeSlots = C_Container.GetContainerFreeSlots(bag)
        if #freeSlots > 0 then
            for k, v in ipairs(freeSlots) do
                bagsWithEmptySlots[emptySlotindex] = bag
                emptySlotindex = emptySlotindex + 1;
            end
        end
    end

    --DevTools_Dump(bagsWithEmptySlots)

    local function equipItem(invSlot, bag, slot)
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if itemLoc then
                local itemGUID = C_Item.GetItemGUID(itemLoc)
                if invSlot.guid == itemGUID then

                    --this seems to work well with the bank items
                    --the logic is to pick up the new item and swap with what was in the slot
                    --in theory this means that items being removed will have an empty slot waiting
                    --however ignored slots create a potential issue as they require bag/bank space to be available (see below)
                    C_Container.PickupContainerItem(bag, slot)
                    PickupInventoryItem(GetInventorySlotInfo(invSlot.slot))

                    --EquipItemByName(info.hyperlink, GetInventorySlotInfo(invSlot.slot))

                    --it could work better to use container item as the bag/slot are known
                    --C_Container.UseContainerItem(bag, slot)

                    return true
                end
            end
        end
        return false;
    end

    local i = 1;
    C_Timer.NewTicker(0.01, function() --ticker might not be needed with the pre mapping of empty slots
        local v = items[i]

        if v.ignored then
            --do nothing user is ignoring this slot
        else
            if v.guid then
                local equipped = false;
                for bag = 0, 4 do
                    if equipped == false then
                        for slot = 1, C_Container.GetContainerNumSlots(bag) do
                            equipped = equipItem(v, bag, slot)
                        end
                    end
                end
    
                if isBankOpen then
                    for slot = 1, C_Container.GetContainerNumSlots(-1) do
                        equipped = equipItem(v, -1, slot)
                    end
                    for bag = 5, 11 do
                        if equipped == false then
                            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                                equipped = equipItem(v, bag, slot)
                            end
                        end
                    end
                end
    
            else
    
                --print(string.format("slot %s is ignored, removing %s", v.slot, tostring(v.link)))
    
                --the premapped empty slots should remain as anything swapped before would go into the slot created by the new item beign equipped
                --this will attempt to remove an item and place into an empty slot
                --if no empty slots exist put the item back into its slot
                if #bagsWithEmptySlots > 0 then
                    local bag = bagsWithEmptySlots[#bagsWithEmptySlots]
    
                    --print(string.format("attempting to put item in bag %s", bag))
    
                    if bag == 0 then
                        PickupInventoryItem(GetInventorySlotInfo(v.slot))
                        PutItemInBackpack()
                        bagsWithEmptySlots[#bagsWithEmptySlots] = nil
                    else
                        PickupInventoryItem(GetInventorySlotInfo(v.slot))
                        PutItemInBag(C_Container.ContainerIDToInventoryID(bag))
                        bagsWithEmptySlots[#bagsWithEmptySlots] = nil
                    end
    
                    --unequipping unsuccessful so place item back
                    if CursorHasItem() then
                        PickupInventoryItem(GetInventorySlotInfo(v.slot))
                    end
                end
            end
        end


        i = i + 1;
    end, #items)
end




























local itemsScanned = {}
function Equipmate.Api.GetAttributesFromTooltip(link)

    -- print("====================")
    -- print(link)

    if itemsScanned[link] then
        --DevTools_Dump(itemsScanned[item.link])
        return itemsScanned[link]
    else
        itemsScanned[link] = {}
    end

    --itemsScanned[link] = {}

    local sockets = {
        "EMPTY_SOCKET_BLUE",
        "EMPTY_SOCKET_YELLOW",
        "EMPTY_SOCKET_RED",
        "EMPTY_SOCKET_META",
    }

    EquipmateScanningTooltip:ClearLines()
    EquipmateScanningTooltip:SetHyperlink(link)
    --C_Timer.After(0.1, function()
        local regions = {EquipmateScanningTooltip:GetRegions()}
        for k, region in ipairs(regions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if type(text) == "string" then

                    local lb, hyp, ub, school = strsplit(" ", text)
                    lb = tonumber(lb)
                    ub = tonumber(ub)
                    if (type(lb) == "number") and (hyp == "-") and (type(ub) == "number") then
                        --print(string.format("%s : min %d max %d", link, lb, ub))
                    end

                    local number = tonumber(text:match("%-?%d+"))
                    local attribute = text:gsub("%-?%d+", "%%d")
                    local _, stat = strsplit(" ", attribute)

                    local x = ITEM_MOD_INTELLECT_SHORT

                    for a, b in pairs(Equipmate.Constants.ItemStatGlobals) do
                        print(type(stat), type(b))
                        if type(stat) == "string" then
                            if stat == b then
                                print("found stat")
                            end
                            print(stat, a, b)
                            print(#stat, #a, #b)
                        end
                    end

                    -- print(">"..(stat or "-").."<")
                    -- print(ITEM_MOD_INTELLECT_SHORT)


                    --if Equipmate.Constants.ItemStatGlobals[stat] then
                    if stat == x then
                        --print("got stat in table")
                        --print(x, stat, number)
                    end




                    local number = tonumber(text:match("%-?%d+"))
                    if number then
                        table.insert(itemsScanned[link], {
                            attribute = text:gsub("%-?%d+", "%%d"),
                            value = number,
                            displayText = text,
                        })
                    else
                        for k, socket in ipairs(sockets) do
                            if text == _G[socket] then
                                table.insert(itemsScanned[link], {
                                    attribute = text:gsub("%-?%d+", "%%d"),
                                    value = number or 1,
                                    displayText = text,
                                })
                            end
                        end
                    end
                end
            end
        end
        --DevTools_Dump(itemsScanned[item.link])
        return itemsScanned[link]
    --end)

    
    -- local stats;
    -- if item.link then
    --     stats = GetItemStats(item.link)
    -- end

    -- if type(stats) == "table" then
        
    --     local t = {}

    --     for stat, value in pairs(stats) do
            
    --         if _G[stat]:find("%%") then
    --             local s = _G[stat]:format(value)
    --             table.insert(t, {
    --                 stat = _G[stat],
    --                 value = value,
    --                 isFormatted = 1,
    --                 displayText = s,
    --             })

    --         else
    --             table.insert(t, {
    --                 stat = _G[stat],
    --                 value = value,
    --                 isFormatted = 0,
    --                 displayText = string.format("%s %d", _G[stat], value)
    --             })
    --         end
    --     end

    --     table.sort(t, function(a, b)
    --         if a.isFormatted == b.isFormatted then
    --             return a.value > b.value
    --         else
    --             return a.isFormatted < b.isFormatted;
    --         end
    --     end)

    --     return t;
    -- end

    --return {};
end


function Equipmate.Api.CompareItems(current, alternative)
    local currentItemStats = Equipmate.Api.GetAttributesFromTooltip(current)
    local altItemStats = Equipmate.Api.GetAttributesFromTooltip(alternative)

    local matchingStats = {}
    local statsGained = {}
    local statsLost = {}
    local attributesHandled = {}

    for k, v in ipairs(currentItemStats) do
        local exists = false;
        for a, b in ipairs(altItemStats) do
            if b.attribute == v.attribute then
                --print("found matching stat", v.attribute)
                attributesHandled[v.attribute] = true

                table.insert(matchingStats, {
                    current = v,
                    alt = b
                })
                exists = true;
            end
        end
        if exists == false then
            --print(v.attribute, "missing in alt stats")
            table.insert(statsLost, v)
        end
    end

    for k, v in ipairs(altItemStats) do
        if not attributesHandled[v.attribute] then
            local exists = false;
            for a, b in ipairs(currentItemStats) do
                if v.attribute == b.attribute then
                    exists = true;
                end
            end
            if exists == false then
                table.insert(statsGained, v)
            end
        end
    end

    --DevTools_Dump({matchingStats, statsLost, statsGained})
    return matchingStats, statsLost, statsGained;
end

-- function EquipmateMixin:RaiderDetailsContainerSuggestedItemListviewItem_OnMouseDown(currentItem, altItem)

--     local matchingStats, statsLost, statsGained = self:CompareItems(currentItem, altItem)

--     local info = string.format("%s: %s\n%s: %s\n\n", L.RAIDER_ITEM_DETAILS_CURRENT, currentItem.link, L.RAIDER_ITEM_DETAILS_ALTERNATIVE, altItem.link)
--     for k, v in ipairs(matchingStats) do
        
--         local attribute = v.alt.attribute;
--         local delta = v.alt.value - v.current.value;

--         if delta > 0 then
--             info = string.format("%s%s (|cff6cbb5a+%s|r)\n", info, attribute:format(v.current.value), delta)
--         elseif delta == 0 then
--             info = string.format("%s%s (|cffD7C447%s|r)\n", info, attribute:format(v.current.value), delta)
--         else
--             info = string.format("%s%s (|cffbb5a6c%s|r)\n", info, attribute:format(v.current.value), delta)
--         end
        
--     end
--     info = string.format("%s\n%s\n", info, L.RAIDER_ITEM_DETAILS_GAINS)
--     for k, v in ipairs(statsGained) do
--         --info = string.format("%s|cff6cbb5a%s|r\n", info, v.attribute:format(v.value))
--         info = string.format("%s|cff6cbb5a%s|r\n", info, v.displayText)
--     end
--     info = string.format("%s\n%s\n", info, L.RAIDER_ITEM_DETAILS_LOSSES)
--     for k, v in ipairs(statsLost) do
--         --info = string.format("%s|cffbb5a6c%s|r\n", info, v.attribute:format(v.value))
--         info = string.format("%s|cffbb5a6c%s|r\n", info, v.displayText)
--     end    

--     self.gearPlannerContainer.itemStatsInfo:SetText(info)

-- end