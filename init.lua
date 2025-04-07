-- mod-version:3

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local common = require "core.common"
local config = require "core.config"

local DocView = require "core.docview"

local Utils = require "plugins.markdown_tools.utils"

local MarkdownTools = {}

config.plugins.markdown_tools = common.merge({
	bold_style = "**",
	italic_style = "__",
	strike_style = "~~",
	math_style = { "$", "$" },
	mathblock_style = { "$$", "$$" },
	-- TODO: bullet points and numbered lists (maybe even different style per indent size)
	-- TODO: table formatting modes:
	--       * automatic (every table gets formatted without any user interaction)
	--       * manual (format on command execution)
	--       * on-interaction (format when the table content gets modified)
}, config.plugins.markdown_tools)

function MarkdownTools.is_view_supported()
	if not core.active_view or not core.active_view:extends(DocView) then
		return false
	end
	local docview = core.active_view
	if not docview.doc.syntax or not docview.doc.syntax.name == "Markdown" then
		return false
	end
	return true, docview
end

---@param chars string | [string, string]
---@param doc core.doc
---@param line1 integer
---@param col1 integer
---@param line2 integer
---@param col2 integer
---@return integer line1, integer col1, integer line2, integer col2
local function surround(chars, doc, line1, col1, line2, col2)
	local starter, ender = chars, chars
	if type(chars) == "table" then
		starter = chars[1]
		ender = chars[2]
	end
	local nchars = #starter
	doc:insert(line1, col1, starter)
	if line1 == line2 then col2 = col2 + nchars end
	doc:insert(line2, col2, ender)
	return line1, col1 + nchars, line2, col2
end

---@param doc core.doc
---@param chars string | [string, string]
local function surround_all(doc, chars)
	for idx, line1, col1, line2, col2, swap in doc:get_selections(true, true) do
		line1, col1, line2, col2 = surround(chars, doc, line1 --[[@as integer]], col1, line2, col2)
		doc:set_selections(idx, line1, col1, line2, col2, swap)
	end
end

command.add(MarkdownTools.is_view_supported, {
	["markdown-tools:embolden"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.bold_style)
	end,
	["markdown-tools:italicize"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.italic_style)
	end,
	["markdown-tools:strike"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.strike_style)
	end,
	["markdown-tools:math"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.math_style)
	end,
	["markdown-tools:mathblock"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.mathblock_style)
	end,
})

keymap.add {
	["ctrl+b"] = "markdown-tools:embolden",
	["ctrl+i"] = "markdown-tools:italicize",
}

-- TODO: command to convert to/from csv

---@type Table
local Table = require "plugins.markdown_tools.table"

local function is_view_supported_and_in_table()
	local res, dv = MarkdownTools.is_view_supported()
	if not res or not dv then return false end
	local doc = dv.doc
	for _, line1, _, line2 in doc:get_selections(true, true) do
		-- TODO: maybe limit number of lines to check
		-- Check first and last line, then every three lines, as a table has at least 3 rows
		local t_loc = Table.is_table(doc.lines, line1)
		if t_loc then return true, dv end
		t_loc = Table.is_table(doc.lines, line2)
		if t_loc then return true, dv end
		for i=line2-1,line1+1,-3 do
			t_loc = Table.is_table(doc.lines, i)
			if t_loc then return true, dv end
		end
	end
	return false
end

local function format_if_needed(doc)
	-- TODO: don't apply this to non-markdown files
	local tables = { }
	local checked_lines = { }
	local function format_line(line)
		if checked_lines[line] then
				return
		end
		checked_lines[line] = true
		local t_loc = Table.is_table(doc.lines, line)
		if not t_loc then
			return
		end
		for i=t_loc.line1,t_loc.line2 do
			checked_lines[i] = true
		end
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local t_format = Table.build_table_format(t_info)
		table.insert(tables, t_format)
	end
	for _, line1, _, line2 in doc:get_selections(true, true) do
		-- TODO: maybe limit number of lines to check
		-- Check first and last line, then every three lines, as a table has at least 3 rows
		format_line(line1)
		format_line(line2)
		for line=line2-1,line1+1,-3 do
			format_line(line)
		end
	end
	for _, t_format in ipairs(tables) do
		Table.apply_table_format(doc, t_format)
	end
end

local function get_cell_xy(line, col, t_info)
	local row_idx = line - t_info.line1 + 1
	local tcol = t_info.n_cols
	for i, cell in ipairs(t_info.rows[row_idx]) do
		if col <= cell.cell_start + cell.offset_start + #cell.text + cell.offset_end then
			tcol = i
			break
		end
	end
	return row_idx, tcol
end

