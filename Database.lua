
local name , addon = ...;

local Database = {}

local datebaseDefaults = {
    minimapButton = {},
    config = {},
    characters = {},
    containers = {},
    outfits = {},
}

function Database:Init(forceReset)
    
    if not EQUIPMATE_GLOBAL then
        EQUIPMATE_GLOBAL = datebaseDefaults
    end

    if forceReset then
        EQUIPMATE_GLOBAL = datebaseDefaults
    end

    self.db = EQUIPMATE_GLOBAL;

    Equipmate.CallbackRegistry:TriggerEvent("Database_OnInitialised")
end

function Database:GetCharacterInfo(nameRealm)
    if self.db and self.db.characters[nameRealm] then
        return self.db.characters[nameRealm]
    end
end

function Database:NewCharacter(nameRealm, classID, raceID)
    if not self.db.characters[nameRealm] then
        self.db.characters[nameRealm] = {
            nameRealm = nameRealm,
            classID = classID,
            raceID = raceID,
        }
        self.db.containers[nameRealm] = {}
    end
end

function Database:GetOutfits()
    return self.db.outfits or {}
end

function Database:DeleteOutfit(name)
    if self.db then
        local keyToRemove;
        for k, v in ipairs(self.db.outfits) do
            if v.name == name then
                keyToRemove = k
            end
        end
        if keyToRemove then
            table.remove(self.db.outfits, keyToRemove)
            Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitDeleted")
        end
    end
end

function Database:NewOutfit(outfit, nameRealm)
    if self.db then
        if not self.db.outfits then
            self.db.outfits = {}
        end
        table.insert(self.db.outfits, {
            name = outfit,
            character = nameRealm,
            items = {},
            icon = 0,
            config = {},
        })
        Equipmate.CallbackRegistry:TriggerEvent("Database_OnNewOutfit", self.db.outfits[#self.db.outfits])
    end
end

addon.Database = Database;