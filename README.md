# snippet-menu

Telescope menu to pick + expand VS Code-style JSON snippets via LuaSnip.

## Requirements

- Neovim 0.9+
- `nvim-telescope/telescope.nvim`
- `L3MON4D3/LuaSnip`

## Install (lazy.nvim)

```lua
{
  "yourname/snippet-menu",
  dependencies = { "nvim-telescope/telescope.nvim", "L3MON4D3/LuaSnip" },
  config = function()
    require("snippet_menu").setup({
      -- snippets_dir = vim.fn.stdpath("config") .. "/snippets",
      -- snippets_dir = { vim.fn.stdpath("config") .. "/snippets", vim.fn.stdpath("data") .. "/site/snippets" },
    })
  end,
}
```

## Usage

- `:SnippetMenu`

## Snippet files

The plugin scans `snippets_dir/**\/*.json`.

Recommended layout:

```
<snippets_dir>/
  lua/
    basic.json
  python/
    django.json
```

Each JSON file is VS Code snippet format:

```json
{
  "My snippet name": {
    "prefix": "trig",
    "body": ["line 1", "line 2"],
    "description": "optional"
  }
}
```
