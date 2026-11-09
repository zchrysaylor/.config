local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Terracotta Noon: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f9efe6',
    fg = hsluv '#4a382c',
    rose = hsluv '#bd4a2d',
    leaf = hsluv '#5f8a3a',
    wood = hsluv '#a97a16',
    water = hsluv '#47709f',
    blossom = hsluv '#9d5680',
    sky = hsluv '#3e8570',
  }, 'light'),
}
