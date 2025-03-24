local TestLib = require "plugins.markdown_tools.tests.testlib"
local is_table = require "plugins.markdown_tools.tests.table.is_table"
local get_table_info = require "plugins.markdown_tools.tests.table.get_table_info"

---@type TestLib
local table_tests = TestLib("Table Tests")
table_tests:add_test(is_table)
table_tests:add_test(get_table_info)

return table_tests
