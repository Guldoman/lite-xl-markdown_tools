local Utils = require "plugins.markdown_tools.utils"

---@class Table
local Table = {}

-- TODO: handle escaped pipes
-- TODO: make tests for the regexes
local is_table_regex = assert(regex.compile([[^\s*(?:(\|).*\|\s*|[^|].*(\|).*)\s*$]]))
local is_table_header_separator = assert(regex.compile([[^(?=[^|]*\|)\s*:?\-*:?\s*(?:\|\s*:?\-+:?\s*)+\|?\s*$]]))

Table.minimum_width = 3
Table.cell_margin = 1

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
---@param lines string[]
---@param line integer
---@return false|table
---@return string?
function Table.is_table(lines, line)
	local result = Table.get_table_line_info(lines[line])
	if not result then
		return false, "Specified line doesn't look like a table row"
	end

	local surrounded = result.surrounded
	local n_cols = result.n_cols
	local line1 = line
	local line2 = line

	if #lines < 3 then
		return false, "A table needs at least three lines"
	end

	-- Find initial table line
	for i=math.max(1, line - 1),1,-1 do
		result = Table.get_table_line_info(lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.n_cols ~= n_cols then
			break
		end
		line1 = i
	end
	if line1 > #lines - 2 then
		return false, "There is not enough space for a table"
	end

	-- Check that the second table line is an header separator
	result = Table.get_table_line_info(lines[line1 + 1])
	if not result then
		return false, "Invalid header separator line"
	end
	if not result.is_header_separator then
		return false, "Second line is not an header separator"
	end
	if result.surrounded ~= surrounded
	   or result.n_cols ~= n_cols then
		return false, "Header separator doesn't match the table"
	end

	-- Find final table line
	for i=line+1,#lines do
		result = Table.get_table_line_info(lines[i])
		if not result then break end
		if result.surrounded ~= surrounded
		   or result.n_cols ~= n_cols then
			break
		end
		line2 = i
	end
	if line2 < line1 + 2 then
		return false, "Table has no data rows"
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

function Table.get_alignment_string(alignment, size)
	assert(size >= 3)
	if alignment == "left" then
		return  string.rep("-", size)
	elseif alignment == "left-explicit" then
		return  ":" .. string.rep("-", size-1)
	elseif alignment == "right" then
		return  string.rep("-", size-1) .. ":"
	elseif alignment == "center" then
		return  ":" .. string.rep("-", size - 2) .. ":"
	else
		error("Invalid alignment")
	end
end

function Table.get_table_info(lines, table_location)
	local line1, line2 = table_location.line1, table_location.line2
	local surrounded = table_location.surrounded
	local max_lens = { }
	local initial_split_index = surrounded and 2 or 1
	local final_split_index = initial_split_index + table_location.n_cols - 1

	local alignment_strings = Utils.split(lines[line1 + 1], "|")
	local alignments = { }
	for i=initial_split_index, final_split_index do
		local alignment = Table.get_alignment(alignment_strings[i])
		assert(alignment, "Invalid alignment")
		table.insert(alignments, alignment)
	end

	local rows = { }
	for i=line1, line2 do
		local row = { }
		local data, pipe_positions = Utils.split(lines[i], "|")
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
				offset_start = #trim_start,
				offset_end = #trim_end,
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

function Table.build_table_format(table_info)
	local formatted_rows = { }
	local surrounded = table_info.surrounded
	for i, row in ipairs(table_info.rows) do
		local formatted_row = { }
		local cell_start = 1
		if surrounded then
			cell_start = cell_start + 1
		end
		for j, cell in ipairs(row) do
			local text, insert_start, insert_end = cell.text, 0, 0
			local max_length = math.max(table_info.max_lengths[j], Table.minimum_width)
			if i == 2 then
				text = Table.get_alignment_string(table_info.alignments[j], max_length)
			else
				insert_start, insert_end = select(2, Utils.format(cell.text, table_info.alignments[j], max_length)) --[[@as integer, integer]]
			end

			-- Avoid external margin on first and last columns when not surrounded
			if surrounded or j > 1 then
				insert_start = insert_start + Table.cell_margin
			end
			if surrounded or j < #row then
				insert_end = insert_end + Table.cell_margin
			end

			table.insert(formatted_row, {
				cell_start = cell_start,
				text = text,
				offset_start = insert_start,
				offset_end = insert_end,
			})
			cell_start = cell_start + insert_start + #text + insert_end + 1
		end
		table.insert(formatted_rows, formatted_row)
	end
	return {
		formatted_rows = formatted_rows,
		-- From table_info
		rows = table_info.rows,
		alignments = table_info.alignments,
		max_lengths = table_info.max_lengths,
		-- From table_location
		line1 = table_info.line1,
		line2 = table_info.line2,
		surrounded = table_info.surrounded,
		n_cols = table_info.n_cols,
	}
end

return Table
