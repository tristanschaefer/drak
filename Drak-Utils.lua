-- Drak is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Tristan Schaefer
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type Drak
local Drak = _G.Drak

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function Drak:FormatDateFromEpoch(epoch)
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
	
	-- Format the date parts
	local weekday = date("%A", epoch) -- Get the day of the week
	local month = date("%B", epoch)
	local day = tonumber(date("%d", epoch))  -- Get day as a number
	local year = date("%Y", epoch)
	local time = date("%I:%M %p", epoch) -- Format time as 12-hour with AM/PM

	-- Combine the parts with the correct day suffix
	local formattedDate = string.format("%s, %s %d%s, %s - %s", weekday, month, day, GetDaySuffix(day), year, time)

	return formattedDate
end