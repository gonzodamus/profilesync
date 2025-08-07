-- ProfileSync/handlers.lua
-- Addon profile handlers registry

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Addon handlers registry
PS.AddonHandlers = {}

-- Cached profile lists
PS.ProfileCache = {}

-- Addons that require reload after profile change
PS.ReloadRequired = {
    ["Cell"] = true,
    ["Plater"] = true,
}

-- Initialize handlers
function PS:InitializeHandlers()
    -- Details handler
    self.AddonHandlers["Details"] = {
        isLoaded = function() return IsAddOnLoaded("Details") end,
        getProfiles = function()
            if not IsAddOnLoaded("Details") then return {} end
            local profiles = {}
            if Details and Details:GetProfileList then
                profiles = Details:GetProfileList()
            end
            return profiles
        end,
        setProfile = function(profileName)
            if not IsAddOnLoaded("Details") then return false, "Details not loaded" end
            if Details and Details.SetProfile then
                Details:SetProfile(profileName)
                return true
            end
            return false, "Details API not available"
        end,
        requiresReload = false
    }
    
    -- Plater handler
    self.AddonHandlers["Plater"] = {
        isLoaded = function() return IsAddOnLoaded("Plater") end,
        getProfiles = function()
            if not IsAddOnLoaded("Plater") then return {} end
            local profiles = {}
            if Plater and Plater.GetProfileList then
                profiles = Plater:GetProfileList()
            end
            return profiles
        end,
        setProfile = function(profileName)
            if not IsAddOnLoaded("Plater") then return false, "Plater not loaded" end
            if Plater and Plater.SwitchProfile then
                Plater:SwitchProfile(profileName)
                return true
            end
            return false, "Plater API not available"
        end,
        requiresReload = true
    }
    
    -- Bartender4 handler
    self.AddonHandlers["Bartender4"] = {
        isLoaded = function() return IsAddOnLoaded("Bartender4") end,
        getProfiles = function()
            if not IsAddOnLoaded("Bartender4") then return {} end
            local profiles = {}
            if Bartender4 and Bartender4.db and Bartender4.db:GetProfileList then
                profiles = Bartender4.db:GetProfileList()
            end
            return profiles
        end,
        setProfile = function(profileName)
            if not IsAddOnLoaded("Bartender4") then return false, "Bartender4 not loaded" end
            if Bartender4 and Bartender4.db and Bartender4.db:SetProfile then
                Bartender4.db:SetProfile(profileName)
                return true
            end
            return false, "Bartender4 API not available"
        end,
        requiresReload = false
    }
    
    -- Cell handler
    self.AddonHandlers["Cell"] = {
        isLoaded = function() return IsAddOnLoaded("Cell") end,
        getProfiles = function()
            if not IsAddOnLoaded("Cell") then return {} end
            local profiles = {}
            if CellDB and CellDB.profiles then
                for profileName, _ in pairs(CellDB.profiles) do
                    table.insert(profiles, profileName)
                end
            end
            return profiles
        end,
        setProfile = function(profileName)
            if not IsAddOnLoaded("Cell") then return false, "Cell not loaded" end
            if CellDB then
                CellDB["profile"] = profileName
                return true
            end
            return false, "Cell API not available"
        end,
        requiresReload = true
    }
end

-- Get cached profiles for an addon
function PS:GetCachedProfiles(addonName)
    if not self.ProfileCache[addonName] then
        local handler = self.AddonHandlers[addonName]
        if handler and handler.getProfiles then
            self.ProfileCache[addonName] = handler.getProfiles()
        else
            self.ProfileCache[addonName] = {}
        end
    end
    return self.ProfileCache[addonName]
end

-- Refresh cached profiles for an addon
function PS:RefreshCachedProfiles(addonName)
    self.ProfileCache[addonName] = nil
    return self:GetCachedProfiles(addonName)
end

-- Get all installed addons from our supported list
function PS:GetInstalledAddons()
    local installed = {}
    for addonName, handler in pairs(self.AddonHandlers) do
        if handler.isLoaded and handler.isLoaded() then
            table.insert(installed, addonName)
        end
    end
    return installed
end

-- Check if profile exists for an addon
function PS:ProfileExists(addonName, profileName)
    local profiles = self:GetCachedProfiles(addonName)
    for _, profile in ipairs(profiles) do
        if profile == profileName then
            return true
        end
    end
    return false
end

-- Apply profile to an addon
function PS:ApplyProfile(addonName, profileName)
    local handler = self.AddonHandlers[addonName]
    if not handler then
        return false, "Addon not supported"
    end
    
    if not handler.isLoaded() then
        return false, addonName .. " not loaded"
    end
    
    if not self:ProfileExists(addonName, profileName) then
        return false, "Profile '" .. profileName .. "' not found in " .. addonName
    end
    
    local success, error = handler.setProfile(profileName)
    if success then
        return true, nil, handler.requiresReload
    else
        return false, error or "Failed to apply profile"
    end
end

-- Get addons that require reload
function PS:GetAddonsRequiringReload()
    local reloadAddons = {}
    for addonName, handler in pairs(self.AddonHandlers) do
        if handler.requiresReload then
            table.insert(reloadAddons, addonName)
        end
    end
    return reloadAddons
end

-- Clear profile cache
function PS:ClearProfileCache()
    self.ProfileCache = {}
end