local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Oxblood Library: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#191012',
    fg = hsluv '#dfcbc2',
    rose = hsluv '#cf5a52',
    leaf = hsluv '#94ad72',
    wood = hsluv '#d8a55c',
    water = hsluv '#8f97b8',
    blossom = hsluv '#c07e93',
    sky = hsluv '#8fb0a0',
  }, 'dark'),
}
