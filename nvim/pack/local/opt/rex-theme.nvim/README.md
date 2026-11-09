# rex-theme.nvim

A Neovim colorscheme that adapts TokyoNight's highlights to your terminal's colors. Designed for Rex, it queries the host terminal directly rather than reading terminal configuration files.

## Requirements

- Neovim 0.12 or newer.
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) on `runtimepath`. Tested with version 4.14.1. Rex uses TokyoNight's palette and highlight APIs, so upstream changes may require updates.
- A true-color terminal that answers OSC 4 queries for the 16 ANSI colors and OSC 10/11 queries for foreground/background. OSC 12 cursor-color replies are optional.

Headless instances and UIs without a terminal use the cached palette or the TokyoNight fallback without sending queries.

## Installation

Install this plugin and TokyoNight with your plugin manager. Load TokyoNight before applying the Rex colorscheme.

For a local checkout, place this directory at `~/.config/nvim/pack/local/opt/rex-theme.nvim/`. With Neovim's built-in package manager:

```lua
vim.pack.add { 'https://github.com/folke/tokyonight.nvim' }
vim.cmd.packadd 'rex-theme.nvim'
vim.cmd.colorscheme 'rex'
```

`setup()` is optional. To configure the plugin, call it before applying the colorscheme:

```lua
require('rex-theme').setup {
  query_timeout = 800,
  -- cache_file = false, -- Uncomment to disable disk caching.
}
vim.cmd.colorscheme 'rex'
```

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `query_timeout` | `800` | Positive integer in milliseconds. Maximum time to collect a palette. Complete replies apply on the next event-loop turn. |
| `cache_file` | See below | Cache path, or `false` to disable disk caching. |

The default cache is `stdpath('cache')/rex-theme/<terminal-hash>.json`, keyed by `TERM_PROGRAM` and `TERM`. Sessions with the same terminal signature share it. Use a separate `cache_file` if those sessions need different cached themes.

Calling `setup()` again cancels the pending query and keeps the currently rendered colors until a fresh palette is available. It does not replace active colors with the newly configured cache file.

## Palette updates

Rex renders cached colors immediately. Without a valid cache, it starts with TokyoNight Night. It then queries the terminal at startup, when a terminal UI attaches, and when focus is gained.

- All 16 ANSI colors and the foreground/background must arrive before a palette can apply. Incomplete replies preserve the last complete palette.
- A complete reply including the cursor color applies without waiting for the timeout. If the cursor reply is missing, Rex waits until the timeout and uses the foreground color for the cursor.
- Focus or manual refresh requests received during a query coalesce into one follow-up query. There is no idle polling.
- Unchanged palettes do not rebuild highlights or rewrite the cache. Changed palettes emit a normal `ColorScheme rex` event so other plugins can restore their highlights.
- Switching to another colorscheme cancels pending work.

ANSI colors supply syntax and diagnostic accents. Neutral UI colors come from the terminal's foreground/background so light palettes do not get white-on-white messages or black cursor lines. Terminal buffer ANSI colors remain unchanged. Accent readability still depends on the terminal palette.

Selection colors are derived from a 35% blend of ANSI blue over the background, with the terminal foreground for selected text. They are not queried from the terminal.

Rex passes per-load options to TokyoNight without replacing its saved configuration. TokyoNight can still read and update its own highlight cache.

### Manual refresh

```vim
:RexThemeRefresh
```

Or from Lua:

```lua
local theme = require 'rex-theme'
theme.refresh()
local palette = theme.get_palette()
```

`refresh()` returns `true` when it sends a query and `false` otherwise. A request made while another query is pending queues one follow-up query. `get_palette()` returns a copy of the last complete palette, or `nil` when using the fallback.

## Tests

From this checkout, point the runner at a TokyoNight checkout:

```sh
TOKYONIGHT_PATH=/path/to/tokyonight.nvim \
  nvim --headless -u NONE -i NONE -l tests/run.lua
```

Alternatively, add TokyoNight to `runtimepath` before running the script. Tests mock terminal replies and use temporary files for both Rex and TokyoNight caches. They cover parsing, partial and duplicate replies, early completion, focus retries, cancellation, cache failures, repeated setup, theme switching, and light/dark neutral-color contrast.

## License

MIT. See [LICENSE](LICENSE). TokyoNight is a separate dependency with its own license.
