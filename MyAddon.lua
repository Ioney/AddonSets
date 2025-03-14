local MyAddonDropdown = CreateFrame("DropdownButton", "MyAddonDropdown", AddonList, "WowStyle1DropdownTemplate")

MyAddonDropdown:SetDefaultText("Select an Option")
MyAddonDropdown:SetPoint("LEFT", AddonList.DisableAllButton, "RIGHT", 10, 0)
MyAddonDropdown:SetSize(150, 30)

local selectedSet = 1
local addonSets = AddonSetsDB or {}

local function GetActiveAddons()
    local activeAddons = {}
    for i = 1, C_AddOns.GetNumAddOns() do
        local name, _, _, _, _, _ = C_AddOns.GetAddOnInfo(i)
        local enabled = (C_AddOns.GetAddOnEnableState(i, UnitName("player")) > Enum.AddOnEnableState.None)
        if enabled then
            table.insert(activeAddons, name)
        end
    end
    return activeAddons
end

local function SaveAddonList(setIndex)
    addonSets[setIndex] = GetActiveAddons()
    AddonSetsDB = addonSets
    print("Saving addon list for set " .. setIndex .. ": " .. table.concat(addonSets[setIndex], ", "))
end

local function DeleteAddonList(setIndex)
    addonSets[setIndex] = nil
    AddonSetsDB = addonSets
    print("Deleting addon list for set " .. setIndex)
end

local function LoadAddonList(setIndex)
    local addonList = addonSets[setIndex]
    if addonList then
        C_AddOns.DisableAllAddOns(UnitName("player"))
        for _, addonName in ipairs(addonList) do
            for i = 1, C_AddOns.GetNumAddOns() do
                local name, _, _, _, _, _ = C_AddOns.GetAddOnInfo(i)
                if name == addonName then
                    C_AddOns.EnableAddOn(i, UnitName("player"))
                    break
                end
            end
        end
        AddonList_Update()
        -- ReloadUI()
        print("Loaded addon list for set " .. setIndex .. ": " .. table.concat(addonList, ", "))
    else
        print("No saved addon list for set " .. setIndex)
    end
end

local function IsSelected(index) return index == selectedSet end
local function SetSelected(index)
    selectedSet = index
    print("Set " .. index .. " selected")
    LoadAddonList(index)
end

local function GeneratorFunction(dropdown, rootDescription)
    rootDescription:CreateTitle("Addon Sets")

    for index = 1, 10 do
        local setButton = rootDescription:CreateRadio("Set " .. index, IsSelected, SetSelected, index)
        setButton:SetResponder(function()
            SetSelected(index)
            return MenuResponse.Close
        end)
        local submenu = setButton:CreateButton("Options")

        submenu:CreateButton("Save", function() SaveAddonList(index) end)
        submenu:CreateButton("Delete", function() DeleteAddonList(index) end)
    end
end

MyAddonDropdown:SetupMenu(GeneratorFunction)
