local M = {}

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "snippet-menu" })
end

function M.safe_require(mod)
  local ok, loaded = pcall(require, mod)
  if not ok then
    return nil
  end
  return loaded
end

function M.as_list(value)
  if value == nil then
    return {}
  end
  if type(value) == "table" then
    return value
  end
  return { value }
end

function M.read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return nil
  end
  return table.concat(lines, "\n")
end

return M
