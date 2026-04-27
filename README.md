# snippet-menu

Меню сниппетов для Neovim: показывает JSON-сниппеты в Telescope и разворачивает выбранный через LuaSnip.

## Как пользоваться

1) Положи сниппеты в `snippets_dir` (структура ниже).
2) Открой меню: `:SnippetMenu`.
3) Выбери папку (filetype) -> сниппет -> Enter.

## Требования

- Neovim 0.9+
- `nvim-telescope/telescope.nvim`
- `L3MON4D3/LuaSnip`
- (опционально) `nvim-tree/nvim-web-devicons` для иконок filetype

## Установка (lazy.nvim)

```lua
{
  "da-b1rmuda/snippetmenu.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "L3MON4D3/LuaSnip",
  },
  config = function()
    require("snippet_menu").setup({
      -- Путь до папки со сниппетами (имя папки = filetype)
      -- snippets_dir = vim.fn.stdpath("config") .. "/snippets",

      -- Можно указать несколько директорий:
      -- snippets_dir = {
      --   vim.fn.stdpath("config") .. "/snippets",
      --   vim.fn.stdpath("data") .. "/site/snippets",
      -- },

      -- Показывать только текущий filetype (и опциональный "all")
      -- filter_current_ft = true,

      -- Preview справа для сниппетов (Telescope previewer)
      -- preview = true,

      -- Кэш: ускоряет открытие (не парсит все JSON каждый раз)
      -- cache = true,
      -- cache_autocmd = true, -- инвалидировать кэш при сохранении *.json внутри snippets_dir

      -- Быстрые клавиши внутри Telescope (можно переопределить или отключить)
      -- keys = {
      --   refresh = "<C-r>",           -- пересканировать/перечитать сниппеты
      --   back = "<BS>",              -- назад к списку папок (в списке сниппетов)
      --   open_split_preview = "<C-p>" -- toggle preview (если доступно)
      -- },
    })
  end,
}
```

## Структура сниппетов

Плагин сканирует `snippets_dir/**/.json` (вложенные папки поддерживаются).

Рекомендуемая структура:

```
<snippets_dir>/
  lua/
    basic.json
  javascript/
    basic.json
  typescript/
    basic.json
```

Формат файла: VS Code snippet JSON.

```json
{
  "Console log": {
    "prefix": ["cl", "log"],
    "body": ["console.log($1);"],
    "description": "console.log(...)"
  }
}
```

## Интеграция с nvim-cmp (показ сниппетов в автодополнении)

Важно: `snippet-menu` - это меню (Telescope).
Чтобы сниппеты были в `nvim-cmp`, их должен загрузить LuaSnip loader.
Сам `snippet-menu` читает `*.json` напрямую и не требует `package.json`.

### 1) Добавь `package.json` рядом со сниппетами

LuaSnip `from_vscode` ожидает manifest `package.json` (как у VS Code extension).

Пример: `<snippets_dir>/package.json`

```json
{
  "name": "nvim-local-snippets",
  "contributes": {
    "snippets": [
      { "language": "javascript", "path": "./javascript/basic.json" },
      { "language": "javascriptreact", "path": "./javascript/basic.json" },
      { "language": "typescript", "path": "./typescript/basic.json" },
      { "language": "typescriptreact", "path": "./typescript/basic.json" }
    ]
  }
}
```

### 2) Загрузить сниппеты в LuaSnip

Пример для `nvim-cmp` (внутри `cmp.lua`):

```lua
local vscode_loader = require("luasnip.loaders.from_vscode")

-- Опционально: friendly-snippets
vscode_loader.lazy_load()

-- Твои JSON сниппеты (где лежит package.json)
vscode_loader.lazy_load({
  -- Укажи путь к папке, где лежит package.json (обычно это твой snippets_dir)
  paths = { vim.fn.stdpath("config") .. "/snippets" },
})
```

После этого source `{ name = "luasnip" }` в `nvim-cmp` начнет показывать сниппеты.

## Частые проблемы

- В `cmp` нет сниппетов: проверь, что есть `package.json` и вызван `from_vscode.lazy_load({ paths = {...} })`.
- `:SnippetMenu` не открывается: проверь, что установлен Telescope.
- Выбор сниппета не вставляет текст: проверь, что установлен LuaSnip.

