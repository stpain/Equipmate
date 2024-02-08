

local addonName, addon = ...;

local Database = addon.Database;

Equipmate.Api = {}

--function Equipmate.Api.RegisterCallBack(event, callback)
    -- EventRegistry:RegisterCallback(event, function(_, ...)
    --     callback(...)
    -- end)

    -- Equipmate.CallbackRegistry:RegisterCallback(event, function(_, ...)
    --     callback(...)
    -- end)

    -- for k, v in pairs(Equipmate.Constants.EventRegistryCallbacks) do
    --     if event == v then
    --         Equipmate.CallbackRegistry:RegisterCallback(event, function(_, ...)
    --             callback(...)
    --         end)
    --     end
    -- end
--end

function Equipmate.Api.FindItemContainerLocationbyLink(itemLink)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link == itemLink then
                return bag, slot;
            end
        end
    end
    if Equipmate.Constants.IsBankOpen then
        for slot = 1, C_Container.GetContainerNumSlots(-1) do
            local link = C_Container.GetContainerItemLink(-1, slot)
            if link == itemLink then
                return -1, slot;
            end
        end
        for bag = 5, 11 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local link = C_Container.GetContainerItemLink(bag, slot)
                if link == itemLink then
                    return bag, slot;
                end
            end
        end
    end
end


function Equipmate.Api.GetEquippedItemsDurability()
    --current, maximum = GetInventoryItemDurability(invSlotId)
    local equipment = {}
    for k, v in ipairs(Equipmate.Constants.InventorySlots) do
        local slotID = GetInventorySlotInfo(v.slot)

    end
end


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
                slotID = slotID,
            })
        end
    end
    return equipment;
end


--check the players current equipment and see if any outfits are a match
--return the outfit name or false if none found
function Equipmate.Api.GetCurrentOutfitStatus()
    
    local currentEquipment = Equipmate.Api.GetPlayerEquipment()

    local slotIdToItemGUID = {}
    for k, v in ipairs(currentEquipment) do
        slotIdToItemGUID[v.slotID] = v.guid
        --print(v.slotID, v.guid)
    end

    local outfits = Database:GetOutfits(addon.thisCharacter)

    for _, outfit in ipairs(outfits) do

        local slotMatches = {}

        --print(outfit.name)

        for _, item in ipairs(outfit.items) do

            --print(item.slotID, item.guid, slotIdToItemGUID[item.slotID])

            slotMatches[item.slotID] = false;
            
            if slotIdToItemGUID[item.slotID] == item.guid then
                slotMatches[item.slotID] = true
            end

        end

        local outfitMatch = true;
        for _, match in pairs(slotMatches) do
            if match == false then
                outfitMatch = false;
            end
        end

        if outfitMatch == true then
            return outfit.name
        end
    end

    return false;
end


--[[
    needs more work
]]
-- function Equipmate.Api.GetEquipmentSetsForCharacter(nameRealm)

--     if not nameRealm then
--         nameRealm = addon.thisCharacter;
--     end

--     local t = {}

--     local outfits = Database:GetOutfits(nameRealm)

--     if #outfits > 0 then
--         for k, outfit in ipairs(outfits) do
--             local copy = {}
--             for x, y in pairs(outfit) do
--                 if type(y) ~= "table" then
--                     copy[x] = y;
--                 else

--                     local t = {}
--                     for a, b in ipairs(y) do
--                         table.insert(t, b)
--                     end
--                     copy[x] = t
--                 end
--             end
--             table.insert(t, copy)
--         end
--     end

--     return t;
-- end


