local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Sonoran Dusk: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#171412',
    fg = hsluv '#ddd0bf',
    rose = hsluv '#d96e56',
    leaf = hsluv '#a0b06a',
    wood = hsluv '#e0a45c',
    water = hsluv '#8598b0',
    blossom = hsluv '#bd8aa2',
    sky = hsluv '#92b39c',
  }, 'dark'),
}
