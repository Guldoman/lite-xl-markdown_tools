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

-- TODO: check all those (surrounded and 1 or 0)
local function offset_location(col, old_row, new_row, surrounded)
	if col < old_row[1].cell_start then
		-- Before the table
		return 1
	end
	for i, cell in ipairs(old_row) do
		local new_cell = new_row[i]
		if col <= cell.cell_start + cell.offset_start then
			-- Before the text
			return new_cell.cell_start + new_cell.offset_start
		elseif col <= cell.cell_start + cell.offset_start + #cell.text + (surrounded and 1 or 0) -- +1 to allow spaces to be inserted
			and not (col >= cell.cell_start + cell.offset_start + #cell.text + cell.offset_end + (surrounded and 1 or 0)) then
			-- Inside the text or a space after
			local in_text_idx = col - (cell.cell_start + cell.offset_start)
			return new_cell.cell_start + new_cell.offset_start + in_text_idx
		elseif col < cell.cell_start + cell.offset_start + #cell.text + cell.offset_end + (surrounded and 1 or 0) then
			-- After the text
			return new_cell.cell_start + new_cell.offset_start + #new_cell.text + 1
		end
	end
	-- After the table
	local last_cell = old_row[#old_row]
	local last_new_cell = new_row[#new_row]
	local left_out_offset = col - (last_cell.cell_start + last_cell.offset_start + #last_cell.text + last_cell.offset_end)
	return left_out_offset + (last_new_cell.cell_start + last_new_cell.offset_start + #last_new_cell.text + last_new_cell.offset_end) + (surrounded and 0 or (last_cell.offset_end > 0 and 1 or 0)), last_cell.offset_end > 0
end

function Table.apply_table_format(doc, table_format)
	local selections = { }
	local additional_spaces = { }
	for idx, line1, col1, line2, col2, swap in doc:get_selections(true, false) do
		if line1 >= table_format.line1 and line1 <= table_format.line2 then
			local row_idx = line1 - table_format.line1 + 1
			local additional_space
			col1, additional_space = offset_location(col1, table_format.rows[row_idx], table_format.formatted_rows[row_idx], table_format.surrounded)
			if additional_space then
				additional_spaces[line1] = true
			end
		end
		if line2 >= table_format.line1 and line2 <= table_format.line2 then
			local row_idx = line2 - table_format.line1 + 1
			local additional_space
			col2, additional_space = offset_location(col2, table_format.rows[row_idx], table_format.formatted_rows[row_idx], table_format.surrounded)
			if additional_space then
				additional_spaces[line2] = true
			end
		end
		table.insert(selections, {
			idx = idx,
			line1 = line1,
			col1 = col1,
			line2 = line2,
			col2 = col2,
			swap = swap,
		})
	end
	local res_rows = { }
	for i, row in ipairs(table_format.formatted_rows) do
		local res_row = { }
		if table_format.surrounded then
			table.insert(res_row, "|")
		end
		for j, cell in ipairs(row) do
			table.insert(res_row, string.rep(" ", cell.offset_start))
			table.insert(res_row, cell.text)
			table.insert(res_row, string.rep(" ", cell.offset_end))
			if not table_format.surrounded and j == table_format.n_cols and additional_spaces[i + table_format.line1 - 1] then
				table.insert(res_row, " ") -- additional space for writing text
			end
			if table_format.surrounded or j < table_format.n_cols then
				table.insert(res_row, "|")
			end
		end
		table.insert(res_rows, table.concat(res_row))
	end
	doc:remove(table_format.line1, 1, table_format.line2, math.huge)
	doc:insert(table_format.line1, 1, table.concat(res_rows, "\n"))
	for _, sel in ipairs(selections) do
		doc:set_selections(sel.idx, sel.line1, sel.col1, sel.line2, sel.col2, sel.swap)
	end
	doc:merge_cursors()
end

return Table
