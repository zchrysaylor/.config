local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Misty Forest: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#131a16',
    fg = hsluv '#c4d2c5',
    rose = hsluv '#cf7a70',
    leaf = hsluv '#8fbf8f',
    wood = hsluv '#c9ad72',
    water = hsluv '#77a3b5',
    blossom = hsluv '#a793bb',
    sky = hsluv '#7cb5a3',
  }, 'dark'),
}
