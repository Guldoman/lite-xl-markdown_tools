local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local build_table_format = TestLib("Table.build_table_format Tests")

local Doc = require "core.doc"
---@type Table
local Table = require "plugins.markdown_tools.table"

build_table_format:add_test("Surrounded table", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|:-:|---|--:|
|Cell Content|Another Cell|Last Column Cell|
|test|test|test|
]])
--[[
|      H1      | H2           |               H3 |
| :----------: | ------------ | ---------------: |
| Cell Content | Another Cell | Last Column Cell |
|     test     | test         |             test |
--]]
	local expected_format = {
		{
			{
				cell_start = 2,
				text = "H1",
				offset_start = 6,
				offset_end = 6,
			},
			{
				cell_start = 17,
				text = "H2",
				offset_start = 1,
				offset_end = 11,
			},
			{
				cell_start = 32,
				text = "H3",
				offset_start = 15,
				offset_end = 1,
			},
		},
		{
			{
				cell_start = 2,
				text = ":----------:",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 17,
				text = "------------",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 32,
				text = "---------------:",
				offset_start = 1,
				offset_end = 1,
			},
		},
		{
			{
				cell_start = 2,
				text = "Cell Content",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 17,
				text = "Another Cell",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 32,
				text = "Last Column Cell",
				offset_start = 1,
				offset_end = 1,
			},
		},
		{
			{
				cell_start = 2,
				text = "test",
				offset_start = 5,
				offset_end = 5,
			},
			{
				cell_start = 17,
				text = "test",
				offset_start = 1,
				offset_end = 9,
			},
			{
				cell_start = 32,
				text = "test",
				offset_start = 13,
				offset_end = 1,
			},
		},
	}
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))

	-- t_format should keep every field of t_info
	for k, v in pairs(t_info) do
		assert(t_format[k] == v)
	end

	assert(t_format.formatted_rows)
	for i, row in ipairs(t_format.formatted_rows) do
		for j, cell in ipairs(row) do
			local expected = expected_format[i][j]
			for k, v in pairs(cell) do
				assert(expected[k] == v, k)
			end
		end
	end
	return true
end)

build_table_format:add_test("Not surrounded table", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
:-:|---|--:
Cell Content|Another Cell|Last Column Cell
test|test|test
]])
--[[
     H1      | H2           |               H3
:----------: | ------------ | ---------------:
Cell Content | Another Cell | Last Column Cell
    test     | test         |             test
--]]
	local expected_format = {
		{
			{
				cell_start = 1,
				text = "H1",
				offset_start = 5,
				offset_end = 6,
			},
			{
				cell_start = 15,
				text = "H2",
				offset_start = 1,
				offset_end = 11,
			},
			{
				cell_start = 30,
				text = "H3",
				offset_start = 15,
				offset_end = 0,
			},
		},
		{
			{
				cell_start = 1,
				text = ":----------:",
				offset_start = 0,
				offset_end = 1,
			},
			{
				cell_start = 15,
				text = "------------",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 30,
				text = "---------------:",
				offset_start = 1,
				offset_end = 0,
			},
		},
		{
			{
				cell_start = 1,
				text = "Cell Content",
				offset_start = 0,
				offset_end = 1,
			},
			{
				cell_start = 15,
				text = "Another Cell",
				offset_start = 1,
				offset_end = 1,
			},
			{
				cell_start = 30,
				text = "Last Column Cell",
				offset_start = 1,
				offset_end = 0,
			},
		},
		{
			{
				cell_start = 1,
				text = "test",
				offset_start = 4,
				offset_end = 5,
			},
			{
				cell_start = 15,
				text = "test",
				offset_start = 1,
				offset_end = 9,
			},
			{
				cell_start = 30,
				text = "test",
				offset_start = 13,
				offset_end = 0,
			},
		},
	}
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))

	-- t_format should keep every field of t_info
	for k, v in pairs(t_info) do
		assert(t_format[k] == v)
	end

	assert(t_format.formatted_rows)
	for i, row in ipairs(t_format.formatted_rows) do
		for j, cell in ipairs(row) do
			local expected = expected_format[i][j]
			for k, v in pairs(cell) do
				assert(expected[k] == v, k)
			end
		end
	end
	return true
end)

return build_table_format
