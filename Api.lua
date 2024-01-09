

local addonName, addon = ...;


Equipmate.Api = {}

function Equipmate.Api.GetPlayerEquipment()
    local equipment = {}
    for k, v in ipairs(Equipmate.Constants.InventorySlots) do
        local slotInfo = GetInventorySlotInfo(v.slot)
        local link = GetInventoryItemLink('player', slotInfo)
        if link then
            local itemLoc = ItemLocation:CreateFromEquipmentSlot(slotInfo)
            if itemLoc then
                local itemGUID = C_Item.GetItemGUID(itemLoc)
                table.insert(equipment, {
                    slot = v.slot,
                    icon = v.icon,
                    link = link,
                    guid = itemGUID,
                })
            end
        else
            table.insert(equipment, {
                slot = v.slot,
                icon = v.icon,
                link = false,
                guid = false,
            })
        end
    end
    return equipment;
end