

local addonName, addon = ...;

local locales = {}

locales.enUS = {
    CHARACTER_HELPTIP = "You can manage your character's equipment here.\n\nTo create a new equipment set open the dropdown and select New Outfit then give it a name.\n\nThe set will be created with your current gear loaded into the list. Right click a slot to view your available items (take care as its not slot specific yet).\n\nTo equip a set click on Equip, or use a macro \n/adventureguide equip [set name] (no spaces allowed)\n\nWarning, items in the bank will require you to have the bank open.",
}


addon.locales = locales[GetLocale()];