

local addonName, addon = ...;

local Database = addon.Database;
local L = addon.locales;




StaticPopupDialogs.NewOutfit = {
    text = "New Outfit",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, data)
        local str = self.editBox:GetText()
        if str and (#str > 0) and (str ~= " ") then
            local outfit = str;
            Database:NewOutfit(outfit, addon.thisCharacter, data)
        end
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    hasEditBox = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    showAlert = false,
}





EquipmateMixin = {
    events = {
        addonLoaded = "ADDON_LOADED",
        playerEnteringWorld = "PLAYER_ENTERING_WORLD"
    },
    selectedOutfit = {},
}
function EquipmateMixin:OnLoad()

    self:RegisterForDrag("LeftButton")

    self.portraitMask = self:CreateMaskTexture()
    self.portraitMask:SetAllPoints(EquipmateUIPortrait)
    self.portraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    EquipmateUIPortrait:AddMaskTexture(self.portraitMask)
    EquipmateUIPortrait:SetTexture("Interface/Addons/Equipmate/tbd-icon")


    for k, v in pairs(self.events) do
        self:RegisterEvent(v)
    end

    Equipmate.CallbackRegistry:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnNewOutfit", self.Character_OnNewOutfit, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnOutfitChanged", self.Character_OnOutfitChanged, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnOutfitDeleted", self.Database_OnOutfitDeleted, self)


    self.characterHelptip:SetText(L.CHARACTER_HELPTIP)
    --self.outfitHelptip:SetScale(0.8)
    self.outfitHelptip:SetScript("OnClick", function()
        self.characterHelptip:SetShown(not self.characterHelptip:IsVisible())
    end)
    self.equipOutfit:SetEnabled(false)
    self.equipOutfit:SetScript("OnClick", function()
        self:Character_ApplySelectedOutfit()
    end)
    self.deleteOutfit:SetEnabled(false)
    self.deleteOutfit:SetScript("OnClick", function()
        self:Character_DeleteOutfit()
    end)
    self.newOutfit:SetScript("OnClick", function()
        StaticPopup_Show("NewOutfit")
    end)

    GameTooltip:HookScript('OnShow', function(tooltip)
        local data = tooltip:GetOwner()
        if data.arg1 and data.arg1 == "equipmate-dropdown-tooltip-hook" then
            tooltip:SetHyperlink(data.arg2)
        end
    end)

end


function EquipmateMixin:OnEvent(event, ...)
    if event == self.events.playerEnteringWorld then
        self:PlayerEnteringWorld()
    end
end

function EquipmateMixin:OnShow()

end

function EquipmateMixin:Database_OnInitialised()
    self:Character_CreateOutfitDropdownMenu()
end

function EquipmateMixin:PlayerEnteringWorld()

    self:UnregisterEvent(self.events.playerEnteringWorld)

    local name, realm = UnitName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    local nameRealm = string.format("%s-%s", name, realm)
    local _, _, classID = UnitClass("player")
    local _, _, raceID = UnitRace("player")

    addon.thisCharacter = nameRealm;

    addon.Database:Init() --pass in true to reset the db

    addon.Database:NewCharacter(nameRealm, classID, raceID)

    self:CreateSlashCommands()
end

function EquipmateMixin:CreateSlashCommands()
    SLASH_EQUIPMATE1 = '/equipmate'
    SLASH_EQUIPMATE2 = '/eqm'
    SlashCmdList['EQUIPMATE'] = function(msg)
        local arg1, arg2 = strsplit(" ", msg)
        if arg1 == "" then
            self:Show()

        elseif (arg1 == "equip") and (type(arg2) == "string") then
            self:Character_ApplySelectedOutfit(arg2)
        end
    end
end














function EquipmateMixin:Character_OnNewOutfit(outfit)
    self.selectedOutfit = outfit;
    self.deleteOutfit:SetEnabled(true)
    self.equipOutfit:SetEnabled(true)
    self:Character_CreateOutfitDropdownMenu()
    self.selectOutfitDropdown:SetText(outfit.name)

    local currentEquipment = Equipmate.Api.GetPlayerEquipment()
    outfit.items = currentEquipment;

    self:Character_LoadOutfitItems(outfit.items)
end

function EquipmateMixin:Character_OnOutfitSelected(outfit)
    self.selectedOutfit = outfit;
    self.deleteOutfit:SetEnabled(true)
    self.equipOutfit:SetEnabled(true)
    self:Character_LoadOutfitItems(outfit.items)
end

function EquipmateMixin:Character_OnOutfitChanged(outfit)
    self:Character_LoadOutfitItems(outfit.items)
end

function EquipmateMixin:Database_OnOutfitDeleted()
    self:Character_LoadOutfitItems({})
    self.selectOutfitDropdown:SetText("")
    self.selectedOutfit = nil
    self.deleteOutfit:SetEnabled(false)
    self.equipOutfit:SetEnabled(false)
    self:Character_CreateOutfitDropdownMenu()
end

function EquipmateMixin:Character_DeleteOutfit()
    if self.selectedOutfit then
        Database:DeleteOutfit(self.selectedOutfit.name)
    end
end

