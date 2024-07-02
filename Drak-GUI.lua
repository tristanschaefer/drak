-- Drak is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Tristan Schaefer
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type Drak
local Drak = _G.Drak

local AceGUI = LibStub("AceGUI-3.0")

Drak.mainFrame = {}
Drak.mainFrameShown = false

local icons = {
	["raid"] = "Interface\\ICONS\\spell_warlock_demonicportal_green",
	["dungeon"] = "Interface\\ICONS\\INV_relics_hourglass",
	["pvp"] = "Interface\\ICONS\\achievement_legionpvptier4",
	["pvp_green"] = "Interface\\ICONS\\Achievement_pvp_g_01",
	["pvp_red"] = "Interface\\ICONS\\achievement_pvp_h_01",
	["mythic_green"] = "Interface\\ICONS\\priest_icon_chakra_green",
	["mythic_red"] = "Interface\\ICONS\\priest_icon_chakra_red",
	["raid_green"] = "Interface\\ICONS\\Inv_misc_head_dragon_green",
	["raid_red"] = "Interface\\ICONS\\Inv_misc_head_dragon_red"
}

-- Table to store the class icons and color strings
local classIconsAndColors = {
	["Death Knight"] = { "Interface\\ICONS\\Classicon_deathknight", CreateColorFromHexString("FFC41E3A") },
	["Warlock"] = { "Interface\\ICONS\\Classicon_warlock", CreateColorFromHexString("FF8788EE") },
	["Druid"] = { "Interface\\ICONS\\Classicon_druid:16", CreateColorFromHexString("FFFF7C0A") },
	["Paladin"] = { "Interface\\ICONS\\Classicon_paladin", CreateColorFromHexString("FFF48CBA") },
	["Priest"] = { "Interface\\ICONS\\Classicon_priest", CreateColorFromHexString("FFFFFFFF") },
	["Evoker"] = { "Interface\\ICONS\\Classicon_evoker", CreateColorFromHexString("FF33937F") },
	["Demon Hunter"] = { "Interface\\ICONS\\Classicon_demonhunter", CreateColorFromHexString("FFA330C9") },
	["Mage"] = { "Interface\\ICONS\\Classicon_mage", CreateColorFromHexString("FF3FC7EB") },
	["Rogue"] = { "Interface\\ICONS\\Classicon_rogue", CreateColorFromHexString("FFFFF468") },
	["Warrior"] = { "Interface\\ICONS\\Classicon_warrior", CreateColorFromHexString("FFC69B6D") },
	["Hunter"] = { "Interface\\ICONS\\Classicon_hunter", CreateColorFromHexString("FFAAD372") },
	["Monk"] = { "Interface\\ICONS\\Classicon_monk", CreateColorFromHexString("FF00FF98") },
	["Shaman"] = { "Interface\\ICONS\\Classicon_shaman", CreateColorFromHexString("FF0070DD") },
}

local gearBracketColors = {
	["Mythic"] = CreateColorFromHexString("FFFF8000"),
	["Hero"] = CreateColorFromHexString("FFA335EE"),
	["Champion"] = CreateColorFromHexString("FF0070DD"),
	["Veteran"] = CreateColorFromHexString("FF1EFF00")
}

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- This table is used to populate the dropdown list in the GUI
function Drak:GetServerNames()
	local serverTable = {}
	-- Iterate over all of the char tables in the saved variables "sv" table
	for k, v in pairs(self.db.sv.char) do
		-- Check if the server name doesn't already exist in serverTable
		if v.realm and not serverTable[v.realm] then
			-- If not, add it as a key to serverTable
			serverTable[v.realm] = true
		end
	end
	return serverTable
end

function Drak:CloseFrame()
	if not self.mainFrame then
		return
	end
	self.mainFrameShown = false
	self.mainFrame:Hide()
end

