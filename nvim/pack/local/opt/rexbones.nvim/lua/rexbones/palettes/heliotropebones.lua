local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Heliotrope Haze: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#14101f',
    fg = hsluv '#dcd2ee',
    rose = hsluv '#f66e93',
    leaf = hsluv '#72e0aa',
    wood = hsluv '#fdca6a',
    water = hsluv '#7a9bf5',
    blossom = hsluv '#c980f2',
    sky = hsluv '#5fd0e5',
  }, 'dark'),
}