function Equipmate.Api.GetOutfitsForContainerItem(itemGUID)

    local t = {}

    local outfits = Database:GetOutfits(addon.thisCharacter)

    if #outfits > 0 then
        for k, outfit in ipairs(outfits) do

            if outfit.items then
                for _, item in ipairs(outfit.items) do
                    if type(item.guid) == "string" and (item.guid == itemGUID) then
                        table.insert(t, outfit)
                    end
                end
            end

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
            if effectiveILvl then
                ret.numItems = ret.numItems + 1
                ret.totalItemLevel = ret.totalItemLevel + effectiveILvl;
            end
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
function Equipmate.Api.TestItemForClassAndSlot(unitClassID, equipLoc, itemClassID, itemSubClassID, invSlot, ignoreSkillCheck, itemLink)

    if itemLink then
        print(string.format("Performing test on item: %s for slotID: %s", itemLink, invSlot))
        print(string.format("EquipLoc: %s, classID: %s, subClassID: %s", equipLoc, itemClassID, itemSubClassID))
    end

    local armorCheck, weaponCheck = false, false;
    if (itemClassID == 2) then

        local weaponSpellID = Equipmate.Constants.ItemSubClassIdToWeaponSkillSpellId[itemSubClassID]
        if type(weaponSpellID) == "number" then
            weaponCheck = IsPlayerSpell(weaponSpellID)
        end

        --override for generic (skinning knife)
        if itemSubClassID == Enum.ItemWeaponSubclass.Generic then
            weaponCheck = true;
        end

        if ignoreSkillCheck then
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
        Equipmate.Api.EquipItemSet(outfit, Equipmate.Constants.IsBankOpen)
    end
end



