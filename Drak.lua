Drak = LibStub("AceAddon-3.0"):NewAddon("Drak", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local mainFrame = nil
local mainFrameShown = false

local raidIcon = "|TInterface\\ICONS\\spell_warlock_demonicportal_green:16|t"
local dungeonIcon = "|TInterface\\ICONS\\INV_relics_hourglass:16|t"
local pvpIcon = "|TInterface\\ICONS\\achievement_legionpvptier4:16|t"
local pvpGreenIcon = "|TInterface\\ICONS\\Achievement_pvp_g_01:16|t"
local pvpRedIcon = "|TInterface\\ICONS\\achievement_pvp_h_01:16|t"
local mythicGreenIcon = "|TInterface\\ICONS\\priest_icon_chakra_green:16|t"
local mythicRedIcon = "|TInterface\\ICONS\\priest_icon_chakra_red:16|t"
local raidGreenIcon = "|TInterface\\ICONS\\Inv_misc_head_dragon_green:16|t"
local raidRedIcon = "|TInterface\\ICONS\\Inv_misc_head_dragon_red:16|t"

local vaults = {
	claim = false,
	mythic = {
		t1 = {level="None",itemType="None",progress=0,threshold=0},
		t2 = {level="None",itemType="None",progress=0,threshold=0},
		t3 = {level="None",itemType="None",progress=0,threshold=0},
	},
	pvp = {
		t1 = {level="None",itemType="None",progress=0,threshold=0},
		t2 = {level="None",itemType="None",progress=0,threshold=0},
		t3 = {level="None",itemType="None",progress=0,threshold=0},
	},
	raid = {
		t1 = {level="None",itemType="None",progress=0,threshold=0},
		t2 = {level="None",itemType="None",progress=0,threshold=0},
		t3 = {level="None",itemType="None",progress=0,threshold=0},
	},
}

local options = {
	name = "Drak",
	handler = DrakHandle,
	type = "group",
	args = {
		msg = {
			type = "input",
			name = "Message",
			desc = "The message to be displayed when you get home.",
			usage = "<Your message>",
			get = "GetMessage",
			set = "SetMessage",
		},
		showOnScreen = {
			type = "toggle",
			name = "Show on Screen",
			desc = "Toggles the display of the message on the screen.",
			get = "IsShowOnScreen",
			set = "ToggleShowOnScreen"
		},
	},
}

-------------------------------------------------------------------------
------------------------- Lifecycle Functions ---------------------------
-------------------------------------------------------------------------

--- Called directly after the addon is fully loaded.
function Drak:OnInitialize()
	-- This is where the SavedVariables go?
	self.db = LibStub("AceDB-3.0"):New("DrakDB", defaults, true)
	AC:RegisterOptionsTable("Drak_options", options)
	self.optionsFrame = ACD:AddToBlizOptions("Drak_options", "Drak")
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("Drak_Profiles", profiles)
	ACD:AddToBlizOptions("Drak_Profiles", "Profiles", "Drak")
	self:RegisterChatCommand("drak", "SlashCommand")
end

--- Called during the PLAYER_LOGIN event when most of the data provided by the game is already present.
--- We perform more startup tasks here, such as registering events, hooking functions, creating frames, or getting 
--- information from the game that wasn't yet available during :OnInitialize()
function Drak:OnEnable()
	print("Drak addon loaded")
	-- Ensure server table exists
	if not DrakDB["server"] then
		DrakDB["server"] = GetRealmName()
	end
end

--- Called when our addon is manually being disabled during a running session.
--- We primarily use this to unhook scripts, unregister events, or hide frames that we created.
function Drak:OnDisable()
	-- Get current time for player's last Login Time
	local playerRealm = GetRealmName()
	local playerName = UnitName("player")
	DrakDB["characters"][playerRealm][playerName]["lastLogin"], DrakDB["characters"][playerRealm][playerName]["lastLoginEpoch"]= Drak:ShowTime()
end

-------------------------------------------------------------------------
------------------------- New Functions Go Here -------------------------
-------------------------------------------------------------------------
function Drak:GetMythicKeystoneInfo()
	local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local level = C_MythicPlus.GetOwnedKeystoneLevel()

	if mapID and level then
		local keystoneName = C_ChallengeMode.GetMapUIInfo(mapID)
		return keystoneName, level
	else
		return nil, nil  -- No active keystone found
	end
end

function Drak:PopulateThreshold()
	local vaultThresholdCheck = C_WeeklyRewards.GetActivities()
	for i, activityInfo in ipairs(vaultThresholdCheck) do
		local _gActivityID = activityInfo.id
		local _gThreshold = activityInfo.threshold
		if _gActivityID == 145 then
			vaults.mythic.t1.threshold = _gThreshold
		elseif _gActivityID == 146 then
			vaults.mythic.t2.threshold = _gThreshold
		elseif _gActivityID == 147 then
			vaults.mythic.t3.threshold = _gThreshold
		elseif _gActivityID == 148 then
			vaults.pvp.t1.threshold = _gThreshold
		elseif _gActivityID == 149 then
			vaults.pvp.t2.threshold = _gThreshold
		elseif _gActivityID == 150 then
			vaults.pvp.t3.threshold = _gThreshold
		elseif _gActivityID == 151 then
			vaults.raid.t1.threshold = _gThreshold
		elseif _gActivityID == 152 then
			vaults.raid.t2.threshold = _gThreshold
		elseif _gActivityID == 153 then
			vaults.raid.t3.threshold = _gThreshold
		end
	end
end

-- Function to check if the name exists
function Drak:nameExist(name,nameList)
	for _, n in ipairs(nameList) do
		if n == name then
			return true
		end
	end
	return false
end

-- Function to retrieve the string for class icons to be displayed in the Label
function Drak:GetClassIcon(class)
	if class == "Death Knight" then
		return "|TInterface\\ICONS\\Classicon_deathknight:16|t", "|cFFC41E3A"
	elseif class == "Warlock" then
		return "|TInterface\\ICONS\\Classicon_warlock:16|t","|cFF8788EE"
	elseif class == "Druid" then
		return "|TInterface\\ICONS\\Classicon_druid:16|t","|cFFFF7C0A"
	elseif class == "Paladin" then
		return "|TInterface\\ICONS\\Classicon_paladin:16|t","|cFFF48CBA"
	elseif class == "Priest" then
		return "|TInterface\\ICONS\\Classicon_priest:16|t","|cFFFFFFFF"
	elseif class == "Evoker" then
		return "|TInterface\\ICONS\\Classicon_evoker:16|t",	"|cFF33937F"
	elseif class == "Demon Hunter" then
		return "|TInterface\\ICONS\\Classicon_demonhunter:16|t", "|cFFA330C9"
	elseif class == "Mage" then
		return "|TInterface\\ICONS\\Classicon_mage:16|t", "|cFF3FC7EB"
	elseif class == "Rogue" then
		return "|TInterface\\ICONS\\Classicon_rogue:16|t", "|cFFFFF468"
	elseif class == "Warrior" then
		return "|TInterface\\ICONS\\Classicon_warrior:16|t", "|cFFC69B6D"
	elseif class == "Hunter" then
		return "|TInterface\\ICONS\\Classicon_hunter:16|t", "|cFFAAD372"
	elseif class == "Monk" then
		return "|TInterface\\ICONS\\Classicon_monk:16|t", "|cFF00FF98"
	elseif class == "Shaman" then
		return "|TInterface\\ICONS\\Classicon_shaman:16|t", "|cFF0070DD"
	end
	return ""
end

-- Function to retrieve Mythic Plus activities and their rewards
function Drak:GetMythicPlusRewards()
	local Link, UpgradeLink, ILvl;
	local activities = C_WeeklyRewards.GetActivities();  -- Retrieve all weekly activities
	if activities then
		for idx = 1,#activities do
			Link, UpgradeLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activities[idx].id);
			if Link then
				ILvl = GetDetailedItemLevelInfo(Link);
				if ILvl then
					print("ilvl:",ILvl,"Link:",Link)
				end
			end

		end
	end
