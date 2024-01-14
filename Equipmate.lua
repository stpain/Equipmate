

--[[
    Equipmate consists of 2 major parts

    Equipment Flyouts:
        These buttons are attached to the Character PaperDollFrame inventory slot buttons
        and allow players the ability to quickly swap their gear per slot

    Equipmate UI:
        This panel/window acts as an equipment set manager and allows players the ability to
        create and equip complete sets (ie all slots)
]]

local addonName, addon = ...;

local Database = addon.Database;
local L = addon.locales;



--[[
    ====================================
    StaticPopupDialogs
    ====================================
]]

StaticPopupDialogs.NewOutfit = {
    text = "New Outfit",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, data)
        local str = self.editBox:GetText()
        if str and (#str > 0) and (str ~= " ") then
            local outfit = str;
            Database:NewOutfit(outfit, addon.thisCharacter)
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






---Create the PaperDollFrame slot buttons and UI toggle button
local function CreatePaperDollButtons()

    local toggleButton = CreateFrame("BUTTON", addonName.."ToggleButton", PaperDollItemsFrame, "TBDSquareSlotButton")

    if RuneFrameControlButton then
        toggleButton:SetPoint("RIGHT", RuneFrameControlButton, "LEFT", -4, 0)
    else
        toggleButton:SetPoint("BOTTOMRIGHT", CharacterHandsSlot, "TOPRIGHT", 0, 3)
    end

    toggleButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(toggleButton, "ANCHOR_RIGHT")
        GameTooltip:AddLine(EQUIPMATE_TT_PAPERDOLL_TOGGLE_BUTTON)
        GameTooltip:Show()
    end)
    toggleButton.icon:SetTexture("Interface/WorldMap/Gear_64")
    toggleButton.icon:SetAtlas("transmog-nav-slot-head")
    toggleButton.icon:ClearAllPoints()
    toggleButton.icon:SetPoint("CENTER", toggleButton, "CENTER", 0, -2)
    --toggleButton.icon:SetTexCoord(0, 0.5, 0, 0.5)
    toggleButton.isOpen = true
    
    toggleButton:SetScript("OnClick", function(f)
        f.isOpen = not f.isOpen
        for k, v in ipairs(Equipmate.Constants.PaperDollInventorySlotToggleButtons) do
            v:SetShown(f.isOpen)
        end

        EquipmateUI:SetShown(f.isOpen)

        if f.isOpen then
            if EngravingFrame and EngravingFrame:IsVisible() then
                RuneFrameControlButton:Click()
            end
        end
    end)

    local function toggleFlyout(flyoutOpenButton, slotButton, slotID, isVerticle)

        for k, v in ipairs(Equipmate.Constants.PaperDollInventorySlotToggleButtons) do
            Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(v, false)
        end

        local flyout = EquipmentFlyoutFrame
        flyout:Hide()

        flyout:SetSlot(slotID)
        flyout:IsVerticle(isVerticle)
        flyout:SetParent(slotButton)
        flyout:SetFrameStrata("TOOLTIP")
        flyout:SetFrameLevel(9996)
        flyout:ClearAllPoints()
        flyout:SetPoint("TOPLEFT", -2, 4)
        flyout:Show()

        Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(flyoutOpenButton, true)
    end

    for slotName, info in pairs(Equipmate.Constants.PaperDollSlotNames) do

        local slot = _G[slotName]

        --this key value is used set the texcoords
        local isVerticle = (info.allignment == "bottom") and true or false
        slot.verticalFlyout = isVerticle;

        local button = CreateFrame("BUTTON", string.format("%s%sFlyoutButton", addonName, slotName), slot, "TBDSlotFlyoutButton")
        if info.allignment == "right" then
            button:SetPoint("TOPRIGHT", 12, 0)
            button:SetPoint("BOTTOMRIGHT", 12, 0)
            button:SetWidth(16)

            Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(button, false)

        else
            button:SetPoint("BOTTOMLEFT", 0, -12)
            button:SetPoint("BOTTOMRIGHT", 0, -12)
            button:SetHeight(16)

            Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(button, false)
        end

        table.insert(Equipmate.Constants.PaperDollInventorySlotToggleButtons, button)

        button:SetScript("OnLeave", function(slotButton)
            --slotButton:Click()
        end)
        button:SetScript("OnEnter", function()
            toggleFlyout(button, slot, info.slotID, isVerticle)
        end)
    end
