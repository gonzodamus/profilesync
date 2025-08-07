-- ProfileSync/core.lua
-- Core addon functionality

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- Addon version
PS.version = "1.0.0"

-- Application state
PS.isApplying = false
PS.applyQueue = {}
PS.currentIndex = 0
PS.results = {}

-- Initialize the addon
function PS:OnEnable()
    self:InitializeDB()
    self:InitializeHandlers()
    self:RegisterEvents()
    self:CreateSlashCommands()
    
    print("|cFF00FF00ProfileSync|r loaded successfully! Version: " .. self.version)
    print("|cFF00FF00ProfileSync|r Type /profilesync to open the UI")
end

-- Register events
function PS:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            PS:OnPlayerLogin()
        elseif event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == "ProfileSync" then
                PS:OnEnable()
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            PS:OnPlayerEnteringWorld()
        end
    end)
end

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
    
    if command == "" then
        PS:ShowUI()
    elseif command == "help" then
        PS:ShowHelp()
    elseif command == "version" then
        print("|cFF00FF00ProfileSync|r Version: " .. PS.version)
    elseif command == "apply" then
        PS:ApplyAllProfiles()
    elseif command == "reset" then
        PS:ResetCharacterData()
        print("|cFF00FF00ProfileSync|r: Character data reset!")
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
    if not next(savedProfiles) then
        if not silent then
            print("|cFFFF0000ProfileSync|r: No profiles configured. Open the UI to set up profiles.")
        end
        return
    end
    
    -- Build apply queue
    self.applyQueue = {}
    self.results = {}
    self.currentIndex = 0
    
    for addonName, profileName in pairs(savedProfiles) do
        table.insert(self.applyQueue, {addon = addonName, profile = profileName})
    end
    
    if not silent then
        print("|cFF00FF00ProfileSync|r: Applying " .. #self.applyQueue .. " profiles...")
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
    local success, error, requiresReload = self:ApplyProfile(item.addon, item.profile)
    
    -- Store result
    table.insert(self.results, {
        addon = item.addon,
        profile = item.profile,
        success = success,
        error = error,
        requiresReload = requiresReload
    })
    
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
    
    for _, result in ipairs(self.results) do
        if result.success then
            successCount = successCount + 1
            if result.requiresReload then
                reloadRequired = true
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
            print("|cFFFFFF00ProfileSync|r: Some addons require a UI reload. Type /reload to apply changes.")
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