function Equipmate.Api.EquipItemSet(outfit, isBankOpen, isSwapScan)

    if UnitAffectingCombat("player") then
        return false;
    end

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


    --make none local?
    local function equipItem(invSlot, bag, slot)
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if itemLoc then
                local itemGUID = C_Item.GetItemGUID(itemLoc)
                if invSlot.guid == itemGUID then

                    --[[
                        TODO:
                            it is worth adding some logic here to check against the itemLink if the guid match is false
                            should this then update the guid value ?
                    ]]


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

                else
                    return false
                end
            end
        end
    end

    local numErrors = 0
    local i = 1;
    C_Timer.NewTicker(0.0025, function() --ticker might not be needed with the pre mapping of empty slots
        local v = outfit.items[i]

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
                        UIErrorsFrame:AddMessage(ERR_EQUIPMENT_MANAGER_BAGS_FULL, 1.0, 0.1, 0.1, 1.0);
                        numErrors = numErrors + 1;
                    end
                end
            end
        end


        i = i + 1;

        if (i > #outfit.items) then
            if isSwapScan then
                Equipmate.CallbackRegistry:TriggerEvent(Equipmate.Constants.CallbackEvents.OutfitOnSwapScanInitialEquip)
            else
                if numErrors == 0 then
                    Equipmate.CallbackRegistry:TriggerEvent(Equipmate.Constants.CallbackEvents.OutfitOnItemsEquipped, outfit.name, true)
                else
                    Equipmate.CallbackRegistry:TriggerEvent(Equipmate.Constants.CallbackEvents.OutfitOnItemsEquipped, outfit.name, false)
                end
            end
        end
    end, #outfit.items)
end





function Equipmate.Api.TrimNumber(num)
    if type(num) == 'number' then
        local trimmed = string.format("%.1f", num)
        return tonumber(trimmed)
    else
        return 1
    end
end






local spellSchools = {
    [2] = 'Holy',
    [3] = 'Fire',
    [4] = 'Nature',
    [5] = 'Frost',
    [6] = 'Shadow',
    [7] = 'Arcane',
}
local statIDs = {
    [1] = 'Strength',
    [2] = 'Agility',
    [3] = 'Stamina',
    [4] = 'Intellect',
    [5] = 'Spirit',
}
function Equipmate.Api.GetPaperDollStats()

    --[[
        the sub table keys (melee[this key]) should be capitalised as they are used in a locale lookup
    ]]
    local stats = {
        attributes = {},
        defence = {},
        melee = {},
        ranged = {},
        spell = {},
    }

    local numSkills = GetNumSkillLines();
    local skillIndex = 0;
    local currentHeader = nil;

    for i = 1, numSkills do
        local skillName = select(1, GetSkillLineInfo(i));
        local isHeader = select(2, GetSkillLineInfo(i));

        if isHeader ~= nil and isHeader then
            currentHeader = skillName;
        else
            if (currentHeader == "Weapon Skills" and skillName == 'Defense') then
                skillIndex = i;
                break;
            end
        end
    end

    -- local baseDef, modDef;
    -- if (skillIndex > 0) then
    --     baseDef = select(4, GetSkillLineInfo(skillIndex));
    --     modDef = select(6, GetSkillLineInfo(skillIndex));
    -- else
    --     baseDef, modDef = UnitDefense('player')
    -- end

    -- local posBuff = 0;
    -- local negBuff = 0;
    -- if ( modDef > 0 ) then
    --     posBuff = modDef;
    -- elseif ( modDef < 0 ) then
    --     negBuff = modDef;
    -- end
    -- stats.defence.defence = {
    --     base = Equipmate.Api.TrimNumber(baseDef),
    --     mod = Equipmate.Api.TrimNumber(modDef),
    -- }


    local baseDef, modDef = UnitDefense('player')
    stats.defence.Defence = (baseDef + modDef)

    local baseArmor, effectiveArmor, armr, posBuff, negBuff = UnitArmor('player');
    stats.defence.Armor = Equipmate.Api.TrimNumber(baseArmor)
    stats.defence.Block = Equipmate.Api.TrimNumber(GetBlockChance());
    stats.defence.Parry = Equipmate.Api.TrimNumber(GetParryChance());
    stats.defence.ShieldBlock = Equipmate.Api.TrimNumber(GetShieldBlock());
    stats.defence.Dodge = Equipmate.Api.TrimNumber(GetDodgeChance());

    -- stats.defence.tooltips = {

    -- }

    --local expertise, offhandExpertise, rangedExpertise = GetExpertise();
    --local base, casting = GetManaRegen();
    stats.spell.SpellHit = 0 -- Equipmate.Api.TrimNumber(GetCombatRatingBonus(CR_HIT_SPELL) + GetSpellHitModifier());
    stats.melee.MeleeHit = 0 --Equipmate.Api.TrimNumber(GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier());
    stats.ranged.RangedHit = 0 -- Equipmate.Api.TrimNumber(GetCombatRatingBonus(CR_HIT_RANGED));

    stats.ranged.RangedCrit = Equipmate.Api.TrimNumber(GetRangedCritChance());
    stats.melee.MeleeCrit = Equipmate.Api.TrimNumber(GetCritChance());

    stats.spell.Haste = Equipmate.Api.TrimNumber(GetHaste());
    stats.melee.Haste = Equipmate.Api.TrimNumber(GetMeleeHaste());
    stats.ranged.Haste = Equipmate.Api.TrimNumber(GetRangedHaste());

    local base, casting = GetManaRegen()
    stats.spell.Mana = base and Equipmate.Api.TrimNumber(base*5) or 0;
    stats.spell.ManaCombat = casting and Equipmate.Api.TrimNumber(casting*5) or 0;

    local maxCrit, critSchool = 0, "-";
    local maxDamage, dmgSchool = 0, "-";

    stats.spell.tooltips = {
        damage = {},
        crit = {},
    }

    for id, school in pairs(spellSchools) do

        local spellDamage = GetSpellBonusDamage(id)
        if spellDamage > maxDamage then
            maxDamage = spellDamage
            dmgSchool = spellSchools[id]
        end
        local spellCrit = GetSpellCritChance(id)
        if spellCrit > maxCrit then
            maxCrit = spellCrit
            critSchool = spellSchools[id]
        end

        table.insert(stats.spell.tooltips.damage, {
            name = spellSchools[id],
            val = Equipmate.Api.TrimNumber(spellDamage)
        })
        table.insert(stats.spell.tooltips.crit, {
            name = spellSchools[id],
            val = Equipmate.Api.TrimNumber(spellCrit)
        })

    end
    stats.spell.SpellCrit = Equipmate.Api.TrimNumber(maxCrit)
    stats.spell.SpellCritSchool = critSchool
    stats.spell.SpellDamage = Equipmate.Api.TrimNumber(maxDamage)
    stats.spell.SpellDamageSchool  = dmgSchool

    stats.spell.HealingBonus = Equipmate.Api.TrimNumber(GetSpellBonusHealing());

    local lowDmg, hiDmg, offlowDmg, offhiDmg, posBuff, negBuff, percentmod = UnitDamage("player");
    local mainSpeed, offSpeed = UnitAttackSpeed("player");
    local mlow = (lowDmg + posBuff + negBuff) * percentmod
    local mhigh = (hiDmg + posBuff + negBuff) * percentmod
    local olow = (offlowDmg + posBuff + negBuff) * percentmod
    local ohigh = (offhiDmg + posBuff + negBuff) * percentmod
    if mainSpeed < 1 then mainSpeed = 1 end
    if mlow < 1 then mlow = 1 end
    if mhigh < 1 then mhigh = 1 end
    if olow < 1 then olow = 1 end
    if ohigh < 1 then ohigh = 1 end

    if offSpeed then
        if offSpeed < 1 then 
            offSpeed = 1
        end
        stats.melee.MeleeDmgOH = Equipmate.Api.TrimNumber((olow + ohigh) / 2.0)
        stats.melee.MeleeDpsOH = Equipmate.Api.TrimNumber(((olow + ohigh) / 2.0) / offSpeed)
    else
        --offSpeed = 1
        stats.melee.MeleeDmgOH = Equipmate.Api.TrimNumber(0)
        stats.melee.MeleeDpsOH = Equipmate.Api.TrimNumber(0)
    end
    stats.melee.MeleeDmgMH = Equipmate.Api.TrimNumber((mlow + mhigh) / 2.0)
    stats.melee.MeleeDpsMH = Equipmate.Api.TrimNumber(((mlow + mhigh) / 2.0) / mainSpeed)

    local speed, lowDmg, hiDmg, posBuff, negBuff, percent = UnitRangedDamage("player");
    local low = (lowDmg + posBuff + negBuff) * percent
    local high = (hiDmg + posBuff + negBuff) * percent
    if speed < 1 then speed = 1 end
    if low < 1 then low = 1 end
    if high < 1 then high = 1 end
    local dmg = (low + high) / 2.0
    stats.ranged.RangedDmg = Equipmate.Api.TrimNumber(dmg)
    stats.ranged.RangedDps = Equipmate.Api.TrimNumber(dmg/speed)

    local base, posBuff, negBuff = UnitAttackPower('player')
    stats.melee.AttackPower = Equipmate.Api.TrimNumber(base + posBuff + negBuff)

    for k, stat in ipairs(statIDs) do
        local baseStat, effectiveStat, pos, neg = UnitStat("player", k);
        table.insert(stats.attributes, {
            id = k,
            name = stat,
            val = Equipmate.Api.TrimNumber(baseStat),
        })
    end

    return stats;
end

local resistanceIDs = {
    [0] = "Physical",
    [1] = "Holy",
    [2] = "Fire",
    [3] = "Nature",
    [4] = "Frost",
    [5] = "Shadow",
    [6] = "Arcane",
}
function Equipmate.Api.GetPlayerResistances()
    local res = {}
    for i = 0, 6 do
        local base, total, bonus, minus = UnitResistance("player", i)

        table.insert(res, {
            name = resistanceIDs[i],
            base = base,
            total = total,
            bonus = bonus,
            minus = minus,
        })

    end
    return res;
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