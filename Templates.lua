

local addonName, addon = ...;



TBDSimpleIconLabelFrameMixin = {}
function TBDSimpleIconLabelFrameMixin:OnLoad()

end
function TBDSimpleIconLabelFrameMixin:SetDataBinding(binding, height)

    --self.anim:Play()
    local x, y = self:GetSize()

    if binding.rightButton then
        if binding.rightButton.size then
            self.rightButton:SetSize(binding.rightButton.size[1], binding.rightButton.size[2])
        else
            self.rightButton:SetSize(height - 4, height - 4)
        end

        if binding.rightButton.atlas then
            self.rightButton.icon:SetAtlas(binding.rightButton.atlas)
        end

        if binding.rightButton.onClick then
            self.rightButton:SetScript("OnClick", binding.rightButton.onClick)
        end

        self.rightButton:Show()
    else
        self.rightButton:Hide()
        self.rightButton:SetSize(1, height - 4)
    end

    if binding.backgroundAlpha then
        self.background:SetAlpha(binding.backgroundAlpha)
    else
        self.background:SetAlpha(0)
    end
    if binding.backgroundAtlas then
        self.background:SetAtlas(binding.backgroundAtlas)
        self.background:SetAlpha(1)
    else
        if binding.backgroundRGB then
            self.background:SetColorTexture(binding.backgroundRGB.r, binding.backgroundRGB.g, binding.backgroundRGB.b)
         else
             self.background:SetColorTexture(0,0,0)
         end
    end

    if binding.label then
        self.label:SetText(binding.label)
    end
    if binding.labelRight then
        self.labelRight:SetText(binding.labelRight)
        self.label:SetPoint("RIGHT", -height, 0)
    end

    if binding.fontObject then
        self.label:SetFontObject(binding.fontObject)
        self.labelRight:SetFontObject(binding.fontObject)
    else
        self.label:SetFontObject(GameFontWhite)
        self.labelRight:SetFontObject(GameFontWhite)
    end

    if binding.atlas then
        self.icon:SetAtlas(binding.atlas)
    elseif binding.icon then
        self.icon:SetTexture(binding.icon)
    end

    if binding.iconCoords then
        self.icon:SetTexCoord(binding.iconCoords[1], binding.iconCoords[2], binding.iconCoords[3], binding.iconCoords[4])
    else
        self.icon:SetTexCoord(0,1,0,1)
    end

    if not binding.icon and not binding.atlas then
        self.icon:SetSize(1, height-4)
    else
        self.icon:SetSize(height-4, height-4)
    end

    if binding.iconSize then
        self.icon:SetSize(binding.iconSize[1], binding.iconSize[2])
    end

    if binding.showMask then
        self.mask:Show()
        local x, y = self.icon:GetSize()
        self.icon:SetSize(x + 6, y + 6)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", 3, 0)
    else
        self.mask:Hide()
        -- local x, y = self.icon:GetSize()
        -- self.icon:SetSize(x - 2, y - 2)
    end

    if binding.onUpdate then
        self:SetScript("OnUpdate", binding.onUpdate)
    end

    if binding.onMouseDown then
        self:SetScript("OnMouseDown", binding.onMouseDown)
        self:EnableMouse(true)
    end

    if binding.onMouseEnter then
        self:SetScript("OnEnter", binding.onMouseEnter)
        self:EnableMouse(true)
    else
        if binding.link then
            self:SetScript("OnEnter", function()
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetHyperlink(binding.link)
                GameTooltip:Show()
            end)
        end
    end

    if binding.onMouseLeave then
        self:SetScript("OnLeave", binding.onMouseLeave)
    else
        self:SetScript("OnLeave", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
    end

    -- if binding.getItemInfoFromID then
    --     if binding.itemID then
    --         local item = Item:CreateFromItemID(binding.itemID)
    --         if not item:IsItemEmpty() then
    --             item:ContinueOnItemLoad(function()
    --                 local link = item:GetItemLink()
    --                 self.label:SetText(link)
    --                 self:EnableMouse(true)
    --                 self:SetScript("OnEnter", function()
    --                     GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    --                     GameTooltip:SetHyperlink(link)
    --                     GameTooltip:Show()
    --                 end)
    --                 -- self:SetScript("OnLeave", function()
    --                 --     GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    --                 -- end)
    --                 self:SetScript("OnMouseDown", function()
    --                     if IsControlKeyDown() then
	-- 						DressUpItemLink(link)
	-- 					elseif IsShiftKeyDown() then
	-- 						HandleModifiedItemClick(link)
	-- 					end
    --                     if binding.onMouseDown then
    --                         binding.onMouseDown()
    --                     end
    --                 end)

    --                 addon:TriggerEvent("Profile_OnItemDataLoaded")
    --             end)
    --         end
    --     end
    -- end

    --self.anim:Play()
end
function TBDSimpleIconLabelFrameMixin:ResetDataBinding()
    self:SetScript("OnMouseDown", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self:EnableMouse(false)
    self.icon:SetTexture(nil)
    self.label:SetText("")
    self.labelRight:SetText("")
    self.rightButton:SetScript("OnClick", nil)
    self.rightButton:Hide()
end



TBDSquareSlotButtonMixin = {}
function TBDSquareSlotButtonMixin:OnLoad()
    if self.tooltipText then
        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.tooltipText)
            GameTooltip:Show()
        end)
    end
end





EquipmentFlyoutButtonMixin = {}
function EquipmentFlyoutButtonMixin:OnLoad()
    
end
function EquipmentFlyoutButtonMixin:SetTooltip(text)
    self:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(text)
        GameTooltip:Show()
    end)
end
function EquipmentFlyoutButtonMixin:SetItem(item)
    if item.icon and item.link then

        local itemMixin = Item:CreateFromItemLink(item.link)
        if not itemMixin:IsItemEmpty() then
            itemMixin:ContinueOnItemLoad(function()
                local quality = itemMixin:GetItemQuality()
                self.quality:SetAtlas(Equipmate.Constants.ItemQualityAtlas[quality])
            end)
        end


        self.icon:SetTexture(item.icon)
        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(item.link)
            GameTooltip:Show()
        end)
        self:Show()
    end
    if item.bag and item.slot then
        self:SetScript("OnClick", function()
            C_Container.PickupContainerItem(item.bag, item.slot)
            PickupInventoryItem(item.invSlotID)

            if CursorHasItem() then
                C_Container.PickupContainerItem(item.bag, item.slot)
            end
        end)
    end
end
function EquipmentFlyoutButtonMixin:ClearItem()
    self:SetScript("OnEnter", nil)
    self.icon:SetTexture(nil)
end

