

local addonName, addon = ...;


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

---Scan the player containers for items that fit the specified inventory slot
---@param invSlot number the inventory slot ID
---@param includeBank boolean indicates if bank containers should be scanned
---@return table items an ipairs table of items
function Equipmate.Api.GetItemsForInvSlot(invSlot, includeBank)

    local items = {}
    local _, _, classID = UnitClass("player")

    local function checkItemInfo(link, bag, slot)

        --print("checkign item", link)

        local armorCheck = true;
        local _, _, _, equipLoc, icon, itemClassID, itemSubClassID = GetItemInfoInstant(link)
        if itemClassID == 2 or itemClassID == 4 then
            --print(link, equipLoc)
            if itemClassID == 4 then
                if itemSubClassID > Equipmate.Constants.ClassIdArmorType[classID] then
                    --print(link, classID, itemSubClassID, Equipmate.Constants.ClassIdArmorType[classID])
                    armorCheck = false
                end
            end

            local invSlotID = Equipmate.Constants.GlobalNameToInvSlot[equipLoc]
            local match;
            if type(invSlotID) == "table" then
                for k, v in ipairs(invSlotID) do
                    if v == invSlot then
                        match = v;
                    end
                end
            else
                match = invSlotID
            end

            if armorCheck and (invSlot == match) then
                local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc then
                    local guid = C_Item.GetItemGUID(itemLoc)
                    return {
                        link = link,
                        guid = guid,
                        invSlotID = match,
                        icon = icon,
                        bag = bag,
                        slot = slot,
                    }
                end
            end
        end
    end

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local item = checkItemInfo(info.hyperlink, bag, slot)
                if type(item) == "table" then
                    table.insert(items, item)
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



































local itemsScanned = {}
function Equipmate.Api.GetAttributesFromTooltip(link)

    if itemsScanned[link] then
        --DevTools_Dump(itemsScanned[item.link])
        return itemsScanned[link]
    else
        itemsScanned[link] = {}
    end

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