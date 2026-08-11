-- AI CLI panels.
--
-- Providers are entries in `M.providers`; each one can run several sessions at
-- once, and every session renders either as a float or as a right vertical
-- split (`M.toggle_layout`). Sessions are Snacks terminals keyed by
-- (cmd, cwd, count), so a session survives hiding and layout changes.

local root = require("utils.root")

local M = {}

---@class AiProvider
---@field label string
---@field cmd string[]
---@field pty_footer? integer rows to leave free when resizing a non-alt-screen pty
---@field float_top_padding? integer
---@field float_bottom_padding? integer

---@type table<string, AiProvider>
M.providers = {
  claude = {
    label = "Claude",
    cmd = { "claude", "--dangerously-skip-permissions" },
  },
  codex = {
    label = "Codex",
    cmd = { "codex", "--dangerously-bypass-approvals-and-sandbox", "--no-alt-screen" },
    -- codex draws inline instead of on the alt screen, so its pty needs an
    -- explicit resize and some slack under the composer
    pty_footer = 2,
    float_top_padding = 1,
    float_bottom_padding = 4,
  },
}

-- Picker order; the first entry is the default when NVIM_AI is unset.
M.order = { "claude", "codex" }

M.provider = os.getenv("NVIM_AI") or M.order[1]
M.layout = "float" ---@type "float"|"split"

local MAX_SESSIONS = 9

-- sessions[provider][n] = snacks.win
local sessions = {}
local last ---@type { provider: string, n: integer }|nil

local function label(name, n)
  return string.format("%s #%d", M.providers[name].label, n)
end

local function win_opts(name, n)
  local p = M.providers[name]

  if M.layout == "split" then
    return {
      position = "right",
      width = 0.42,
      border = "none",
      wo = { winbar = label(name, n) },
    }
  end

  local top = p.float_top_padding or 0
  local bottom = p.float_bottom_padding or 0
  local height = 0.85
  if top > 0 or bottom > 0 then
    height = function()
      return math.max(8, vim.o.lines - vim.o.cmdheight - top - bottom - 2)
    end
  end

  return {
    position = "float",
    width = 0.85,
    height = height,
    row = top > 0 and top or nil,
    border = "rounded",
    title = " " .. label(name, n) .. " ",
    title_pos = "center",
    wo = { winbar = "" },
  }
end

local function is_live(name, n)
  local win = sessions[name] and sessions[name][n]
  if win and win:buf_valid() then
    return win
  end
  if sessions[name] then
    sessions[name][n] = nil
  end
  return nil
end

