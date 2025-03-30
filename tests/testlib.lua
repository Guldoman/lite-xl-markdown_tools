local Object = require "core.object"

---@class TestLib : core.object
---@field protected name string
---@field protected before_all test_cb
---@field protected after_all test_cb
---@field protected before_each test_cb
---@field protected after_each test_cb
---@field protected output_fn fun(string)
---@field protected callback_data any
---@field protected directives_allowed_to_fail table<string, boolean>
---@field protected tests table[test]
local TestLib = Object:extend()

---@alias callback_data any

---@alias test_cb fun(TestLib, callback_data)

---@alias positive_test_fn fun(): true
---@alias negative_test_fn fun(): false, string?
---@alias test_fn (positive_test_fn | negative_test_fn)
---@alias testable test_fn | TestLib

---@alias test_directives "SKIP" | "TODO"

---@class test
---@field fn testable
---@field description? string
---@field directive? test_directives
---@field directive_reason? string

local function noop()
end

local function to_stdout(str)
	print(str)
end

---@protected
function TestLib:new(name, options)
	options = options or { }
	---@type string
	self.name = name
	self.before_all = options.before_all or noop
	self.after_all = options.after_all or noop
	self.before_each = options.before_each or noop
	self.after_each = options.after_each or noop

	self.output_fn = options.output_fn or to_stdout
	self.callback_data = options.callback_data

	self.indent_string = options.indent_string or "    "

	self.directives_allowed_to_fail = options.directives_allowed_to_fail or {
		SKIP = true,
		TODO = true,
	}

	self.tests = { }
end

function TestLib:set_before_all(cb)
	self.before_all = cb
end

function TestLib:set_after_all(cb)
	self.after_all = cb
end

function TestLib:set_before_each(cb)
	self.before_each = cb
end

function TestLib:set_after_each(cb)
	self.after_each = cb
end

function TestLib:set_callback_data(data)
	self.callback_data = data
end

---@override fun(test: testable)
---@override fun(name: string, test: testable)
---@override fun(name: string, directive: test_directive, test: testable)
function TestLib:add_test(...)
	local args = { ... }
	local fn, description, directive, directive_reason
	if #args == 1 then
		fn = args[1]
	elseif #args == 2 then
		description = args[1]
		fn = args[2]
	elseif #args == 3 then
		description = args[1]
		directive = args[2]
		fn = args[3]
	elseif #args == 4 then
		description = args[1]
		directive = args[2]
		directive_reason = args[3]
		fn = args[4]
	else
		error("Wrong number of parameters")
	end
	table.insert(self.tests, {
		fn = fn,
		description = description,
		directive = directive,
		directive_reason = directive_reason,
	})
end

function TestLib:run()
	self.output_fn("TAP version 14")
	self:run_indented(0)
end

function TestLib:get_indented(str, level)
	local res = { }
	for s in string.gmatch(str, "(.*)\n?") do
		table.insert(res, string.rep(self.indent_string, level) .. s)
	end
	return table.concat(res, "\n")
end

function TestLib:get_test_message(test)
	local message = ""
	if test.description then
		message = message .. " - " .. test.description
	end
	if test.directive then
		message = message .. " # " .. test.directive
		if test.directive_reason then
			message = message .. " " .. test.directive_reason
		end
	end
	return message
end

---@protected
---@param level integer
function TestLib:run_indented(level)
	local failed_tests = { }
	local failed_message
	self.output_fn(self:get_indented("# " .. self.name, level))
	self.output_fn(self:get_indented("1.." .. #self.tests, level))
	self.before_all()
	for i, t in ipairs(self.tests) do
		---@cast t test
		if type(t.fn) ~= "function" then
			local tl = t.fn
			---@cast tl TestLib
			t.fn = function()
				return tl:run_indented(level + 1)
			end
		end
		local completed, a, b, result, message
		if t.directive == "SKIP" then
			goto continue
		end
		self.before_each()
		completed, a, b = xpcall(t.fn --[[@as test_fn]], function(msg)
			print(">>>", debug.traceback("", 2))
			print("---->", msg)
		end)
		if not completed then
			result = false
			message = a
		else
			result = a
			message = b
		end
		-- TODO: print error message somewhere better
		if not result and not self.directives_allowed_to_fail[t.directive] then
			table.insert(failed_tests, i)
			self.output_fn(self:get_indented(string.format("# %s", message), level))
		end
		self.after_each()
		::continue::
		local output_line = string.format("%sok %d%s", result and "" or "not ", i, self:get_test_message(t))
		self.output_fn(self:get_indented(output_line, level))
	end
	self.after_all()
	return #failed_tests == 0, failed_message
end

return TestLib
