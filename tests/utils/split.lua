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

split_tests:add_test("Split with escape", function()
	local text = {
		"Hello world\\",
		"How are you doing",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 1, #result)
	assert(result[1] == table.concat(text, "\n"), result[1])
	assert(#token_indexes == 0)
	return true
end)

split_tests:add_test("Split with multiple escapes", function()
	local text = {
		"\\",
		"Hello world",
		"How are you doing\\",
		"\\",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 2, #result)
	assert(result[1] == table.concat({ text[1], text[2] }, "\n"), result[1])
	assert(result[2] == table.concat({ text[3], text[4] }, "\n"), result[2])
	assert(#token_indexes == 1)
	assert(token_indexes[1] == #text[1] + #text[2] + 2, token_indexes[1])
	return true
end)

split_tests:add_test("Split with every token escaped", function()
	local text = {
		"\\",
		"Hello world\\",
		"How are you doing\\",
		"\\",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 1, #result)
	assert(result[1] == table.concat(text, "\n"), result[1])
	assert(#token_indexes == 0)
	return true
end)

split_tests:add_test("Split with irrelevant escapes", function()
	local text = {
		"\\",
		"\\Hello\\ world\\",
		"\\How are\\ you doing\\",
		"\\",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 1, #result)
	assert(result[1] == table.concat(text, "\n"), result[1])
	assert(#token_indexes == 0)
	return true
end)

split_tests:add_test("Split with only escapes and tokens", function()
	local text = {
		"\\",
		"\\\\\\",
		"\\\\\\",
		"\\",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 1, #result)
	assert(result[1] == table.concat(text, "\n"), result[1])
	assert(#token_indexes == 0)
	return true
end)

split_tests:add_test("Split with only escapes", function()
	local text = {
		"\\\\\\\\\\\\\\\\",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "\\")
	assert(#result == 1, #result)
	assert(result[1] == table.concat(text, "\n"), result[1])
	assert(#token_indexes == 0)
	return true
end)

split_tests:add_test("Split with multi-characters token", function()
	local text = {
		"Hello world",
		"How are you doing"
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), " w")
	assert(#result == 2)
	assert(result[1] == "Hello", result[1])
	assert(result[2] == "orld\nHow are you doing")
	assert(#token_indexes == 1)
	assert(token_indexes[1] == 6, token_indexes[1])
	return true
end)

split_tests:add_test("Split with multi-characters escape", function()
	local text = {
		"Hello@#",
		"world",
		"How@#",
		"are",
		"you@#",
		"doing",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "@#")
	assert(#result == 3, #result)
	assert(result[1] == "Hello@#\nworld", result[1])
	assert(result[2] == "How@#\nare", result[2])
	assert(result[3] == "you@#\ndoing", result[3])
	assert(#token_indexes == 2)
	assert(token_indexes[1] == 14, token_indexes[1])
	assert(token_indexes[2] == 24, token_indexes[2])
	return true
end)

split_tests:add_test("Split with multi-characters escape with same character", function()
	local text = {
		"Hello--",
		"world",
		"How--",
		"are",
		"you--",
		"doing",
	}
	local result, token_indexes = Utils.split(table.concat(text, "\n"), "\n", "--")
	assert(#result == 3, #result)
	assert(result[1] == "Hello--\nworld", result[1])
	assert(result[2] == "How--\nare", result[2])
	assert(result[3] == "you--\ndoing", result[3])
	assert(#token_indexes == 2)
	assert(token_indexes[1] == 14, token_indexes[1])
	assert(token_indexes[2] == 24, token_indexes[2])
	return true
end)

return split_tests
