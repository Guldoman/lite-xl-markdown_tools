local TestLib = require "plugins.markdown_tools.tests.testlib"

---@type TestLib
local split_tests = TestLib("Utils.format Tests")

---@type Utils
local Utils = require "plugins.markdown_tools.utils"

split_tests:add_test("Simple Split", function()
	local text = {
		"Hello world",
		"How are you doing"
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n")
	assert(#result == #text)
	for i, line in ipairs(text) do
		assert(result[i] == line, result[i])
	end
	assert(#token_indexes == 1)
	assert(token_indexes[1] == #text[1] + 1, token_indexes[1])
	return true
end)

split_tests:add_test("Split with no final value", function()
	local text = {
		"Hello world",
		"How are you doing",
		""
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n")
	assert(#result == #text)
	for i, line in ipairs(text) do
		assert(result[i] == line, result[i])
	end
	assert(#token_indexes == 2)
	assert(token_indexes[1] == #text[1] + 1, token_indexes[1])
	assert(token_indexes[2] == #text[1] + #text[2] + 2, token_indexes[2])
	return true
end)

return split_tests
