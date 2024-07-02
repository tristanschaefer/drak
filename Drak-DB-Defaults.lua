-- Drak is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Tristan Schaefer
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type Drak
local Drak = _G.Drak

-------------------------------------------------------------------------
-------------------------------------------------------------------------

Drak.database_defaults = {
	char = {
		name = "",
		realm = "",
		class = "",
		playerLevel = 0,
		lastLoginFormatted = "",
		lastLoginEpoch = 0,
		keystoneName = "None",
		keystoneLevel = 0,
		claim = false,

		mythic = {
			t1 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t2 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t3 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
		},

		pvp = {
			t1 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t2 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t3 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
		},

		raid = {
			t1 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t2 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
			t3 = {
				level = "None",
				itemType = "None",
				progress = 0,
				threshold = 0
			},
		}
	}
}