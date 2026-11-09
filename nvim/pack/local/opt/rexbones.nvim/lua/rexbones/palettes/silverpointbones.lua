local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Silver Point Dark: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#131313',
    fg = hsluv '#b4b4b4',
    rose = hsluv '#b4b4b4',
    leaf = hsluv '#707070',
    wood = hsluv '#b4b4b4',
    water = hsluv '#707070',
    blossom = hsluv '#b4b4b4',
    sky = hsluv '#707070',
  }, 'dark'),
  -- Silver Point Light: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f4f4f4',
    fg = hsluv '#1a1a1a',
    rose = hsluv '#5c5c5c',
    leaf = hsluv '#8e8e8e',
    wood = hsluv '#5c5c5c',
    water = hsluv '#8e8e8e',
    blossom = hsluv '#5c5c5c',
    sky = hsluv '#8e8e8e',
  }, 'light'),
}
