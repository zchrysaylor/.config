local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Basalt Shore: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#14181a',
    fg = hsluv '#c8d3d3',
    rose = hsluv '#dd7a72',
    leaf = hsluv '#7cbfa0',
    wood = hsluv '#d2b071',
    water = hsluv '#729fc0',
    blossom = hsluv '#a68fc0',
    sky = hsluv '#66c2b5',
  }, 'dark'),
}