function EquipmateMixin:Character_ApplySelectedOutfit(name)


    --this is for macro use
    --look for an outfit with matching name
    --call OnOutfitSelected to simulate the dropdown menu
    if name then
        local foundOutift = false
        local outfits = Database:GetOutfits()
        for k, v in ipairs(outfits) do
            if v.name == name and v.character == addon.thisCharacter then
                self:Character_OnOutfitSelected(v)
                foundOutift = true
            end
        end
        if foundOutift == false then
            return
        end
    end

    if not self.selectedOutfit then
        return
    end

    local bagsWithEmptySlots = {}
    local emptySlotindex = 1
    for bag = 0, 4 do
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
        local v = self.selectedOutfit.items[i]
        if v.guid then
            local equipped = false;
            for bag = 0, 4 do
                if equipped == false then
                    for slot = 1, C_Container.GetContainerNumSlots(bag) do
                        equipped = equipItem(v, bag, slot)
                    end
                end
            end

            if BankFrame:IsVisible() then
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

            --the premapped empty slots should remain as anything swapped before would go into the slot created by the new item beign equipped
            --this will attempt to remove an item and place into an empty slot
            --if no empty slots exist put the item back into its slot
            if #bagsWithEmptySlots > 0 then
                local bag = bagsWithEmptySlots[#bagsWithEmptySlots]
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

        i = i + 1;
    end, #self.selectedOutfit.items)

end

function EquipmateMixin:Character_LoadOutfitItems(items)

    local function createEquipmentItemEntry(invSlot, bag, slot)
        local t = {}
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            local _, _, _, equipLoc, icon, classID, subClassID = GetItemInfoInstant(info.hyperlink)
            if classID == 2 or classID == 4 then

                
                -- local thisSlotID = GetInventorySlotInfo(v.slot)
                -- local itemSlotID = C_Item.GetItemInventoryTypeByID(info.itemID)
                -- print(info.hyperlink, _G[v.slot], _G[equipLoc])

                --[[
                    there has to be a way to control which items match for the slot
                    so the menu will only show items that can go into a slot

                    for now just show all items, users will need a little manual effort
                ]]

                local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc then
                    local itemGUID = C_Item.GetItemGUID(itemLoc)
                    t = {
                        text = info.hyperlink,
                        notCheckable = true,
                        func = function()
                            invSlot.link = info.hyperlink
                            invSlot.guid = itemGUID
                            Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
                        end,
                        arg1 = "equipmate-dropdown-tooltip-hook",
                        arg2 = info.hyperlink,
                        tooltipOnButton = true,
                        tooltipTitle = addonName,
                    }

                end

            end
        end
        return t;
    end

    local t = {}
    for k, v in ipairs(items) do
        table.insert(t, {
            label = v.link,
            icon = v.icon,
            iconSize = { 22, 22 },
            onMouseEnter = function(f)
                if v.link then
                    GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(v.link)
                    GameTooltip:Show()
                end
            end,
            onMouseDown = function(f, b)
                if b == "RightButton" and self.selectedOutfit then
                    local menu = {
                        {
                            text = string.format("Choose item - |cffffffff%s", _G[v.slot]),
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = IGNORE,
                            notCheckable = true,
                            func = function()
                                v.link = false
                                v.guid = false
                                Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
                            end,
                        },
                    }

                    local equippedItems = Equipmate.Api.GetPlayerEquipment()
                    for k, v1 in ipairs(equippedItems) do
                        if (v.slot == v1.slot) and (v1.link ~= false) then
                            table.insert(menu, {
                                text = string.format("Current: %s", v1.link),
                                notCheckable = true,
                                func = function()
                                    v.link = v1.link
                                    v.guid = v1.guid
                                    Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
                                end,
                            })
                        end
                    end

                    table.insert(menu, Equipmate.ContextMenuSeparator)

                    for bag = 0, 4 do
                        for slot = 1, C_Container.GetContainerNumSlots(bag) do
                            local itemEntry = createEquipmentItemEntry(v, bag, slot)
                            table.insert(menu, itemEntry)
                        end
                    end

                    if BankFrame:IsVisible() then
                        table.insert(menu, Equipmate.ContextMenuSeparator)
                        table.insert(menu, {
                            text = "Items in Bank",
                            isTitle = true,
                            notCheckable = true,
                        })

                        for slot = 1, C_Container.GetContainerNumSlots(-1) do
                            local itemEntry = createEquipmentItemEntry(v, -1, slot)
                            table.insert(menu, itemEntry)
                        end
                        for bag = 5, 11 do
                            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                                local itemEntry = createEquipmentItemEntry(v, bag, slot)
                                table.insert(menu, itemEntry)
                            end
                        end
                    else
                        table.insert(menu, Equipmate.ContextMenuSeparator)
                        table.insert(menu, {
                            text = "Bank items not available.",
                            isTitle = true,
                            notCheckable = true,
                        })
                    end

                    EasyMenu(menu, Equipmate.ContextMenu, "cursor", 0, 0, "MENU", 1.25)
                end
            end,
        })
    end
    self.equipmentListview.scrollView:SetDataProvider(CreateDataProvider(t))

end

function EquipmateMixin:Character_CreateOutfitDropdownMenu()
    local outfitMenu = {
        {
            text = "New Outfit",
            icon = "communities-icon-addgroupplus",
            func = function()
                StaticPopup_Show("NewOutfit")
            end,
        },
    }
    local outfits = Database:GetOutfits()
    for i = #outfits, 1, -1 do
        local outfit = outfits[i]
        if outfit.character == addon.thisCharacter then
            table.insert(outfitMenu, {
                text = outfit.name,
                func = function()
                    self:Character_OnOutfitSelected(outfit)
                end,
            })
        end
    end
    self.selectOutfitDropdown:SetMenu(outfitMenu)
end
