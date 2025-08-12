-- ProfileSync/handlers.lua
-- Addon profile handlers registry with API versioning

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Retail/11.x API wrappers
local function IsAddOnLoaded(addon)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(addon)
    end
    return _G.IsAddOnLoaded(addon)
end

local function GetAddOnMetadata(addon, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addon, field)
    end
    return _G.GetAddOnMetadata(addon, field)
end

-- Addon handlers registry
PS.AddonHandlers = {}

-- Cached profile lists
PS.ProfileCache = {}

-- Addons that require reload after profile change
PS.ReloadRequired = {
    ["Cell"] = true,
    ["Plater"] = true,
}

-- API Compatibility Matrix
PS.APICompatibility = {
    ["Details"] = {
        minVersion = "3.0.0",
        maxVersion = "4.0.0",
        apiVersions = {
            ["3.0.0"] = {
                getProfiles = function()
                    if Details and Details:GetProfileList then
                        return Details:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Details and Details.SetProfile then
                        Details:SetProfile(profileName)
                        return true
                    end
                    return false, "Details API not available"
                end
            },
            ["4.0.0"] = {
                getProfiles = function()
                    if Details and Details:GetProfileList then
                        return Details:GetProfileList()
                    end
                    -- Fallback for newer versions
                    if Details and Details.profile and Details.profile:GetProfileList then
                        return Details.profile:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Details and Details.SetProfile then
                        Details:SetProfile(profileName)
                        return true
                    end
                    -- Fallback for newer versions
                    if Details and Details.profile and Details.profile:SetProfile then
                        Details.profile:SetProfile(profileName)
                        return true
                    end
                    return false, "Details API not available"
                end
            }
        }
    },
    ["Plater"] = {
        minVersion = "1.0.0",
        maxVersion = "2.0.0",
        apiVersions = {
            ["1.0.0"] = {
                getProfiles = function()
                    if Plater and Plater.GetProfileList then
                        return Plater:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Plater and Plater.SwitchProfile then
                        Plater:SwitchProfile(profileName)
                        return true
                    end
                    return false, "Plater API not available"
                end
            },
            ["2.0.0"] = {
                getProfiles = function()
                    if Plater and Plater.GetProfileList then
                        return Plater:GetProfileList()
                    end
                    -- Fallback for newer versions
                    if Plater and Plater.db and Plater.db:GetProfileList then
                        return Plater.db:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Plater and Plater.SwitchProfile then
                        Plater:SwitchProfile(profileName)
                        return true
                    end
                    -- Fallback for newer versions
                    if Plater and Plater.db and Plater.db:SetProfile then
                        Plater.db:SetProfile(profileName)
                        return true
                    end
                    return false, "Plater API not available"
                end
            }
        }
    },
    ["Bartender4"] = {
        minVersion = "4.0.0",
        maxVersion = "5.0.0",
        apiVersions = {
            ["4.0.0"] = {
                getProfiles = function()
                    if Bartender4 and Bartender4.db and Bartender4.db:GetProfileList then
                        return Bartender4.db:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Bartender4 and Bartender4.db and Bartender4.db:SetProfile then
                        Bartender4.db:SetProfile(profileName)
                        return true
                    end
                    return false, "Bartender4 API not available"
                end
            },
            ["5.0.0"] = {
                getProfiles = function()
                    if Bartender4 and Bartender4.db and Bartender4.db:GetProfileList then
                        return Bartender4.db:GetProfileList()
                    end
                    -- Fallback for newer versions
                    if Bartender4 and Bartender4:GetProfileList then
                        return Bartender4:GetProfileList()
                    end
                    return {}
                end,
                setProfile = function(profileName)
                    if Bartender4 and Bartender4.db and Bartender4.db:SetProfile then
                        Bartender4.db:SetProfile(profileName)
                        return true
                    end
                    -- Fallback for newer versions
                    if Bartender4 and Bartender4:SetProfile then
                        Bartender4:SetProfile(profileName)
                        return true
                    end
                    return false, "Bartender4 API not available"
                end
            }
        }
    },
    ["Cell"] = {
        minVersion = "1.0.0",
        maxVersion = "2.0.0",
        apiVersions = {
            ["1.0.0"] = {
                getProfiles = function()
                    local profiles = {}
                    if CellDB and CellDB.profiles then
                        for profileName, _ in pairs(CellDB.profiles) do
                            table.insert(profiles, profileName)
                        end
                    end
                    return profiles
                end,
                setProfile = function(profileName)
                    if CellDB then
                        CellDB["profile"] = profileName
                        return true
                    end
                    return false, "Cell API not available"
                end
            },
            ["2.0.0"] = {
                getProfiles = function()
                    local profiles = {}
                    if CellDB and CellDB.profiles then
                        for profileName, _ in pairs(CellDB.profiles) do
                            table.insert(profiles, profileName)
                        end
                    end
                    -- Fallback for newer versions
                    if Cell and Cell.GetProfileList then
                        return Cell:GetProfileList()
                    end
                    return profiles
                end,
                setProfile = function(profileName)
                    if CellDB then
                        CellDB["profile"] = profileName
                        return true
                    end
                    -- Fallback for newer versions
                    if Cell and Cell.SetProfile then
                        Cell:SetProfile(profileName)
                        return true
                    end
                    return false, "Cell API not available"
                end
            }
        }
    }
}

