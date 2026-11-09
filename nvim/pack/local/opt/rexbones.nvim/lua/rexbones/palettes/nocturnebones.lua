local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Nocturne Rose: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#191216',
    fg = hsluv '#e2cdd6',
    rose = hsluv '#ec6d8b',
    leaf = hsluv '#8cba92',
    wood = hsluv '#dfae79',
    water = hsluv '#8f95d6',
    blossom = hsluv '#cd85c0',
    sky = hsluv '#83b7b2',
  }, 'dark'),
}
