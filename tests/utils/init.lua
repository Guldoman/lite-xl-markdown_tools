local TestLib = require "plugins.markdown_tools.tests.testlib"
local format =  require "plugins.markdown_tools.tests.utils.format"
local split =  require "plugins.markdown_tools.tests.utils.split"

---@type TestLib
local utils_tests = TestLib("Utils Tests")
utils_tests:add_test(format)
utils_tests:add_test(split)

return utils_tests
