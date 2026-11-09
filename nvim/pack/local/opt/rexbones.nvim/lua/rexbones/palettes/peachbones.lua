local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Peach Veranda: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#fdf3ec',
    fg = hsluv '#4d3a33',
    rose = hsluv '#c44f36',
    leaf = hsluv '#578c42',
    wood = hsluv '#ab7c1c',
    water = hsluv '#4472ac',
    blossom = hsluv '#9c5589',
    sky = hsluv '#3a8878',
  }, 'light'),
}