end

-- Returns the item gear track (Myth/Hero/Champion/Veteran/etc)
function Drak:VaultItemTrackType(type,level)
	-- not listed below but type 2 is pvp
	if type == 1 then -- type 1 is Mythic dungeons
		if level >= 8 then -- 8 keys and above give myth gear
			return "|cffff8000Myth Item|r", _
		elseif level >= 0 then -- 0 to 7 key levels give hero gear
			return "|cffa335eeHero Item|r", _
		else
			return "None", _
		end
	elseif type == 3 then -- type 3 is Raid
		if level == 16 then -- 14 corresponds to Mythic Raid
			return "Myth", "|cffff8000Mythic Raid|r"
		elseif level == 15 then -- 14 corresponds to Heroic Raid
			return "Hero", "|cffa335eeHeroic Raid|r"
		elseif level == 14 then -- 14 corresponds to Normal Raid
			return "Champion", "|cff0070ddNormal Raid|r"
		elseif level == 17 then -- 17 corresponds to LFR
			return "Veteran", "|cff1eff00Raid Finder|r"
		else
			return "None","None"
		end
	else
		return "None"
	end
end

function Drak:GetVaultData()

	Drak:PopulateThreshold()

	local playerName = UnitName("player")
	local playerRealm = GetRealmName()
	local playerClass = UnitClass("player")

	-- Accessing the values within the Great Vault frame
	local activities = C_WeeklyRewards.GetActivities()
	vaults.claim = C_WeeklyRewards.HasAvailableRewards()

	for i, activityInfo in ipairs(activities) do
		local activityID = activityInfo.id
		local v_level = activityInfo.level -- displays the highest key level completed
		local type = activityInfo.type
		local progress = activityInfo.progress -- shows amount of keys completed, conquest progress, and # of raid bosses killed
		local vaultItemType, instanceType = self:VaultItemTrackType(type,v_level)

		--print("activityID:",activityID,"v_level:",v_level)
		if activityID == 145 then
			vaults.mythic.t1.level = v_level
			vaults.mythic.t1.progress = progress
			if progress >= vaults.mythic.t1.threshold then
				vaults.mythic.t1.progress = vaults.mythic.t1.threshold
				vaults.mythic.t1.itemType = vaultItemType
			end
		elseif activityID == 146 then
			vaults.mythic.t2.level = v_level
			vaults.mythic.t2.progress = progress
			if progress >= vaults.mythic.t2.threshold then
				vaults.mythic.t2.progress = vaults.mythic.t2.threshold
				vaults.mythic.t2.itemType = vaultItemType
			end
		elseif activityID == 147 then
			vaults.mythic.t3.level = v_level
			vaults.mythic.t3.progress = progress
			if progress >= vaults.mythic.t3.threshold then
				vaults.mythic.t3.progress = vaults.mythic.t3.threshold
				vaults.mythic.t3.itemType = vaultItemType
			end
		elseif activityID == 148 then
			vaults.pvp.t1.level = v_level
			vaults.pvp.t1.progress = progress
			if progress >= vaults.pvp.t1.threshold then
				vaults.pvp.t1.progress = vaults.pvp.t1.threshold
				vaults.pvp.t1.itemType = "Champion"
			end
		elseif activityID == 149 then
			vaults.pvp.t2.level = v_level
			vaults.pvp.t2.progress = progress
			if progress >= vaults.pvp.t2.threshold then
				vaults.pvp.t2.progress = vaults.pvp.t2.threshold
				vaults.pvp.t2.itemType = "Champion"
			end
		elseif activityID == 150 then
			vaults.pvp.t3.level = v_level
			vaults.pvp.t3.progress = progress
			if progress >= vaults.pvp.t3.threshold then
				vaults.pvp.t3.progress = vaults.pvp.t3.threshold
				vaults.pvp.t3.itemType = "Champion"
			end
		elseif activityID == 151 then
			vaults.raid.t1.level = v_level
			vaults.raid.t1.progress = progress
			if progress >= vaults.raid.t1.threshold then
				vaults.raid.t1.progress = vaults.raid.t1.threshold
				vaults.raid.t1.level = instanceType
				vaults.raid.t1.itemType = vaultItemType
			end
		elseif activityID == 152 then
			vaults.raid.t2.level = v_level
			vaults.raid.t2.progress = progress
			if progress >= vaults.raid.t2.threshold  then
				vaults.raid.t2.progress = vaults.raid.t2.threshold
				vaults.raid.t2.level = instanceType
				vaults.raid.t2.itemType = vaultItemType
			end
		elseif activityID == 153 then
			vaults.raid.t3.level = v_level
			vaults.raid.t3.progress = progress
			if progress >= vaults.raid.t3.threshold  then
				vaults.raid.t3.progress = vaults.raid.t3.threshold
				vaults.raid.t3.level = instanceType
				vaults.raid.t3.itemType = vaultItemType
			end
		end
	end

	-- Ensure characters table exists
	if not DrakDB["characters"] then
		DrakDB["characters"] = {}
	end

	-- check if player is expansion's current max level before adding to tables
	local playerLevel = UnitLevel("player")
	local maxExpansionLevel = GetMaxLevelForExpansionLevel(GetExpansionLevel()) -- This will return the max level for the current expansion

	if playerLevel == maxExpansionLevel then

		Drak:UpdateTables(playerRealm,playerName)

		-- Add player class and vault to the specific player
		DrakDB["characters"][playerRealm][playerName]["vaults"] = vaults
		DrakDB["characters"][playerRealm][playerName]["class"] = playerClass

		local keystoneName, keystoneLevel = Drak:GetMythicKeystoneInfo()
		if keystoneName and keystoneLevel then
			DrakDB["characters"][playerRealm][playerName]["key"]["name"] = keystoneName
			DrakDB["characters"][playerRealm][playerName]["key"]["level"] = keystoneLevel
		else
			DrakDB["characters"][playerRealm][playerName]["key"]["name"] = "None"
			DrakDB["characters"][playerRealm][playerName]["key"]["level"] = ""
		end
	end
