
local name , addon = ...;

local Database = {}

local datebaseDefaults = {
    minimapButton = {},
    config = {},
    characters = {},
    containers = {},
    outfits = {},
    outfitBindings = {}
}

local characterConfigDefaultPriority = {
    [1] = "party-40",
    [2] = "party-25",
    [3] = "party-10",
    [4] = "party-05",
    [5] = "rested",
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
    if not self.db.config[nameRealm] then
        self.db.config[nameRealm] = {}
    end
end

function Database:SetKeyBindingOutfit(keyBindID, setID)
    if self.db then
        self.db.outfitBindings[keyBindID] = setID;
    end
end

function Database:GetOutfitFromKeyBindingID(id)
    if self.db then
        if self.db.outfitBindings[id] then
            for k, v in ipairs(self.db.outfits) do
                if v.id == self.db.outfitBindings[id] then
                    return v;
                end
            end
        end
    end
end

function Database:GetOutfits(nameRealm)
    if self.db then
        if not nameRealm then
            return self.db.outfits or {}
        else
            local t = {}
            for k, v in ipairs(self.db.outfits) do
                if v.character == nameRealm then
                    table.insert(t, v)
                end
            end
            return t;
        end
    end
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
            Equipmate.CallbackRegistry:TriggerEvent("Database_OnOutfitDeleted", name)
        end
    end
end

function Database:NewOutfit(outfitName, nameRealm)
    if self.db then
        if not self.db.outfits then
            self.db.outfits = {}
        end
        table.insert(self.db.outfits, {
            name = outfitName,
            character = nameRealm,
            items = {},
            icon = 0,
            config = {},
            id = time(),
        })
        Equipmate.CallbackRegistry:TriggerEvent("Database_OnNewOutfit", outfitName, self.db.outfits[#self.db.outfits])
    end
end

addon.Database = Database;