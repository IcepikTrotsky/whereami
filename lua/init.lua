local M = {}

---Represents the ancestor of some node.
---@class Ancestor
---@field name TSNode
---@field definition TSNode

local query_string = [[
		(function_declaration
	  name: (_) @ancestor.name
	) @ancestor
	]]
local query = vim.treesitter.query.parse("lua", query_string)

---@param node TSNode
---@return Ancestor[]
local function get_ancestors(node)
  local ancestor = node:tree():root() ---@type TSNode?
  local ancestors = {} ---@type Ancestor[]

  while ancestor do
    for _, match in query:iter_matches(ancestor, 0, nil, nil, { max_start_depth = 0 }) do
      local anc = {}
      for cap, nodes in pairs(match) do
        if query.captures[cap] == "ancestor.name" then
          anc.name = nodes[1]
        elseif query.captures[cap] == "ancestor" then
          anc.definition = nodes[1]
        end
      end
      table.insert(ancestors, anc)
    end
    ancestor = ancestor:child_with_descendant(node)
  end

  return ancestors
end

---TODO: Show linecount of immediate parent
---@param node TSNode
local function build_node_path(node)
  local node_path = ""
  local ancestors = get_ancestors(node)

  if #ancestors == 0 then
    return ""
  end

  for _, ancestor in pairs(ancestors) do
    node_path = node_path .. vim.treesitter.get_node_text(ancestor.name, 0) .. " | "
  end

  return node_path
end

function M.enable()
  local group = vim.api.nvim_create_augroup("WhereAmI", { clear = false })

  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    -- TODO: When other languages are supported, how do we keep this
    -- pattern up to date?
    pattern = "*.lua",
    callback = function()
      local current_node = vim.treesitter.get_node()
      if not current_node then
        return
      end

      local start = vim.uv.hrtime()
      local winbar_text = build_node_path(current_node)
      local duration = (vim.uv.hrtime() - start) / 1000

      vim.opt_local.winbar = winbar_text .. string.format("(%d us)", duration)
    end,
  })
end

function M.disable()
  -- TODO: Does this work if the auto group doesn't exist?
  vim.api.nvim_del_augroup_by_name "WhereAmI"
end

return M
