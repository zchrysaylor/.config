local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Ink Meridian: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#101623',
    fg = hsluv '#ccd6ea',
    rose = hsluv '#de6e7c',
    leaf = hsluv '#7cbf8e',
    wood = hsluv '#d9b06e',
    water = hsluv '#6f96e8',
    blossom = hsluv '#a687e0',
    sky = hsluv '#67b7cf',
  }, 'dark'),
}
