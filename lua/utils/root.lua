local M = {}

function M.get()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

  if vim.v.shell_error ~= 0 or not root or root == "" then
    return vim.fn.getcwd()
  end

  return root
end

-- Additional workspace folders that should be visible alongside the project
-- root, mirroring the "folders" list in *.code-workspace files.
function M.get_extras()
  local extras = {}
  local notebooks = vim.fn.expand("~/notebooks")

  if vim.fn.isdirectory(notebooks) == 1 then
    table.insert(extras, notebooks)
  end

  return extras
end

function M.get_all()
  local all = { M.get() }
  vim.list_extend(all, M.get_extras())
  return all
end

return M
