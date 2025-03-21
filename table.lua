local Table = {}

local is_table_regex = assert(regex.compile([[^\s*(?:(\|).*\|\s*|[^|].*(\|).*)$]]))
local is_table_header_separator = assert(regex.compile([[^(?=.*\|)(\|?\s*:?\-+:?\s*\|?)+$]]))
---@param str string
local function get_table_line_info(str)
	local match = is_table_regex:match(str)
	if not match then return end
	local surrounded = match == "|"
	local nfields = surrounded and -1 or 1
	for _ in string.gmatch(str, "|") do
		nfields = nfields + 1
	end
	local is_header_separator = is_table_header_separator:match(str)
	return {
		surrounded = surrounded,
		nfields = nfields,
		is_header_separator = not not is_header_separator,
	}
end


-- TODO: Define table requirements:
--       Should a table have an empty line above?
--       How to deal with single column tables without pipes around it?

---Check if the specified line is part of a table.
---
---@param doc core.doc
---@param line integer
---@return false|table
function Table.is_table(doc, line)
	local result = get_table_line_info(doc.lines[line])
	if not result then return false end

	local surrounded = result.surrounded
	local nfields = result.nfields
	local line1 = line
	local line2 = line

	if #doc.lines < 3 then
		-- A table needs at least three lines
		return false
	end

	-- Find initial table line
	for i=math.min(#doc.lines, line-1),1,-1 do
		result = get_table_line_info(doc.lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.nfields ~= nfields then
			break
		end
		line1 = i
	end
	if line1 > #doc.lines-2 then
		-- There is not enough space for a table
		return false
	end

	-- Check that the second table line is an header separator
	result = get_table_line_info(doc.lines[line1 + 1])
	if not result then return false end
	if result.surrounded ~= surrounded
	   or result.nfields ~= nfields
	   or not result.is_header_separator then
		return false
	end

	-- Find final table line
	for i=line+1,#doc.lines do
		result = get_table_line_info(doc.lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.nfields ~= nfields then
			break
		end
		line2 = i
	end

	return {
		line1 = line1,
		line2 = line2,
		surrounded = surrounded,
		nfields = nfields,
	}
end

return Table
