local Utils = require "plugins.markdown_tools.utils"

---@class Table
local Table = {}

-- TODO: handle escaped pipes

local is_table_regex = assert(regex.compile([[^\s*(?:(\|).*\|\s*|[^|].*(\|).*)\s*$]]))
local is_table_header_separator = assert(regex.compile([[^(?=[^|]*\|)\s*:?\-*(?:\|\s*:?\-+:?\s*)+\|?\s*$]]))

---@param str string
function Table.get_table_line_info(str)
	local match = is_table_regex:match(str)
	if not match then return end
	local surrounded = match == "|"
	local n_cols = surrounded and -1 or 1
	for _ in string.gmatch(str, "|") do
		n_cols = n_cols + 1
	end
	local is_header_separator = is_table_header_separator:match(str)
	return {
		surrounded = surrounded,
		n_cols = n_cols,
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
	local result = Table.get_table_line_info(doc.lines[line])
	if not result then return false end

	local surrounded = result.surrounded
	local n_cols = result.n_cols
	local line1 = line
	local line2 = line

	if #doc.lines < 3 then
		-- A table needs at least three lines
		return false
	end

	-- Find initial table line
	for i=math.min(#doc.lines, line-1),1,-1 do
		result = Table.get_table_line_info(doc.lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.n_cols ~= n_cols then
			break
		end
		line1 = i
	end
	if line1 > #doc.lines-2 then
		-- There is not enough space for a table
		return false
	end

	-- Check that the second table line is an header separator
	result = Table.get_table_line_info(doc.lines[line1 + 1])
	if not result then return false end
	if result.surrounded ~= surrounded
	   or result.n_cols ~= n_cols
	   or not result.is_header_separator then
		return false
	end

	-- Find final table line
	for i=line+1,#doc.lines do
		result = Table.get_table_line_info(doc.lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.n_cols ~= n_cols then
			break
		end
		line2 = i
	end

	return {
		line1 = line1,
		line2 = line2,
		surrounded = surrounded,
		n_cols = n_cols,
	}
end

function Table.get_alignment(str)
	if string.match(str, "^%s*%-+%s*$") then
		return "left"
	elseif string.match(str, "^%s*:%-+%s*$") then
		return "left-explicit"
	elseif string.match(str, "^%s*%-+:%s*$") then
		return "right"
	elseif string.match(str, "^%s*:%-+:%s*$") then
		return "center"
	end
	return false
end

function Table.get_table_info(doc, table_location)
	local line1, line2 = table_location.line1, table_location.line2
	local surrounded = table_location.surrounded
	local max_lens = { }
	local initial_split_index = surrounded and 2 or 1
	local final_split_index = initial_split_index + table_location.n_cols - 1

	local alignment_strings = Utils.split(doc.lines[line1 + 1], "|")
	local alignments = { }
	for i=initial_split_index, final_split_index do
		local alignment = Table.get_alignment(alignment_strings[i])
		assert(alignment, "Invalid alignment")
		table.insert(alignments, alignment)
	end

	local rows = { }
	for i=line1, line2 do
		local row = { }
		local data, pipe_positions = Utils.split(doc.lines[i], "|")
		for j=initial_split_index, final_split_index do
			local col = j - initial_split_index + 1
			local text, trim_start, trim_end = Utils.trim(data[j])
			local cell_start = 1
			if surrounded then
				cell_start = pipe_positions[j - initial_split_index + 1] + 1
			else
				cell_start = col == 1 and 1 or pipe_positions[col - 1] + 1
			end
			local cell = {
				cell_start = cell_start,
				text = text,
				trim_start = trim_start,
				trim_end = trim_end,
			}
			-- Skip header separation line
			if i ~= line1 + 1 then
				max_lens[col] = math.max(max_lens[col] or 0, string.ulen(cell.text))
			end
			table.insert(row, cell)
		end
		table.insert(rows, row)
	end
	return {
		rows = rows,
		alignments = alignments,
		max_lengths = max_lens,
		-- From table_location
		line1 = table_location.line1,
		line2 = table_location.line2,
		surrounded = table_location.surrounded,
		n_cols = table_location.n_cols,
	}
end

return Table
