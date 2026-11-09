local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Ivory Gallery: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#ffffff',
    fg = hsluv '#1f2328',
    rose = hsluv '#c13a24',
    leaf = hsluv '#2f7d3c',
    wood = hsluv '#9a6a00',
    water = hsluv '#1a6fd4',
    blossom = hsluv '#7d4bb5',
    sky = hsluv '#1b7c8c',
  }, 'light'),
}
