---TODO: Onlyf get ancestors that match some properties, like being a function
---@param node TSNode
local function get_ancestors(node)
	local ancestor = node:tree():root() ---@type TSNode?
	local ancestors = {}

	while ancestor do
		table.insert(ancestors, ancestor)
		ancestor = ancestor:child_with_descendant(node)
	end

	return ancestors
end

---TODO: Show function names etc rather than node types
---TODO: Show linecount of immediate parent
---@param node TSNode
local function build_node_path(node)
	local node_path = ""

	for _, ancestor in pairs(get_ancestors(node)) do
		node_path = node_path .. ancestor:type() .. " | "
	end

	return node_path
end

vim.api.nvim_create_autocmd(
	{ "CursorHold", "CursorHoldI" },
	{
		callback = function()
			local current_node = vim.treesitter.get_node()
			if not current_node then
				return
			end

			local start = vim.uv.hrtime()
			local winbar_text = build_node_path(current_node)
			local duration = (vim.uv.hrtime() - start) / 1000

			vim.opt_local.winbar = winbar_text .. string.format("(%d us)", duration)
		end
	}
)
