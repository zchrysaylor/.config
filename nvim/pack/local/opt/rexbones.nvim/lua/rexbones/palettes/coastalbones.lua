local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Coastal Linen: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#faf6ee',
    fg = hsluv '#3d4652',
    rose = hsluv '#c25547',
    leaf = hsluv '#57904d',
    wood = hsluv '#ac8125',
    water = hsluv '#3a74ad',
    blossom = hsluv '#91589a',
    sky = hsluv '#2f8fa6',
  }, 'light'),
}
