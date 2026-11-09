local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Midnight Tundra: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0e141b',
    fg = hsluv '#c9d4de',
    rose = hsluv '#d9707c',
    leaf = hsluv '#7fb88a',
    wood = hsluv '#d8b174',
    water = hsluv '#6da3cf',
    blossom = hsluv '#a58cc7',
    sky = hsluv '#6fb5b8',
  }, 'dark'),
}
