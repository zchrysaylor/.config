local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Orchard Breeze: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f4f9ef',
    fg = hsluv '#3a4a35',
    rose = hsluv '#c65043',
    leaf = hsluv '#4f9440',
    wood = hsluv '#a8831f',
    water = hsluv '#4478b0',
    blossom = hsluv '#90569c',
    sky = hsluv '#37897a',
  }, 'light'),
}
