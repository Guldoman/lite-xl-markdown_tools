local Utils = { }

function Utils.split(str, token)
	local res = { }
	local indexes = { }
	local index = 1
	repeat
		local initial, final = string.find(str, token, index, true)
		if not initial then
			final = #str
		else
			table.insert(indexes, final)
		end
		table.insert(res, string.sub(str, index, final - 1))
		index = final + 1 --[[@as integer]]
	until not initial
	return res, indexes
end

function Utils.trim(str)
	local trim_start, res, trim_end = string.match(str, "^(%s*)(.-)(%s*)$")
	return res, trim_start, trim_end
end

function Utils.format(str, alignment, size, pad_str)
	pad_str = pad_str or " "
	local len = #str
	assert(size >= len)
	local left, right = 0, 0
	if alignment == "left" then
		right = size - len
	elseif alignment == "right" then
		left = size - len
	elseif alignment == "center" then
		local middle = (size - len) / 2
		left = math.floor(middle)
		right = math.ceil(middle)
	end
	return string.format("%s%s%s", string.rep(pad_str, left), str, string.rep(pad_str, right))
end

return Utils
