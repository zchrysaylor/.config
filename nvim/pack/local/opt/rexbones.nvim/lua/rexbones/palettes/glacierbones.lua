local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Glacier Mint: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f0f9f6',
    fg = hsluv '#2f4640',
    rose = hsluv '#c05045',
    leaf = hsluv '#3d9060',
    wood = hsluv '#a48224',
    water = hsluv '#3f7ab8',
    blossom = hsluv '#8858ab',
    sky = hsluv '#26948e',
  }, 'light'),
}
