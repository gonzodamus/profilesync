-- ProfileSync/ui.lua
-- User interface

local addonName, addon = ...
ProfileSync = ProfileSync or {}
local PS = ProfileSync

-- UI elements
PS.mainFrame = nil
PS.addonRows = {}
PS.dropdowns = {}

-- Initialize UI
function PS:InitializeUI()
    self:CreateMainFrame()
    self:CreateContent()
end

-- Create main frame
function PS:CreateMainFrame()
    local frame = CreateFrame("Frame", "ProfileSyncMainFrame", UIParent, "UIPanelDialogTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Set title
    frame.Title:SetText("ProfileSync")
    
    -- Close button
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    self.mainFrame = frame
end

-- Create content
function PS:CreateContent()
    local frame = self.mainFrame
    
    -- Auto-apply checkbox
    local autoApplyCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoApplyCheckbox:SetPoint("TOPLEFT", 20, -50)
    autoApplyCheckbox:SetScript("OnClick", function(self)
        PS:SetAutoApply(self:GetChecked())
    end)
    autoApplyCheckbox.text:SetText("Auto-apply profiles on new characters")
    
    -- Keep a direct reference for robust updates
    self.autoApplyCheckbox = autoApplyCheckbox

    -- Allow untested versions checkbox
    local untestedCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    untestedCheckbox:SetPoint("TOPLEFT", 20, -75)
    untestedCheckbox:SetScript("OnClick", function(self)
        PS:SetAllowUntested(self:GetChecked())
        PS:UpdateUI()
    end)
    untestedCheckbox.text:SetText("Allow untested addon versions")
    self.untestedCheckbox = untestedCheckbox
    
    -- Content area
    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", 20, -110)
    contentFrame:SetPoint("BOTTOMRIGHT", -20, 60)
    
    -- Scroll frame for addon list
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 300)
    scrollFrame:SetScrollChild(scrollChild)
    
    self.contentFrame = contentFrame
    self.scrollChild = scrollChild
    
    -- Apply button
    local applyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    applyButton:SetSize(120, 30)
    applyButton:SetPoint("BOTTOM", 70, 20)
    applyButton:SetText("Apply Profiles")
    applyButton:SetScript("OnClick", function()
        PS:ApplyAllProfiles()
    end)
    self.applyButton = applyButton

    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(120, 30)
    refreshButton:SetPoint("BOTTOM", -70, 20)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        PS:ClearProfileCache()
        PS:UpdateUI()
    end)
    self.refreshButton = refreshButton
    
    -- Progress text
    local progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("BOTTOM", 0, 50)
    progressText:SetText("")
    
    self.progressText = progressText
end

