local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local get_table_info_tests = TestLib("Table.get_table_info Tests")

local Doc = require "core.doc"
---@type Table
local Table = require "plugins.markdown_tools.table"

-- TODO: Write tests before progressing to actually formatting

--       Also for formatting, make a formatting "planner" function
--       that returns how the indexes change, which is then fed
--       to the actual formatter function that also handles doc carets

get_table_info_tests:add_test("Surrounded table", function()
	local doc = Doc()
	doc:text_input([[
|cell1|cell2|cell3|
|-----|-----|-----|
|cell4|cell5|cell6|
|cell7|cell8|cell9|
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for j, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.text == string.format("cell%d", n), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----", n))
			end
			assert(cell.cell_start == (j-1) * (#("cell0") + 1) + 2)
			assert(cell.offset_start == 0)
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 5)
	assert(t_info.max_lengths[2] == 5)
	assert(t_info.max_lengths[3] == 5)
	return true
end)

get_table_info_tests:add_test("Not surrounded table", function()
	local doc = Doc()
	doc:text_input([[
cell1|cell2|cell3
-----|-----|-----
cell4|cell5|cell6
cell7|cell8|cell9
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for j, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.text == string.format("cell%d", n), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----"))
			end
			assert(cell.cell_start == (j-1) * (#("cell0") + 1) + 1)
			assert(cell.offset_start == 0)
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 5)
	assert(t_info.max_lengths[2] == 5)
	assert(t_info.max_lengths[3] == 5)
	return true
end)

get_table_info_tests:add_test("Surrounded table with leading spaces", function()
	local doc = Doc()
	doc:text_input([[
 |3|5|7|
  |-----|-----|-----|
   |5|7|9|
  |4|6|8|
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for _, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.cell_start == tonumber(cell.text), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----"))
			end
			assert(cell.offset_start == 0)
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 1)
	assert(t_info.max_lengths[2] == 1)
	assert(t_info.max_lengths[3] == 1)
	return true
end)

get_table_info_tests:add_test("Not surrounded table with leading spaces", function()
	local doc = Doc()
	doc:text_input([[
 1|4|6
  -----|-----|-----
   1|6|8
    1|7|9
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for j, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.cell_start == tonumber(cell.text), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----"))
			end
			if j ~= 1 then
				assert(cell.offset_start == 0)
			else
				assert(cell.offset_start == i)
			end
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 1)
	assert(t_info.max_lengths[2] == 1)
	assert(t_info.max_lengths[3] == 1)
	return true
end)

get_table_info_tests:add_test("Surrounded table with escaped pipes",
                              "SKIP", "Handling of escaped pipes not yet implemented",
                              function()
	local doc = Doc()
	doc:text_input([[
|ce\|\|1|ce\|\|2|ce\|\|3|
|-----|-----|-----|
|ce\|\|4|ce\|\|5|ce\|\|6|
|ce\|\|7|ce\|\|8|ce\|\|9|
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for j, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.text == string.format([[ce\|\|%d]], n), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----", n))
			end
			assert(cell.cell_start == (j-1) * (#([[ce\|\|0]]) + 1) + 2)
			assert(cell.offset_start == 0)
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 7)
	assert(t_info.max_lengths[2] == 7)
	assert(t_info.max_lengths[3] == 7)
	return true
end)

get_table_info_tests:add_test("Not surrounded table with escaped pipes",
                              "SKIP", "Handling of escaped pipes not yet implemented",
                              function()
	local doc = Doc()
	doc:text_input([[
ce\|\|1|ce\|\|2|ce\|\|3
-----|-----|-----
ce\|\|4|ce\|\|5|ce\|\|6
ce\|\|7|ce\|\|8|ce\|\|9
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	local n = 1
	for i, row in ipairs(t_info.rows) do
		for j, cell in ipairs(row) do
			if i ~= 2 then
				assert(cell.text == string.format([[ce\|\|%d]], n), cell.text)
				n = n + 1
			else
				assert(cell.text == string.format("-----"))
			end
			assert(cell.cell_start == (j-1) * (#([[ce\|\|0]]) + 1) + 1)
			assert(cell.offset_start == 0)
			assert(cell.offset_end == 0)
		end
	end
	assert(n == 9 + 1, "Wrong number of cells")
	assert(t_info.alignments[1] == "left")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "left")
	assert(t_info.max_lengths[1] == 7)
	assert(t_info.max_lengths[2] == 7)
	assert(t_info.max_lengths[3] == 7)
	return true
end)

get_table_info_tests:add_test("Surrounded table alignments", function()
	local doc = Doc()
	doc:text_input([[
|cell1|cell2|cell3|cell1|
|:----|-----|----:|:---:|
|cell4|cell5|cell6|cell4|
|cell7|cell8|cell9|cell7|
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	assert(t_info.alignments[1] == "left-explicit")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "right")
	assert(t_info.alignments[4] == "center")
	return true
end)

get_table_info_tests:add_test("Not surrounded table alignments", function()
	local doc = Doc()
	doc:text_input([[
cell1|cell2|cell3|cell1
:----|-----|----:|:---:
cell4|cell5|cell6|cell4
cell7|cell8|cell9|cell7
]])
	local t_loc = assert(Table.is_table(doc, 1))
	local t_info = assert(Table.get_table_info(doc, t_loc))

	-- t_info should keep every field of t_loc
	for k, v in pairs(t_loc) do
		assert(t_info[k] == v)
	end

	assert(t_info.alignments[1] == "left-explicit")
	assert(t_info.alignments[2] == "left")
	assert(t_info.alignments[3] == "right")
	assert(t_info.alignments[4] == "center")
	return true
end)

return get_table_info_tests