command.add(is_view_supported_and_in_table, {
	["markdown-tools:format-table"] = function(dv)
		format_if_needed(dv.doc)
	end,
	["markdown-tools:select-column"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local _, y = get_cell_xy(line, col, t_info)
		local n = 1
		for i, row in ipairs(t_info.rows) do
			local cell = row[y]
			local l = i + t_info.line1 - 1
			doc:set_selections(n, l, cell.cell_start, l, cell.cell_start + cell.offset_start + #cell.text + cell.offset_end)
			n = n + 1
		end
	end,
	["markdown-tools:next-cell"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		y = y + 1
		if y > t_info.n_cols then
			y = 1
			x = x + 1
		end
		if x > t_info.line2 - t_info.line1 + 1 then
			x = 1
		end
		local l = t_info.line1 + x - 1
		local cell = t_info.rows[x][y]
		local c = cell.cell_start + cell.offset_start
		doc:set_selection(l, c, l, c)
	end,
	["markdown-tools:previous-cell"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		y = y - 1
		if y <= 0 then
			y = t_info.n_cols
			x = x - 1
		end
		if x <= 0 then
			x = t_info.line2 - t_info.line1 + 1
		end
		local l = t_info.line1 + x - 1
		local cell = t_info.rows[x][y]
		local c = cell.cell_start + cell.offset_start
		doc:set_selection(l, c, l, c)
	end,
	["markdown-tools:add-row-above"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		Table.insert_row(t_info, x)
		local t_format = Table.build_table_format(t_info)
		Table.apply_table_format(doc, t_format)
		line = t_format.line1 + x - 1
		col = t_format.formatted_rows[x][y].cell_start + t_format.formatted_rows[x][y].offset_start
		doc:set_selection(line, col)
	end,
	["markdown-tools:add-row-below"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		if x < 2 then x = 2 end
		Table.insert_row(t_info, x + 1)
		local t_format = Table.build_table_format(t_info)
		Table.apply_table_format(doc, t_format)
		line = t_format.line1 + x
		col = t_format.formatted_rows[x + 1][y].cell_start + t_format.formatted_rows[x + 1][y].offset_start
		doc:set_selection(line, col)
	end,
	["markdown-tools:add-column-left"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		Table.insert_column(t_info, y)
		local t_format = Table.build_table_format(t_info)
		Table.apply_table_format(doc, t_format)
		col = t_format.formatted_rows[x][y].cell_start + t_format.formatted_rows[x][y].offset_start
		doc:set_selection(line, col)
	end,
	["markdown-tools:add-column-right"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		Table.insert_column(t_info, y + 1)
		local t_format = Table.build_table_format(t_info)
		Table.apply_table_format(doc, t_format)
		col = t_format.formatted_rows[x][y + 1].cell_start + t_format.formatted_rows[x][y + 1].offset_start
		doc:set_selection(line, col)
	end,
	["markdown-tools:delete-column"] = function(dv)
		local doc = dv.doc
		local line, col = doc:get_selection(false, true)
		local t_loc = Table.is_table(doc.lines, line)
		local t_info = Table.get_table_info(doc.lines, t_loc)
		local x, y = get_cell_xy(line, col, t_info)
		local last = y == t_info.n_cols
		Table.remove_column(t_info, y)
		local t_format = Table.build_table_format(t_info)
		Table.apply_table_format(doc, t_format)
		col = t_format.formatted_rows[x][y - (last and 1 or 0)].cell_start + t_format.formatted_rows[x][y - (last and 1 or 0)].offset_start
		doc:set_selection(line, col)
	end,
})

keymap.add({
	["tab"] = "markdown-tools:next-cell",
	["shift+tab"] = "markdown-tools:previous-cell",
	["return"] = "markdown-tools:add-row-below",
})

local Doc = require "core.doc"
local doc_text_input = Doc.text_input
function Doc:text_input(...)
	local res = { doc_text_input(self, ...) }
	format_if_needed(self)
	return table.unpack(res)
end

local doc_backspace = command.map["doc:backspace"].perform
command.map["doc:backspace"].perform = function(dv, ...)
	local res = { doc_backspace(dv, ...) }
	format_if_needed(dv.doc)
	return table.unpack(res)
end

local doc_delete = command.map["doc:delete"].perform
command.map["doc:delete"].perform = function(dv, ...)
	local res = { doc_delete(dv, ...) }
	format_if_needed(dv.doc)
	return table.unpack(res)
end


local last_test = { } -- cheap cache
local function is_view_supported_and_clipboard_has_table()
	local res, dv = MarkdownTools.is_view_supported()
	if not res or not dv then return false end
	local clip = system.get_clipboard()
	if last_test[clip] then
		return true, dv, last_test[clip]
	end
	last_test = { } -- clear cache
	local lines = Utils.split(clip, PLATFORM == "Windows" and "\r\n" or "\n")
	if #lines < 2 then -- not enough rows to form an actual table
		return false
	end
	local rows = { }
	local n_cols
	local started_table = false
	local finished_table = false
	for _, line in ipairs(lines) do
		if #line == 0 then
			if not started_table then
				goto continue
			end
			if not finished_table then
				finished_table = true
				goto continue
			end
		end
		started_table = true
		local cells = Utils.split(line, "\t")
		if #cells == 0 then
			return false
		end
		if not n_cols then
			n_cols = #cells
		end
		if #cells > 0 and finished_table then
			return false
		end
		if #cells ~= n_cols then
			return false
		end
		table.insert(rows, cells)
		::continue::
	end
	last_test[clip] = rows
	return true, dv, rows
end

command.add(is_view_supported_and_clipboard_has_table, {
	["markdown-tools:paste-table"] = function(dv, rows)
		local text = { }
		for i, row in ipairs(rows) do
			table.insert(text, string.format("|%s|", table.concat(row, "|")))
			if i == 1 then
				table.insert(text, string.format("|%s|", string.rep("---", #row, "|")))
			end
		end
		dv.doc:text_input(table.concat(text, "\n"))
	end
})

keymap.add({
	["ctrl+v"] = "markdown-tools:paste-table",
})

return MarkdownTools
