

local addonName, addon = ...;

local locales = {}

locales.enUS = {

    TT_PAPERDOLL_TOGGLE_BUTTON = "Equipmate",

    UI_RESCAN_BUTTON_TOOLTIP_TITLE = "Rescan equipment",
    UI_RESCAN_BUTTON_TOOLTIP_TEXT = "Scan your characters equipment and update the current outfit.",

    UI_OUTFIT_SELECT_DROPDOWN_TOOLTIP_TITLE = "Select outfit",
    UI_OUTFIT_SELECT_DROPDOWN_TOOLTIP_TEXT = "Your outfits will be listed here. Select an outfit to view its items.\nIf an outfit is selected you can rescan to update the items.",

    TT_UI_OUTFIT_CONFIG_BUTTON = "Outfit config",
    
    CHARACTER_HELPTIP = "You can manage your character's equipment here.\n\nCreate a new equipment set and give it a name.\n\nThe set will be created with your current gear loaded into the list.\n\nYou can view alternative items via the slot flyouts or manually change items. To save the set click 'Rescan'.\n\nTo equip a set click on Equip, or use a macro \n/equipmate equip [set name] (set name cannot contain any spaces)\n\nWarning, items in the bank will require you to have the bank open.",

    FLYOUT_IGNORE_SLOT = "Ignore slot",
    FLYOUT_PUT_IN_BAG = "Put item in bag",
}


addon.locales = locales[GetLocale()];


--thsi allows use in xml without having to constantly set in Lua
--CAUTION - always prefix the key (done in the string.format now)
for k, v in pairs(addon.locales) do
    _G[string.format("%s_%s", addonName:upper(), k)] = v;
end