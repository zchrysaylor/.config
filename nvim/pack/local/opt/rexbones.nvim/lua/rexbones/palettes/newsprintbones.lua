local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Newsprint Fog: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f2f2f0',
    fg = hsluv '#333331',
    rose = hsluv '#b3402e',
    leaf = hsluv '#5d7f52',
    wood = hsluv '#987921',
    water = hsluv '#4f6d94',
    blossom = hsluv '#85607f',
    sky = hsluv '#4d7f7c',
  }, 'light'),
}