-- Primary Addon Frame - mainFrame and displays the addon data
function Drak:ShowFrame()
	self.mainFrame = AceGUI:Create("Window")
	self.mainFrame:SetTitle("Great Vault Checks")
	self.mainFrame:SetStatusText("Author: Drakwlya - Addon used to check Great Vaults across alts")
	self.mainFrame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		self:CloseFrame()
	end)
	self.mainFrame:SetLayout("Flow")
	self.mainFrame:SetWidth(800)  -- Set the width
	self.mainFrame:SetHeight(600) -- Set the height
	--mainFrame:SetMinResize(600,600)
	-- Get the underlying Blizzard frame
	local blizzFrame = self.mainFrame.frame

	-- Set the minimum and maximum dimensions
	local minWidth = 800

	local dialogbg = blizzFrame:CreateTexture(nil, "BACKGROUND")
	dialogbg:SetColorTexture(0,0,0,1) -- Interface\\Tooltips\\UI-Tooltip-Background
	dialogbg:SetPoint("TOPLEFT", 8, -24)
	dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)

	-- Hook the OnUpdate script to enforce size constraints
	blizzFrame:SetScript("OnUpdate", function(self)
		local width = self:GetSize()

		-- Enforce minimum width and height
		if width < minWidth then
			self:SetWidth(minWidth)

		end

	end)

	-- Add a close button to the top right corner of the frame
	local closeButton = CreateFrame("Button", nil, self.mainFrame.frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", self.mainFrame.frame, "TOPRIGHT")
	closeButton:SetScript("OnClick", self.CloseFrame)

	local button = AceGUI:Create("Button")
	button:SetText("Check Vault")
	button:SetWidth(200)
	button:SetCallback("OnClick", function()
		LoadAddOn("Blizzard_WeeklyRewards")
		WeeklyRewardsFrame:Show()
	end)
	self.mainFrame:AddChild(button)
	button:SetPoint("CENTER")
	self.mainFrame:Show()

	local serverLabel = AceGUI:Create("Label")
	serverLabel:SetText("Server: ")
	serverLabel:SetFullWidth(true)
	serverLabel:SetFontObject(GameFontNormal)
	self.mainFrame:AddChild(serverLabel)

	-- Create a horizontal container for the dropdown and delete button
	local horizontalContainer = AceGUI:Create("SimpleGroup")
	horizontalContainer:SetFullWidth(true)
	horizontalContainer:SetLayout("Flow")
	self.mainFrame:AddChild(horizontalContainer)

	-- Create and add the dropdown to the horizontal container
	local dropdown = AceGUI:Create("Dropdown")
	dropdown:SetWidth(200)

	local serverTable = self:GetServerNames()
	local dropdownList = {}
	for serverName, _ in pairs(serverTable) do
		dropdownList[serverName] = serverName
	end

	dropdownList["None"] = "None"
	local playerRealm = self.db.char.realm
	dropdown:SetList(dropdownList)
	dropdown:SetValue(playerRealm)

	horizontalContainer:AddChild(dropdown)

	-- Create and add the delete button to the horizontal container
	--[[local deleteButton = AceGUI:Create("Button")
	deleteButton:SetText("Delete")
	deleteButton:SetWidth(100)
	deleteButton:SetCallback("OnClick", function()
		-- Add the logic to delete the selected server here
		local serverName = dropdown:GetValue()
		if serverName and serverName ~= "None" then
			self:ShowConfirmationDialog(serverName, function()
				DrakDB["characters"][serverName] = nil
				dropdownList[serverName] = nil
				dropdown:SetList(dropdownList)
				dropdown:SetValue("None")
				print(selectedValue .. " has been deleted.")
			end)
		else
			print("No server selected or 'None' selected.")
		end
	end)
	horizontalContainer:AddChild(deleteButton)]]

	-- Create a container for the ScrollFrame
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	self.mainFrame:AddChild(scrollContainer)

	-- Create the ScrollFrame itself
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	scrollContainer:AddChild(scroll)

	self:GetVaultData()

	-- Set callback for value change event
	dropdown:SetCallback("OnValueChanged", function(widget, event, value)
		playerRealm = value
		scroll:ReleaseChildren()
		self:PopulatePlayerLabels(playerRealm, scroll)
	end)

	self:PopulatePlayerLabels(playerRealm, scroll)
	self.mainFrameShown = true
end

-- Define a function to create a spacer
function Drak:CreateSpacer(parent)
	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)
	parent:AddChild(spacer)
	return spacer
end

-- Function to show the confirmation dialog
function Drak:ShowConfirmationDialog(serverName, onConfirm)
	local confirmFrame = AceGUI:Create("Frame")
	confirmFrame:SetTitle("Confirm Deletion")
	confirmFrame:SetStatusText("Are you sure you want to delete " .. serverName .. "?")
	confirmFrame:SetLayout("Flow")
	confirmFrame:SetWidth(400)
	confirmFrame:SetHeight(200)

	local label = AceGUI:Create("Label")
	label:SetText("Are you sure you want to delete " .. serverName .. "?")
	label:SetFullWidth(true)
	confirmFrame:AddChild(label)

	local yesButton = AceGUI:Create("Button")
	yesButton:SetText("Yes")
	yesButton:SetWidth(100)
	yesButton:SetCallback("OnClick", function()
		onConfirm()
		AceGUI:Release(confirmFrame)
	end)
	confirmFrame:AddChild(yesButton)

	local noButton = AceGUI:Create("Button")
	noButton:SetText("No")
	noButton:SetWidth(100)
	noButton:SetCallback("OnClick", function()
		AceGUI:Release(confirmFrame)
	end)
	confirmFrame:AddChild(noButton)
