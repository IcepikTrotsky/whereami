local query_string = [[
		(function_declaration
	  name: (_) @ancestor.name
	) @ancestor
	]]
local query = vim.treesitter.query.parse("lua", query_string)

---@param node TSNode
---@return table<integer, TSNode[]>
local function get_ancestors(node)
	local ancestor = node:tree():root() ---@type TSNode?
	local ancestors = {}

	while ancestor do
		for _, match in query:iter_matches(ancestor, 0, nil, nil, { max_start_depth = 0 }) do
			table.insert(ancestors, match)
		end
		ancestor = ancestor:child_with_descendant(node)
	end

	return ancestors
end

---TODO: Show linecount of immediate parent
---@param node TSNode
local function build_node_path(node)
	local node_path = ""

	for _, ancestor in pairs(get_ancestors(node)) do
		for cap, nodes in pairs(ancestor) do
			-- TODO: How do we ensure that this function has access to
			-- this query without it being a global variable?
			if query.captures[cap] == "ancestor.name" then
				-- TODO: We're assuming that there will only ever be one node here
				node_path = node_path .. vim.treesitter.get_node_text(nodes[1], 0) .. " | "
			end
		end
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
