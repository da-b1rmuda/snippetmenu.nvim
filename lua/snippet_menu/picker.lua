local loader = require("snippet_menu.loader")
local utils = require("snippet_menu.utils")
local config = require("snippet_menu.config")

local M = {}

local function hint_segment(key, label)
  if not key or key == "" then
    return nil
  end
  return string.format("%s %s", key, label)
end

local function join_hints(parts)
  local out = {}
  for _, p in ipairs(parts) do
    if p and p ~= "" then
      table.insert(out, p)
    end
  end
  return table.concat(out, "  •  ")
end

local function folder_hints()
  if config.options.show_hints == false then
    return nil
  end

  local keys = config.options.keys or {}
  return join_hints({
    hint_segment("ESC", "close"),
    hint_segment(keys.refresh, "refresh"),
  })
end

local function snippet_hints()
  if config.options.show_hints == false then
    return nil
  end

  local keys = config.options.keys or {}
  local back = keys.back_alt or keys.back

  return join_hints({
    hint_segment("ESC", "close"),
    hint_segment(back, "back"),
    hint_segment(keys.refresh, "refresh"),
    hint_segment(keys.open_split_preview, "preview"),
  })
end

local function expand(entry)
  local ls = utils.safe_require("luasnip")
  if not ls then
    utils.notify("LuaSnip is required to expand snippets (missing 'L3MON4D3/LuaSnip').", vim.log.levels.ERROR)
    return
  end

  if not entry.body or entry.body == "" then
    utils.notify("Snippet body is empty.", vim.log.levels.WARN)
    return
  end

  ls.lsp_expand(entry.body)
end

local function telescope_modules()
  local pickers = utils.safe_require("telescope.pickers")
  local finders = utils.safe_require("telescope.finders")
  local actions = utils.safe_require("telescope.actions")
  local action_state = utils.safe_require("telescope.actions.state")
  local telescope_config = utils.safe_require("telescope.config")
  local previewers = utils.safe_require("telescope.previewers")

  if not (pickers and finders and actions and action_state and telescope_config) then
    utils.notify("Telescope is required (missing 'nvim-telescope/telescope.nvim').", vim.log.levels.ERROR)
    return nil
  end

  return {
    pickers = pickers,
    finders = finders,
    actions = actions,
    action_state = action_state,
    telescope_config = telescope_config,
    previewers = previewers,
  }
end

local function get_icon_for_filetype(filetype)
  local devicons = utils.safe_require("nvim-web-devicons")
  if not devicons then
    return ""
  end

  if devicons.get_icon_by_filetype then
    local icon = devicons.get_icon_by_filetype(filetype, { default = true })
    if icon then
      return icon .. " "
    end
  end

  local ext_by_ft = {
    lua = "lua",
    python = "py",
    javascript = "js",
    javascriptreact = "jsx",
    typescript = "ts",
    typescriptreact = "tsx",
    json = "json",
    html = "html",
    css = "css",
    sh = "sh",
    bash = "sh",
  }

  local ext = ext_by_ft[filetype] or "txt"
  local icon = devicons.get_icon("file." .. ext, ext, { default = true })
  if icon then
    return icon .. " "
  end

  return ""
end