end
















EquipmateMixin = {
    selectedOutfit = {},
}
function EquipmateMixin:OnLoad()

    self:SetTitle(addonName)

    self.portraitMask = self:CreateMaskTexture()
    self.portraitMask:SetAllPoints(EquipmateUIPortrait)
    self.portraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    EquipmateUIPortrait:AddMaskTexture(self.portraitMask)
    EquipmateUIPortrait:SetTexture("Interface/Addons/Equipmate/tbd-icon")

    self.outfitConfig.icon:SetTexture("Interface/WorldMap/Gear_64")
    self.outfitConfig.icon:SetTexCoord(0, 0.5, 0, 0.5)

    self.rescanOutfit.icon:SetAtlas("transmog-icon-revert")
    self.rescanOutfit:SetScript("OnClick", function()
        self:RescanEquipment(true)
    end)


    for k, v in pairs(Equipmate.Constants.BlizzardEvents) do
        self:RegisterEvent(v)
    end

    Equipmate.CallbackRegistry:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnNewOutfit", self.OnNewOutfit, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnOutfitChanged", self.OnOutfitChanged, self)
    Equipmate.CallbackRegistry:RegisterCallback("Database_OnOutfitDeleted", self.Database_OnOutfitDeleted, self)


    self.characterHelptip:SetText(L.CHARACTER_HELPTIP)
    --self.outfitHelptip:SetScale(0.8)
    self.outfitHelptip:SetScript("OnClick", function()
        self.characterHelptip:SetShown(not self.characterHelptip:IsVisible())
    end)
    self.equipOutfit:SetEnabled(false)
    self.equipOutfit:SetScript("OnClick", function()
        self:ApplySelectedOutfit()
    end)
    self.deleteOutfit:SetEnabled(false)
    self.deleteOutfit:SetScript("OnClick", function()
        self:DeleteOutfit()
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
    if event == Equipmate.Constants.BlizzardEvents.PlayerEnteringWorld then
        self:PlayerEnteringWorld()
    end
end

function EquipmateMixin:OnShow()

end

function EquipmateMixin:Database_OnInitialised()
    self:CreateOutfitDropdownMenu()

    CreatePaperDollButtons()
end

function EquipmateMixin:PlayerEnteringWorld()

    self:UnregisterEvent(Equipmate.Constants.BlizzardEvents.PlayerEnteringWorld)

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
            self:ApplySelectedOutfit(arg2)
        end
    end
end

function EquipmateMixin:OnNewOutfit(outfit)
    self.selectedOutfit = outfit;
    self.deleteOutfit:SetEnabled(true)
    self.equipOutfit:SetEnabled(true)
    self:CreateOutfitDropdownMenu()
    self.selectOutfitDropdown:SetText(outfit.name)

    local currentEquipment = Equipmate.Api.GetPlayerEquipment()
    outfit.items = currentEquipment;

    self:LoadOutfitItems(outfit.items)
end

function EquipmateMixin:RescanEquipment(updateSelectedOutfit)
    
    if updateSelectedOutfit and self.selectedOutfit then
        local currentEquipment = Equipmate.Api.GetPlayerEquipment()
        self:UpdateOutfitItems(nil, currentEquipment)
    end
end

function EquipmateMixin:UpdateOutfitItems(outfit, items)
    
    if not outfit then
        if self.selectedOutfit and self.selectedOutfit.name then
            self.selectedOutfit.items = items;
            self:LoadOutfitItems(self.selectedOutfit.items)
            print(string.format("[%s] updated outfit items for - %s", addonName, self.selectedOutfit.name))
        end
    end
end

function EquipmateMixin:OnOutfitSelected(outfit)
    self.selectedOutfit = outfit;
    self.deleteOutfit:SetEnabled(true)
    self.equipOutfit:SetEnabled(true)
    self:LoadOutfitItems(outfit.items)
end

function EquipmateMixin:OnOutfitChanged(outfit)
    self:LoadOutfitItems(outfit.items)
end

function EquipmateMixin:Database_OnOutfitDeleted()
    self:LoadOutfitItems({})
    self.selectOutfitDropdown:SetText("")
    self.selectedOutfit = nil
    self.deleteOutfit:SetEnabled(false)
    self.equipOutfit:SetEnabled(false)
    self:CreateOutfitDropdownMenu()
end

function EquipmateMixin:DeleteOutfit()
    if self.selectedOutfit then
        Database:DeleteOutfit(self.selectedOutfit.name)
    end
end

function EquipmateMixin:ApplySelectedOutfit(name)

    --this is for macro use
    --look for an outfit with matching name
    --call OnOutfitSelected to simulate the dropdown menu
    if name then
        local foundOutift = false
        local outfits = Database:GetOutfits()
        for k, v in ipairs(outfits) do
            if v.name == name and v.character == addon.thisCharacter then
                self:OnOutfitSelected(v)
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

        i = i + 1;
    end, #self.selectedOutfit.items)

end

function EquipmateMixin:LoadOutfitItems(items)

    local outfitItemInfo = Equipmate.Api.GetItemSetInfo(items)
    self.outfitInfoLeft:SetText(string.format("%d items", outfitItemInfo.numItems))
    self.outfitInfoRight:SetText(string.format("Ilvl %s", outfitItemInfo.averageItemLevel))

    -- local _, _, classID = UnitClass("player")
    -- local itemsAdded = {}
    -- local function createEquipmentItemEntry(item, bag, slot)
    --     local match, _ = Equipmate.Api.TestItemForClassAndSlot(classID, item.slotID, item.link, bag, slot)
    --     if match then
    --         local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    --         if itemLoc then
    --             local itemGUID = C_Item.GetItemGUID(itemLoc)
    --             if not itemsAdded[itemGUID] then
    --                 itemsAdded[itemGUID] = true
    --                 return {
    --                     text = item.link,
    --                     notCheckable = true,
    --                     func = function()
    --                         item.link = item.link
    --                         item.guid = itemGUID
    --                         Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
    --                     end,
    --                     arg1 = "equipmate-dropdown-tooltip-hook",
    --                     arg2 = item.link,
    --                     tooltipOnButton = true,
    --                     tooltipTitle = addonName,
    --                 }
    --             end
    --         end
    --     end
    -- end

    local t = {}
    for k, item in ipairs(items) do
        table.insert(t, {
            label = item.link,
            icon = item.icon,
            iconSize = { 22, 22 },
            onMouseEnter = function(f)
                if item.link then
                    GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(item.link)
                    GameTooltip:Show()
                end
            end,
            -- onMouseDown = function(f, b)
            --     if b == "RightButton" and self.selectedOutfit then
            --         local menu = {
            --             {
            --                 text = string.format("Choose item - |cffffffff%s", _G[item.slot]),
            --                 isTitle = true,
            --                 notCheckable = true,
            --             },
            --             {
            --                 text = IGNORE,
            --                 notCheckable = true,
            --                 func = function()
            --                     item.link = false
            --                     item.guid = false
            --                     Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
            --                 end,
            --             },
            --         }

            --         local equippedItems = Equipmate.Api.GetPlayerEquipment()
            --         for k, v1 in ipairs(equippedItems) do
            --             if (item.slot == v1.slot) and (v1.link ~= false) then
            --                 table.insert(menu, {
            --                     text = string.format("Current: %s", v1.link),
            --                     notCheckable = true,
            --                     func = function()
            --                         item.link = v1.link
            --                         item.guid = v1.guid
            --                         Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitChanged", self.selectedOutfit)
            --                     end,
            --                 })
            --             end
            --         end

            --         table.insert(menu, Equipmate.ContextMenuSeparator)

            --         for bag = 0, 4 do
            --             for slot = 1, C_Container.GetContainerNumSlots(bag) do
            --                 local itemEntry = createEquipmentItemEntry(item, bag, slot)
            --                 if type(itemEntry) == "table" then
            --                     table.insert(menu, itemEntry)
            --                 end
            --             end
            --         end

            --         if BankFrame:IsVisible() then
            --             table.insert(menu, Equipmate.ContextMenuSeparator)
            --             table.insert(menu, {
            --                 text = "Items in Bank",
            --                 isTitle = true,
            --                 notCheckable = true,
            --             })

            --             for slot = 1, C_Container.GetContainerNumSlots(-1) do
            --                 local itemEntry = createEquipmentItemEntry(item, -1, slot)
            --                 if type(itemEntry) == "table" then
            --                     table.insert(menu, itemEntry)
            --                 end
            --             end
            --             for bag = 5, 11 do
            --                 for slot = 1, C_Container.GetContainerNumSlots(bag) do
            --                     local itemEntry = createEquipmentItemEntry(item, bag, slot)
            --                     if type(itemEntry) == "table" then
            --                         table.insert(menu, itemEntry)
            --                     end
            --                 end
            --             end
            --         else
            --             table.insert(menu, Equipmate.ContextMenuSeparator)
            --             table.insert(menu, {
            --                 text = "Bank items not available.",
            --                 isTitle = true,
            --                 notCheckable = true,
            --             })
            --         end

            --         EasyMenu(menu, Equipmate.ContextMenu, "cursor", 0, 0, "MENU", 1.25)
            --     end
            -- end,
        })
    end
    self.equipmentListview.scrollView:SetDataProvider(CreateDataProvider(t))

end

function EquipmateMixin:CreateOutfitDropdownMenu()
    -- local outfitMenu = {
    --     {
    --         text = "New Outfit",
    --         icon = "communities-icon-addgroupplus",
    --         func = function()
    --             StaticPopup_Show("NewOutfit")
    --         end,
    --     },
    -- }
    local outfitMenu = {}
    local outfits = Database:GetOutfits()
    for i = #outfits, 1, -1 do
        local outfit = outfits[i]
        if outfit.character == addon.thisCharacter then
            table.insert(outfitMenu, {
                text = outfit.name,
                func = function()
                    self:OnOutfitSelected(outfit)
                end,
            })
        end
    end
    self.selectOutfitDropdown:SetMenu(outfitMenu)
end









EquipmentFlyoutFrameMixin = {}
function EquipmentFlyoutFrameMixin:OnLoad()
    self.items = {}
    self.buttons = {}
    self.slotID = false

    -- local ignoreSlotButton = CreateFrame("BUTTON", string.format("%sEquipmentFlyoutButton%s", addonName, "1"), self.buttonFrame, "EquipmentFlyoutButtonTemplate")
    -- ignoreSlotButton:SetNormalTexture(255352)
    -- ignoreSlotButton:SetSize(40,40)
    -- ignoreSlotButton:SetTooltip(L.FLYOUT_IGNORE_SLOT)
    -- self.buttons[1] = ignoreSlotButton;

    local putInBagButton = CreateFrame("BUTTON", string.format("%sEquipmentFlyoutButton%s", addonName, "1"), self.buttonFrame, "EquipmentFlyoutButtonTemplate")
    putInBagButton:SetNormalTexture(255351)
    putInBagButton:SetSize(40,40)
    putInBagButton:SetTooltip(L.FLYOUT_PUT_IN_BAG)
    self.buttons[1] = putInBagButton;

    NineSliceUtil.ApplyLayout(self.buttonFrame, Equipmate.Constants.FlyoutButtonsFrameLayout)

    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:SetScript("OnEvent", function(_, event, ...)
        if event == "BAG_UPDATE_DELAYED" then
            self:Update()
        end
        if event == "MODIFIER_STATE_CHANGED" then
            if IsShiftKeyDown() then
                self:Update()
            end
        end
    end)

end
function EquipmentFlyoutFrameMixin:IsVerticle(isVerticle)
    self.isVerticle = isVerticle;
end
function EquipmentFlyoutFrameMixin:SetSlot(slotID)
    self.slotID = slotID;
end
function EquipmentFlyoutFrameMixin:ClearItems()
    wipe(self.items)
end
function EquipmentFlyoutFrameMixin:OnHide()
    for k, v in ipairs(Equipmate.Constants.PaperDollInventorySlotToggleButtons) do
        Equipmate.Api.EquipmentFlyoutPopoutButton_SetReversed(v, false)
    end
    self:SetScript("OnUpdate", nil)
    if self.fadeTimer then
        self.fadeTimer:Cancel()
    end
end
function EquipmentFlyoutFrameMixin:OnShow()
    self:Update()

    self.fadeTimer = C_Timer.NewTimer(1.75, function()
        self:SetScript("OnUpdate", function()
            if self.buttonFrame:IsVisible() then
                local isOver = false
                if self:IsMouseOver() then
                    isOver = true
                end
                if self.buttonFrame:IsMouseOver() then
                    isOver = true
                end
                for k, v in ipairs(self.buttons) do
                    if v:IsMouseOver() then
                        isOver = true
                    end
                end
                if self:GetParent():IsMouseOver() then
                    isOver = true
                end
                if not isOver then
                    self:Hide()
                end
            end
        end)
    end)
end
function EquipmentFlyoutFrameMixin:OnKeyUp(key)
    self:Update()
end
function EquipmentFlyoutFrameMixin:OnKeyDown(key)
    self:Update()
end
function EquipmentFlyoutFrameMixin:Update()

    if not self.slotID then
        return;
    end

    self.items = Equipmate.Api.GetItemsForInvSlot(self.slotID, false)
    
    for k, v in ipairs(self.buttons) do
        v:Hide()
    end
    self.buttons[1]:Show()
    --self.buttons[2]:Show()

    self.buttons[1]:SetScript("OnClick", function()
        for bag = 0, 4 do
            local freeSlots = C_Container.GetContainerFreeSlots(bag)
            if #freeSlots > 0 then
                PickupInventoryItem(self.slotID)
                C_Container.PickupContainerItem(bag, freeSlots[1])
            end
        end
    end)
    --self.buttons[1]:SetScript("OnClick", function()
        --code this to ignore this slot on equipment sets
    --end)

    if #self.items > 0 then
        for k, item in ipairs(self.items) do
            local buttonIndex = k+1
            if not self.buttons[buttonIndex] then
                local button = CreateFrame("BUTTON", string.format("%sEquipmentFlyoutButton%s", addonName, buttonIndex), self.buttonFrame, "EquipmentFlyoutButtonTemplate")
                button:SetSize(40,40)
                self.buttons[buttonIndex] = button;
            end
            self.buttons[buttonIndex]:SetItem(item)
        end
    end

    local columOffset = 0;
    local rowOffset = 0;

    if self.isVerticle then
        local i = 0;
        for k, button in ipairs(self.buttons) do
            button:ClearAllPoints()
            button:SetPoint("TOP", 0, (i * -40) - 5)
            i = i + 1;
        end
        self.buttonFrame:SetSize(50, 10 + ((#self.items+1)*40))
        self.buttonFrame:ClearAllPoints()
        self.buttonFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -6)

        --self:SetHitRectInsets(-1, -1, -1, -6)

    else
        local i = 0;
        for k, button in ipairs(self.buttons) do
            button:ClearAllPoints()
            button:SetPoint("LEFT", (i * 40) + 5, rowOffset)
            i = i + 1;
        end
        self.buttonFrame:SetSize(10 + ((#self.items+1)*40), 50)
        self.buttonFrame:ClearAllPoints()
        self.buttonFrame:SetPoint("LEFT", self, "RIGHT", 6, 0)

        --self:SetHitRectInsets(-1, -6, -1, -1)
    end

    --is this mayeb a better layout?
    -- for k, button in ipairs(self.buttons) do
    --     button:ClearAllPoints()
    --     button:SetPoint("LEFT", ((k-1) * 40) + 5, 0)
    -- end
    --self.buttonFrame:SetSize(10 + ((#self.items+1)*40), 50)

end





