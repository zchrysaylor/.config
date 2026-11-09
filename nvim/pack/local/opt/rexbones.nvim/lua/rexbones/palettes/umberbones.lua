local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Roasted Umber: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#16110d',
    fg = hsluv '#d9c8b8',
    rose = hsluv '#cf6f52',
    leaf = hsluv '#96a86a',
    wood = hsluv '#d3a35f',
    water = hsluv '#8c95a8',
    blossom = hsluv '#b58a92',
    sky = hsluv '#8fac93',
  }, 'dark'),
}
