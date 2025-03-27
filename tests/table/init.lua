local TestLib = require "plugins.markdown_tools.tests.testlib"
local is_table = require "plugins.markdown_tools.tests.table.is_table"
local get_table_info = require "plugins.markdown_tools.tests.table.get_table_info"
local build_table_format = require "plugins.markdown_tools.tests.table.build_table_format"
local apply_table_format = require "plugins.markdown_tools.tests.table.apply_table_format"

---@type TestLib
local table_tests = TestLib("Table Tests")
table_tests:add_test(is_table)
table_tests:add_test(get_table_info)
table_tests:add_test(build_table_format)
table_tests:add_test(apply_table_format)

return table_tests
