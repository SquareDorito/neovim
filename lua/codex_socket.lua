local M = {}

local function project_root()
  local cwd = vim.fn.getcwd()
  local git_root = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end

  return vim.fs.root(0, { ".git", "pyrightconfig.json", "pyproject.toml", "package.json", "tsconfig.json" }) or cwd
end

local function socket_path(root)
  local dir = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-codex"
  vim.fn.mkdir(dir, "p")

  local name = vim.fn.fnamemodify(root, ":t")
  local hash = vim.fn.sha256(root):sub(1, 10)
  return string.format("%s/%s-%s.sock", dir, name, hash)
end

local function warmup_files(root)
  return {
    root .. "/rebal/imports.py",
    root .. "/dashboard/src/index.tsx",
    root .. "/src/index.tsx",
    root .. "/src/main.tsx",
    root .. "/src/index.ts",
    root .. "/src/main.ts",
  }
end

function M.start()
  local root = project_root()
  local socket = socket_path(root)

  pcall(vim.fn.serverstart, socket)
  vim.g.codex_root = root
  vim.g.codex_socket = socket

  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      for _, path in ipairs(warmup_files(root)) do
        if vim.fn.filereadable(path) == 1 then
          local bufnr = vim.fn.bufadd(path)
          if not vim.api.nvim_buf_is_loaded(bufnr) then
            vim.bo[bufnr].swapfile = false
          end
          pcall(vim.fn.bufload, bufnr)
          if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "" then
            local filetype = vim.filetype.match({ filename = path, buf = bufnr })
            if filetype then
              vim.bo[bufnr].filetype = filetype
            end
          end
          vim.bo[bufnr].buflisted = false
        end
      end
    end,
  })
end

return M
