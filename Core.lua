local name, addon = ...;

Equipmate = {}

Equipmate.ContextMenu = CreateFrame("Frame", "EquipmateContextMenu", UIParent, "UIDropDownMenuTemplate")
Equipmate.ContextMenuSeparator = {
    hasArrow = false;
    dist = 0;
    text = "",
    isTitle = true;
    isUninteractable = true;
    notCheckable = true;
    iconOnly = true;
    icon = "Interface\\Common\\UI-TooltipDivider-Transparent";
    tCoordLeft = 0;
    tCoordRight = 1;
    tCoordTop = 0;
    tCoordBottom = 1;
    tSizeX = 0;
    tSizeY = 8;
    tFitDropDownSizeX = true;
    iconInfo = {
        tCoordLeft = 0,
        tCoordRight = 1,
        tCoordTop = 0,
        tCoordBottom = 1,
        tSizeX = 0,
        tSizeY = 8,
        tFitDropDownSizeX = true
    }
}

Equipmate.Constants = {}

-- Equipmate.Constants.Colours = {}
-- Equipmate.Constants.Colours.BlizzardBlue = CreateColor(0.2, 0.8, 1.0, 1.0)

Equipmate.Constants.PaperDollInventorySlotToggleButtons = {}

Equipmate.Constants.BlizzardEvents = {
    AddonLoaded = "ADDON_LOADED",
    PlayerEnteringWorld = "PLAYER_ENTERING_WORLD",
    BankFrameOpened = "BANKFRAME_OPENED",
    BankFrameClosed = "BANKFRAME_CLOSED",
}

Equipmate.Constants.CallbackEvents = {
    DatabaseOnInitialised = "Database_OnInitialised",
    DatabaseOnConfigChanged = "Database_OnConfigChanged",
    DatabaseOnNewOutfit = "Database_OnNewOutfit",
    DatabaseOnOutfitChanged = "Database_OnOutfitChanged",
    DatabaseOnOutfitDeleted = "Database_OnOutfitDeleted",

    BankFrameStateChanged = "BankFrame_StateChanged",

    OutfitSetSlotIgnore = "Outfit_SetSlotIgnore",
    OutfitOnItemsEquipped = "Outfit_OnItemsEquipped",
    OutfitOnSwapScanInitialEquip = "Outfit_OnSwapScanInitialEquip",
}

-- events usable by other addons
Equipmate.Constants.EventRegistryCallbacks = {
    Database_OnNewOutfit = "EQUIPMATE_ON_OUTFIT_CREATED",
    Database_OnOutfitDeleted = "EQUIPMATE_ON_OUTFIT_DELETED",
    Database_OnOutfitChanged = "EQUIPMATE_ON_OUTFIT_CHANGED",
    Outfit_OnItemsEquipped = "EQUIPMATE_ON_OUTFIT_EQUIPPED",
}

Equipmate.Constants.IsBankOpen = false;

Equipmate.Constants.ItemQualityAtlas = {
    [2] = "bags-glow-green",
    [3] = "bags-glow-blue",
    [4] = "bags-glow-purple",
    [5] = "bags-glow-orange",
}

Equipmate.Constants.InventorySlots = {
    {
        slot = "HEADSLOT",
        icon = 136516,
    },
    {
        slot = "NECKSLOT",
        icon = 136519,
    },
    {
        slot = "SHOULDERSLOT",
        icon = 136526,
    },
    {
        slot = "BACKSLOT",
        icon = 136512, -- 136521,
    },
    {
        slot = "CHESTSLOT",
        icon = 136512,
    },
    {
        slot = "SHIRTSLOT",
        icon = 136525,
    },
    {
        slot = "TABARDSLOT",
        icon = 136527,
    },
    {
        slot = "WRISTSLOT",
        icon = 136530,
    },
    {
        slot = "HANDSSLOT",
        icon = 136515,
    },
    {
        slot = "WAISTSLOT",
        icon = 136529,
    },
    {
        slot = "LEGSSLOT",
        icon = 136517,
    },
    {
        slot = "FEETSLOT",
        icon = 136513,
    },
    {
        slot = "FINGER0SLOT",
        icon = 136514,
    },
    {
        slot = "FINGER1SLOT",
        icon = 136523,
    },
    {
        slot = "TRINKET0SLOT",
        icon = 136528,
    },
    {
        slot = "TRINKET1SLOT",
        icon = 136528,
    },
    {
        slot = "MAINHANDSLOT",
        icon = 136518,
    },
    {
        slot = "SECONDARYHANDSLOT",
        icon = 136524,
    },
    {
        slot = "RANGEDSLOT",
        icon = 136520,
    },
    -- {
    --     slot = "RELICSLOT",
    --     icon = 136522,
    -- },
}