-- Version comparison utility
function PS:CompareVersions(version1, version2)
    local v1Parts = {strsplit(".", version1)}
    local v2Parts = {strsplit(".", version2)}
    
    for i = 1, math.max(#v1Parts, #v2Parts) do
        local v1 = tonumber(v1Parts[i]) or 0
        local v2 = tonumber(v2Parts[i]) or 0
        
        if v1 < v2 then
            return -1
        elseif v1 > v2 then
            return 1
        end
    end
    
    return 0
end

-- Sanitize version strings like "v4.1.2-release" -> "4.1.2"
function PS:SanitizeVersionString(version)
    if not version or version == "" then return "0.0.0" end
    -- Keep only digits and dots
    local cleaned = version:gsub("[^0-9%.]", "")
    -- Collapse multiple dots
    cleaned = cleaned:gsub("%.+", ".")
    -- Trim leading/trailing dots
    cleaned = cleaned:gsub("^%.", ""):gsub("%.$", "")
    if cleaned == "" then return "0.0.0" end
    return cleaned
end

-- Get addon version
function PS:GetAddonVersion(addonName)
    local version = GetAddOnMetadata(addonName, "Version")
    if not version or version == "" then
        -- Try alternative version detection methods
        if addonName == "Details" and Details then
            version = Details.version or Details.Version
        elseif addonName == "Plater" and Plater then
            version = Plater.version or Plater.Version
        elseif addonName == "Bartender4" and Bartender4 then
            version = Bartender4.version or Bartender4.Version
        elseif addonName == "Cell" and Cell then
            version = Cell.version or Cell.Version
        end
    end
    
    return self:SanitizeVersionString(version or "0.0.0")
end

-- Check if addon version is compatible
function PS:IsVersionCompatible(addonName, version)
    local compatibility = self.APICompatibility[addonName]
    if not compatibility then
        return false, "Addon not in compatibility matrix"
    end
    
    local minVersion = self:SanitizeVersionString(compatibility.minVersion)
    local maxVersion = self:SanitizeVersionString(compatibility.maxVersion)
    local current = self:SanitizeVersionString(version)
    
    if self:CompareVersions(current, minVersion) < 0 then
        return false, string.format("Version %s is below minimum required version %s", current, minVersion)
    end
    
    if self:CompareVersions(current, maxVersion) > 0 then
        if self.GetAllowUntested and self:GetAllowUntested() then
            return true, string.format("Proceeding with untested version %s (max supported %s)", current, maxVersion)
        end
        return false, string.format("Version %s is above maximum supported version %s", current, maxVersion)
    end
    
    return true
end

-- Get best API version for addon
function PS:GetBestAPIVersion(addonName, currentVersion)
    local compatibility = self.APICompatibility[addonName]
    if not compatibility then
        return nil, "Addon not in compatibility matrix"
    end
    
    local apiVersions = compatibility.apiVersions
    local bestVersion = nil
    local bestMatch = -1
    local current = self:SanitizeVersionString(currentVersion)
    
    for version, _ in pairs(apiVersions) do
        local candidate = self:SanitizeVersionString(version)
        if self:CompareVersions(current, candidate) >= 0 then
            local match = self:CompareVersions(current, candidate)
            if match > bestMatch then
                bestMatch = match
                bestVersion = version
            end
        end
    end
    
    return bestVersion
end

-- Helper to fetch compatibility detail for UI
function PS:GetCompatibilityDetail(addonName)
    local handler = self.AddonHandlers[addonName]
    if not handler then return nil end
    local version = handler.version()
    local isCompatible, message = handler.isCompatible()
    return {
        name = addonName,
        version = version,
        isCompatible = isCompatible,
        message = message
    }
end

-- Initialize handlers with version checking
function PS:InitializeHandlers()
    for addonName, compatibility in pairs(self.APICompatibility) do
        local handler = {
            isLoaded = function() return IsAddOnLoaded(addonName) end,
            getProfiles = function()
                if not IsAddOnLoaded(addonName) then return {} end
                
                local version = self:GetAddonVersion(addonName)
                local isCompatible, message = self:IsVersionCompatible(addonName, version)
                
                if not isCompatible then
                    self:PrintError(string.format("%s version %s: %s", addonName, version, message))
                    return {}
                elseif message then
                    self:Print(string.format("%s version %s: %s", addonName, version, message))
                end
                
                local bestAPIVersion = self:GetBestAPIVersion(addonName, version)
                if not bestAPIVersion then
                    self:PrintError(string.format("No compatible API version found for %s version %s", addonName, version))
                    return {}
                end
                
                local apiVersion = compatibility.apiVersions[bestAPIVersion]
                if apiVersion and apiVersion.getProfiles then
                    return apiVersion.getProfiles()
                end
                
                return {}
            end,
            setProfile = function(profileName)
                if not IsAddOnLoaded(addonName) then 
                    return false, addonName .. " not loaded" 
                end
                
                local version = self:GetAddonVersion(addonName)
                local isCompatible, message = self:IsVersionCompatible(addonName, version)
                
                if not isCompatible then
                    return false, string.format("Version incompatibility: %s", message)
                end
                
                local bestAPIVersion = self:GetBestAPIVersion(addonName, version)
                if not bestAPIVersion then
                    return false, string.format("No compatible API version found for %s version %s", addonName, version)
                end
                
                local apiVersion = compatibility.apiVersions[bestAPIVersion]
                if apiVersion and apiVersion.setProfile then
                    local ok, err = apiVersion.setProfile(profileName)
                    if ok and message then
                        PS:Print(string.format("%s v%s applied with untested compatibility.", addonName, version))
                    end
                    return ok, err
                end
                
                return false, string.format("API not available for %s version %s", addonName, version)
            end,
            requiresReload = self.ReloadRequired[addonName] or false,
            version = function() return self:GetAddonVersion(addonName) end,
            isCompatible = function() 
                local version = self:GetAddonVersion(addonName)
                return self:IsVersionCompatible(addonName, version)
            end,
            compatibilityError = function()
                local version = self:GetAddonVersion(addonName)
                local isCompatible, message = self:IsVersionCompatible(addonName, version)
                return isCompatible, message
            end
        }
        
        self.AddonHandlers[addonName] = handler
    end
end

-- Get cached profiles for an addon with version checking
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

-- Get all installed addons from our supported list with version info
function PS:GetInstalledAddons()
    local installed = {}
    for addonName, handler in pairs(self.AddonHandlers) do
        if handler.isLoaded and handler.isLoaded() then
            local isCompatible, error = handler.isCompatible()
            table.insert(installed, {
                name = addonName,
                version = handler.version(),
                isCompatible = isCompatible,
                compatibilityError = error
            })
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

-- Apply profile to an addon with enhanced error handling
function PS:ApplyProfile(addonName, profileName)
    local handler = self.AddonHandlers[addonName]
    if not handler then
        return false, "Addon not supported"
    end
    
    if not handler.isLoaded() then
        return false, addonName .. " not loaded"
    end
    
    local isCompatible, error = handler.isCompatible()
    if not isCompatible then
        return false, string.format("Version incompatibility: %s", error)
    end
    
    if not self:ProfileExists(addonName, profileName) then
        return false, "Profile '" .. profileName .. "' not found in " .. addonName
    end
    
    local success, error, requiresReload = handler.setProfile(profileName)
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

-- Get compatibility report for all addons
function PS:GetCompatibilityReport()
    local report = {}
    for addonName, handler in pairs(self.AddonHandlers) do
        local isLoaded = handler.isLoaded()
        local version = handler.version()
        local isCompatible, error = handler.isCompatible()
        
        table.insert(report, {
            addon = addonName,
            isLoaded = isLoaded,
            version = version,
            isCompatible = isCompatible,
            compatibilityError = error
        })
    end
    return report
end