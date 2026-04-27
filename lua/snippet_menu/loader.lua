local config = require("snippet_menu.config")
local parser = require("snippet_menu.parser")
local utils = require("snippet_menu.utils")

local M = {}

local function to_slash(path)
  return (path or ""):gsub("\\", "/")
end

function M.files()
  local dirs = utils.as_list(config.options.snippets_dir)
  local out = {}

  for _, dir in ipairs(dirs) do
    local pattern = to_slash(dir) .. "/**/*.json"
    local files = vim.fn.glob(pattern, false, true)
    for _, f in ipairs(files) do
      table.insert(out, f)
    end
  end

  return out
end

function M.load_json(path)
  local content = utils.read_file(path)
  if not content or content == "" then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return decoded
end

function M.collect()
  local entries = {}

  for _, file in ipairs(M.files()) do
    local ok, json = pcall(M.load_json, file)

    if ok and json then
      local ft = vim.fn.fnamemodify(vim.fn.fnamemodify(file, ":h"), ":t")
      local group = vim.fn.fnamemodify(file, ":t:r")

      for name, snip in pairs(json) do
        table.insert(
          entries,
          parser.normalize_vscode_snippet(name, snip, {
            filetype = ft,
            group = group,
            path = file,
          })
        )
      end
    end
  end

  return entries
end

return M
