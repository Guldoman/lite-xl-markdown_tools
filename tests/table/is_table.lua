local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local is_table_tests = TestLib("Table.is_table Tests")

local Doc = require "core.doc"
---@type Table
local Table = require "plugins.markdown_tools.table"

is_table_tests:add_test("Generic test", function()
	local doc = Doc()
	doc:text_input([[
Hello
this is not part of the table
|but has random | pipes |

|H1|H2|H3|
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |

]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end
	for i=5,8 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 5)
		assert(res.line2 == 8)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	for i=9,10 do
		assert(Table.is_table(doc.lines, i) == false)
	end
	return true
end)

is_table_tests:add_test("Table surrounded", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
---|---|---
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table with one column", function()
	local doc = Doc()
	doc:text_input([[
|H1|
|---|
|c1 |
|c1 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 1)
	end
	return true
end)

is_table_tests:add_test("Table with one column not surrounded", "SKIP", "Unclear how to deal with this", function()
	local doc = Doc()
	doc:text_input([[
H1
---
c1
c1
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 1)
	end
	return true
end)

is_table_tests:add_test("Table without any data rows", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|---|---|
]])
	for i=1,2 do
		local res = Table.is_table(doc.lines, i)
		assert(res == false) -- TODO: check the reason
	end
	return true
end)

is_table_tests:add_test("Table with broken header", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3|
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end
	return true
end)

is_table_tests:add_test("Table with wrong number of header fields", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|H4|
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end
	return true
end)

is_table_tests:add_test("Table with broken header separator", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|---|---
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---||---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		assert(Table.is_table(doc.lines, i) == false)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with leading whitespace", function()
	local doc = Doc()
	doc:text_input([[
  |H1|H2|H3|
  |---|---|---|
  |c1 |c2 |c3 |
  |c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
	|H1|H2|H3|
	|---|---|---|
	|c1 |c2 |c3 |
	|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
	|H1|H2|H3|
  |---|---|---|
	|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with trailing whitespace", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|  
|---|---|---|  
|c1 |c2 |c3 |  
|c1 |c2 |c3 |  
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3|	
|---|---|---|	
|c1 |c2 |c3 |	
|c1 |c2 |c3 |	
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
	|H1|H2|H3|	
  |---|---|---|  
	|c1 |c2 |c3 |	
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with alignment", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|:---|---:|:---:|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with alignment", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
:---|---:|:---:
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
H1|H2|H3
:--:|:---|:----
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with minimal alignment", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
:--|--:|:-:
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
H1|H2|H3
:-:|--:|:--
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
H1|H2|H3
 :-: | --: | :-- 
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with bad alignment", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|-:-|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res == false)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|:|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res == false)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with bad alignment", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
---|-:-|---
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res == false)
	end

	doc = Doc()
	doc:text_input([[
H1|H2|H3
---|:|---
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res == false)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with escaped pipes",
                        "SKIP", "Handling of escaped pipes not yet implemented", function()
	local doc = Doc()
	doc:text_input([[
|H1\||H2|H3|
|---|---|---|
|c1 |c2\| |c3 |
|c1 |c2 |c3\| |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with escaped pipes",
                        "SKIP", "Handling of escaped pipes not yet implemented", function()
	local doc = Doc()
	doc:text_input([[
H1\||H2|H3
---|---|---
c1 |c2\| |c3
c1 |c2 |c3\|
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with empty header", function()
	local doc = Doc()
	doc:text_input([[
| | | |
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
||||
|---|---|---|
|c1 |c2 |c3 |
|c1 |c2 |c3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table surrounded with empty data rows", function()
	local doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|---|---|
| | | |
| | | |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
|H1|H2|H3|
|---|---|---|
||||
||||
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with empty header",
                        "SKIP", "How to handle the similarity with a surrounded table", function()
	local doc = Doc()
	doc:text_input([[
 | | 
---|---|---
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
||
---|---|---
c1 |c2 |c3
c1 |c2 |c3
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Table not surrounded with empty data rows",
                        "SKIP", "How to handle the similarity with a surrounded table", function()
	local doc = Doc()
	doc:text_input([[
H1|H2|H3
---|---|---
 | | 
 | | 
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end

	doc = Doc()
	doc:text_input([[
H1|H2|H3
---|---|---
||
||
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Surrounded table with multi-byte characters", function()
	local doc = Doc()
	doc:text_input([[
|à1|è2|ì3|
|---|---|---|
|ò1 |ù2 |é3 |
|ç1 |€2 |£3 |
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Not surrounded table with multi-byte characters", function()
	local doc = Doc()
	doc:text_input([[
à1|è2|ì3
---|---|---
ò1 |ù2 |é3
ç1 |€2 |£3
]])
	for i=1,4 do
		local res = Table.is_table(doc.lines, i)
		assert(res)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == false)
		assert(res.n_cols == 3)
	end
	return true
end)

is_table_tests:add_test("Surrounded table with escaped pipes", function()
	local doc = Doc()
	doc:text_input([[
|H\|1|H\|2|H\|3|
|---|---|---|
|c\|1 |c\|2 |c\|3 |
|c\|1 |c\|2 |c\|3 |
]])
	for i=1,4 do
		local res, reason = Table.is_table(doc.lines, i)
		assert(res, reason)
		assert(res.line1 == 1)
		assert(res.line2 == 4)
		assert(res.surrounded == true)
		assert(res.n_cols == 3)
	end
	return true
end)

return is_table_tests
