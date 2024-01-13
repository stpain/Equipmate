

local addonName, addon = ...;

local locales = {}

locales.enUS = {

    TT_PAPERDOLL_TOGGLE_BUTTON = "Equipmate",
    TT_UI_RESCAN_BUTTON = "Rescan equipment\n\n|cffffffffScan your characters equipment and update\nthe current outfit (if and outfit is selected)",
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