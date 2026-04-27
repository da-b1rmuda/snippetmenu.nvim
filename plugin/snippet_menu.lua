vim.api.nvim_create_user_command("SnippetMenu", function()
  require("snippet_menu").open()
end, {})
