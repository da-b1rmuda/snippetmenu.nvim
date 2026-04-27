local config = require("snippet_menu.config")
local parser = require("snippet_menu.parser")
local utils = require("snippet_menu.utils")

local M = {}

local function to_slash(path)
  return (path or ""):gsub("\\", "/")
end

local cache = {
  files = nil, -- array of file paths
  by_file = {}, -- [path] = { mtime = number, entries = table }
  enabled = true,
}

local function file_mtime(path)
  local uv = vim.uv or vim.loop
  if not uv or not uv.fs_stat then
    return nil
  end

  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end

  local mt = stat.mtime
  if type(mt) == "table" then
    local sec = mt.sec or 0
    local nsec = mt.nsec or 0
    return sec * 1e9 + nsec
  end

  if type(mt) == "number" then
    return mt
  end

  return nil
end

local function same_files(a, b)
  if a == b then
    return true
  end
  if not a or not b then
    return false
  end
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
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

  table.sort(out)
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

function M.invalidate(path)
  if path then
    cache.by_file[path] = nil
    cache.files = nil
    return
  end

  cache.by_file = {}
  cache.files = nil
end

function M.setup()
  cache.enabled = config.options.cache ~= false

  if config.options.cache_autocmd == false then
    return
  end

  local group = vim.api.nvim_create_augroup("SnippetMenuCache", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.json",
    callback = function(args)
      local file = args and args.file or nil
      if not file or file == "" then
        return
      end

      local file_slash = to_slash(file)
      local dirs = utils.as_list(config.options.snippets_dir)
      for _, dir in ipairs(dirs) do
        local dir_slash = to_slash(dir)
        if dir_slash ~= "" and file_slash:sub(1, #dir_slash) == dir_slash then
          M.invalidate(file)
          return
        end
      end
    end,
  })
end

function M.collect()
  local files = M.files()
  local use_cache = cache.enabled and config.options.cache ~= false

  if not use_cache then
    cache.files = nil
    cache.by_file = {}
  end

  local should_rebuild_all = not use_cache or not same_files(cache.files, files)
  cache.files = files

  local entries = {}

  -- Drop cache entries for removed files.
  if use_cache and should_rebuild_all then
    local keep = {}
    for _, f in ipairs(files) do
      keep[f] = true
    end
    for path, _ in pairs(cache.by_file) do
      if not keep[path] then
        cache.by_file[path] = nil
      end
    end
  end

  for _, file in ipairs(files) do
    local cached = use_cache and cache.by_file[file] or nil
    local mt = use_cache and file_mtime(file) or nil

    if cached and mt and cached.mtime == mt and cached.entries then
      for _, e in ipairs(cached.entries) do
        table.insert(entries, e)
      end
    else
      local ok, json = pcall(M.load_json, file)
      if ok and json then
        local ft = vim.fn.fnamemodify(vim.fn.fnamemodify(file, ":h"), ":t")
        local group = vim.fn.fnamemodify(file, ":t:r")

        local built = {}
        for name, snip in pairs(json) do
          table.insert(
            built,
            parser.normalize_vscode_snippet(name, snip, {
              filetype = ft,
              group = group,
              path = file,
            })
          )
        end

        for _, e in ipairs(built) do
          table.insert(entries, e)
        end

        if use_cache then
          cache.by_file[file] = { mtime = mt, entries = built }
        end
      end
    end
  end

  return entries
end

return M
