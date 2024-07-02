-- Drak is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Tristan Schaefer
-- This code is licensed under the MIT license (see LICENSE for details)

--- Drak is the main addon object for the Drak add-on.
---@class Drak : AceAddon-3.0 @The main addon object for the Drak add-on
_G.Drak = LibStub("AceAddon-3.0"):NewAddon("Drak", "AceTimer-3.0", "AceHook-3.0",
		"AceConsole-3.0", "AceEvent-3.0")

-- Create a local handle to our addon table
---@type Drak
local Drak = _G.Drak

-------------------------------------------------------------------------
------------------------- Lifecycle Functions ---------------------------
-------------------------------------------------------------------------

--- Called directly after the addon is fully loaded.
--- We do initialization tasks here, such as loading our saved variables or setting up slash commands.
function Drak:OnInitialize()
	-- Initialize the database and feed in our default values
	self.db = LibStub("AceDB-3.0"):New("DrakDB", self.database_defaults)
	
	-- Register our slash command
	self:RegisterChatCommand("drak", "SlashCommand")
end

--- Called during the PLAYER_LOGIN event when most of the data provided by the game is already present.
--- We perform more startup tasks here, such as registering events, hooking functions, creating frames, or getting 
--- information from the game that wasn't yet available during :OnInitialize()
function Drak:OnEnable()
	-- Populate our db with the player's information
	self.db.char.name = UnitName("player")
	self.db.char.realm = GetRealmName()
	self.db.char.class = UnitClass("player")
	self.db.char.playerLevel = UnitLevel("player")
	
	-- Get the player's last login time (epoch and formatted)
	self.db.char.lastLoginEpoch = time()
	self.db.char.lastLoginFormatted = self:FormatDateFromEpoch(self.db.char.lastLoginEpoch)
	
	-- Populate the player's vault data during the PLAYER_ENTERING_WORLD event
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		self:GetVaultData()
	end)
end

--- Called when our addon is manually being disabled during a running session.
--- We primarily use this to unhook scripts, unregister events, or hide frames that we created.
function Drak:OnDisable()
	-- Empty --
end

-------------------------------------------------------------------------
------------------------- New Functions Go Here -------------------------
-------------------------------------------------------------------------

function Drak:PopulateThreshold()
	for _, activityInfo in pairs(C_WeeklyRewards.GetActivities()) do
		
		-- Mythic+
		if activityInfo.id == 145 then
			self.db.char.mythic.t1.threshold = activityInfo.threshold
		elseif activityInfo.id == 146 then
			self.db.char.mythic.t2.threshold = activityInfo.threshold
		elseif activityInfo.id == 147 then
			self.db.char.mythic.t3.threshold = activityInfo.threshold
		
			-- PvP
		elseif activityInfo.id == 148 then
			self.db.char.pvp.t1.threshold = activityInfo.threshold
		elseif activityInfo.id == 149 then
			self.db.char.pvp.t2.threshold = activityInfo.threshold
		elseif activityInfo.id == 150 then
			self.db.char.pvp.t3.threshold = activityInfo.threshold
		
			-- Raid
		elseif activityInfo.id == 151 then
			self.db.char.raid.t1.threshold = activityInfo.threshold
		elseif activityInfo.id == 152 then
			self.db.char.raid.t2.threshold = activityInfo.threshold
		elseif activityInfo.id == 153 then
			self.db.char.raid.t3.threshold = activityInfo.threshold
		end
	end
end

-- Function to retrieve Mythic Plus activities and their rewards
function Drak:GetMythicPlusRewards()
	local Link, UpgradeLink, ILvl
	
	-- Retrieve all weekly activities
	local activities = C_WeeklyRewards.GetActivities()
	if activities then
		for idx = 1, #activities do
			Link, UpgradeLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activities[idx].id)
			if Link then
				ILvl = GetDetailedItemLevelInfo(Link)
				if ILvl then
					print("ilvl:", ILvl, "Link:", Link)
				end
			end

		end
	end
end

-- Returns the item gear track (Myth/Hero/Champion/Veteran/etc)
function Drak:VaultItemTrackType(type, level)
	-- not listed below but type 2 is pvp
	if type == 1 then
		-- type 1 is Mythic dungeons
		if level >= 8 then
			-- 8 keys and above give myth gear
			return "Myth"
		elseif level >= 0 then
			-- 0 to 7 key levels give hero gear
			return "Hero"
		end
	elseif type == 3 then
		-- type 3 is Raid
		if level == 16 then
			-- 14 corresponds to Mythic Raid
			return "Myth", "Mythic Raid"
		elseif level == 15 then
			-- 14 corresponds to Heroic Raid
			return "Hero", "Heroic Raid"
		elseif level == 14 then
			-- 14 corresponds to Normal Raid
			return "Champion", "Normal Raid"
		elseif level == 17 then
			-- 17 corresponds to LFR
			return "Veteran", "Raid Finder"
		end
	end
	
	return "None", "None"