local function open_snippets_picker(mods, entries, title_suffix, filter_ft)
  local pickers = mods.pickers
  local finders = mods.finders
  local actions = mods.actions
  local action_state = mods.action_state
  local telescope_config = mods.telescope_config
  local previewers = mods.previewers

  local previewer = nil
  if config.options.preview and previewers and previewers.new_buffer_previewer then
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        local value = entry and entry.value or nil
        if not value then
          return
        end

        local lines = {
          string.format("%s", value.name or ""),
          string.format("filetype: %s", value.filetype or ""),
          string.format("group:    %s", value.group or ""),
          string.format("prefix:   %s", (value.prefix and value.prefix ~= "" and value.prefix) or table.concat(value.prefixes or {}, ", ")),
          string.format("desc:     %s", value.description or ""),
          "",
          "----",
          "",
        }

        local body_lines = value.body_lines
        if not body_lines or #body_lines == 0 then
          body_lines = vim.split(value.body or "", "\n", { plain = true })
        end

        for _, l in ipairs(body_lines) do
          table.insert(lines, l)
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].modifiable = false

        if value.filetype and value.filetype ~= "" then
          pcall(function()
            vim.bo[self.state.bufnr].filetype = value.filetype
          end)
        end
      end,
    })
  end

  pickers
    .new({}, {
      prompt_title = "Snippets" .. (title_suffix or ""),
      results_title = snippet_hints(),

      finder = finders.new_table({
        results = entries,

        entry_maker = function(entry)
          local prefix = entry.prefix
          if prefix == "" and entry.prefixes and #entry.prefixes > 0 then
            prefix = table.concat(entry.prefixes, ", ")
          end
          if prefix == "" then
            prefix = "(no prefix)"
          end

          local icon = get_icon_for_filetype(entry.filetype)

          return {
            value = entry,
            display = string.format("%s[%s] %s -> %s", icon, entry.group, prefix, entry.name),
            ordinal = table.concat({
              entry.filetype,
              entry.group,
              prefix,
              entry.name,
              entry.description,
            }, " "),
          }
        end,
      }),

      sorter = telescope_config.values.generic_sorter({}),
      previewer = previewer,

      attach_mappings = function(prompt_bufnr, map)
        local keys = config.options.keys or {}
        local layout_actions = utils.safe_require("telescope.actions.layout")

        local refresh_key = keys.refresh
        if refresh_key then
          map({ "i", "n" }, refresh_key, function()
            require("snippet_menu.loader").invalidate()
            actions.close(prompt_bufnr)

            local all = require("snippet_menu.loader").collect()
            local refreshed = all
            if filter_ft and filter_ft ~= "" then
              refreshed = {}
              for _, e in ipairs(all) do
                if e.filetype == filter_ft then
                  table.insert(refreshed, e)
                end
              end
            end

            open_snippets_picker(mods, refreshed, title_suffix, filter_ft)
          end)
        end

        local back_key = keys.back
        if back_key then
          map({ "i", "n" }, back_key, function()
            actions.close(prompt_bufnr)
            M.open()
          end)
        end

        local back_alt_key = keys.back_alt
        if back_alt_key then
          map({ "i", "n" }, back_alt_key, function()
            actions.close(prompt_bufnr)
            M.open()
          end)
        end

        local toggle_preview_key = keys.open_split_preview
        if toggle_preview_key and layout_actions and layout_actions.toggle_preview then
          map({ "i", "n" }, toggle_preview_key, layout_actions.toggle_preview)
        end

        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          expand(selection.value)
        end)

        return true
      end,
    })
    :find()
end

local function filetype_items(entries)
  local counts = {}
  for _, e in ipairs(entries) do
    local ft = e.filetype or ""
    if ft ~= "" then
      counts[ft] = (counts[ft] or 0) + 1
    end
  end

  local items = {}
  for ft, count in pairs(counts) do
    table.insert(items, { filetype = ft, count = count })
  end

  table.sort(items, function(a, b)
    return a.filetype < b.filetype
  end)

  return items
end

function M.open()
  local mods = telescope_modules()
  if not mods then
    return
  end

  local all_entries = loader.collect()
  local items = filetype_items(all_entries)
  local current_ft = vim.bo.filetype

  if config.options.filter_current_ft and current_ft and current_ft ~= "" then
    local filtered_items = {}
    for _, item in ipairs(items) do
      if item.filetype == current_ft then
        table.insert(filtered_items, item)
        break
      end
    end
    items = filtered_items
  end

  if config.options.include_all then
    table.insert(items, 1, { filetype = "__all__", count = #all_entries })
  end

  if config.options.include_current_ft then
    if current_ft and current_ft ~= "" then
      for i, item in ipairs(items) do
        if item.filetype == current_ft then
          table.remove(items, i)
          table.insert(items, 1, item)
          break
        end
      end
    end
  end

  mods.pickers
    .new({}, {
      prompt_title = "Snippet folders",
      results_title = folder_hints(),

      finder = mods.finders.new_table({
        results = items,

        entry_maker = function(item)
          local ft = item.filetype
          local is_all = ft == "__all__"
          local label = is_all and "all" or ft
          local icon = is_all and "󰒲 " or get_icon_for_filetype(ft)

          return {
            value = item,
            display = string.format("%s%s (%d)", icon, label, item.count or 0),
            ordinal = label,
          }
        end,
      }),

      sorter = mods.telescope_config.values.generic_sorter({}),

      attach_mappings = function(prompt_bufnr, map)
        local keys = config.options.keys or {}

        local refresh_key = keys.refresh
        if refresh_key then
          map({ "i", "n" }, refresh_key, function()
            require("snippet_menu.loader").invalidate()
            mods.actions.close(prompt_bufnr)
            M.open()
          end)
        end

        mods.actions.select_default:replace(function()
          local selection = mods.action_state.get_selected_entry()
          mods.actions.close(prompt_bufnr)

          local item = selection.value
          if item.filetype == "__all__" then
            open_snippets_picker(mods, all_entries, " (all)", nil)
            return
          end

          local filtered = {}
          for _, e in ipairs(all_entries) do
            if e.filetype == item.filetype then
              table.insert(filtered, e)
            end
          end

          open_snippets_picker(mods, filtered, " (" .. item.filetype .. ")", item.filetype)
        end)

        return true
      end,
    })
    :find()
end

return M
