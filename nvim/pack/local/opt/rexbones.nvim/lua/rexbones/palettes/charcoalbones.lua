local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Charcoal Atelier: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#161616',
    fg = hsluv '#d6d2cc',
    rose = hsluv '#d96a4d',
    leaf = hsluv '#9aab84',
    wood = hsluv '#cfae7a',
    water = hsluv '#8aa0b4',
    blossom = hsluv '#b193a8',
    sky = hsluv '#8fafa8',
  }, 'dark'),
}
