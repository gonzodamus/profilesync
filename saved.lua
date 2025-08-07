-- ProfileSync/saved.lua
-- Saved variables management

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Initialize saved variables
function PS:InitializeDB()
    ProfileSyncDB = ProfileSyncDB or {}
    
    -- Ensure character-specific data exists
    local charKey = self:GetCharacterKey()
    ProfileSyncDB[charKey] = ProfileSyncDB[charKey] or {}
    
    -- Initialize character data structure
    local charData = ProfileSyncDB[charKey]
    charData.addonProfiles = charData.addonProfiles or {}
    charData.autoApply = charData.autoApply or false
    charData.profilesApplied = charData.profilesApplied or false
    
    self.db = ProfileSyncDB
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
end