end

function Drak:CreatePlayerLabel(parent, charTable, index)
	local charInfoLabel = AceGUI:Create("Label")
	local playerInfo = AceGUI:Create("Label")
	local raidLabel = AceGUI:Create("Label")
	local dungeonLabel = AceGUI:Create("Label")
	local pvpLabel = AceGUI:Create("Label")

	-- Set the font template to use for the label
	charInfoLabel:SetFontObject(GameFontHighlightLarge) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
	playerInfo:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
	raidLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
	dungeonLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
	pvpLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.

	local keyName = charTable.keystoneName or "None"
	local keyLevel = charTable.keystoneLevel or "0"

	keyLevel = "+" .. keyLevel

	local classIcon, classColorObj = unpack(classIconsAndColors[charTable.class])

	-- Raid Stuff
	local t1Verify = icons.pvp_red
	local t2Verify = icons.pvp_red
	local t3Verify = icons.pvp_red
	local greenColor = CreateColorFromHexString("FF00FF00")
	local greyColor = CreateColorFromHexString("FF808080")
	local whiteColor = CreateColorFromHexString("FFFFFFFF")

	local raid_t1_track = charTable.raid.t1.level
	if raid_t1_track == 0 then
		raid_t1_track = "None"
	end
	local raid_t2_track = charTable.raid.t2.level
	if raid_t2_track == 0 then
		raid_t2_track = "None"
	end
	local raid_t3_track = charTable.raid.t3.level
	if raid_t3_track == 0 then
		raid_t3_track = "None"
	end

	local raid_t1_progress = charTable.raid.t1.progress or 0
	local raid_t2_progress = charTable.raid.t2.progress or 0
	local raid_t3_progress = charTable.raid.t3.progress or 0

	local raid_t1_threshold = charTable.raid.t1.threshold or 0
	local raid_t2_threshold = charTable.raid.t2.threshold or 0
	local raid_t3_threshold = charTable.raid.t3.threshold or 0

	local charProgress = 0
	if raid_t3_progress >= raid_t3_threshold then
		charProgress = 3
	elseif raid_t2_progress >= raid_t2_threshold then
		charProgress = 2
	elseif raid_t1_progress >= raid_t1_threshold then
		charProgress = 1
	end

	local t1ColorObj
	local t2ColorObj
	local t3ColorObj

	if charProgress == 3 then
		t1Verify = "|T" .. icons.raid_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.raid_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.raid_green .. ":16|t"
		t3ColorObj = greenColor
	elseif charProgress == 2 then
		t1Verify = "|T" .. icons.raid_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.raid_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.raid_red .. ":16|t"
		t3ColorObj = whiteColor
	elseif charProgress == 1 then
		t1Verify = "|T" .. icons.raid_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.raid_red .. ":16|t"
		t2ColorObj = whiteColor
		t3Verify = "|T" .. icons.raid_red .. ":16|t"
		t3ColorObj = greyColor
	elseif charProgress == 0.5 then
		t1Verify = "|T" .. icons.raid_red .. ":16|t"
		t1ColorObj = whiteColor
		t2Verify = "|T" .. icons.raid_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.raid_red .. ":16|t"
		t3ColorObj = greyColor
	else
		t1Verify = "|T" .. icons.raid_red .. ":16|t"
		t1ColorObj = greyColor
		t2Verify = "|T" .. icons.raid_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.raid_red .. ":16|t"
		t3ColorObj = greyColor
	end

	local raidString = " Raids:            " .. t1Verify .. t1ColorObj:WrapTextInColorCode("  [" .. raid_t1_track .. " - " .. raid_t1_progress .. "/" .. raid_t1_threshold .. "]     ") ..
			t2Verify .. t2ColorObj:WrapTextInColorCode("  [" .. raid_t2_track .. " - " .. raid_t2_progress .. "/" .. raid_t2_threshold .. "]     ") ..
			t3Verify .. t3ColorObj:WrapTextInColorCode("  [" .. raid_t3_track .. " - " .. raid_t3_progress .. "/" .. raid_t3_threshold .. "]")

	-- M+ Stuff
	local mythic_t1_track = charTable.mythic.t1.level or "None"
	local mythic_t2_track = charTable.mythic.t2.level or "None"
	local mythic_t3_track = charTable.mythic.t3.level or "None"
	local mythic_t1_itemType = charTable.mythic.t1.itemType or "None"
	local mythic_t2_itemType = charTable.mythic.t2.itemType or "None"
	local mythic_t3_itemType = charTable.mythic.t3.itemType or "None"
	local mythic_t1_progress = charTable.mythic.t1.progress or 0
	local mythic_t2_progress = charTable.mythic.t2.progress or 0
	local mythic_t3_progress = charTable.mythic.t3.progress or 0
	local mythic_t1_threshold = charTable.mythic.t1.threshold or 0
	local mythic_t2_threshold = charTable.mythic.t2.threshold or 0
	local mythic_t3_threshold = charTable.mythic.t3.threshold or 0

	charProgress = 0
	if mythic_t3_progress >= mythic_t3_threshold then
		charProgress = 3
	elseif mythic_t2_progress >= mythic_t2_threshold then
		charProgress = 2
	elseif mythic_t1_progress >= mythic_t1_threshold then
		charProgress = 1
	end

	if charProgress == 3 then
		t1Verify = "|T" .. icons.mythic_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.mythic_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.mythic_green .. ":16|t"
		t3ColorObj = greenColor
	elseif charProgress == 2 then
		t1Verify = "|T" .. icons.mythic_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.mythic_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.mythic_red .. ":16|t"
		t3ColorObj = whiteColor
	elseif charProgress == 1 then
		t1Verify = "|T" .. icons.mythic_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.mythic_red .. ":16|t"
		t2ColorObj = whiteColor
		t3Verify = "|T" .. icons.mythic_red .. ":16|t"
		t3ColorObj = greyColor
	elseif charProgress == 0.5 then
		t1Verify = "|T" .. icons.mythic_red .. ":16|t"
		t1ColorObj = whiteColor
		t2Verify = "|T" .. icons.mythic_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.mythic_red .. ":16|t"
		t3ColorObj = greyColor
	else
		t1Verify = "|T" .. icons.mythic_red .. ":16|t"
		t1ColorObj = greyColor
		t2Verify = "|T" .. icons.mythic_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.mythic_red .. ":16|t"
		t3ColorObj = greyColor
	end

	local dungeonString = " Dungeons:   " .. t1Verify .. t1ColorObj:WrapTextInColorCode("  [" .. mythic_t1_itemType .. " - Key +" .. mythic_t1_track .. " - " .. mythic_t1_progress .. "/" .. mythic_t1_threshold .. "]     ") ..
			t2Verify .. t2ColorObj:WrapTextInColorCode("  [" .. mythic_t2_itemType .. " - Key +" .. mythic_t2_track .. " - " .. mythic_t2_progress .. "/" .. mythic_t2_threshold .. "]     ") ..
			t3Verify .. t3ColorObj:WrapTextInColorCode("  [" .. mythic_t3_itemType .. " - Key +" .. mythic_t3_track .. " - " .. mythic_t3_progress .. "/" .. mythic_t3_threshold .. "]")

	-- PvP Stuff
	local pvp_t1_progress = charTable.pvp.t1.progress or 0
	local pvp_t2_progress = charTable.pvp.t2.progress or 0
	local pvp_t3_progress = charTable.pvp.t3.progress or 0
	local pvp_t1_threshold = charTable.pvp.t1.threshold or 0
	local pvp_t2_threshold = charTable.pvp.t2.threshold or 0
	local pvp_t3_threshold = charTable.pvp.t3.threshold or 0

	charProgress = 0
	if pvp_t3_progress >= pvp_t3_threshold then
		charProgress = 3
	elseif pvp_t2_progress >= pvp_t2_threshold then
		charProgress = 2
	elseif pvp_t1_progress >= pvp_t1_threshold then
		charProgress = 1
	elseif pvp_t1_progress > 0 then
		charProgress = 0.5
	end

	if charProgress == 3 then
		t1Verify = "|T" .. icons.pvp_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.pvp_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.pvp_green .. ":16|t"
		t3ColorObj = greenColor
	elseif charProgress == 2 then
		t1Verify = "|T" .. icons.pvp_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.pvp_green .. ":16|t"
		t2ColorObj = greenColor
		t3Verify = "|T" .. icons.pvp_red .. ":16|t"
		t3ColorObj = whiteColor
	elseif charProgress == 1 then
		t1Verify = "|T" .. icons.pvp_green .. ":16|t"
		t1ColorObj = greenColor
		t2Verify = "|T" .. icons.pvp_red .. ":16|t"
		t2ColorObj = whiteColor
		t3Verify = "|T" .. icons.pvp_red .. ":16|t"
		t3ColorObj = greyColor
	elseif charProgress == 0.5 then
		t1Verify = "|T" .. icons.pvp_red .. ":16|t"
		t1ColorObj = whiteColor
		t2Verify = "|T" .. icons.pvp_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.pvp_red .. ":16|t"
		t3ColorObj = greyColor
	else
		t1Verify = "|T" .. icons.pvp_red .. ":16|t"
		t1ColorObj = greyColor
		t2Verify = "|T" .. icons.pvp_red .. ":16|t"
		t2ColorObj = greyColor
		t3Verify = "|T" .. icons.pvp_red .. ":16|t"
		t3ColorObj = greyColor
	end

	local pvpString = " PvP:               " .. t1Verify .. t1ColorObj:WrapTextInColorCode("  [" .. pvp_t1_progress .. "/" .. pvp_t1_threshold .. "]     ") ..
			t2Verify .. t2ColorObj:WrapTextInColorCode("  [" .. pvp_t2_progress .. "/" .. pvp_t2_threshold .. "]     ") ..
			t3Verify .. t3ColorObj:WrapTextInColorCode("  [" .. pvp_t3_progress .. "/" .. pvp_t3_threshold .. "]")

	local vaultClaim = charTable.claim
	local verifyVaultClaim = ""
	if vaultClaim == true then
		verifyVaultClaim = "Yes"
	else
		verifyVaultClaim = "No"
	end

	if keyName == "None" then
		charInfoLabel:SetText(classColorObj:WrapTextInColorCode(
				string.rep("-", 100) .. "\n" ..
						"[" .. index .. ".] - " .. charTable.name .. " --- " .. charTable.class .. " " ..
						"|T" .. classIcon .. ":16|t" .. " --- Keystone:  " .. keyName .. "\n" ..
						string.rep("-", 100))
		)
	else
		charInfoLabel:SetText(classColorObj:WrapTextInColorCode(
				string.rep("-", 100) .. "\n" ..
						"[" .. index .. ".] - " .. charTable.name .. " --- " .. charTable.class .. " " ..
						"|T" .. classIcon .. ":16|t" .. " --- Keystone:  " .. keyName .. " " .. keyLevel .. "\n" ..
						"|T" .. icons.dungeon .. "16|t" .. string.rep("-", 100))
		)

	end

	local playerInfoString = "Last logged in: " .. charTable.lastLoginFormatted
	raidLabel:SetText(" >>  " .. "|T" .. icons.raid .. ":16|t" .. raidString)
	dungeonLabel:SetText(" >>  " .. "|T" .. icons.dungeon .. ":16|t" .. dungeonString)
	pvpLabel:SetText(" >>  " .. "|T" .. icons.pvp .. ":16|t" .. pvpString)
	playerInfo:SetText(playerInfoString)

	charInfoLabel:SetFullWidth(true) -- Set label to full width
	raidLabel:SetFullWidth(true) -- Set label to full width
	dungeonLabel:SetFullWidth(true) -- Set label to full width
	pvpLabel:SetFullWidth(true) -- Set label to full width
	playerInfo:SetFullWidth(true) -- Set label to full width

	-- Add label to the main frame

	self:CreateSpacer(parent)
	parent:AddChild(charInfoLabel)
	parent:AddChild(raidLabel)
	parent:AddChild(dungeonLabel)
	parent:AddChild(pvpLabel)
	parent:AddChild(playerInfo)
	self:CreateSpacer(parent)
end

function Drak:PopulatePlayerLabels(playerRealm, scrollFrame)
	local count = 1

	--local sortedTable = Drak:SortPlayerList(playerName, playerRealm)
	for k, v in pairs(self.db.sv.char) do
		if v.realm == playerRealm and v.playerLevel and v.playerLevel == GetMaxLevelForLatestExpansion() then
			self:CreatePlayerLabel(scrollFrame, v, count)
			count = count + 1
		end
	end
end

--[[function Drak:SortPlayerList(playerName, playerRealm)
	-- Sort based on the last login time
	local function sortEpochs(character1, character2)
		return self.db.sv.char[character1.." - "..playerRealm].lastLoginEpoch > self.db.sv.char[character2.." - "..playerRealm].lastLoginEpoch
	end

	-- Extract player names into an array for sorting
	local playerNamesTable = {}
	for charName in pairs(self:GetPlayerNamesMatchingRealm(playerRealm)) do
		if charName ~= playerName then
			table.insert(playerNamesTable, charName)
		end
	end

	-- Sort the player names array using the custom sort function
	table.sort(playerNamesTable, sortEpochs)
	return playerNamesTable
end]]