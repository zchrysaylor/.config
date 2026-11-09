local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Sunlit Parchment: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f8f2e3',
    fg = hsluv '#4a3f2e',
    rose = hsluv '#b8442f',
    leaf = hsluv '#587f35',
    wood = hsluv '#9a7410',
    water = hsluv '#3a6ea5',
    blossom = hsluv '#96568e',
    sky = hsluv '#337a70',
  }, 'light'),
}
