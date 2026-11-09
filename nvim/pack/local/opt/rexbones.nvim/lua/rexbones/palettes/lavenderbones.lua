local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Lavender Postcard: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f7f4fb',
    fg = hsluv '#40374f',
    rose = hsluv '#c04e56',
    leaf = hsluv '#4a8f56',
    wood = hsluv '#a67e28',
    water = hsluv '#4a6fc0',
    blossom = hsluv '#8557b8',
    sky = hsluv '#3e8496',
  }, 'light'),
}
