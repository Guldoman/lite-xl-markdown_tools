local TestLib = require "plugins.markdown_tools.tests.testlib"
local format =  require "plugins.markdown_tools.tests.utils.format"

---@type TestLib
local utils_tests = TestLib("Utils Tests")
utils_tests:add_test(format)

return utils_tests
