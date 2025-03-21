-- mod-version:3

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local common = require "core.common"
local config = require "core.config"

local DocView = require "core.docview"

local MarkdownTools = {}

config.plugins.markdown_tools = common.merge({
	bold_style = "**",
	italic_style = "__",
	strike_style = "~~",
	math_style = { "$", "$" },
	mathblock_style = { "$$", "$$" },
	-- TODO: bullet points and numbered lists (maybe even different style per indent size)
	-- TODO: table formatting modes:
	--       * automatic (every table gets formatted without any user interaction)
	--       * manual (format on command execution)
	--       * on-interaction (format when the table content gets modified)
}, config.plugins.markdown_tools)

function MarkdownTools.is_view_supported()
	if not core.active_view or not core.active_view:extends(DocView) then
		return false
	end
	local docview = core.active_view
	if not docview.doc.syntax or not docview.doc.syntax.name == "Markdown" then
		return false
	end
	return true, docview
end

---@param chars string | [string, string]
---@param doc core.doc
---@param line1 integer
---@param col1 integer
---@param line2 integer
---@param col2 integer
---@return integer line1, integer col1, integer line2, integer col2
local function surround(chars, doc, line1, col1, line2, col2)
	local starter, ender = chars, chars
	if type(chars) == "table" then
		starter = chars[1]
		ender = chars[2]
	end
	local nchars = #starter
	doc:insert(line1, col1, starter)
	if line1 == line2 then col2 = col2 + nchars end
	doc:insert(line2, col2, ender)
	return line1, col1 + nchars, line2, col2
end

---@param doc core.doc
---@param chars string | [string, string]
local function surround_all(doc, chars)
	for idx, line1, col1, line2, col2, swap in doc:get_selections(true, true) do
		line1, col1, line2, col2 = surround(chars, doc, line1 --[[@as integer]], col1, line2, col2)
		doc:set_selections(idx, line1, col1, line2, col2, swap)
	end
end

command.add(MarkdownTools.is_view_supported, {
	["markdown-tools:embolden"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.bold_style)
	end,
	["markdown-tools:italicize"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.italic_style)
	end,
	["markdown-tools:strike"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.strike_style)
	end,
	["markdown-tools:math"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.math_style)
	end,
	["markdown-tools:mathblock"] = function(dv)
		surround_all(dv.doc, config.plugins.markdown_tools.mathblock_style)
	end,
})

keymap.add {
	["ctrl+b"] = "markdown-tools:embolden",
	["ctrl+i"] = "markdown-tools:italicize",
}

return MarkdownTools
