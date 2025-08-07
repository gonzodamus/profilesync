-- MyAddon.lua
-- Main addon file

-- Create addon namespace
MyAddon = MyAddon or {}
local addon = MyAddon

-- Addon version
addon.version = "1.0.0"

-- Initialize saved variables
function addon:InitializeDB()
    MyAddonDB = MyAddonDB or {}
    self.db = MyAddonDB
end

-- Main addon initialization
function addon:OnEnable()
    self:InitializeDB()
    self:RegisterEvents()
    self:CreateSlashCommands()
    
    print("|cFF00FF00MyAddon|r loaded successfully! Version: " .. self.version)
end

-- Register events
function addon:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("ADDON_LOADED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            addon:OnPlayerLogin()
        elseif event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == "MyAddon" then
                addon:OnEnable()
            end
        end
    end)
end

-- Handle player login
function addon:OnPlayerLogin()
    -- Add any login-specific functionality here
    print("|cFF00FF00MyAddon|r: Player logged in!")
end

-- Create slash commands
function addon:CreateSlashCommands()
    SLASH_MYADDON1 = "/myaddon"
    SLASH_MYADDON2 = "/ma"
    
    SlashCmdList["MYADDON"] = function(msg)
        addon:HandleSlashCommand(msg)
    end
end

-- Handle slash commands
function addon:HandleSlashCommand(msg)
    local command = string.lower(msg or "")
    
    if command == "" or command == "help" then
        print("|cFF00FF00MyAddon Commands:|r")
        print("/myaddon or /ma - Show this help")
        print("/myaddon version - Show addon version")
        print("/myaddon test - Test functionality")
        print("/myaddon show - Show the addon UI")
        print("/myaddon hide - Hide the addon UI")
        print("/myaddon toggle - Toggle the addon UI")
    elseif command == "version" then
        print("|cFF00FF00MyAddon|r Version: " .. self.version)
    elseif command == "test" then
        print("|cFF00FF00MyAddon|r: Test command executed!")
        self:DoSomething()
    elseif command == "show" then
        self:ShowUI()
    elseif command == "hide" then
        self:HideUI()
    elseif command == "toggle" then
        self:ToggleUI()
    else
        print("|cFFFF0000MyAddon|r: Unknown command. Type /myaddon help for available commands.")
    end
end

-- Utility functions
function addon:Print(msg)
    print("|cFF00FF00MyAddon|r: " .. msg)
end

-- Example function that can be called from other parts of the addon
function addon:DoSomething()
    self:Print("Doing something awesome!")
end

-- UI Functions
function addon:ShowUI()
    if MyAddonFrame then
        MyAddonFrame:Show()
        self:Print("UI shown!")
    else
        self:Print("UI frame not found!")
    end
end

function addon:HideUI()
    if MyAddonFrame then
        MyAddonFrame:Hide()
        self:Print("UI hidden!")
    else
        self:Print("UI frame not found!")
    end
end

function addon:ToggleUI()
    if MyAddonFrame then
        if MyAddonFrame:IsShown() then
            self:HideUI()
        else
            self:ShowUI()
        end
    else
        self:Print("UI frame not found!")
    end
end