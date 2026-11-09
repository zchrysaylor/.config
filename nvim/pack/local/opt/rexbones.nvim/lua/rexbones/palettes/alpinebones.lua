local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Alpine Milk: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#fafafa',
    fg = hsluv '#333940',
    rose = hsluv '#c94f46',
    leaf = hsluv '#4a9256',
    wood = hsluv '#b28422',
    water = hsluv '#3d7cc9',
    blossom = hsluv '#8a5fb0',
    sky = hsluv '#2e8fa0',
  }, 'light'),
}