end

-- Function to ensure that the player data table is not missing any of the keys after updating the code
-- This helps resolve if the player has not logged in a character after the addon has updated and added a key that was not in prior versions of the code
function Drak:UpdateTables(playerRealm,playerName)
	-- Ensure playerRealm table exists
	if not DrakDB["characters"][playerRealm] then
		DrakDB["characters"][playerRealm] = {}
	end

	-- Ensure playerName table exists
	if not DrakDB["characters"][playerRealm][playerName] then
		DrakDB["characters"][playerRealm][playerName] = {}
	end

	if not DrakDB["characters"][playerRealm][playerName]["lastLogin"] then
		DrakDB["characters"][playerRealm][playerName]["lastLogin"] = "Need to logout/reload to update"
	end

	if not DrakDB["characters"][playerRealm][playerName]["lastLoginEpoch"] then
		DrakDB["characters"][playerRealm][playerName]["lastLoginEpoch"] = 0
	end

	-- Ensure player keystone table exists
	if not DrakDB["characters"][playerRealm][playerName]["key"] then
		DrakDB["characters"][playerRealm][playerName]["key"] = {}
		DrakDB["characters"][playerRealm][playerName]["key"]["name"] = "None"
		DrakDB["characters"][playerRealm][playerName]["key"]["level"] = ""
	end

	-- Ensure player class table exists
	if not DrakDB["characters"][playerRealm][playerName]["class"] then
		DrakDB["characters"][playerRealm][playerName]["class"] = {}
	end