-- Create addon row
function PS:CreateAddonRow(addonName, yOffset)
    local row = CreateFrame("Frame", nil, self.scrollChild)
    row:SetSize(440, 30)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Addon name with version
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", 0, 0)
    nameText:SetText(addonName)
    nameText:SetWidth(150)
    
    -- Version text
    local versionText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("LEFT", 160, 0)
    versionText:SetWidth(80)
    versionText:SetText("")
    
    -- Compatibility indicator
    local compatIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    compatIcon:SetPoint("LEFT", 250, 0)
    compatIcon:SetWidth(20)
    compatIcon:SetText("")
    
    -- Profile dropdown
    local dropdown = CreateFrame("Frame", "ProfileSyncDropdown" .. addonName, row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", 280, 0)
    dropdown:SetScript("OnShow", function()
        PS:InitializeDropdown(dropdown, addonName)
    end)
    
    -- Store references
    row.addonName = addonName
    row.nameText = nameText
    row.versionText = versionText
    row.compatIcon = compatIcon
    row.dropdown = dropdown
    
    self.addonRows[addonName] = row
    self.dropdowns[addonName] = dropdown
    
    return row
end

-- Initialize dropdown
function PS:InitializeDropdown(dropdown, addonName)
    local profiles = PS:GetCachedProfiles(addonName)
    local savedProfile = PS:GetSavedProfile(addonName)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        if level == 1 then
            -- Add "None" option
            info.text = "None"
            info.value = nil
            info.func = function()
                PS:SaveAddonProfile(addonName, nil)
                UIDropDownMenu_SetText(dropdown, "None")
            end
            UIDropDownMenu_AddButton(info)
            
            -- Add profile options
            for _, profile in ipairs(profiles) do
                info.text = profile
                info.value = profile
                info.func = function()
                    PS:SaveAddonProfile(addonName, profile)
                    UIDropDownMenu_SetText(dropdown, profile)
                end
                UIDropDownMenu_AddButton(info)
            end
            
            -- Add refresh option
            info.text = "Refresh"
            info.value = "refresh"
            info.func = function()
                PS:RefreshCachedProfiles(addonName)
                PS:UpdateUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set current selection
    if savedProfile then
        UIDropDownMenu_SetText(dropdown, savedProfile)
    else
        UIDropDownMenu_SetText(dropdown, "None")
    end
end

-- Update addon row with version and compatibility info
function PS:UpdateAddonRow(row, addonInfo)
    if not addonInfo then return end
    
    -- Update version text
    row.versionText:SetText("v" .. addonInfo.version)
    
    -- Update compatibility indicator
    if addonInfo.isCompatible then
        row.compatIcon:SetText("|cFF00FF00✓|r")
        row.compatIcon:SetTextColor(0, 1, 0)
        
        -- Ensure dropdown enabled
        UIDropDownMenu_EnableDropDown(row.dropdown)
        row.dropdown:Enable() -- just in case
        row.dropdown:SetScript("OnEnter", nil)
        row.dropdown:SetScript("OnLeave", nil)
    else
        row.compatIcon:SetText("|cFFFF0000✗|r")
        row.compatIcon:SetTextColor(1, 0, 0)
        
        -- Disable dropdown and explain why
        UIDropDownMenu_DisableDropDown(row.dropdown)
        row.dropdown:Disable()
        row.dropdown:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Incompatible Version")
            GameTooltip:AddLine(addonInfo.compatibilityError or "This addon version is not supported.", 1, 0, 0)
            GameTooltip:Show()
        end)
        row.dropdown:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

-- Update UI
function PS:UpdateUI()
    if not self.mainFrame or not self.mainFrame:IsShown() then
        return
    end
    
    -- Update checkboxes directly
    if self.autoApplyCheckbox then
        self.autoApplyCheckbox:SetChecked(PS:GetAutoApply())
    end
    if self.untestedCheckbox then
        self.untestedCheckbox:SetChecked(PS:GetAllowUntested())
    end
    
    -- Clear existing rows
    for _, row in pairs(self.addonRows) do
        row:Hide()
    end
    
    -- Get installed addons with version info
    local installedAddons = PS:GetInstalledAddons()
    
    -- Create rows for installed addons
    local yOffset = 0
    for _, addonInfo in ipairs(installedAddons) do
        local row = self.addonRows[addonInfo.name]
        if not row then
            row = self:CreateAddonRow(addonInfo.name, -yOffset)
        end
        
        -- Update row with version and compatibility info
        self:UpdateAddonRow(row, addonInfo)
        
        row:Show()
        row:SetPoint("TOPLEFT", 0, -yOffset)
        yOffset = yOffset + 35
    end
    
    -- Update scroll frame size
    self.scrollChild:SetHeight(yOffset)
    
    -- Update progress text
    if PS.isApplying then
        local progress = string.format("Applying profiles... (%d/%d)", PS.currentIndex, #PS.applyQueue)
        self.progressText:SetText(progress)
    else
        self.progressText:SetText("")
    end
end

-- Show main frame
function PS:ShowMainFrame()
    if not self.mainFrame then
        self:InitializeUI()
    end
    
    self.mainFrame:Show()
    self:UpdateUI()
end

-- Hide main frame
function PS:HideMainFrame()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

-- Override the core ShowUI function
PS.ShowUI = PS.ShowMainFrame