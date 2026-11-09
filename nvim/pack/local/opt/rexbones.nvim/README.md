# rexbones

Rex palettes with Zenbones highlighting, based on the local `petrolbones.nvim` theme.

Includes all 41 palettes from the installed Rex Beta bundle as 39 colorschemes. Merino and Silver Point each have light and dark variants.

Requires [zenbones.nvim](https://github.com/zenbones-theme/zenbones.nvim) and [lush.nvim](https://github.com/rktjmp/lush.nvim).

## Loading

This local package lives at `~/.config/nvim/pack/local/opt/rexbones.nvim/`. With the dependencies loaded:

```vim
packadd rexbones.nvim
colorscheme abyssalbones
```

Use `:colorscheme <name>` to switch themes. Single-appearance themes set `background` to match their Rex source. For Merino and Silver Point, choose the variant with `background`:

```vim
set background=light
colorscheme merinobones
```

The standalone `petrolbones.nvim` package has been replaced by this bundle. This Neovim configuration loads `petrolbones` as a fallback and enables Rex tracking.

## Follow Rex (optional)

Tracking is off by default. The colorschemes work without Rex or a `setup()` call. To follow the local Rex app on macOS, select a fallback first, then enable tracking:

```lua
vim.cmd.packadd 'rexbones.nvim'
vim.cmd.colorscheme 'petrolbones'
require('rexbones').setup { auto_sync = true }
```

The plugin reads Rex's appearance and theme ID asynchronously at setup, startup, UI attachment, and `FocusGained`. There is no polling or terminal palette matching. Overlapping refreshes share the in-flight query, and unchanged themes do not reload highlights. Merino and Silver Point select the matching light/dark variant automatically. Auto appearance follows macOS.

Missing preferences, unknown theme IDs, and unsupported platforms leave the current colorscheme unchanged. Reads have a one-second timeout each. This uses Rex's internal `com.superlogical.rex` preference keys (`Workspace.appearance`, `Workspace.darkThemeID`, and `Workspace.lightThemeID`), which may change in future Rex versions. It reads this Mac's settings, not a remote client's.

Manually loading any colorscheme stops tracking and cancels pending reads. Enable it again with `setup { auto_sync = true }`, or disable it explicitly with `setup { auto_sync = false }`.

## Colorschemes

| Colorscheme | Rex source | Appearance |
| --- | --- | --- |
| `abyssalbones` | Abyssal Trench | dark |
| `alpinebones` | Alpine Milk | light |
| `basaltbones` | Basalt Shore | dark |
| `buttercreambones` | Buttercream Diner | light |
| `cathodebones` | Cathode Amber | dark |
| `charcoalbones` | Charcoal Atelier | dark |
| `cinderbones` | Cinder Peak | dark |
| `coastalbones` | Coastal Linen | light |
| `cobaltbones` | Cobalt Foundry | dark |
| `emberbones` | Ember Hollow | dark |
| `glacierbones` | Glacier Mint | light |
| `heliotropebones` | Heliotrope Haze | dark |
| `inkbones` | Ink Meridian | dark |
| `ivorybones` | Ivory Gallery | light |
| `juniperbones` | Juniper Smoke | dark |
| `lavenderbones` | Lavender Postcard | light |
| `merinobones` | Merino Dark / Merino Light | dark / light |
| `midnightbones` | Midnight Tundra | dark |
| `mistybones` | Misty Forest | dark |
| `mossbones` | Moss Cathedral | dark |
| `neonbones` | Neon Arcade | dark |
| `newsprintbones` | Newsprint Fog | light |
| `nocturnebones` | Nocturne Rose | dark |
| `orchardbones` | Orchard Breeze | light |
| `oxbloodbones` | Oxblood Library | dark |
| `peachbones` | Peach Veranda | light |
| `petrolbones` | Petrol Lagoon | dark |
| `phosphorbones` | Phosphor Archive | dark |
| `polarbones` | Polar Aurora | dark |
| `porcelainbones` | Porcelain Morning | light |
| `umberbones` | Roasted Umber | dark |
| `saffronbones` | Saffron Nightfall | dark |
| `silverpointbones` | Silver Point Dark / Silver Point Light | dark / light |
| `sonoranbones` | Sonoran Dusk | dark |
| `staticbones` | Static Noir | dark |
| `sunlitbones` | Sunlit Parchment | light |
| `terracottabones` | Terracotta Noon | light |
| `velvetbones` | Velvet Dusk | dark |
| `whitbybones` | Whitby Bay | dark |

## Highlighting

Each palette supplies the original Rex sRGB background, foreground, and ANSI colors 1 through 6. The Zenbones slots are `bg`, `fg`, `rose` (red), `leaf` (green), `wood` (yellow), `water` (blue), `blossom` (magenta), and `sky` (cyan). As in the original petrolbones, Lush converts these hex inputs to HSLuv and may round the resulting colors slightly.

Zenbones generates supporting shades and all syntax, Tree-sitter, LSP, and supported plugin highlights. The shared loader retains the existing petrolbones overrides:

- Floating borders use the generated `bg1` shade.
- Help links, help options, and Markdown URLs use `leaf`.

The loader also applies Zenbones' generated 16-color palette to Neovim's embedded terminal, matching the original petrolbones behavior. It does not change Rex's terminal palette. Rex's extended palette, cursor color, and selection color are not inputs.

## Configuration

Standard Zenbones options use the selected colorscheme's name:

```lua
vim.g.abyssalbones = {
  italic_comments = false,
  -- darkness = 'warm',
}
vim.cmd.colorscheme 'abyssalbones'
```

Configuration is per colorscheme. Set options before applying it. Dark-only and light-only settings follow Zenbones' usual behavior.

## Files

- `colors/`: named colorscheme entry points.
- `lua/rexbones/init.lua`: shared Zenbones generator and border/link overrides.
- `lua/rexbones/palettes/`: eight-color palettes; the Petrol Lagoon palette was copied verbatim from the original standalone package.
- `lua/rexbones/themes.lua`: mapping from colorscheme names to Rex source IDs.
- `lua/rexbones/sync.lua`: opt-in, event-driven tracking of local Rex preferences.

The colors were extracted from:

```text
/Applications/Rex Beta.app/Contents/Resources/SuperUI_SuperDesignTokens.bundle/Contents/Resources/themes.json
```

## Tests

Run in a separate headless Neovim process, with Zenbones and Lush installed in the packpath:

```sh
nvim --headless -u NONE -i NONE --noplugin -l ~/.config/nvim/pack/local/opt/rexbones.nvim/tests/smoke.lua
```

Test tracking with mocked preference reads (does not change Rex settings):

```sh
nvim --headless -u NONE -i NONE --noplugin -l ~/.config/nvim/pack/local/opt/rexbones.nvim/tests/sync.lua
```

To also compare every palette against the Rex source:

```sh
REXBONES_REX_THEMES='/Applications/Rex Beta.app/Contents/Resources/SuperUI_SuperDesignTokens.bundle/Contents/Resources/themes.json' \
nvim --headless -u NONE -i NONE --noplugin -l ~/.config/nvim/pack/local/opt/rexbones.nvim/tests/smoke.lua
```
