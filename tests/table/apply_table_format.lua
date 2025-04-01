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
		1, 3, 4, 5, 15, 16, 18, 19, 20, 30, 31, 33, 34, 35, 49, 50, 51,
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

	for idx, _, col1, _, col2, _ in doc:get_selections(false, false) do
		assert(col1 == expected_selections[idx])
		assert(col2 == expected_selections[idx])
	end

	return true
end)

apply_table_format_tests:add_test("Not surrounded table", function()
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
		6, 7, 8, 9, 10, 17, 18, 19, 20, 21, 45, 46, 47, 48,
		2, 3, 4, 14, 15, 17, 18, 19, 29, 30, 32, 33, 34, 48,
		2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
		6, 7, 8, 9, 10, 11, 17, 18, 19, 20, 21, 22, 44, 45, 46, 47, 48,
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

	for idx, _, col1, _, col2, _ in doc:get_selections(false, false) do
		assert(col1 == expected_selections[idx])
		assert(col2 == expected_selections[idx])
	end

	return true
end)

apply_table_format_tests:add_test("Surrounded table don't go to next cell", function()
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
	doc:set_selection(1, 10, 1, 10)
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	Table.apply_table_format(doc, t_format)

	local _, col1, _, col2 = doc:get_selection(false, false)
	assert(col1 == 11)
	assert(col2 == 11)

	return true
end)

apply_table_format_tests:add_test("Not surrounded table don't go to next cell", function()
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
	doc:set_selection(1, 7, 1, 7)
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	Table.apply_table_format(doc, t_format)

	local _, col1, _, col2 = doc:get_selection(false, false)
	assert(col1 == 10)
	assert(col2 == 10)

	return true
end)

apply_table_format_tests:add_test("Not surrounded table add last space", function()
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
	doc:set_selections(1, 1, 22, 1, 22)
	doc:set_selections(2, 3, 55, 3, 55)
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	Table.apply_table_format(doc, t_format)

	for _, _, col1, _, col2, _ in doc:get_selections(false, false) do
		assert(col1 == 49)
		assert(col2 == 49)
	end
	assert(#doc.lines[1] == 49)
	assert(#doc.lines[2] == 48)
	assert(#doc.lines[3] == 49)
	assert(#doc.lines[4] == 48)

	return true
end)

apply_table_format_tests:add_test("Surrounded table selections", function()
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
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	local n = 1
	for i, row in ipairs(t_format.rows) do
		local line1 = t_format.line1 + i - 1
		for _, cell in ipairs(row) do
			local col1 = cell.cell_start + cell.offset_start
			local col2 = col1 + #cell.text
			doc:set_selections(n, line1, col1, line1, col2)
			n = n + 1
		end
	end

	local expected_selections = { }
	for i, row in ipairs(t_format.formatted_rows) do
		local line1 = t_format.line1 + i - 1
		for _, cell in ipairs(row) do
			local col1 = cell.cell_start + cell.offset_start
			local col2 = col1 + #cell.text
			table.insert(expected_selections, {
				line1 = line1,
				col1 = col1,
				line2 = line1,
				col2 = col2,
			})
		end
	end
	Table.apply_table_format(doc, t_format)

	for idx, line1, col1, line2, col2 in doc:get_selections(false, false) do
		assert(line1 == expected_selections[idx].line1)
		assert(col1 == expected_selections[idx].col1)
		assert(line2 == expected_selections[idx].line2)
		assert(col2 == expected_selections[idx].col2)
	end

	return true
end)

apply_table_format_tests:add_test("Not surrounded table selections", function()
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
	local t_loc = assert(Table.is_table(doc.lines, 1))
	local t_info = assert(Table.get_table_info(doc.lines, t_loc))
	local t_format = assert(Table.build_table_format(t_info))
	local n = 1
	for i, row in ipairs(t_format.rows) do
		local line1 = t_format.line1 + i - 1
		for _, cell in ipairs(row) do
			local col1 = cell.cell_start + cell.offset_start
			local col2 = col1 + #cell.text
			doc:set_selections(n, line1, col1, line1, col2)
			n = n + 1
		end
	end

	local expected_selections = { }
	for i, row in ipairs(t_format.formatted_rows) do
		local line1 = t_format.line1 + i - 1
		for _, cell in ipairs(row) do
			local col1 = cell.cell_start + cell.offset_start
			local col2 = col1 + #cell.text
			table.insert(expected_selections, {
				line1 = line1,
				col1 = col1,
				line2 = line1,
				col2 = col2,
			})
		end
	end
	Table.apply_table_format(doc, t_format)

	for idx, line1, col1, line2, col2 in doc:get_selections(false, false) do
		assert(line1 == expected_selections[idx].line1)
		assert(col1 == expected_selections[idx].col1)
		assert(line2 == expected_selections[idx].line2)
		assert(col2 == expected_selections[idx].col2)
	end

	return true
end)

return apply_table_format_tests
