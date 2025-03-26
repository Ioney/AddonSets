local L = LibStub("AceLocale-3.0"):GetLocale("AddonSets")

local addonSetsDropdown = CreateFrame("DropdownButton", "AddonSetsDropdown",
                                      AddonList, "WowStyle1DropdownTemplate")
addonSetsDropdown:SetDefaultText(L["AddonSets"])
addonSetsDropdown:SetPoint("BOTTOMLEFT", AddonList, "BOTTOMLEFT", 10, -1)
addonSetsDropdown:SetSize(150, 30)

local character = UnitName("player")
local selectedSet = 1
local addonSets = {}
local addonSetNames = {}

local function GetActiveAddons()
    local activeAddons = {}
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        if C_AddOns.GetAddOnEnableState(i, character) > 0 then
            table.insert(activeAddons, name)
        end
    end
    return activeAddons
end

local function SaveAddonSet(index)
    addonSets[index] = GetActiveAddons()
    AddonSetsDB.sets = addonSets
    AddonSetsDB.lastSelectedSet = index
end

local function DeleteAddonSet(index)
    addonSets[index], addonSetNames[index] = nil, nil
    AddonSetsDB.sets, AddonSetsDB.names = addonSets, addonSetNames
end

local function ConfirmDeleteAddonSet(index)
    StaticPopupDialogs["CONFIRM_DELETE_ADDON_SET"] = {
        text = L["ConfirmDeleteSet"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function() DeleteAddonSet(index) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    StaticPopup_Show("CONFIRM_DELETE_ADDON_SET")
end

local function LoadAddonSet(index)
    if not addonSets[index] then return end

    C_AddOns.DisableAllAddOns(character)

    for _, addonName in ipairs(addonSets[index]) do
        C_AddOns.EnableAddOn(addonName, character)
    end

    AddonList_Update()
end

local function SetSelected(index)
    selectedSet = index
    AddonSetsDB.lastSelectedSet = index
    LoadAddonSet(index)
end

local function RenameAddonSet(index)
    StaticPopupDialogs["RENAME_ADDON_SET"] = {
        text = L["NewSetName"],
        button1 = L["OK"],
        button2 = L["Cancel"],
        hasEditBox = true,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            addonSetNames[index] = newName
            AddonSetsDB.names = addonSetNames
        end,
        EditBoxOnEnterPressed = function(self)
            addonSetNames[index] = self:GetText()
            AddonSetsDB.names = addonSetNames
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    StaticPopup_Show("RENAME_ADDON_SET")
end

local function GenerateDropdownMenu(dropdown, rootDescription)
    rootDescription:CreateTitle(L["AddonSets"])

    for index = 1, 10 do
        local addonCount = addonSets[index] and #addonSets[index] or 0
        local text = addonSetNames[index] or ("%s %d"):format(L["Set"], index)
        if addonCount > 0 then
            text = ("%s (%d)"):format(text, addonCount)
        end

        local setButton = rootDescription:CreateRadio(text, function()
            return index == selectedSet
        end, SetSelected, index)

        setButton:SetResponder(function()
            SetSelected(index)
            return MenuResponse.Close
        end)

        setButton:CreateButton(L["Save"], function() SaveAddonSet(index) end)

        if addonCount > 0 then
            setButton:CreateButton(L["Rename"],
                                   function() RenameAddonSet(index) end)
            setButton:CreateButton(L["Delete"],
                                   function()
                ConfirmDeleteAddonSet(index)
            end)
        end
    end

    rootDescription:CreateDivider()

    rootDescription:CreateButton(L["EnableAll"], function()
        C_AddOns.EnableAllAddOns(character)
        AddonList_Update()
    end)

    rootDescription:CreateButton(L["DisableAll"], function()
        for i = 1, C_AddOns.GetNumAddOns() do
            if C_AddOns.GetAddOnInfo(i) ~= "AddonSets" then
                C_AddOns.DisableAddOn(i, character)
            end
        end
        AddonList_Update()
    end)
end

addonSetsDropdown:SetupMenu(GenerateDropdownMenu)

local function OnAddonLoaded(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "AddonSets" then
        AddonSetsDB = AddonSetsDB or
                          {sets = {}, names = {}, lastSelectedSet = 1}
        addonSets, addonSetNames, selectedSet = AddonSetsDB.sets,
                                                AddonSetsDB.names,
                                                AddonSetsDB.lastSelectedSet
        -- Hide Blizzard buttons
        if AddonList.EnableAllButton then
            AddonList.EnableAllButton:Hide()
        end
        if AddonList.DisableAllButton then
            AddonList.DisableAllButton:Hide()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)
