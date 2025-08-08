-- ProfileSync/core.lua
-- Core addon functionality

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Addon version
PS.version = "1.0.0"
PS.debug = PS.debug or false

-- Application state
PS.isApplying = false
PS.applyQueue = {}
PS.currentIndex = 0
PS.results = {}
PS._initialized = PS._initialized or false
PS._eventsRegistered = PS._eventsRegistered or false

-- Initialize the addon (runs once when our addon finishes loading)
function PS:OnEnable()
    if self._initialized then return end
    self._initialized = true

    -- Initialize database container (no character-specific access here)
    if self.InitializeDB then
        self:InitializeDB()
    end

    -- Initialize handlers
    if self.InitializeHandlers then
        self:InitializeHandlers()
    end

    -- Register runtime events (no ADDON_LOADED here)
    self:RegisterEvents()

    -- Create slash commands
    self:CreateSlashCommands()
    
    print("|cFF00FF00ProfileSync|r loaded successfully! Version: " .. self.version)
    print("|cFF00FF00ProfileSync|r Type /profilesync to open the UI")
end

-- Register events (singleton frame)
function PS:RegisterEvents()
    if self._eventsRegistered then return end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            -- Character-specific init happens here
            if PS.InitializeCharacterData then
                PS:InitializeCharacterData()
            end
            PS:OnPlayerLogin()
        elseif event == "PLAYER_ENTERING_WORLD" then
            PS:OnPlayerEnteringWorld()
        end
    end)

    self.eventFrame = frame
    self._eventsRegistered = true
end

-- Bootstrap loader: listen for ADDON_LOADED only to start OnEnable
local bootstrapFrame = CreateFrame("Frame")
bootstrapFrame:RegisterEvent("ADDON_LOADED")
bootstrapFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if loadedAddon == "ProfileSync" then
        if not PS._initialized then
            PS:OnEnable()
        end
        -- We no longer need to listen after initialization
        bootstrapFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Handle player login
function PS:OnPlayerLogin()
    -- Check if we should auto-apply profiles
    if self:GetAutoApply() and not self:HaveProfilesBeenApplied() then
        C_Timer.After(2, function() -- Delay to ensure other addons are loaded
            self:AutoApplyProfiles()
        end)
    end
end

-- Handle entering world
function PS:OnPlayerEnteringWorld()
    -- Refresh profile cache when entering world
    self:ClearProfileCache()
end

-- Auto-apply profiles for new characters
function PS:AutoApplyProfiles()
    local savedProfiles = self:GetAllSavedProfiles()
    if next(savedProfiles) then
        print("|cFF00FF00ProfileSync|r: Auto-applying profiles for new character...")
        self:ApplyAllProfiles(true) -- true = silent mode
    end
end

-- Create slash commands
function PS:CreateSlashCommands()
    SLASH_PROFILESYNC1 = "/profilesync"
    SLASH_PROFILESYNC2 = "/ps"
    
    SlashCmdList["PROFILESYNC"] = function(msg)
        PS:HandleSlashCommand(msg)
    end
end

