local M = {}

---Represents the ancestor of some node.
---@class Ancestor
---@field name TSNode
---@field definition TSNode

---@param node TSNode
---@return Ancestor[]
local function get_ancestors(node)
  local parser = vim.treesitter.get_parser(0)
  if not parser then
    return {}
  end

  -- TODO: Will the first tree always be the one that we want?
  -- What does it actually mean if there are multiple?
  local tree = parser:parse()[1]
  local ancestor = tree:root() ---@type TSNode?
  local ancestors = {} ---@type Ancestor[]

  -- TODO: Where is the best place to manage queries?
  local query = vim.treesitter.query.get(parser:lang(), "whereami")
  if not query then
    return ancestors
  end


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

  local parent = ancestors[#ancestors].definition
  local start_row, _, end_row = parent:range()
  local cursor = vim.api.nvim_win_get_cursor(0)

  node_path = node_path .. string.format("(line %d/%d)", cursor[1] - start_row, end_row - start_row + 1)

  return node_path
end

function M.enable()
  local group = vim.api.nvim_create_augroup("WhereAmI", { clear = false })

  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    -- TODO: When other languages are supported, how do we keep this
    -- pattern up to date?
    pattern = { "*.lua", "*.php" },
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

function M.setup()
  vim.api.nvim_create_user_command(
    "WhereAmI",
    function(args)
      if args.args == "enable" then
        M.enable()
      elseif args.args == "disable" then
        M.disable()
      else
        vim.notify("Invalid argument: " .. args.args)
      end
    end,
    {
      nargs = 1,
      complete = function() return { "enable", "disable" } end,
    }
  )
end

return M
