local M = {}

M.options = {
  snippets_dir = vim.fn.stdpath("config") .. "/snippets",
  include_current_ft = true,
  include_all = true,
  -- v2: when true, show only current buffer filetype (and optional "all")
  filter_current_ft = false,
  -- v3: Telescope preview panel on the right for snippet items
  preview = true,
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