-- Handle slash commands
function PS:HandleSlashCommand(msg)
    local command = string.lower(msg or "")
    local cmd, arg = command:match("^(%S+)%s*(%S*)$")
    cmd = cmd or command
    arg = arg or ""
    
    if cmd == "" then
        PS:ShowUI()
    elseif cmd == "help" then
        PS:ShowHelp()
    elseif cmd == "version" then
        print("|cFF00FF00ProfileSync|r Version: " .. PS.version)
    elseif cmd == "apply" then
        PS:ApplyAllProfiles()
    elseif cmd == "reset" then
        PS:ResetCharacterData()
        print("|cFF00FF00ProfileSync|r: Character data reset!")
    elseif cmd == "compatibility" or cmd == "compat" then
        PS:ShowCompatibilityReport()
    elseif cmd == "status" then
        PS:ShowStatusReport()
    elseif cmd == "untested" then
        if arg == "on" or arg == "true" then
            PS:SetAllowUntested(true)
        elseif arg == "off" or arg == "false" then
            PS:SetAllowUntested(false)
        else
            PS:SetAllowUntested(not PS:GetAllowUntested())
        end
        print("|cFF00FF00ProfileSync|r: Allow untested versions = " .. tostring(PS:GetAllowUntested()))
        PS:UpdateUI()
    elseif cmd == "debug" then
        if arg == "on" or arg == "true" then
            PS.debug = true
        elseif arg == "off" or arg == "false" then
            PS.debug = false
        else
            PS.debug = not PS.debug
        end
        print("|cFF00FF00ProfileSync|r: Debug logging = " .. tostring(PS.debug))
    else
        print("|cFFFF0000ProfileSync|r: Unknown command. Type /profilesync help for available commands.")
    end
end

-- Show help
function PS:ShowHelp()
    print("|cFF00FF00ProfileSync Commands:|r")
    print("/profilesync or /ps - Open the UI")
    print("/profilesync help - Show this help")
    print("/profilesync version - Show addon version")
    print("/profilesync apply - Apply all profiles")
    print("/profilesync reset - Reset character data")
    print("/profilesync compatibility - Show compatibility report")
    print("/profilesync status - Show detailed status report")
    print("/profilesync untested [on|off] - Toggle allowing untested addon versions")
    print("/profilesync debug [on|off] - Toggle debug logging")
end

-- Show compatibility report
function PS:ShowCompatibilityReport()
    local report = PS:GetCompatibilityReport()
    
    print("|cFF00FF00ProfileSync Compatibility Report:|r")
    print("=" .. string.rep("=", 50))
    
    for _, addon in ipairs(report) do
        local status = addon.isLoaded and "|cFF00FF00Loaded|r" or "|cFFFF0000Not Loaded|r"
        local compatibility = addon.isCompatible and "|cFF00FF00Compatible|r" or "|cFFFF0000Incompatible|r"
        
        print(string.format("%s (v%s): %s - %s", addon.addon, addon.version, status, compatibility))
        
        if not addon.isCompatible and addon.compatibilityError then
            print("  |cFFFF0000Error:|r " .. addon.compatibilityError)
        end
    end
    
    print("=" .. string.rep("=", 50))
end