end

function Drak:SlashCommand(msg)
	if not msg or msg:trim() == "" then
		if mainFrameShown == true then
			mainFrame:Hide()
			mainFrameShown = false
		else
			Drak.ShowFrame()
		end
	elseif msg == "vault" then
		print("AreRewardsCurrWeek",C_WeeklyRewards.AreRewardsForCurrentRewardPeriod())


	else
		-- Load the Blizzard_WeeklyRewards addon
		LoadAddOn("Blizzard_WeeklyRewards")
	
		-- Show the Great Vault frame
		--WeeklyRewardsFrame:Show()

		Drak:CheckVaults()
		--Drak:GetMythicPlusRewards()
	end
end

-- This table is used to populate the dropdown list in the GUI
function Drak:GetServerNames()
	local serverTable = {}
	for server, _ in pairs(DrakDB.characters) do
		-- Check if the server name doesn't already exist in serverTable
		if not serverTable[server] then
			-- If not, add it as a key to serverTable
			serverTable[server] = true -- or any other value you want to associate with the server name
		end
	end
	return serverTable
end

-- Primary Addon Frame - mainFrame and displays the addon data
function Drak:ShowFrame()
	local function CloseFrame()
		mainFrameShown = false
		mainFrame:Hide()
	end

	mainFrame = AceGUI:Create("Frame")
	mainFrame:SetTitle("Great Vault Checks")
	mainFrame:SetStatusText("Author: Drakwlya - Addon used to check Great Vaults across alts")
	mainFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) CloseFrame() end)
	mainFrame:SetLayout("Flow")
	mainFrame:SetWidth(800)  -- Set the width
	mainFrame:SetHeight(600) -- Set the height
	--mainFrame:SetMinResize(600,600)
	-- Get the underlying Blizzard frame
	local blizzFrame = mainFrame.frame

	-- Set the minimum and maximum dimensions
	local minWidth = 800

	-- Hook the OnUpdate script to enforce size constraints
	blizzFrame:SetScript("OnUpdate", function(self)
		local width = self:GetSize()

		-- Enforce minimum width and height
		if width < minWidth then
			self:SetWidth(minWidth)

		end

	end)

	-- Add a close button to the top right corner of the frame
	local closeButton = CreateFrame("Button", nil, mainFrame.frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", mainFrame.frame, "TOPRIGHT")
	closeButton:SetScript("OnClick", CloseFrame)

	local button = AceGUI:Create("Button")
	button:SetText("Check Vault")
	button:SetWidth(200)
	button:SetCallback("OnClick", function()
		LoadAddOn("Blizzard_WeeklyRewards")
		WeeklyRewardsFrame:Show()
	end)
	mainFrame:AddChild(button)
	button:SetPoint("CENTER")
	mainFrame:Show()

	local serverLabel = AceGUI:Create("Label")
	serverLabel:SetText("Server: ")
	serverLabel:SetFullWidth(true)
	serverLabel:SetFontObject(GameFontNormal)
	mainFrame:AddChild(serverLabel)

	-- Create a horizontal container for the dropdown and delete button
	local horizontalContainer = AceGUI:Create("SimpleGroup")
	horizontalContainer:SetFullWidth(true)
	horizontalContainer:SetLayout("Flow")
	mainFrame:AddChild(horizontalContainer)

	-- Create and add the dropdown to the horizontal container
	local dropdown = AceGUI:Create("Dropdown")
	dropdown:SetWidth(200)

	local serverTable = Drak:GetServerNames()
	local dropdownList = {}
	for serverName, _ in pairs(serverTable) do
		dropdownList[serverName] = serverName
	end

	dropdownList["None"] = "None"
	local playerRealm = DrakDB["server"]
	dropdown:SetList(dropdownList)
	dropdown:SetValue(playerRealm)

	horizontalContainer:AddChild(dropdown)

	-- Function to show the confirmation dialog
	local function ShowConfirmationDialog(serverName, onConfirm)
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

	-- Create and add the delete button to the horizontal container
	local deleteButton = AceGUI:Create("Button")
	deleteButton:SetText("Delete")
	deleteButton:SetWidth(100)
	deleteButton:SetCallback("OnClick", function()
		-- Add the logic to delete the selected server here
		local serverName = dropdown:GetValue()
		if serverName and serverName ~= "None" then
			ShowConfirmationDialog(serverName, function()
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
	horizontalContainer:AddChild(deleteButton)

	-- Create a container for the ScrollFrame
	local scrollcontainer = AceGUI:Create("SimpleGroup")
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetFullHeight(true)
	scrollcontainer:SetLayout("Fill")
	mainFrame:AddChild(scrollcontainer)

	-- Create the ScrollFrame itself
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	scrollcontainer:AddChild(scroll)

	-- Define a function to create a spacer
	local function CreateSpacer(parent)
		local spacer = AceGUI:Create("Label")
		spacer:SetText(" ")
		spacer:SetFullWidth(true)
		parent:AddChild(spacer)
		return spacer
	end


	Drak:GetVaultData()

	local function CreatePlayerLabel(parent,playerRealm,charName,index)
		local charInfoLabel = AceGUI:Create("Label")
		local playerInfo = AceGUI:Create("Label")
		local raidLabel = AceGUI:Create("Label")
		local dungeonLabel = AceGUI:Create("Label")
		local pvpLabel = AceGUI:Create("Label")

		Drak:UpdateTables(playerRealm,charName)

		-- Set the font template to use for the label
		charInfoLabel:SetFontObject(GameFontHighlightLarge) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
		playerInfo:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
		raidLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
		dungeonLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.
		pvpLabel:SetFontObject(GameFontNormal) -- Adjust the font template as needed, e.g., GameFontNormalLarge, GameFontNormalHuge, etc.

		local keyName = "None"
		local keyLevel = ""

		keyName = DrakDB["characters"][playerRealm][charName]["key"]["name"]
		keyLevel = "+"..DrakDB["characters"][playerRealm][charName]["key"]["level"]

		local classIcon, classColor = Drak:GetClassIcon(DrakDB["characters"][playerRealm][charName]["class"])

		-- Raid Stuff
		local t1Verify = pvpRedIcon
		local t2Verify = pvpRedIcon
		local t3Verify = pvpRedIcon
		local greenColor = "|cFF00FF00"
		local greyColor = "|cFF808080"
		local whiteColor = "|cFFFFFFFF"

		local raid_t1_track = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t1.level
		if raid_t1_track == 0 then
			raid_t1_track = "None"
		end
		local raid_t2_track = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t2.level
		if raid_t2_track == 0 then
			raid_t2_track = "None"
		end
		local raid_t3_track = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t3.level
		if raid_t3_track == 0 then
			raid_t3_track = "None"
		end

		local raid_t1_progress = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t1.progress
		local raid_t2_progress = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t2.progress
		local raid_t3_progress = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t3.progress

		local raid_t1_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t1.threshold
		local raid_t2_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t2.threshold
		local raid_t3_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].raid.t3.threshold

		local charProgress = 0
		if raid_t3_progress >= raid_t3_threshold then
			charProgress = 3
		elseif raid_t2_progress >= raid_t2_threshold then
			charProgress = 2
		elseif raid_t1_progress >= raid_t1_threshold then
			charProgress = 1
		end

		if charProgress == 3 then
			t1Verify = raidGreenIcon..greenColor
			t2Verify = raidGreenIcon..greenColor
			t3Verify = raidGreenIcon..greenColor
		elseif charProgress == 2 then
			t1Verify = raidGreenIcon..greenColor
			t2Verify = raidGreenIcon..greenColor
			t3Verify = raidRedIcon..whiteColor
		elseif charProgress == 1 then
			t1Verify = raidGreenIcon..greenColor
			t2Verify = raidRedIcon..whiteColor
			t3Verify = raidRedIcon..greyColor
		else
			t1Verify = raidRedIcon..greyColor
			t2Verify = raidRedIcon..greyColor
			t3Verify = raidRedIcon..greyColor
		end

		local raidString = " Raids:            "..t1Verify.."  ["..raid_t1_track.." - "..raid_t1_progress.."/"..raid_t1_threshold.."]     "..t2Verify.."  ["..raid_t2_track.." - "..raid_t2_progress.."/"..raid_t2_threshold.."]     "..t3Verify.."  ["..raid_t3_track.." - "..raid_t3_progress.."/"..raid_t3_threshold.."]"

		-- M+ Stuff
		local mythic_t1_track = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t1.level
		local mythic_t2_track = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t2.level
		local mythic_t3_track = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t3.level
		local mythic_t1_itemType = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t1.itemType
		local mythic_t2_itemType = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t2.itemType
		local mythic_t3_itemType = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t3.itemType
		local mythic_t1_progress = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t1.progress
		local mythic_t2_progress = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t2.progress
		local mythic_t3_progress = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t3.progress
		local mythic_t1_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t1.threshold
		local mythic_t2_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t2.threshold
		local mythic_t3_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].mythic.t3.threshold

		charProgress = 0
		if mythic_t3_progress >= mythic_t3_threshold then
			charProgress = 3
		elseif mythic_t2_progress >= mythic_t2_threshold then
			charProgress = 2
		elseif mythic_t1_progress >= mythic_t1_threshold then
			charProgress = 1
		end

		if charProgress == 3 then
			t1Verify = mythicGreenIcon..greenColor
			t2Verify = mythicGreenIcon..greenColor
			t3Verify = mythicGreenIcon..greenColor
		elseif charProgress == 2 then
			t1Verify = mythicGreenIcon..greenColor
			t2Verify = mythicGreenIcon..greenColor
			t3Verify = mythicRedIcon..whiteColor
		elseif charProgress == 1 then
			t1Verify = mythicGreenIcon..greenColor
			t2Verify = mythicRedIcon..whiteColor
			t3Verify = mythicRedIcon..greyColor
		else
			t1Verify = mythicRedIcon..greyColor
			t2Verify = mythicRedIcon..greyColor
			t3Verify = mythicRedIcon..greyColor
		end

		local dungeonString = " Dungeons:   "..t1Verify.."  ["..mythic_t1_itemType.." - Key +"..mythic_t1_track.." - "..mythic_t1_progress.."/"..mythic_t1_threshold.."]     "..t2Verify.."  ["..mythic_t2_itemType.." - Key +"..mythic_t2_track.." - "..mythic_t2_progress.."/"..mythic_t2_threshold.."]     "..t3Verify.."  ["..mythic_t3_itemType.." - Key +"..mythic_t3_track.." - "..mythic_t3_progress.."/"..mythic_t3_threshold.."]"
		-- PvP Stuff
		local pvp_t1_progress = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t1.progress
		local pvp_t2_progress = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t2.progress
		local pvp_t3_progress = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t3.progress
		local pvp_t1_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t1.threshold
		local pvp_t2_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t2.threshold
		local pvp_t3_threshold = DrakDB["characters"][playerRealm][charName]["vaults"].pvp.t3.threshold

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
			t1Verify = pvpGreenIcon..greenColor
			t2Verify = pvpGreenIcon..greenColor
			t3Verify = pvpGreenIcon..greenColor
		elseif charProgress == 2 then
			t1Verify = pvpGreenIcon..greenColor
			t2Verify = pvpGreenIcon..greenColor
			t3Verify = pvpRedIcon..whiteColor
		elseif charProgress == 1 then
			t1Verify = pvpGreenIcon..greenColor
			t2Verify = pvpRedIcon..whiteColor
			t3Verify = pvpRedIcon..greyColor
		elseif charProgress == 0.5 then
			t1Verify = pvpRedIcon..whiteColor
			t2Verify = pvpRedIcon..greyColor
			t3Verify = pvpRedIcon..greyColor
		else
			t1Verify = pvpRedIcon..greyColor
			t2Verify = pvpRedIcon..greyColor
			t3Verify = pvpRedIcon..greyColor
		end

		local pvpString = " PvP:               "..t1Verify.."  ["..pvp_t1_progress.."/"..pvp_t1_threshold.."]     "..t2Verify.."  ["..pvp_t2_progress.."/"..pvp_t2_threshold.."]     "..t3Verify.."  ["..pvp_t3_progress.."/"..pvp_t3_threshold.."]"

		local vaultClaim = DrakDB["characters"][playerRealm][charName]["vaults"]["claim"]
		local verifyVaultClaim = ""
		if vaultClaim == true then
			verifyVaultClaim = "Yes"
		else
			verifyVaultClaim = "No"
		end

		--charInfoLabel:SetText("["..index..".] "..charName.." - "..DrakDB["characters"][playerRealm][charName]["class"].." "..classIcon.."      Vault Available?:  [ "..verifyVaultClaim.." ]     Keystone: "..dungeonIcon.."  "..keyLevel.." "..keyName)
		if keyName == "None" then
			charInfoLabel:SetText(classColor..string.rep("-",100).."\n |r["..index..".] - "..classColor..charName.." --- "..DrakDB["characters"][playerRealm][charName]["class"].." "..classIcon.."|cFFCCCCCC  --- Keystone:  "..whiteColor..keyName..classColor.."\n"..string.rep("-",100).."|r")
		else
			charInfoLabel:SetText(classColor..string.rep("-",100).."\n |r["..index..".] - "..classColor..charName.." --- "..DrakDB["characters"][playerRealm][charName]["class"].." "..classIcon.."|cFFCCCCCC --- Keystone:  "..whiteColor..keyLevel.." "..keyName..classColor.." "..dungeonIcon.."\n"..string.rep("-",100).."|r")
		end

		local playerInfoString = "|cffffff00 Logged out: |cffDAA520 "..DrakDB["characters"][playerRealm][charName]["lastLogin"]
		raidLabel:SetText(" >>  "..raidIcon..raidString)
		dungeonLabel:SetText(" >>  "..dungeonIcon..dungeonString)
		pvpLabel:SetText(" >>  "..pvpIcon..pvpString)
		playerInfo:SetText(playerInfoString)

		charInfoLabel:SetFullWidth(true) -- Set label to full width
		raidLabel:SetFullWidth(true) -- Set label to full width
		dungeonLabel:SetFullWidth(true) -- Set label to full width
		pvpLabel:SetFullWidth(true) -- Set label to full width
		playerInfo:SetFullWidth(true) -- Set label to full width

		-- Add label to the main frame

		CreateSpacer(parent)
		parent:AddChild(charInfoLabel)
		parent:AddChild(raidLabel)
		parent:AddChild(dungeonLabel)
		parent:AddChild(pvpLabel)
		parent:AddChild(playerInfo)
		CreateSpacer(parent)
	end

	local function PopulatePlayerLabels(playerRealm,scroll)
		local count = 1
		local playerName = UnitName("player")
		CreatePlayerLabel(scroll,playerRealm,playerName,count)
		count = count + 1
		local sortedTable = Drak:SortPlayerList(playerName,playerRealm)
		for _,charName in pairs(sortedTable) do
			if DrakDB["characters"][playerRealm][charName] then
				CreatePlayerLabel(scroll,playerRealm,charName,count)
				count = count + 1
			end
		end
	end

	-- Set callback for value change event
	dropdown:SetCallback("OnValueChanged", function(widget, event, value)
		DrakDB["server"] = value
		playerRealm = value
		scroll:ReleaseChildren()
		PopulatePlayerLabels(playerRealm,scroll)
	end)

	PopulatePlayerLabels(playerRealm,scroll)
	mainFrameShown = true
end

function Drak:ShowTime()

	-- Function to get the correct day suffix
	local function GetDaySuffix(day)
		local suffix = "th"
		if day == 1 or day == 21 or day == 31 then
			suffix = "st"
		elseif day == 2 or day == 22 then
			suffix = "nd"
		elseif day == 3 or day == 23 then
			suffix = "rd"
		end
		return suffix
	end

	-- Example timestamp for May 15, 2024, at 1:18 PM (adjust this as needed)
	local timestamp = time()

	-- Format the date parts
	local weekday = date("%A", timestamp) -- Get the day of the week
	local month = date("%B", timestamp)
	local day = tonumber(date("%d", timestamp))  -- Get day as a number
	local year = date("%Y", timestamp)
	local time = date("%I:%M %p", timestamp) -- Format time as 12-hour with AM/PM

	-- Combine the parts with the correct day suffix
	local formattedDate = string.format("%s, %s %d%s, %s - %s", weekday, month, day, GetDaySuffix(day), year, time)

	return formattedDate, timestamp

	--local currentTime = time()
	--local currentDate = date("%Y-%m-%d %H:%M:%S")

	--local serverTime = GetServerTime()
	--local hours, minutes = GetGameTime()

	--print("Current time (epoch):", currentTime)
	--print("Current date and time:", currentDate)
	--print("Server time (epoch):", serverTime)
	--print("In-game time: " .. hours .. ":" .. string.format("%02d", minutes))
end

function Drak:SortPlayerList(playerName,playerRealm)
	-- Sort based on the last login time
	local function sortEpochs(character1, character2)
		return DrakDB["characters"][playerRealm][character1].lastLoginEpoch > DrakDB["characters"][playerRealm][character2].lastLoginEpoch
	end

	-- Extract player names into an array for sorting
	local playerNamesTable = {}
	for charName in pairs(DrakDB["characters"][playerRealm]) do
		if charName ~= playerName then
			table.insert(playerNamesTable, charName)
		end
	end

	-- Sort the player names array using the custom sort function
	table.sort(playerNamesTable, sortEpochs)
	return playerNamesTable
end

-- Hidden frame to handle events
local eventFrame = CreateFrame("Frame")

-- Event handler function
local function OnEvent(self, event, ...)
	if event == "PLAYER_LOGOUT" then
		local playerRealm = GetRealmName()
		local playerName = UnitName("player")
		DrakDB["characters"][playerRealm][playerName]["lastLogin"], DrakDB["characters"][playerRealm][playerName]["lastLoginEpoch"]= Drak:ShowTime()
	end
	if event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(5, function()
			Drak:GetVaultData()
		end)
	end
end

-- Register events on the hidden frame
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", OnEvent)
