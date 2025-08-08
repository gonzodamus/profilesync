-- ProfileSync/saved.lua
-- Saved variables management

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Initialize saved variables container (no character-specific access here)
function PS:InitializeDB()
    ProfileSyncDB = ProfileSyncDB or {}
    self.db = ProfileSyncDB
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
    charData.addonProfiles = charData.addonProfiles or {}
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

-- Save addon profile mapping
function PS:SaveAddonProfile(addonName, profileName)
    if not self.charData then return end
    self.charData.addonProfiles[addonName] = profileName
end

-- Get saved profile for an addon
function PS:GetSavedProfile(addonName)
    if not self.charData then return nil end
    return self.charData.addonProfiles[addonName]
end

-- Get all saved addon profiles
function PS:GetAllSavedProfiles()
    if not self.charData then return {} end
    return self.charData.addonProfiles
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
    self.charData.addonProfiles = {}
    self.charData.autoApply = false
    self.charData.profilesApplied = false
    self.charData.allowUntested = false
end