-- Show detailed status report
function PS:ShowStatusReport()
    local report = PS:GetCompatibilityReport()
    local installedAddons = PS:GetInstalledAddons()
    local savedProfiles = PS:GetAllSavedProfiles()
    
    print("|cFF00FF00ProfileSync Status Report:|r")
    print("=" .. string.rep("=", 50))
    
    -- Compatibility status
    print("|cFFFFFF00Compatibility Status:|r")
    for _, addon in ipairs(report) do
        if addon.isLoaded then
            local compatibility = addon.isCompatible and "|cFF00FF00✓|r" or "|cFFFF0000✗|r"
            print(string.format("  %s %s (v%s)", compatibility, addon.addon, addon.version))
            
            if not addon.isCompatible and addon.compatibilityError then
                print("    |cFFFF0000Error:|r " .. addon.compatibilityError)
            end
        end
    end
    
    -- Installed addons
    print("\n|cFFFFFF00Installed Addons:|r")
    for _, addon in ipairs(installedAddons) do
        local compatibility = addon.isCompatible and "|cFF00FF00✓|r" or "|cFFFF0000✗|r"
        print(string.format("  %s %s (v%s)", compatibility, addon.name, addon.version))
    end
    
    -- Saved profiles
    print("\n|cFFFFFF00Saved Profiles:|r")
    if next(savedProfiles) then
        for addonName, profileName in pairs(savedProfiles) do
            print(string.format("  %s: %s", addonName, profileName))
        end
    else
        print("  No profiles configured")
    end
    
    -- Auto-apply status
    local autoApply = PS:GetAutoApply()
    print(string.format("\n|cFFFFFF00Auto-apply:|r %s", autoApply and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    
    print("=" .. string.rep("=", 50))
end

-- Apply all saved profiles
function PS:ApplyAllProfiles(silent)
    if self.isApplying then
        if not silent then
            print("|cFFFF0000ProfileSync|r: Already applying profiles, please wait...")
        end
        return
    end
    
    local savedProfiles = self:GetAllSavedProfiles()
    self:Debug("Starting apply with " .. tostring((savedProfiles and next(savedProfiles)) and (function(tbl) local c=0 for _ in pairs(tbl) do c=c+1 end return c end)(savedProfiles) or 0) .. " saved entries")
    if not next(savedProfiles) then
        if not silent then
            print("|cFFFF0000ProfileSync|r: No profiles configured. Open the UI to set up profiles.")
        end
        return
    end
    
    -- Build apply queue with preflight validation
    self.applyQueue = {}
    self.results = {}
    self.currentIndex = 0
    
    local skipped = 0
    for addonName, profileName in pairs(savedProfiles) do
        local handler = self.AddonHandlers and self.AddonHandlers[addonName]
        if not handler then
            table.insert(self.results, {
                addon = addonName,
                profile = profileName,
                success = false,
                error = "Addon not supported",
                requiresReload = false
            })
            skipped = skipped + 1
        elseif not handler.isLoaded() then
            table.insert(self.results, {
                addon = addonName,
                profile = profileName,
                success = false,
                error = addonName .. " not loaded",
                requiresReload = false
            })
            skipped = skipped + 1
        else
            local isCompatible, compMsg = handler.isCompatible()
            if not isCompatible then
                table.insert(self.results, {
                    addon = addonName,
                    profile = profileName,
                    success = false,
                    error = "Version incompatibility: " .. (compMsg or "unknown"),
                    requiresReload = false
                })
                skipped = skipped + 1
            elseif not self:ProfileExists(addonName, profileName) then
                table.insert(self.results, {
                    addon = addonName,
                    profile = profileName,
                    success = false,
                    error = "Profile '" .. tostring(profileName) .. "' not found in " .. addonName,
                    requiresReload = false
                })
                skipped = skipped + 1
            else
                table.insert(self.applyQueue, {addon = addonName, profile = profileName, retried = false})
            end
        end
    end
    
    if not silent then
        local queued = #self.applyQueue
        if skipped > 0 then
            print("|cFFFFFF00ProfileSync|r: Skipping " .. skipped .. " item(s) due to validation errors. Queued " .. queued .. ".")
        else
            print("|cFF00FF00ProfileSync|r: Applying " .. queued .. " profiles...")
        end
    end
    self:Debug("Queue size after preflight: " .. tostring(#self.applyQueue))
    
    if #self.applyQueue == 0 then
        -- Nothing to process; finish to report skipped failures
        self.isApplying = false
        self:FinishApplying(silent)
        return
    end
    
    self.isApplying = true
    self:ProcessNextProfile(silent)
end

-- Process next profile in queue
function PS:ProcessNextProfile(silent)
    self.currentIndex = self.currentIndex + 1
    
    if self.currentIndex > #self.applyQueue then
        -- All profiles processed
        self:FinishApplying(silent)
        return
    end
    
    local item = self.applyQueue[self.currentIndex]
    self:Debug("Applying [" .. tostring(self.currentIndex) .. "/" .. tostring(#self.applyQueue) .. "] " .. item.addon .. " -> " .. tostring(item.profile))
    local success, error, requiresReload = self:ApplyProfile(item.addon, item.profile)
    
    -- Store result
    table.insert(self.results, {
        addon = item.addon,
        profile = item.profile,
        success = success,
        error = error,
        requiresReload = requiresReload
    })
    
    -- If failed, do a one-time retry after a short delay
    if not success and not item.retried then
        item.retried = true
        if not silent then
            local progress = string.format("(%d/%d)", self.currentIndex, #self.applyQueue)
            print("|cFFFFFF00ProfileSync|r " .. progress .. " Retrying " .. item.profile .. " for " .. item.addon .. "...")
        end
        C_Timer.After(0.3, function()
            local rs, re, rr = PS:ApplyProfile(item.addon, item.profile)
            PS:Debug("Retry result: " .. tostring(rs) .. ", " .. tostring(re))
            -- Update last result entry
            PS.results[#PS.results] = {
                addon = item.addon,
                profile = item.profile,
                success = rs,
                error = re,
                requiresReload = rr
            }
            if not silent then
                local progress = string.format("(%d/%d)", PS.currentIndex, #PS.applyQueue)
                if rs then
                    print("|cFF00FF00ProfileSync|r " .. progress .. " Applied " .. item.profile .. " to " .. item.addon .. " (after retry)")
                else
                    print("|cFFFF0000ProfileSync|r " .. progress .. " Failed to apply " .. item.profile .. " to " .. item.addon .. ": " .. (re or "Unknown error"))
                end
            end
            C_Timer.After(0.1, function()
                PS:ProcessNextProfile(silent)
            end)
        end)
        return
    end
    
    -- Show progress if not silent
    if not silent then
        local progress = string.format("(%d/%d)", self.currentIndex, #self.applyQueue)
        if success then
            print("|cFF00FF00ProfileSync|r " .. progress .. " Applied " .. item.profile .. " to " .. item.addon)
        else
            print("|cFFFF0000ProfileSync|r " .. progress .. " Failed to apply " .. item.profile .. " to " .. item.addon .. ": " .. (error or "Unknown error"))
        end
    end
    
    -- Process next profile after a short delay
    C_Timer.After(0.1, function()
        self:ProcessNextProfile(silent)
    end)
end

-- Finish applying profiles
function PS:FinishApplying(silent)
    self.isApplying = false
    
    -- Count results
    local successCount = 0
    local failCount = 0
    local reloadRequired = false
    local reloadAddons = {}
    
    for _, result in ipairs(self.results) do
        if result.success then
            successCount = successCount + 1
            if result.requiresReload then
                reloadRequired = true
                table.insert(reloadAddons, result.addon)
            end
        else
            failCount = failCount + 1
        end
    end
    
    -- Mark as applied if any succeeded
    if successCount > 0 then
        self:MarkProfilesApplied()
    end
    
    if not silent then
        if successCount > 0 then
            print("|cFF00FF00ProfileSync|r: Successfully applied " .. successCount .. " profiles!")
        end
        
        if failCount > 0 then
            print("|cFFFF0000ProfileSync|r: Failed to apply " .. failCount .. " profiles.")
        end
        
        if reloadRequired then
            print("|cFFFFFF00ProfileSync|r: Some addons require a UI reload (" .. table.concat(reloadAddons, ", ") .. "). Type /reload to apply changes.")
        end
    end
    
    -- Update UI if it's open
    if PS.UpdateUI then
        PS:UpdateUI()
    end
end

-- Show UI (placeholder - will be implemented in ui.lua)
function PS:ShowUI()
    if PS.ShowMainFrame then
        PS:ShowMainFrame()
    else
        print("|cFFFF0000ProfileSync|r: UI not available yet.")
    end
end

-- Update UI (placeholder - will be implemented in ui.lua)
function PS:UpdateUI()
    -- This will be called from ui.lua
end

-- Utility functions
function PS:Print(msg)
    print("|cFF00FF00ProfileSync|r: " .. msg)
end

function PS:PrintError(msg)
    print("|cFFFF0000ProfileSync|r: " .. msg)
end

function PS:Debug(msg)
    if self.debug then
        print("|cFF999999[ProfileSync:DEBUG]|r " .. tostring(msg))
    end
end