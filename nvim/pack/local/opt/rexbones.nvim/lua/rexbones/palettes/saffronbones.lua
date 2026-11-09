local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Saffron Nightfall: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#131320',
    fg = hsluv '#d9d4c8',
    rose = hsluv '#e0705f',
    leaf = hsluv '#9cb56b',
    wood = hsluv '#ffc247',
    water = hsluv '#7d8fd0',
    blossom = hsluv '#bb87c0',
    sky = hsluv '#76b7ad',
  }, 'dark'),
}
