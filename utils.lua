local Utils = { }

function Utils.split(str, token, escape_token)
	local escape_token_len = escape_token and #escape_token
	local res = { }
	local indexes = { }
	local index = 1
	repeat
		local initial, final
		local tmp_index = index
		repeat
			local done = false
			initial, final = string.find(str, token, tmp_index, true)
			if not initial or not escape_token or escape_token_len == 0 then
				-- No token to the end of the string
				break
			end
			-- Check for the number of escapes
			local n = -1
			repeat
				n = n + 1
				local idx = final - ((n + 1) * escape_token_len)
			until string.sub(str, idx, idx + escape_token_len - 1) ~= escape_token
			if n % 2 ~= 0 then
				tmp_index = final + 1
			else
				done = true
			end
		until done
		if not initial then
			final = #str + 1
		else
			table.insert(indexes, initial)
		end
		table.insert(res, string.sub(str, index, (initial or final) - 1))
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
	local len = string.ulen(str)
	assert(size >= len)
	local left, right = 0, 0
	if alignment == "left" or alignment == "left-explicit" then
		right = size - len
	elseif alignment == "right" then
		left = size - len
	elseif alignment == "center" then
		local middle = (size - len) / 2
		left = math.floor(middle)
		right = math.ceil(middle)
	end
	return string.format("%s%s%s", string.rep(pad_str, left), str, string.rep(pad_str, right)), left, right
end

return Utils
