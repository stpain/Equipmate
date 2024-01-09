

local addonName, addon = ...;


EquipmateMixin = {}
function EquipmateMixin:OnLoad()
    self:RegisterForDrag("LeftButton")

    self.portraitMask = self:CreateMaskTexture()
    self.portraitMask:SetAllPoints(EquipmateUIPortrait)
    self.portraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    EquipmateUIPortrait:AddMaskTexture(self.portraitMask)
    EquipmateUIPortrait:SetTexture("Interface/Addons/Equipmate/tbd-icon")
end