end

function Drak:GetVaultData()

	self:PopulateThreshold()

	-- check if player is expansion's current max level before adding to tables
	if UnitLevel("player") == GetMaxLevelForExpansionLevel(GetExpansionLevel()) then

		self.db.char.keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
		if self.db.char.keystoneLevel ~= 0 then
			self.db.char.keystoneName = C_ChallengeMode.GetMapUIInfo(C_MythicPlus.GetOwnedKeystoneChallengeMapID())
		else
			self.db.char.keystoneName = "None"
		end

		-- Get the player's current vault activities
		self.db.char.claim = C_WeeklyRewards.HasAvailableRewards()

		for _, activityInfo in pairs(C_WeeklyRewards.GetActivities()) do
			local vaultItemType, instanceType = self:VaultItemTrackType(activityInfo.type, activityInfo.level)
			
			if activityInfo.id == 145 then
				self.db.char.mythic.t1.level = activityInfo.level
				self.db.char.mythic.t1.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.mythic.t1.threshold then
					self.db.char.mythic.t1.progress = self.db.char.mythic.t1.threshold
					self.db.char.mythic.t1.itemType = vaultItemType
				end
			elseif activityInfo.id == 146 then
				self.db.char.mythic.t2.level = activityInfo.level
				self.db.char.mythic.t2.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.mythic.t2.threshold then
					self.db.char.mythic.t2.progress = self.db.char.mythic.t2.threshold
					self.db.char.mythic.t2.itemType = vaultItemType
				end
			elseif activityInfo.id == 147 then
				self.db.char.mythic.t3.level = activityInfo.level
				self.db.char.mythic.t3.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.mythic.t3.threshold then
					self.db.char.mythic.t3.progress = self.db.char.mythic.t3.threshold
					self.db.char.mythic.t3.itemType = vaultItemType
				end
			elseif activityInfo.id == 148 then
				self.db.char.pvp.t1.level = activityInfo.level
				self.db.char.pvp.t1.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.pvp.t1.threshold then
					self.db.char.pvp.t1.progress = self.db.char.pvp.t1.threshold
					self.db.char.pvp.t1.itemType = "Champion"
				end
			elseif activityInfo.id == 149 then
				self.db.char.pvp.t2.level = activityInfo.level
				self.db.char.pvp.t2.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.pvp.t2.threshold then
					self.db.char.pvp.t2.progress = self.db.char.pvp.t2.threshold
					self.db.char.pvp.t2.itemType = "Champion"
				end
			elseif activityInfo.id == 150 then
				self.db.char.pvp.t3.level = activityInfo.level
				self.db.char.pvp.t3.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.pvp.t3.threshold then
					self.db.char.pvp.t3.progress = self.db.char.pvp.t3.threshold
					self.db.char.pvp.t3.itemType = "Champion"
				end
			elseif activityInfo.id == 151 then
				self.db.char.raid.t1.level = activityInfo.level
				self.db.char.raid.t1.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.raid.t1.threshold then
					self.db.char.raid.t1.progress = self.db.char.raid.t1.threshold
					self.db.char.raid.t1.level = instanceType
					self.db.char.raid.t1.itemType = vaultItemType
				end
			elseif activityInfo.id == 152 then
				self.db.char.raid.t2.level = activityInfo.level
				self.db.char.raid.t2.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.raid.t2.threshold then
					self.db.char.raid.t2.progress = self.db.char.raid.t2.threshold
					self.db.char.raid.t2.level = instanceType
					self.db.char.raid.t2.itemType = vaultItemType
				end
			elseif activityInfo.id == 153 then
				self.db.char.raid.t3.level = activityInfo.level
				self.db.char.raid.t3.progress = activityInfo.progress
				if activityInfo.progress >= self.db.char.raid.t3.threshold then
					self.db.char.raid.t3.progress = self.db.char.raid.t3.threshold
					self.db.char.raid.t3.level = instanceType
					self.db.char.raid.t3.itemType = vaultItemType
				end
			end
		end
	end
end

function Drak:SlashCommand(msg)
	if not msg or msg:trim() == "" then
		if self.mainFrameShown == true then
			self.mainFrame:Hide()
			self.mainFrameShown = false
		else
			Drak:ShowFrame()
		end
	elseif msg == "vault" then
		print("AreRewardsCurrWeek", C_WeeklyRewards.AreRewardsForCurrentRewardPeriod())

	else
		-- Load the Blizzard_WeeklyRewards addon
		LoadAddOn("Blizzard_WeeklyRewards")

		-- Show the Great Vault frame
		--WeeklyRewardsFrame:Show()

		self:CheckVaults()
		--Drak:GetMythicPlusRewards()
	end
end

