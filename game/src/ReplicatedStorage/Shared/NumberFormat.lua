--[[
	NumberFormat  (ReplicatedStorage.Shared.NumberFormat)

	Short number text for the HUD, signs and shop: 950, 1.2K, 4.5M, 3.1B, 7T, 2.2Qa ...
	Lua 5.3-compatible Luau, so the tests can load it.
]]

local NumberFormat = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1.2K", 1000000 -> "1M", 999 -> "999", 12.5 -> "12.5"
function NumberFormat.short(n)
	if n ~= n then
		return "0"
	end
	if n < 0 then
		return "-" .. NumberFormat.short(-n)
	end
	if n < 1000 then
		if n == math.floor(n) then
			return string.format("%d", n)
		end
		return (string.format("%.1f", n):gsub("%.0$", ""))
	end
	local index = 0
	while n >= 999.5 and index < #SUFFIXES do
		n = n / 1000
		index = index + 1
	end
	local text
	if n >= 100 then
		text = string.format("%d", math.floor(n + 0.5))
	else
		text = string.format("%.1f", n):gsub("%.0$", "")
	end
	return text .. SUFFIXES[index]
end

function NumberFormat.cash(n)
	return "$" .. NumberFormat.short(n)
end

-- 1234567 -> "1,234,567" (whole numbers only)
function NumberFormat.commas(n)
	local text = string.format("%d", math.floor(n))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^(%-?),", "%1"))
end

-- 75 -> "1:15"
function NumberFormat.clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
	end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

return NumberFormat
