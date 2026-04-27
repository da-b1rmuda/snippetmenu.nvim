local M = {}

local function normalize_prefix(prefix)
  if prefix == nil then
    return { list = {}, display = "" }
  end

  if type(prefix) == "string" then
    return { list = { prefix }, display = prefix }
  end

  if type(prefix) == "table" then
    local list = {}
    for _, p in ipairs(prefix) do
      if type(p) == "string" and p ~= "" then
        table.insert(list, p)
      end
    end
    return { list = list, display = table.concat(list, ", ") }
  end

  return { list = {}, display = "" }
end

local function normalize_body(body)
  if body == nil then
    return { lines = {}, text = "" }
  end

  if type(body) == "string" then
    return { lines = vim.split(body, "\n", { plain = true }), text = body }
  end

  if type(body) == "table" then
    local lines = {}
    for _, line in ipairs(body) do
      if type(line) == "string" then
        table.insert(lines, line)
      end
    end
    return { lines = lines, text = table.concat(lines, "\n") }
  end

  return { lines = {}, text = "" }
end

function M.normalize_vscode_snippet(name, snip, meta)
  meta = meta or {}
  snip = snip or {}

  local prefix = normalize_prefix(snip.prefix)
  local body = normalize_body(snip.body)

  return {
    name = name or "",
    prefix = prefix.display,
    prefixes = prefix.list,
    body = body.text,
    body_lines = body.lines,
    description = snip.description or "",
    filetype = meta.filetype or "",
    group = meta.group or "",
    path = meta.path or "",
  }
end

return M
