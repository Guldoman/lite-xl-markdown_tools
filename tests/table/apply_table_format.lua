local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local apply_table_format_tests = TestLib("Table.apply_table_format Tests")

local Doc = require "core.doc"
---@type Table
local Table = require "plugins.markdown_tools.table"

apply_table_format_tests:add_test("Surrounded table", function()
	local doc = Doc()
	doc:text_input([[
 |  H_1  |  H_2  |  H_3  |
  |  :-:  |  ---  |  --:  |
   |  Cell Content  |  Another Cell  |  Last Column Cell  |
    |  test  |  test  |  test  |
]])
--[[
|     H_1      | H_2          |              H_3 |
| :----------: | ------------ | ---------------: |
| Cell Content | Another Cell | Last Column Cell |
|     test     | test         |             test |
--]]
local expected_selections = {
	1, 7, 8, 9, 10, 11, 18, 19, 20, 21, 22, 46, 47, 48, 49, 50, 51,
	1, 3, 4, 5, 6, 7, 16, 18, 19, 20, 21, 22, 31, 33, 34, 35, 36, 37, 50, 51,
	1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
	1, 7, 8, 9, 10, 11, 12, 18, 19, 20, 21, 22, 23, 45, 46, 47, 48, 49, 50, 51,
	1,
}
	local n = 1
	for i, str in ipairs(doc.lines) do
		for j=1,#str do
			doc:set_selections(n, i, j, i, j)
			n = n + 1
		end
	end
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	Table.apply_table_format(doc, t_format)

	for idx, _, col1, _, col2, _ in doc:get_selections(false, true) do
		assert(col1 == expected_selections[idx])
		assert(col2 == expected_selections[idx])
	end

	return true
end)

apply_table_format_tests:add_test("Not surrounded table", "TODO", function()
	local doc = Doc()
	doc:text_input([[
 H_1  |  H_2  |  H_3
  :-:  |  ---  |  --:
   Cell Content  |  Another Cell  |  Last Column Cell
    test  |  test  |  test
]])
--[[
    H_1      | H_2          |              H_3
:----------: | ------------ | ---------------:
Cell Content | Another Cell | Last Column Cell
    test     | test         |             test
--]]
local expected_selections = {
	5, 6, 7, 8, 9, 16, 17, 18, 19, 20, 44, 45, 46, 47,
	1, 2, 3, 4, 14, 16, 17, 18, 19, 29, 31, 32, 33, 34, 47,
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
	5, 6, 7, 8, 9, 10, 16, 17, 18, 19, 20, 21, 43, 44, 45, 46, 47,
	1,
}
	local n = 1
	for i, str in ipairs(doc.lines) do
		for j=1,#str do
			doc:set_selections(n, i, j, i, j)
			n = n + 1
		end
	end
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	Table.apply_table_format(doc, t_format)

	for idx, _, col1, _, col2, _ in doc:get_selections(false, true) do
		assert(col1 == expected_selections[idx])
		assert(col2 == expected_selections[idx])
	end

	return true
end)

return apply_table_format_tests
