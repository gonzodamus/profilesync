-- ProfileSync/saved.lua
-- Saved variables management

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Initialize saved variables container (no character-specific access here)
function PS:InitializeDB()
    ProfileSyncDB = ProfileSyncDB or {}
    self.db = ProfileSyncDB

    -- Initialize global (account-wide) storage for addon profiles
    self.db.addonProfiles = self.db.addonProfiles or {}
    self.db._migratedToGlobal = self.db._migratedToGlobal or false
    -- self.charData will be set on PLAYER_LOGIN by InitializeCharacterData
end

-- Initialize character-specific data (call on PLAYER_LOGIN)
function PS:InitializeCharacterData()
    if not self.db then
        self:InitializeDB()
    end

    local charKey = self:GetCharacterKey()
    self.db[charKey] = self.db[charKey] or {}

    local charData = self.db[charKey]
    -- Backward compatibility: migrate any legacy per-character addonProfiles to global once
    if not self.db._migratedToGlobal then
        -- Merge any existing per-character addonProfiles tables into the global table
        for key, data in pairs(self.db) do
            if type(data) == "table" and data.addonProfiles and type(data.addonProfiles) == "table" then
                for addonName, profileName in pairs(data.addonProfiles) do
                    if self.db.addonProfiles[addonName] == nil then
                        self.db.addonProfiles[addonName] = profileName
                    end
                end
                -- Leave legacy data intact to avoid surprising users; future saves will use global
            end
        end
        self.db._migratedToGlobal = true
    end

    -- Character-scoped settings/state
    charData.autoApply = charData.autoApply or false
    charData.profilesApplied = charData.profilesApplied or false
    -- Settings
    charData.allowUntested = charData.allowUntested or false

    self.charData = charData
end

-- Get unique character key (realm + character name)
function PS:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm .. "-" .. name
end

-- Save addon profile mapping (account-wide)
function PS:SaveAddonProfile(addonName, profileName)
    if not self.db then return end
    -- nil clears the mapping
    self.db.addonProfiles[addonName] = profileName
end

-- Get saved profile for an addon (account-wide)
function PS:GetSavedProfile(addonName)
    if not self.db then return nil end
    return self.db.addonProfiles[addonName]
end

-- Get all saved addon profiles (account-wide)
function PS:GetAllSavedProfiles()
    if not self.db then return {} end
    return self.db.addonProfiles
end

-- Set auto-apply setting
function PS:SetAutoApply(enabled)
    if not self.charData then return end
    self.charData.autoApply = enabled
end

-- Get auto-apply setting
function PS:GetAutoApply()
    if not self.charData then return false end
    return self.charData.autoApply
end

-- Toggle for allowing untested versions
function PS:SetAllowUntested(enabled)
    if not self.charData then return end
    self.charData.allowUntested = enabled and true or false
end

function PS:GetAllowUntested()
    if not self.charData then return false end
    return self.charData.allowUntested == true
end

-- Mark profiles as applied for this character
function PS:MarkProfilesApplied()
    if not self.charData then return end
    self.charData.profilesApplied = true
end

-- Check if profiles have been applied to this character
function PS:HaveProfilesBeenApplied()
    if not self.charData then return false end
    return self.charData.profilesApplied
end

-- Reset character data (for testing)
function PS:ResetCharacterData()
    if not self.charData then return end
    -- Do not clear global addonProfiles here; this is character-scoped reset
    self.charData.autoApply = false
    self.charData.profilesApplied = false
    self.charData.allowUntested = false
end