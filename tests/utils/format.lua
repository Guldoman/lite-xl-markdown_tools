local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local format_tests = TestLib("Utils.format Tests")

---@type Utils
local Utils = require "plugins.markdown_tools.utils"

format_tests:add_test("Left align", function()
	assert(Utils.format("test", "left", 10) == "test      ")
	assert(Utils.format(" test", "left", 10) == " test     ")
	return true
end)

format_tests:add_test("Right align", function()
	assert(Utils.format("test", "right", 10) == "      test")
	assert(Utils.format("test ", "right", 10) == "     test ")
	return true
end)

format_tests:add_test("Center align", function()
	local text, left, right
	text, left, right = Utils.format("test", "center", 10)
	assert(text == "   test   ")
	assert(left == 3)
	assert(right == 3)
	text, left, right = Utils.format("test ", "center", 10)
	assert(text  == "  test    ")
	assert(left == 2)
	assert(right == 3)
	text, left, right = Utils.format("test", "center", 11)
	assert(text == "   test    ")
	assert(left == 3)
	assert(right == 4)
	text, left, right = Utils.format("test1", "center", 11)
	assert(text == "   test1   ")
	assert(left == 3)
	assert(right == 3)
	text, left, right = Utils.format("test1", "center", 13)
	assert(text == "    test1    ")
	assert(left == 4)
	assert(right == 4)
	return true
end)

return format_tests
