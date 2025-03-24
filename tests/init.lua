local TestLib = require "plugins.markdown_tools.tests.testlib"
local table_tests = require "plugins.markdown_tools.tests.table"
local utils_tests = require "plugins.markdown_tools.tests.utils"

---@type TestLib
local t = TestLib("Tests")
t:add_test(table_tests)
t:add_test(utils_tests)
t:run()
