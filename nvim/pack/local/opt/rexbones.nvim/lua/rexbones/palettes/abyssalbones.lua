local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Abyssal Trench: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#06101a',
    fg = hsluv '#b8cdd9',
    rose = hsluv '#e26a6a',
    leaf = hsluv '#52c79a',
    wood = hsluv '#d4b25e',
    water = hsluv '#4a90c9',
    blossom = hsluv '#9179c9',
    sky = hsluv '#3fbdc9',
  }, 'dark'),
}
