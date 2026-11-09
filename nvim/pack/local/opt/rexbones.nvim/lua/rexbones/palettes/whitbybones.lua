local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Whitby Bay: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#272a38',
    fg = hsluv '#f7f7ee',
    rose = hsluv '#ff5d57',
    leaf = hsluv '#4df08a',
    wood = hsluv '#f5f28a',
    water = hsluv '#b696f7',
    blossom = hsluv '#ff7ed1',
    sky = hsluv '#90ecf6',
  }, 'dark'),
}
