local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Cathode Amber: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#140f08',
    fg = hsluv '#f0c88a',
    rose = hsluv '#e8763f',
    leaf = hsluv '#b8a83f',
    wood = hsluv '#ffb642',
    water = hsluv '#c98d4f',
    blossom = hsluv '#cf8a62',
    sky = hsluv '#d4a852',
  }, 'dark'),
}
