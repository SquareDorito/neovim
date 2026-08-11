local M = {}

local function parse_worktrees(lines)
  local worktrees = {}
  local current = nil

  local function finish()
    if current then
      table.insert(worktrees, current)
      current = nil
    end
  end

  for _, line in ipairs(lines) do
    if line == "" then
      finish()
    else
      local path = line:match("^worktree (.+)$")
      local branch = line:match("^branch refs/heads/(.+)$")
      local head = line:match("^HEAD (.+)$")

      if path then
        finish()
        current = {
          path = path,
          branch = "",
          head = "",
          detached = false,
          bare = false,
        }
      elseif current and branch then
        current.branch = branch
      elseif current and head then
        current.head = head
      elseif current and line == "detached" then
        current.detached = true
      elseif current and line == "bare" then
        current.bare = true
      end
    end
  end

  finish()

  table.sort(worktrees, function(a, b)
    return a.path < b.path
  end)

  return worktrees
end

local function tab_for_path(path)
  local normalized = vim.fs.normalize(path)

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local cwd = vim.fn.getcwd(-1, tabnr)

    if vim.fs.normalize(cwd) == normalized then
      return tab
    end
  end

  return nil
end

local function label(item)
  local suffix = item.branch

  if suffix == "" and item.detached and item.head ~= "" then
    suffix = "detached " .. item.head:sub(1, 8)
  elseif suffix == "" and item.bare then
    suffix = "bare"
  end

  if suffix ~= "" then
    return item.path .. "  [" .. suffix .. "]"
  end

  return item.path
end

local function open_worktree(item)
  local existing_tab = tab_for_path(item.path)

  if existing_tab then
    vim.api.nvim_set_current_tabpage(existing_tab)
  else
    vim.cmd("tabnew")
    vim.cmd("tcd " .. vim.fn.fnameescape(item.path))
  end

  local ok = pcall(require, "neo-tree.command")

  if ok then
    require("neo-tree.command").execute({
      action = "show",
      dir = item.path,
    })
  else
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  end
end

function M.select()
  local lines = vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })

  if vim.v.shell_error ~= 0 then
    vim.notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end

  local worktrees = parse_worktrees(lines)

  if #worktrees == 0 then
    vim.notify("No git worktrees found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(worktrees, {
    prompt = "Git worktrees",
    format_item = label,
  }, function(item)
    if item then
      open_worktree(item)
    end
  end)
end

return M