Equipmate.Constants.PaperDollSlotNames = {    
    ["CharacterHeadSlot"] = { allignment = "right", slotID = 1, },
    ["CharacterNeckSlot"] = { allignment = "right", slotID = 2, },
    ["CharacterShoulderSlot"] = { allignment = "right", slotID = 3, },
    ["CharacterBackSlot"] = { allignment = "right", slotID = 15, },
    ["CharacterChestSlot"] = { allignment = "right", slotID = 5, },
    ["CharacterShirtSlot"] = { allignment = "right", slotID = 4, },
    ["CharacterTabardSlot"] = { allignment = "right", slotID = 19, },
    ["CharacterWristSlot"] = { allignment = "right", slotID = 9, },

    ["CharacterHandsSlot"] = { allignment = "right", slotID = 10, },
    ["CharacterWaistSlot"] = { allignment = "right", slotID = 6, },
    ["CharacterLegsSlot"] = { allignment = "right", slotID = 7, },
    ["CharacterFeetSlot"] = { allignment = "right", slotID = 8, },
    ["CharacterFinger0Slot"] = { allignment = "right", slotID = 11, },
    ["CharacterFinger1Slot"] = { allignment = "right", slotID = 12, },
    ["CharacterTrinket0Slot"] = { allignment = "right", slotID = 13, },
    ["CharacterTrinket1Slot"] = { allignment = "right", slotID = 14, },

    ["CharacterMainHandSlot"] = { allignment = "bottom", slotID = 16, },
    ["CharacterSecondaryHandSlot"] = { allignment = "bottom", slotID = 17, },
    ["CharacterRangedSlot"] = { allignment = "bottom", slotID = 18, },
}

Equipmate.Constants.GlobalNameToInvSlot = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_BODY"] = 4,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HAND"] = 10,
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_MAINHAND"] = 16,
    ["INVTYPE_OFFHAND"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_TABARD"] = 19,
    ["INVTYPE_WEAPON"] = {16, 17},
    ["INVTYPE_2HWEAPON"] = 16,
    ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_FINGER"] = {11, 12},
    ["INVTYPE_TRINKET"] = {13, 14},
}

Equipmate.Constants.ClassIdArmorType = {
    [1] = 4, --warrior
    [2] = 4, --paladin
    [3] = 3, --hunter
    [4] = 2, --rogue
    [5] = 1, --priest
    [6] = 4, --dk
    [7] = 3, --shaman
    [8] = 1, --mage
    [9] = 1, --warlocki
    [10] = 2, --monk
    [11] = 2, --druid
    [12] = 2, --dh
}

Equipmate.Constants.ClassSkillSpellId = {
    DualWield = 674,
    Shields = 9116,
}

Equipmate.Constants.ItemSubClassIdToArmorSkillSpellId = {
    [Enum.ItemArmorSubclass.Cloth] = 9078,
    [Enum.ItemArmorSubclass.Leather] = 9077,
    [Enum.ItemArmorSubclass.Mail] = 8737,
    [Enum.ItemArmorSubclass.Plate] = 750,
}

Equipmate.Constants.ItemSubClassIdToWeaponSkillSpellId = {
    [Enum.ItemWeaponSubclass.Polearm] = 200,
    [Enum.ItemWeaponSubclass.Sword1H] = 201,
    [Enum.ItemWeaponSubclass.Sword2H] = 202,
    [Enum.ItemWeaponSubclass.Axe1H] = 196,
    [Enum.ItemWeaponSubclass.Axe2H] = 197,
    [Enum.ItemWeaponSubclass.Mace1H] = 198,
    [Enum.ItemWeaponSubclass.Mace2H] = 199,
    [Enum.ItemWeaponSubclass.Staff] = 227,
    [Enum.ItemWeaponSubclass.Dagger] = 1180,
    [Enum.ItemWeaponSubclass.Wand] = 5009,
    [Enum.ItemWeaponSubclass.Fishingpole] = 7738,
    [Enum.ItemWeaponSubclass.Guns] = 266,
    [Enum.ItemWeaponSubclass.Bows] = 264,
    [Enum.ItemWeaponSubclass.Crossbow] = 5011,
}

Equipmate.Constants.FlyoutButtonsFrameLayout = {
    TopLeftCorner =	{ atlas = "ChatBubble-NineSlice-CornerTopLeft", x = -2, y = 2, },
    TopRightCorner =	{ atlas = "ChatBubble-NineSlice-CornerTopRight", x = 2, y = 2, },
    BottomLeftCorner =	{ atlas = "ChatBubble-NineSlice-CornerBottomLeft", x = -2, y = -2, },
    BottomRightCorner =	{ atlas = "ChatBubble-NineSlice-CornerBottomRight", x = 2, y = -2, },
    TopEdge = { atlas = "_ChatBubble-NineSlice-EdgeTop", },
    BottomEdge = { atlas = "_ChatBubble-NineSlice-EdgeBottom"},
    LeftEdge = { atlas = "!ChatBubble-NineSlice-EdgeLeft", },
    RightEdge = { atlas = "!ChatBubble-NineSlice-EdgeRight", },
    Center = { atlas = "ChatBubble-NineSlice-Center", },
}

Equipmate.Constants.ItemStatGlobals = {
    Intellect = ITEM_MOD_INTELLECT_SHORT,
    Agility = ITEM_MOD_AGILITY_SHORT,
    Strength = ITEM_MOD_STRENGTH_SHORT,
    Spirit = ITEM_MOD_SPIRIT_SHORT,
    Stamina = ITEM_MOD_STAMINA_SHORT,
}

Equipmate.Constants.ConfigEvents = {
    GROUP_ROSTER_UPDATE = true,
    ZONE_CHANGED_NEW_AREA = true,
}