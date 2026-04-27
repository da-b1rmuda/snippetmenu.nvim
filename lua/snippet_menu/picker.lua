local loader = require("snippet_menu.loader")
local utils = require("snippet_menu.utils")

local M = {}

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

function M.open()
  local pickers = utils.safe_require("telescope.pickers")
  local finders = utils.safe_require("telescope.finders")
  local actions = utils.safe_require("telescope.actions")
  local action_state = utils.safe_require("telescope.actions.state")
  local telescope_config = utils.safe_require("telescope.config")

  if not (pickers and finders and actions and action_state and telescope_config) then
    utils.notify("Telescope is required (missing 'nvim-telescope/telescope.nvim').", vim.log.levels.ERROR)
    return
  end

  pickers
    .new({}, {
      prompt_title = "Snippets",

      finder = finders.new_table({
        results = loader.collect(),

        entry_maker = function(entry)
          local prefix = entry.prefix
          if prefix == "" and entry.prefixes and #entry.prefixes > 0 then
            prefix = table.concat(entry.prefixes, ", ")
          end
          if prefix == "" then
            prefix = "(no prefix)"
          end

          return {
            value = entry,
            display = string.format("[%s/%s] %s -> %s", entry.filetype, entry.group, prefix, entry.name),
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

      attach_mappings = function(prompt_bufnr)
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

return M
