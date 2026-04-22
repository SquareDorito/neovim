local M = {}

function M.get()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

  if vim.v.shell_error ~= 0 or not root or root == "" then
    return vim.fn.getcwd()
  end

  return root
end

return M
