local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Cobalt Foundry: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#10151c',
    fg = hsluv '#c2cedb',
    rose = hsluv '#e57373',
    leaf = hsluv '#81b366',
    wood = hsluv '#d4a95f',
    water = hsluv '#4f95e0',
    blossom = hsluv '#9d85cf',
    sky = hsluv '#56b3c4',
  }, 'dark'),
}