--- Live sessions, in provider order.
---@return { provider: string, n: integer, win: snacks.win }[]
function M.list()
  local out = {}
  for _, name in ipairs(M.order) do
    for n = 1, MAX_SESSIONS do
      local win = is_live(name, n)
      if win then
        out[#out + 1] = { provider = name, n = n, win = win }
      end
    end
  end
  return out
end

local function resize_pty(win, name)
  local p = M.providers[name]
  if not (p and p.pty_footer) or not win:win_valid() then
    return
  end

  local job = vim.b[win.buf].terminal_job_id
  if not job then
    return
  end

  local width = vim.api.nvim_win_get_width(win.win)
  local height = math.max(8, vim.api.nvim_win_get_height(win.win) - p.pty_footer)
  pcall(vim.fn.jobresize, job, width, height)
end

local function refresh_ptys()
  vim.schedule(function()
    for _, s in ipairs(M.list()) do
      resize_pty(s.win, s.provider)
    end
  end)
end

--- Open (or focus) session `n` of `name`, creating the terminal if needed.
---@param name? string provider key; defaults to the active provider
---@param n? integer session number; defaults to the last one used
function M.open(name, n)
  name = name or M.provider
  local p = M.providers[name]
  if not p then
    vim.notify("Unknown AI provider: " .. tostring(name), vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(p.cmd[1]) ~= 1 then
    vim.notify(p.cmd[1] .. " is not on PATH", vim.log.levels.ERROR)
    return
  end

  n = n or (last and last.provider == name and last.n) or 1

  local win = is_live(name, n)
  if not win then
    win = Snacks.terminal.get(p.cmd, {
      cwd = root.get(),
      count = n,
      win = vim.tbl_extend("force", win_opts(name, n), {
        on_buf = function(self)
          vim.b[self.buf].ai_provider = name
          vim.b[self.buf].ai_session = n
        end,
        on_win = refresh_ptys,
      }),
    })
    sessions[name] = sessions[name] or {}
    sessions[name][n] = win
  end

  M.provider = name
  last = { provider = name, n = n }

  win:show():focus()
  refresh_ptys()
  return win
end

--- Toggle the most recently used panel: focus it, or hide it if it is focused.
function M.toggle()
  if _G.close_bottom_term_if_open and _G.close_bottom_term_if_open() then
    return
  end

  local win = last and is_live(last.provider, last.n)
  if win and win:valid() then
    if vim.api.nvim_get_current_buf() == win.buf then
      win:hide()
    else
      win:focus()
    end
    return
  end

  M.open(last and last.provider, last and last.n)
end

--- Start a new session for `name` in the first free slot.
function M.new(name)
  name = name or M.provider
  for n = 1, MAX_SESSIONS do
    if not is_live(name, n) then
      return M.open(name, n)
    end
  end
  vim.notify(("Already at %d %s sessions"):format(MAX_SESSIONS, name), vim.log.levels.WARN)
end

--- Pick from live sessions and "new session" entries for every provider.
function M.pick()
  local items = {}
  for _, s in ipairs(M.list()) do
    items[#items + 1] = {
      text = ("%s%s"):format(label(s.provider, s.n), s.win:valid() and "" or "  (hidden)"),
      run = function()
        M.open(s.provider, s.n)
      end,
    }
  end
  for _, name in ipairs(M.order) do
    items[#items + 1] = {
      text = ("+ new %s session"):format(M.providers[name].label),
      run = function()
        M.new(name)
      end,
    }
  end

  vim.ui.select(items, {
    prompt = "AI session",
    format_item = function(item)
      return item.text
    end,
  }, function(item)
    if item then
      item.run()
    end
  end)
end

--- Cycle focus through live sessions across all providers.
function M.cycle(step)
  local live = M.list()
  if #live == 0 then
    return M.open()
  end

  local idx = 1
  for i, s in ipairs(live) do
    if last and s.provider == last.provider and s.n == last.n then
      idx = i
    end
  end

  local next_session = live[((idx - 1 + step) % #live) + 1]
  M.open(next_session.provider, next_session.n)
end

--- Re-lay out every session as a float or as a right vertical split.
---@param layout "float"|"split"
function M.set_layout(layout)
  M.layout = layout

  for _, s in ipairs(M.list()) do
    local shown = s.win:valid()
    local focused = shown and vim.api.nvim_get_current_win() == s.win.win

    if shown then
      s.win:hide()
    end
    s.win.opts = vim.tbl_deep_extend("force", s.win.opts, win_opts(s.provider, s.n))
    if shown then
      s.win:show()
      if focused then
        s.win:focus()
      end
    end
  end

  refresh_ptys()
  vim.notify("AI panels: " .. (layout == "split" and "right split" or "float"))
end

function M.toggle_layout()
  M.set_layout(M.layout == "float" and "split" or "float")
end

--- Hide every visible panel. Returns true if anything was hidden.
function M.hide_all()
  local hid = false
  for _, s in ipairs(M.list()) do
    if s.win:valid() then
      s.win:hide()
      hid = true
    end
  end
  return hid
end

local function current_session()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.b[buf].ai_provider
  if name then
    return is_live(name, vim.b[buf].ai_session)
  end
  return last and is_live(last.provider, last.n)
end

--- Paste text into the active session without submitting it.
local function send(text)
  local win = current_session() or M.open()
  if not win then
    return
  end

  local job = vim.b[win.buf].terminal_job_id
  if not job then
    return
  end

  win:show()
  -- bracketed paste, so multi-line text lands as one block instead of being
  -- submitted line by line
  vim.fn.chansend(job, "\27[200~" .. text .. "\27[201~")
end

local function relative_path(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end

  local prefix = root.get() .. "/"
  if name:sub(1, #prefix) == prefix then
    return name:sub(#prefix + 1)
  end
  return vim.fn.fnamemodify(name, ":~:.")
end

--- Send the visual selection to the active session.
function M.send_selection()
  local save = vim.fn.getreg("a")
  local save_type = vim.fn.getregtype("a")
  vim.cmd('noautocmd normal! "ay')
  local text = vim.fn.getreg("a")
  vim.fn.setreg("a", save, save_type)

  if text ~= "" then
    send(text)
  end
end

--- Send the current buffer as an @-mention.
function M.add_buffer()
  local path = relative_path(vim.api.nvim_get_current_buf())
  if not path then
    vim.notify("Buffer has no file path", vim.log.levels.WARN)
    return
  end
  send("@" .. path .. " ")
end

--- Provider/session label for statuslines, e.g. "Claude #1".
function M.status()
  if not last then
    return M.providers[M.provider] and M.providers[M.provider].label or M.provider
  end
  return label(last.provider, last.n)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("AiPanels", { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "TermOpen", "WinEnter" }, {
    group = group,
    callback = refresh_ptys,
  })

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end

  map("n", "<leader>cc", M.toggle, "Toggle AI panel")
  map("n", "<leader>cp", M.pick, "Pick AI provider / session")
  map("n", "<leader>cn", function() M.new() end, "New AI session")
  map("n", "<leader>cw", M.toggle_layout, "AI panel: float <-> right split")
  map("n", "<leader>cj", function() M.cycle(1) end, "Next AI session")
  map("n", "<leader>ck", function() M.cycle(-1) end, "Previous AI session")
  map("x", "<leader>cs", M.send_selection, "Send selection to AI")
  map("n", "<leader>cb", M.add_buffer, "Send buffer path to AI")

  map({ "n", "t" }, "<C-]>", function()
    if not vim.b[vim.api.nvim_get_current_buf()].ai_provider then
      return
    end
    if vim.api.nvim_get_mode().mode == "t" then
      vim.cmd("stopinsert")
    end
    M.hide_all()
  end, "Hide AI panel")

  vim.api.nvim_create_user_command("AI", function(opts)
    if opts.args == "" then
      M.toggle()
    else
      M.open(opts.args)
    end
  end, {
    nargs = "?",
    complete = function()
      return M.order
    end,
    desc = "Toggle or open an AI provider panel",
  })

  vim.api.nvim_create_user_command("AILayout", function(opts)
    if opts.args == "" then
      M.toggle_layout()
    else
      M.set_layout(opts.args == "split" and "split" or "float")
    end
  end, {
    nargs = "?",
    complete = function()
      return { "float", "split" }
    end,
    desc = "Switch AI panels between float and right split",
  })
end

return M
