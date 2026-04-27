return {
  {
    "linrongbin16/gitlinker.nvim",
    cmd = { "GitLink" },
    keys = {
      { "<leader>gy", "<cmd>GitLink<cr>",          mode = { "n", "v" }, desc = "Yank git permalink" },
      { "<leader>gY", "<cmd>GitLink!<cr>",         mode = { "n", "v" }, desc = "Open git permalink in browser" },
      { "<leader>gl", "<cmd>GitLink blame<cr>",    mode = { "n", "v" }, desc = "Yank blame URL" },
      { "<leader>gL", "<cmd>GitLink! blame<cr>",   mode = { "n", "v" }, desc = "Open blame URL in browser" },
    },
    opts = {
      router = {
        browse = {
          ["^dev%.azure%.com"] = function(lk)
            local org, project, repo = lk.remote_url:match(
              "dev%.azure%.com[:/]([^/]+)/([^/]+)/_git/([^/%.]+)"
            )
            if not (org and project and repo) then
              error("could not parse ADO remote: " .. tostring(lk.remote_url))
            end
            local url = string.format(
              "https://dev.azure.com/%s/%s/_git/%s?path=/%s&version=GC%s",
              org, project, repo, lk.file, lk.rev
            )
            if lk.lstart then
              url = url
                .. "&line=" .. lk.lstart
                .. "&lineEnd=" .. (lk.lend or lk.lstart) + 1
                .. "&lineStartColumn=1&lineEndColumn=1"
            end
            return url
          end,
        },
        blame = {
          ["^dev%.azure%.com"] = function(lk)
            local org, project, repo = lk.remote_url:match(
              "dev%.azure%.com[:/]([^/]+)/([^/]+)/_git/([^/%.]+)"
            )
            if not (org and project and repo) then
              error("could not parse ADO remote: " .. tostring(lk.remote_url))
            end
            local url = string.format(
              "https://dev.azure.com/%s/%s/_git/%s/annotate?path=/%s&version=GC%s",
              org, project, repo, lk.file, lk.rev
            )
            if lk.lstart then
              url = url .. "&line=" .. lk.lstart
            end
            return url
          end,
        },
      },
    },
  },
}
